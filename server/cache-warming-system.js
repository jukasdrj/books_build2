/**
 * Automatic Cache Warming System for CloudFlare Books Proxy
 * Pre-loads new releases, popular books, and historical bestsellers
 * Uses intelligent rate limiting and multiple API providers
 */

export class CacheWarmer {
  constructor(env, ctx) {
    this.env = env;
    this.ctx = ctx;
    
    // Rate limiting configuration
    this.rateLimits = {
      googleBooks: { daily: 1000, perSecond: 10, current: 0 },
      isbndb: { monthly: 8000, current: 0 },
      openLibrary: { perMinute: 100, current: 0 }
    };
  }

  // ===== NEW RELEASE DETECTION & CACHING =====
  
  async warmNewReleases(days = 7) {
    console.log(`🆕 WARMING NEW RELEASES: Last ${days} days`);
    
    const results = {
      processed: 0,
      cached: 0,
      errors: [],
      startTime: Date.now()
    };

    try {
      // Calculate date range for new releases
      const endDate = new Date();
      const startDate = new Date();
      startDate.setDate(startDate.getDate() - days);
      
      const dateRange = {
        start: startDate.toISOString().split('T')[0],
        end: endDate.toISOString().split('T')[0]
      };

      // Search strategies for new releases
      const searchStrategies = [
        {
          provider: 'google-books',
          queries: [
            `publishedDate:${dateRange.start}..${dateRange.end} subject:fiction orderBy=newest`,
            `publishedDate:${dateRange.start}..${dateRange.end} subject:"literary fiction" orderBy=newest`,
            `publishedDate:${dateRange.start}..${dateRange.end} subject:biography orderBy=newest`,
            `publishedDate:${dateRange.start}..${dateRange.end} subject:history orderBy=newest`,
            `publishedDate:${dateRange.start}..${dateRange.end} subject:science orderBy=newest`
          ]
        }
      ];

      // Process each search strategy
      for (const strategy of searchStrategies) {
        for (const query of strategy.queries) {
          try {
            await this.rateLimitDelay(strategy.provider);
            
            const books = await this.searchAndCacheBooks(query, 20, strategy.provider);
            results.processed += books.length;
            results.cached += books.filter(b => b.cached).length;
            
            console.log(`📚 Processed ${books.length} books from query: ${query.substring(0, 50)}...`);
            
          } catch (error) {
            results.errors.push({
              query: query,
              provider: strategy.provider,
              error: error.message
            });
          }
        }
      }

      // Store warming progress
      await this.storeWarmingProgress('new-releases', {
        ...results,
        dateRange: dateRange,
        completedAt: Date.now()
      });

      console.log(`✅ NEW RELEASES WARMING COMPLETE: ${results.cached}/${results.processed} books cached`);
      return results;

    } catch (error) {
      console.error('New releases warming failed:', error);
      results.errors.push({ general: error.message });
      return results;
    }
  }

  // ===== HISTORICAL TOP BOOKS CACHING =====

  async warmHistoricalBestsellers(batchSize = 100) {
    console.log(`📚 WARMING HISTORICAL BESTSELLERS: ${batchSize} books`);
    
    const results = {
      processed: 0,
      cached: 0,
      errors: [],
      startTime: Date.now()
    };

    try {
      // Get progress from previous runs
      const progress = await this.getWarmingProgress('historical-bestsellers') || { processedLists: [] };
      
      // Predefined lists of popular books
      const popularBookLists = await this.getPopularBookLists();
      
      // Find next unprocessed batch
      let booksToProcess = [];
      for (const [listName, books] of Object.entries(popularBookLists)) {
        if (!progress.processedLists.includes(listName)) {
          booksToProcess = books.slice(0, batchSize);
          progress.currentList = listName;
          break;
        }
      }

      if (booksToProcess.length === 0) {
        console.log('📖 All historical bestseller lists completed, starting over...');
        progress.processedLists = [];
        booksToProcess = popularBookLists.classics.slice(0, batchSize);
        progress.currentList = 'classics';
      }

      // Process books batch
      for (const book of booksToProcess) {
        try {
          await this.rateLimitDelay('google-books');
          
          let query;
          if (book.isbn) {
            query = `isbn:${book.isbn}`;
          } else if (book.title && book.author) {
            query = `intitle:"${book.title}" inauthor:"${book.author}"`;
          } else {
            continue; // Skip malformed entries
          }

          const books = await this.searchAndCacheBooks(query, 1, 'google-books');
          if (books.length > 0) {
            results.cached++;
            console.log(`✅ Cached: ${book.title} by ${book.author}`);
          }
          results.processed++;

        } catch (error) {
          results.errors.push({
            book: book,
            error: error.message
          });
        }
      }

      // Update progress
      if (results.processed >= batchSize * 0.8) { // 80% success rate
        progress.processedLists.push(progress.currentList);
      }

      await this.storeWarmingProgress('historical-bestsellers', {
        ...progress,
        lastRun: results,
        completedAt: Date.now()
      });

      console.log(`✅ HISTORICAL WARMING BATCH COMPLETE: ${results.cached}/${results.processed} books cached`);
      return results;

    } catch (error) {
      console.error('Historical bestsellers warming failed:', error);
      results.errors.push({ general: error.message });
      return results;
    }
  }

  // ===== POPULAR AUTHORS COMPLETE WORKS =====

  async warmPopularAuthors(batchSize = 50) {
    console.log(`👤 WARMING POPULAR AUTHORS: ${batchSize} books`);
    
    const results = {
      processed: 0,
      cached: 0,
      errors: [],
      startTime: Date.now()
    };

    try {
      const progress = await this.getWarmingProgress('popular-authors') || { processedAuthors: [] };
      const popularAuthors = await this.getPopularAuthorsList();
      
      // Find next unprocessed author
      let currentAuthor = null;
      for (const author of popularAuthors) {
        if (!progress.processedAuthors.includes(author.name)) {
          currentAuthor = author;
          break;
        }
      }

      if (!currentAuthor) {
        console.log('👥 All popular authors processed, restarting cycle...');
        progress.processedAuthors = [];
        currentAuthor = popularAuthors[0];
      }

      // Search for author's works
      await this.rateLimitDelay('google-books');
      const query = `inauthor:"${currentAuthor.name}" orderBy=relevance`;
      const books = await this.searchAndCacheBooks(query, batchSize, 'google-books');
      
      results.processed = books.length;
      results.cached = books.filter(b => b.cached).length;

      // Mark author as processed if we got good results
      if (results.cached >= Math.min(10, batchSize * 0.5)) {
        progress.processedAuthors.push(currentAuthor.name);
      }

      await this.storeWarmingProgress('popular-authors', {
        ...progress,
        lastAuthor: currentAuthor.name,
        lastRun: results,
        completedAt: Date.now()
      });

      console.log(`✅ AUTHOR WARMING COMPLETE: ${currentAuthor.name} - ${results.cached}/${results.processed} books cached`);
      return results;

    } catch (error) {
      console.error('Popular authors warming failed:', error);
      results.errors.push({ general: error.message });
      return results;
    }
  }

  // ===== HELPER FUNCTIONS =====

  async searchAndCacheBooks(query, maxResults, provider) {
    const books = [];
    
    try {
      let apiResults;
      
      switch (provider) {
        case 'google-books':
          apiResults = await this.searchGoogleBooks(query, maxResults);
          break;
        case 'isbndb':
          apiResults = await this.searchISBNdb(query, maxResults);
          break;
        case 'open-library':
          apiResults = await this.searchOpenLibrary(query, maxResults);
          break;
        default:
          throw new Error(`Unknown provider: ${provider}`);
      }

      if (apiResults?.items) {
        for (const item of apiResults.items) {
          try {
            // Cache the book data
            const cacheKey = this.generateCacheKey(item);
            const bookData = this.normalizeBookData(item, provider);
            
            await this.setCachedData(cacheKey, bookData, 2592000); // 30 days
            
            books.push({
              id: item.id || item.volumeInfo?.title,
              title: item.volumeInfo?.title,
              authors: item.volumeInfo?.authors,
              cached: true,
              provider: provider
            });
            
          } catch (error) {
            console.warn(`Failed to cache book: ${error.message}`);
            books.push({
              id: item.id,
              cached: false,
              error: error.message
            });
          }
        }
      }

      return books;

    } catch (error) {
      console.error(`Search failed for query "${query}":`, error.message);
      throw error;
    }
  }

  generateCacheKey(item) {
    // Try ISBN first, then fallback to title-based key
    const isbn = item.volumeInfo?.industryIdentifiers?.find(id => 
      id.type === 'ISBN_13' || id.type === 'ISBN_10'
    )?.identifier;
    
    if (isbn) {
      return `isbn/${isbn}.json`;
    }
    
    // Fallback to title + author key
    const title = item.volumeInfo?.title || '';
    const author = item.volumeInfo?.authors?.[0] || '';
    const key = `${title}-${author}`.toLowerCase()
      .replace(/[^a-z0-9]/g, '-')
      .replace(/-+/g, '-')
      .substring(0, 50);
    
    return `book/${key}.json`;
  }

  normalizeBookData(item, provider) {
    return {
      ...item,
      cached: true,
      cacheSource: 'warming-system',
      provider: provider,
      cachedAt: Date.now()
    };
  }

  async rateLimitDelay(provider) {
    const delays = {
      'google-books': 100,  // 10 requests per second = 100ms delay
      'isbndb': 200,        // Conservative approach
      'open-library': 600   // 100 per minute = 600ms delay
    };
    
    const delay = delays[provider] || 1000;
    await new Promise(resolve => setTimeout(resolve, delay));
  }

  // ===== DATA SOURCES =====

  async getPopularBookLists() {
    return {
      classics: [
        { title: "To Kill a Mockingbird", author: "Harper Lee", isbn: "9780061120084" },
        { title: "1984", author: "George Orwell", isbn: "9780547249643" },
        { title: "Pride and Prejudice", author: "Jane Austen", isbn: "9780141439518" },
        { title: "The Great Gatsby", author: "F. Scott Fitzgerald", isbn: "9780743273565" },
        { title: "One Hundred Years of Solitude", author: "Gabriel García Márquez", isbn: "9780060883287" },
        { title: "Beloved", author: "Toni Morrison", isbn: "9781400033416" },
        { title: "The Catcher in the Rye", author: "J.D. Salinger", isbn: "9780316769174" },
        { title: "Lord of the Flies", author: "William Golding", isbn: "9780571056866" },
        { title: "Jane Eyre", author: "Charlotte Brontë", isbn: "9780141441146" },
        { title: "Wuthering Heights", author: "Emily Brontë", isbn: "9780141439556" }
      ],
      contemporary: [
        { title: "The Seven Husbands of Evelyn Hugo", author: "Taylor Jenkins Reid", isbn: "9781501161933" },
        { title: "Where the Crawdads Sing", author: "Delia Owens", isbn: "9780735219090" },
        { title: "The Silent Patient", author: "Alex Michaelides", isbn: "9781250301697" },
        { title: "Educated", author: "Tara Westover", isbn: "9780399590504" },
        { title: "The Handmaid's Tale", author: "Margaret Atwood", isbn: "9780385490818" },
        { title: "The Kite Runner", author: "Khaled Hosseini", isbn: "9781594631931" },
        { title: "Gone Girl", author: "Gillian Flynn", isbn: "9780307588364" },
        { title: "The Girl with the Dragon Tattoo", author: "Stieg Larsson", isbn: "9780307454546" },
        { title: "Life of Pi", author: "Yann Martel", isbn: "9780156027328" },
        { title: "The Book Thief", author: "Markus Zusak", isbn: "9780375842207" }
      ],
      diverse_voices: [
        { title: "Americanah", author: "Chimamanda Ngozi Adichie", isbn: "9780307455925" },
        { title: "The Joy Luck Club", author: "Amy Tan", isbn: "9780143038092" },
        { title: "Persepolis", author: "Marjane Satrapi", isbn: "9780375714573" },
        { title: "The Namesake", author: "Jhumpa Lahiri", isbn: "9780618485222" },
        { title: "Homegoing", author: "Yaa Gyasi", isbn: "9781101971062" },
        { title: "The Sellout", author: "Paul Beatty", isbn: "9780374260507" },
        { title: "Exit West", author: "Mohsin Hamid", isbn: "9780735212183" },
        { title: "The Sympathizer", author: "Viet Thanh Nguyen", isbn: "9780802123459" },
        { title: "There There", author: "Tommy Orange", isbn: "9780525520375" },
        { title: "An American Marriage", author: "Tayari Jones", isbn: "9781616201340" }
      ]
    };
  }

  async getPopularAuthorsList() {
    return [
      { name: "Stephen King", priority: 1 },
      { name: "J.K. Rowling", priority: 1 },
      { name: "Agatha Christie", priority: 1 },
      { name: "Shakespeare", priority: 1 },
      { name: "Jane Austen", priority: 1 },
      { name: "Toni Morrison", priority: 2 },
      { name: "Gabriel García Márquez", priority: 2 },
      { name: "George Orwell", priority: 2 },
      { name: "Virginia Woolf", priority: 2 },
      { name: "James Joyce", priority: 2 },
      { name: "Chimamanda Ngozi Adichie", priority: 2 },
      { name: "Haruki Murakami", priority: 2 },
      { name: "Margaret Atwood", priority: 2 },
      { name: "Gillian Flynn", priority: 3 },
      { name: "Dan Brown", priority: 3 }
    ];
  }

  // ===== STORAGE FUNCTIONS =====

  async storeWarmingProgress(type, data) {
    const key = `warming_progress/${type}`;
    try {
      await this.env.BOOKS_CACHE?.put(key, JSON.stringify(data), { expirationTtl: 2592000 }); // 30 days
    } catch (error) {
      console.warn(`Failed to store warming progress: ${error.message}`);
    }
  }

  async getWarmingProgress(type) {
    const key = `warming_progress/${type}`;
    try {
      const data = await this.env.BOOKS_CACHE?.get(key);
      return data ? JSON.parse(data) : null;
    } catch (error) {
      console.warn(`Failed to get warming progress: ${error.message}`);
      return null;
    }
  }

  async setCachedData(cacheKey, data, ttlSeconds) {
    const jsonData = JSON.stringify(data);
    const promises = [];
    
    try {
      // Store in R2 for long-term cache
      if (this.env.BOOKS_R2) {
        promises.push(
          this.env.BOOKS_R2.put(cacheKey, jsonData, {
            httpMetadata: { 
              contentType: 'application/json',
              cacheControl: `max-age=${ttlSeconds}`
            }
          })
        );
      }
      
      // Store in KV for hot access  
      const kvTtl = Math.min(ttlSeconds, 86400); // Max 1 day in KV
      promises.push(
        this.env.BOOKS_CACHE?.put(cacheKey, jsonData, { expirationTtl: kvTtl })
      );
      
      // Execute both cache operations in background
      if (this.ctx && this.ctx.waitUntil) {
        this.ctx.waitUntil(Promise.all(promises.filter(Boolean)));
      } else {
        await Promise.all(promises.filter(Boolean));
      }
      
    } catch (error) {
      console.warn(`Cache write error for key ${cacheKey}:`, error.message);
    }
  }

  // ===== API INTEGRATION FUNCTIONS =====
  // (These would use the same API functions from the main worker)

  async searchGoogleBooks(query, maxResults) {
    const apiKey = this.env.google1 || this.env.google2;
    
    const params = new URLSearchParams({
      q: query,
      maxResults: Math.min(maxResults, 40).toString(),
      printType: 'books',
      projection: 'full',
      key: apiKey
    });

    const response = await fetch(`https://www.googleapis.com/books/v1/volumes?${params}`);
    
    if (!response.ok) {
      throw new Error(`Google Books API error: ${response.status}`);
    }

    return await response.json();
  }

  async searchISBNdb(query, maxResults) {
    const apiKey = this.env.ISBNdb1;
    
    if (!apiKey) {
      throw new Error('ISBNdb API key not configured');
    }
    
    const baseUrl = 'https://api2.isbndb.com';
    const endpoint = query.match(/^\d{10}(\d{3})?$/) ? `/book/${query}` : `/books/${encodeURIComponent(query)}`;
    
    const params = new URLSearchParams({
      pageSize: Math.min(maxResults, 20).toString(),
      page: '1'
    });
    
    const url = `${baseUrl}${endpoint}?${params}`;
    
    const response = await fetch(url, {
      headers: {
        'X-API-KEY': apiKey,
        'Content-Type': 'application/json'
      }
    });
    
    if (!response.ok) {
      throw new Error(`ISBNdb API error: ${response.status}`);
    }
    
    const data = await response.json();
    const books = data.books || [data.book].filter(Boolean);
    
    return {
      kind: 'books#volumes',
      totalItems: data.total || books.length,
      items: books.map(book => ({
        kind: 'books#volume',
        id: book.isbn13 || book.isbn || '',
        volumeInfo: {
          title: book.title || '',
          authors: book.authors ? book.authors.filter(Boolean) : [],
          publishedDate: book.date_published || '',
          publisher: book.publisher || '',
          description: book.overview || book.synopsis || '',
          industryIdentifiers: [
            book.isbn13 && { type: 'ISBN_13', identifier: book.isbn13 },
            book.isbn && { type: 'ISBN_10', identifier: book.isbn }
          ].filter(Boolean),
          categories: book.subjects || []
        }
      }))
    };
  }

  async searchOpenLibrary(query, maxResults) {
    const params = new URLSearchParams({
      q: query,
      limit: Math.min(maxResults, 100).toString(),
      fields: 'key,title,author_name,first_publish_year,isbn,publisher,language,subject',
      format: 'json'
    });

    const response = await fetch(`https://openlibrary.org/search.json?${params}`);
    
    if (!response.ok) {
      throw new Error(`Open Library API error: ${response.status}`);
    }

    const data = await response.json();
    
    return {
      kind: 'books#volumes',
      totalItems: data.numFound,
      items: data.docs.map(doc => ({
        kind: 'books#volume',
        id: doc.key?.replace('/works/', '') || '',
        volumeInfo: {
          title: doc.title || '',
          authors: doc.author_name || [],
          publishedDate: doc.first_publish_year?.toString() || '',
          publisher: Array.isArray(doc.publisher) ? doc.publisher[0] : doc.publisher || '',
          industryIdentifiers: doc.isbn ? doc.isbn.slice(0, 2).map(isbn => ({
            type: isbn.length === 13 ? 'ISBN_13' : 'ISBN_10',
            identifier: isbn
          })) : [],
          categories: doc.subject ? doc.subject.slice(0, 3) : []
        }
      }))
    };
  }

  // ===== CACHE WARMING STATUS =====

  async getWarmingStatus() {
    const statuses = {};
    const types = ['new-releases', 'historical-bestsellers', 'popular-authors'];
    
    for (const type of types) {
      statuses[type] = await this.getWarmingProgress(type);
    }
    
    return {
      timestamp: new Date().toISOString(),
      warming: statuses,
      nextRuns: {
        'new-releases': 'Daily at 2:00 AM UTC',
        'popular-authors': 'Weekly Sunday at 3:00 AM UTC', 
        'historical-bestsellers': 'Monthly 1st at 4:00 AM UTC'
      }
    };
  }
}