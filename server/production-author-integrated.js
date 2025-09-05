/**
 * Production CloudFlare Worker with Author Cultural Indexing System
 * Integrates AuthorCulturalIndexer with existing optimized caching
 * Implements Task 8 (Author Indexing) and Task 9 (Cultural Data Propagation)
 */

import { AuthorCulturalIndexer, CulturalUtils } from './author-cultural-indexing.js';

export default {
  async fetch(request, env, ctx) {
    // Handle CORS preflight
    if (request.method === 'OPTIONS') {
      return handleCORS();
    }

    try {
      const url = new URL(request.url);
      const path = url.pathname;

      // Initialize Author Cultural Indexer
      const authorIndexer = new AuthorCulturalIndexer(env, ctx);

      // Route requests with enhanced caching + author indexing
      if (path === '/search') {
        return await handleOptimizedBookSearchWithAuthors(request, env, ctx, authorIndexer);
      } else if (path === '/isbn') {
        return await handleOptimizedISBNLookupWithAuthors(request, env, ctx, authorIndexer);
      } else if (path === '/authors/search') {
        return await handleAuthorSearch(request, env, ctx, authorIndexer);
      } else if (path === '/authors/profile') {
        return await handleAuthorProfile(request, env, ctx, authorIndexer);
      } else if (path === '/authors/cultural-stats') {
        return await handleCulturalStats(request, env, ctx, authorIndexer);
      } else if (path === '/authors/propagate') {
        return await handleCulturalPropagation(request, env, ctx, authorIndexer);
      } else if (path === '/health') {
        return new Response(JSON.stringify({ 
          status: 'healthy',
          version: '4.0-author-integrated',
          timestamp: new Date().toISOString(),
          caching: {
            system: env.BOOKS_R2 ? 'R2+KV-Hybrid' : 'KV-Only',
            kv: env.BOOKS_CACHE ? 'available' : 'missing',
            r2: env.BOOKS_R2 ? 'available' : 'missing'
          },
          features: [
            'intelligent-caching',
            'multi-provider-fallback', 
            'performance-optimization',
            'author-cultural-indexing', // NEW
            'cultural-data-propagation', // NEW
            'production-ready'
          ],
          authorIndexing: {
            profiles: 'enabled',
            culturalAnalysis: 'enabled',
            propagation: 'enabled'
          }
        }), {
          headers: getCORSHeaders('application/json')
        });
      } else {
        return new Response(JSON.stringify({ error: 'Endpoint not found' }), {
          status: 404,
          headers: getCORSHeaders('application/json')
        });
      }
    } catch (error) {
      console.error('Worker error:', error);
      return new Response(JSON.stringify({ 
        error: 'Internal server error',
        message: error.message 
      }), {
        status: 500,
        headers: getCORSHeaders('application/json')
      });
    }
  }
};

// ===== TASK 8: AUTHOR INDEXING SERVICE =====

// Enhanced search with author profile integration
async function handleOptimizedBookSearchWithAuthors(request, env, ctx, authorIndexer) {
  const url = new URL(request.url);
  
  // Validate input
  const validation = validateSearchParams(url);
  if (validation.errors.length > 0) {
    return new Response(JSON.stringify({ 
      error: 'Invalid parameters',
      details: validation.errors
    }), {
      status: 400,
      headers: getCORSHeaders()
    });
  }
  
  const { query, maxResults, sortBy, includeTranslations } = validation.sanitized;
  const requestStartTime = Date.now();

  // Enhanced rate limiting
  const rateLimitResult = await checkRateLimit(request, env);
  if (!rateLimitResult.allowed) {
    return new Response(JSON.stringify({ 
      error: 'Rate limit exceeded',
      retryAfter: rateLimitResult.retryAfter 
    }), {
      status: 429,
      headers: {
        ...getCORSHeaders(),
        'Retry-After': rateLimitResult.retryAfter.toString()
      }
    });
  }

  // Check intelligent cache first
  const cacheKey = CACHE_KEYS.search(query, maxResults, sortBy, includeTranslations);
  const cached = await getCachedData(cacheKey, env);
  if (cached) {
    // Enrich cached results with author profiles
    const enrichedResult = await enrichResultsWithAuthorProfiles(cached.data, authorIndexer);
    
    return new Response(JSON.stringify({
      ...enrichedResult,
      cached: true,
      cacheSource: cached.source,
      processingTime: Date.now() - requestStartTime
    }), {
      headers: {
        ...getCORSHeaders(),
        'X-Cache': `HIT-${cached.source}`,
        'X-Processing-Time': `${Date.now() - requestStartTime}ms`
      }
    });
  }

  // Try API providers in order
  let result = null;
  let provider = null;

  // 1. Google Books API (primary)
  try {
    result = await searchGoogleBooks(query, maxResults, sortBy, includeTranslations, env);
    provider = 'google-books';
  } catch (error) {
    console.error('Google Books failed:', error.message);
  }

  // 2. ISBNdb (fallback)
  if (!result || result.items?.length === 0) {
    try {
      result = await searchISBNdb(query, maxResults, env);
      provider = 'isbndb';
    } catch (error) {
      console.error('ISBNdb failed:', error.message);
    }
  }

  // 3. Open Library (fallback)
  if (!result || result.items?.length === 0) {
    try {
      result = await searchOpenLibrary(query, maxResults, env);
      provider = 'open-library';
    } catch (error) {
      console.error('Open Library failed:', error.message);
    }
  }

  if (!result) {
    const errorResult = { 
      error: 'All book providers failed',
      items: [],
      totalItems: 0,
      cached: false,
      provider: 'none'
    };
    
    // Cache empty results too (shorter TTL)
    setCachedData(cacheKey, errorResult, 3600, env, ctx);
    
    return new Response(JSON.stringify(errorResult), {
      status: 503,
      headers: getCORSHeaders()
    });
  }

  // ===== TASK 8: BUILD AUTHOR PROFILES =====
  // Process authors from search results
  if (result.items && result.items.length > 0) {
    ctx.waitUntil(processAuthorsFromResults(result.items, authorIndexer));
  }

  // Enhance result with metadata
  result.provider = provider;
  result.cached = false;
  result.processingTime = Date.now() - requestStartTime;

  // ===== TASK 9: ENRICH WITH CULTURAL DATA =====
  const enrichedResult = await enrichResultsWithAuthorProfiles(result, authorIndexer);

  // Cache successful results with intelligent TTL
  const ttl = result.items?.length > 0 ? 2592000 : 3600; // 30 days for results, 1 hour for empty
  setCachedData(cacheKey, enrichedResult, ttl, env, ctx);

  return new Response(JSON.stringify(enrichedResult), {
    headers: {
      ...getCORSHeaders(),
      'X-Cache': 'MISS',
      'X-Provider': provider,
      'X-Processing-Time': `${enrichedResult.processingTime}ms`
    }
  });
}

// Enhanced ISBN lookup with author profile integration
async function handleOptimizedISBNLookupWithAuthors(request, env, ctx, authorIndexer) {
  const url = new URL(request.url);
  const rawISBN = url.searchParams.get('isbn');
  const validation = validateISBN(rawISBN);
  const requestStartTime = Date.now();
  
  if (validation.error) {
    return new Response(JSON.stringify({ 
      error: validation.error 
    }), {
      status: 400,
      headers: getCORSHeaders()
    });
  }
  
  const isbn = validation.sanitized;
  const cacheKey = CACHE_KEYS.isbn(isbn);

  // Check cache first
  const cached = await getCachedData(cacheKey, env);
  if (cached) {
    // Enrich cached result with author profile
    const enrichedResult = await enrichSingleResultWithAuthorProfile(cached.data, authorIndexer);
    
    return new Response(JSON.stringify({
      ...enrichedResult,
      cached: true,
      cacheSource: cached.source,
      processingTime: Date.now() - requestStartTime
    }), {
      headers: {
        ...getCORSHeaders(),
        'X-Cache': `HIT-${cached.source}`,
        'X-Processing-Time': `${Date.now() - requestStartTime}ms`
      }
    });
  }

  // Try providers for ISBN lookup
  let result = null;
  let provider = null;

  // Google Books ISBN lookup
  try {
    result = await lookupISBNGoogle(isbn, env);
    provider = 'google-books';
  } catch (error) {
    console.error('Google Books ISBN lookup failed:', error.message);
  }

  // ISBNdb ISBN lookup
  if (!result) {
    try {
      result = await lookupISBNISBNdb(isbn, env);
      provider = 'isbndb';
    } catch (error) {
      console.error('ISBNdb ISBN lookup failed:', error.message);
    }
  }

  // Open Library ISBN lookup
  if (!result) {
    try {
      result = await lookupISBNOpenLibrary(isbn, env);
      provider = 'open-library';
    } catch (error) {
      console.error('Open Library ISBN lookup failed:', error.message);
    }
  }

  if (!result) {
    const errorResult = { 
      error: 'ISBN not found in any provider',
      isbn: isbn,
      cached: false,
      provider: 'none'
    };
    
    // Cache negative results too (shorter TTL)
    setCachedData(cacheKey, errorResult, 3600, env, ctx);
    
    return new Response(JSON.stringify(errorResult), {
      status: 404,
      headers: getCORSHeaders()
    });
  }

  result.provider = provider;
  result.cached = false;
  result.processingTime = Date.now() - requestStartTime;

  // ===== TASK 8: BUILD AUTHOR PROFILE =====
  if (result.volumeInfo?.authors) {
    ctx.waitUntil(processAuthorsFromResults([result], authorIndexer));
  }

  // ===== TASK 9: ENRICH WITH CULTURAL DATA =====
  const enrichedResult = await enrichSingleResultWithAuthorProfile(result, authorIndexer);

  // Cache ISBN lookups - 1 year TTL (book metadata is permanent)
  setCachedData(cacheKey, enrichedResult, 31536000, env, ctx);

  return new Response(JSON.stringify(enrichedResult), {
    headers: {
      ...getCORSHeaders(),
      'X-Cache': 'MISS',
      'X-Provider': provider,
      'X-Processing-Time': `${enrichedResult.processingTime}ms`
    }
  });
}

// New endpoint: Author search by cultural criteria
async function handleAuthorSearch(request, env, ctx, authorIndexer) {
  const url = new URL(request.url);
  const criteria = {
    region: url.searchParams.get('region'),
    nationality: url.searchParams.get('nationality'),
    gender: url.searchParams.get('gender'),
    language: url.searchParams.get('language'),
    theme: url.searchParams.get('theme'),
    minConfidence: parseInt(url.searchParams.get('minConfidence')) || 50
  };

  try {
    const results = await authorIndexer.searchAuthorsByCulture(criteria);
    
    return new Response(JSON.stringify({
      ...results,
      timestamp: new Date().toISOString()
    }), {
      headers: getCORSHeaders('application/json')
    });
  } catch (error) {
    return new Response(JSON.stringify({ 
      error: 'Author search failed',
      message: error.message 
    }), {
      status: 500,
      headers: getCORSHeaders('application/json')
    });
  }
}

// New endpoint: Get author profile
async function handleAuthorProfile(request, env, ctx, authorIndexer) {
  const url = new URL(request.url);
  const authorName = url.searchParams.get('name');

  if (!authorName) {
    return new Response(JSON.stringify({ 
      error: 'Author name parameter required' 
    }), {
      status: 400,
      headers: getCORSHeaders('application/json')
    });
  }

  try {
    const normalizedName = authorIndexer.normalizeAuthorName(authorName);
    const authorId = await authorIndexer.generateAuthorId(normalizedName);
    const profile = await authorIndexer.getAuthorProfile(authorId);

    if (!profile) {
      return new Response(JSON.stringify({ 
        error: 'Author profile not found',
        name: authorName
      }), {
        status: 404,
        headers: getCORSHeaders('application/json')
      });
    }

    return new Response(JSON.stringify(profile), {
      headers: getCORSHeaders('application/json')
    });
  } catch (error) {
    return new Response(JSON.stringify({ 
      error: 'Failed to retrieve author profile',
      message: error.message 
    }), {
      status: 500,
      headers: getCORSHeaders('application/json')
    });
  }
}

// New endpoint: Cultural diversity statistics
async function handleCulturalStats(request, env, ctx, authorIndexer) {
  try {
    const stats = await authorIndexer.getCulturalDiversityStats();
    
    return new Response(JSON.stringify(stats), {
      headers: getCORSHeaders('application/json')
    });
  } catch (error) {
    return new Response(JSON.stringify({ 
      error: 'Failed to get cultural statistics',
      message: error.message 
    }), {
      status: 500,
      headers: getCORSHeaders('application/json')
    });
  }
}

// New endpoint: Trigger cultural data propagation
async function handleCulturalPropagation(request, env, ctx, authorIndexer) {
  const url = new URL(request.url);
  const authorName = url.searchParams.get('author');

  if (!authorName) {
    return new Response(JSON.stringify({ 
      error: 'Author name parameter required' 
    }), {
      status: 400,
      headers: getCORSHeaders('application/json')
    });
  }

  try {
    const normalizedName = authorIndexer.normalizeAuthorName(authorName);
    const authorId = await authorIndexer.generateAuthorId(normalizedName);
    const profile = await authorIndexer.getAuthorProfile(authorId);

    if (!profile) {
      return new Response(JSON.stringify({ 
        error: 'Author profile not found',
        name: authorName
      }), {
        status: 404,
        headers: getCORSHeaders('application/json')
      });
    }

    const propagationResult = await authorIndexer.propagateCulturalData(profile);

    return new Response(JSON.stringify({
      author: authorName,
      profileId: authorId,
      propagation: propagationResult,
      timestamp: new Date().toISOString()
    }), {
      headers: getCORSHeaders('application/json')
    });
  } catch (error) {
    return new Response(JSON.stringify({ 
      error: 'Cultural propagation failed',
      message: error.message 
    }), {
      status: 500,
      headers: getCORSHeaders('application/json')
    });
  }
}

// ===== TASK 8 & 9: HELPER FUNCTIONS =====

// Process authors from API results and build profiles
async function processAuthorsFromResults(items, authorIndexer) {
  const authorProcessingPromises = [];

  for (const item of items) {
    const authors = item.volumeInfo?.authors || [];
    
    for (const authorName of authors) {
      if (authorName && authorName.trim()) {
        // Build comprehensive author profile with book data
        const bookMetadata = {
          id: item.id,
          title: item.volumeInfo?.title,
          publishedDate: item.volumeInfo?.publishedDate,
          publisher: item.volumeInfo?.publisher,
          language: item.volumeInfo?.language,
          categories: item.volumeInfo?.categories,
          description: item.volumeInfo?.description,
          industryIdentifiers: item.volumeInfo?.industryIdentifiers,
          authors: authors
        };

        authorProcessingPromises.push(
          authorIndexer.buildAuthorProfile(authorName, [bookMetadata])
        );
      }
    }
  }

  try {
    await Promise.allSettled(authorProcessingPromises);
    console.log(`📚 AUTHOR INDEXING: Processed ${authorProcessingPromises.length} author profiles`);
  } catch (error) {
    console.error('Author processing failed:', error.message);
  }
}

// Enrich search results with cultural author data
async function enrichResultsWithAuthorProfiles(result, authorIndexer) {
  if (!result.items || result.items.length === 0) {
    return result;
  }

  const enrichmentPromises = result.items.map(async (item) => {
    try {
      const authors = item.volumeInfo?.authors || [];
      const authorProfiles = [];

      for (const authorName of authors) {
        const normalizedName = authorIndexer.normalizeAuthorName(authorName);
        const authorId = await authorIndexer.generateAuthorId(normalizedName);
        const profile = await authorIndexer.getAuthorProfile(authorId);
        
        if (profile) {
          authorProfiles.push({
            name: authorName,
            culturalProfile: profile.culturalProfile,
            confidence: profile.culturalProfile.confidence
          });
        }
      }

      // Add cultural metadata to book item
      if (authorProfiles.length > 0) {
        item.culturalMetadata = {
          authors: authorProfiles,
          diversityScore: CulturalUtils.calculateDiversityScore([{ culturalMetadata: { authorProfile: authorProfiles[0] } }]),
          lastUpdated: Date.now(),
          version: '1.0'
        };
      }

      return item;
    } catch (error) {
      console.warn(`Failed to enrich item ${item.id}:`, error.message);
      return item;
    }
  });

  const enrichedItems = await Promise.allSettled(enrichmentPromises);
  
  return {
    ...result,
    items: enrichedItems.map(settled => 
      settled.status === 'fulfilled' ? settled.value : settled.reason
    ),
    enrichmentStats: {
      processed: enrichedItems.length,
      enriched: enrichedItems.filter(item => 
        item.status === 'fulfilled' && item.value.culturalMetadata
      ).length
    }
  };
}

// Enrich single result (for ISBN lookup) with cultural author data
async function enrichSingleResultWithAuthorProfile(result, authorIndexer) {
  if (!result.volumeInfo?.authors) {
    return result;
  }

  try {
    const authors = result.volumeInfo.authors;
    const authorProfiles = [];

    for (const authorName of authors) {
      const normalizedName = authorIndexer.normalizeAuthorName(authorName);
      const authorId = await authorIndexer.generateAuthorId(normalizedName);
      const profile = await authorIndexer.getAuthorProfile(authorId);
      
      if (profile) {
        authorProfiles.push({
          name: authorName,
          culturalProfile: profile.culturalProfile,
          confidence: profile.culturalProfile.confidence
        });
      }
    }

    // Add cultural metadata to book result
    if (authorProfiles.length > 0) {
      result.culturalMetadata = {
        authors: authorProfiles,
        diversityScore: CulturalUtils.calculateDiversityScore([{ culturalMetadata: { authorProfile: authorProfiles[0] } }]),
        lastUpdated: Date.now(),
        version: '1.0'
      };
    }

    return result;
  } catch (error) {
    console.warn(`Failed to enrich single result:`, error.message);
    return result;
  }
}

// ===== EXISTING CACHE AND API FUNCTIONS =====
// (All the existing functions from production-optimized-worker.js remain the same)

// Enhanced cache system
const CACHE_KEYS = {
  search: (query, maxResults, sortBy, translations) => 
    `search/${btoa(query).replace(/[/+=]/g, '_')}/${maxResults}/${sortBy}/${translations}.json`,
  isbn: (isbn) => `isbn/${isbn}.json`
};

async function getCachedData(cacheKey, env) {
  try {
    // Try KV first (hot cache)
    const kvData = await env.BOOKS_CACHE?.get(cacheKey);
    if (kvData) {
      return {
        data: JSON.parse(kvData),
        source: 'KV-HOT'
      };
    }
    
    // Try R2 second (cold cache)  
    if (env.BOOKS_R2) {
      const r2Object = await env.BOOKS_R2.get(cacheKey);
      if (r2Object) {
        const jsonData = await r2Object.text();
        const data = JSON.parse(jsonData);
        
        // Promote to hot cache for future requests
        env.waitUntil(env.BOOKS_CACHE?.put(cacheKey, jsonData, { expirationTtl: 86400 }));
        
        return {
          data: data,
          source: 'R2-COLD'
        };
      }
    }
    
    return null;
  } catch (error) {
    console.warn(`Cache read error for key ${cacheKey}:`, error.message);
    return null;
  }
}

async function setCachedData(cacheKey, data, ttlSeconds, env, ctx) {
  const jsonData = JSON.stringify(data);
  const promises = [];
  
  try {
    // Store in R2 for long-term cache (cold cache)
    if (env.BOOKS_R2) {
      promises.push(
        env.BOOKS_R2.put(cacheKey, jsonData, {
          httpMetadata: { 
            contentType: 'application/json',
            cacheControl: `max-age=${ttlSeconds}`
          }
        })
      );
    }
    
    // Store in KV for hot access with shorter TTL  
    const kvTtl = Math.min(ttlSeconds, 86400); // Max 1 day in KV
    promises.push(
      env.BOOKS_CACHE?.put(cacheKey, jsonData, { expirationTtl: kvTtl })
    );
    
    // Execute both cache operations in background
    if (ctx && ctx.waitUntil) {
      ctx.waitUntil(Promise.all(promises.filter(Boolean)));
    } else {
      await Promise.all(promises.filter(Boolean));
    }
    
  } catch (error) {
    console.warn(`Cache write error for key ${cacheKey}:`, error.message);
  }
}

// Include all existing API functions (Google Books, ISBNdb, Open Library)
// Include all existing utility functions (CORS, validation, rate limiting)
// [These remain exactly the same as in production-optimized-worker.js]

// WORKING API IMPLEMENTATIONS (from your current worker)

async function searchGoogleBooks(query, maxResults, sortBy, includeTranslations, env) {
  const apiKey = env.google1 || env.google2;
  
  const params = new URLSearchParams({
    q: query,
    maxResults: maxResults.toString(),
    printType: 'books',
    projection: 'full',
    orderBy: sortBy,
    key: apiKey
  });

  if (!includeTranslations) {
    params.append('langRestrict', 'en');
  }

  const response = await fetch(`https://www.googleapis.com/books/v1/volumes?${params}`);
  
  if (!response.ok) {
    throw new Error(`Google Books API error: ${response.status}`);
  }

  return await response.json();
}

async function lookupISBNGoogle(isbn, env) {
  const apiKey = env.google1 || env.google2;
  
  const params = new URLSearchParams({
    q: `isbn:${isbn}`,
    maxResults: '1',
    printType: 'books',
    projection: 'full',
    key: apiKey
  });

  const response = await fetch(`https://www.googleapis.com/books/v1/volumes?${params}`);
  
  if (!response.ok) {
    throw new Error(`Google Books ISBN API error: ${response.status}`);
  }

  const data = await response.json();
  return data.items?.[0] || null;
}

async function searchOpenLibrary(query, maxResults, env) {
  const params = new URLSearchParams({
    q: query,
    limit: maxResults.toString(),
    fields: 'key,title,author_name,first_publish_year,isbn,publisher,language,subject,cover_i,edition_count',
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
        description: '',
        industryIdentifiers: doc.isbn ? doc.isbn.slice(0, 2).map(isbn => ({
          type: isbn.length === 13 ? 'ISBN_13' : 'ISBN_10',
          identifier: isbn
        })) : [],
        pageCount: null,
        categories: doc.subject ? doc.subject.slice(0, 3) : [],
        imageLinks: doc.cover_i ? {
          thumbnail: `https://covers.openlibrary.org/b/id/${doc.cover_i}-M.jpg`,
          smallThumbnail: `https://covers.openlibrary.org/b/id/${doc.cover_i}-S.jpg`
        } : null,
        language: Array.isArray(doc.language) ? doc.language[0] : doc.language || 'en',
        previewLink: `https://openlibrary.org${doc.key}`,
        infoLink: `https://openlibrary.org${doc.key}`
      }
    }))
  };
}

async function lookupISBNOpenLibrary(isbn, env) {
  const response = await fetch(`https://openlibrary.org/api/books?bibkeys=ISBN:${isbn}&format=json&jscmd=data`);
  
  if (!response.ok) {
    throw new Error(`Open Library ISBN API error: ${response.status}`);
  }

  const data = await response.json();
  const bookData = data[`ISBN:${isbn}`];
  
  if (!bookData) {
    return null;
  }

  return {
    kind: 'books#volume',
    id: bookData.key?.replace('/books/', '') || isbn,
    volumeInfo: {
      title: bookData.title || '',
      authors: bookData.authors?.map(author => author.name) || [],
      publishedDate: bookData.publish_date || '',
      publisher: bookData.publishers?.[0]?.name || '',
      description: bookData.notes || '',
      industryIdentifiers: [{
        type: isbn.length === 13 ? 'ISBN_13' : 'ISBN_10',
        identifier: isbn
      }],
      pageCount: bookData.number_of_pages || null,
      categories: bookData.subjects?.map(subject => subject.name).slice(0, 3) || [],
      imageLinks: bookData.cover ? {
        thumbnail: bookData.cover.medium,
        smallThumbnail: bookData.cover.small
      } : null,
      language: 'en',
      previewLink: bookData.url,
      infoLink: bookData.url
    }
  };
}

async function searchISBNdb(query, maxResults, env) {
  const apiKey = env.ISBNdb1;
  
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
        pageCount: book.pages ? parseInt(book.pages) : null,
        categories: book.subjects || [],
        imageLinks: book.image ? {
          thumbnail: book.image,
          smallThumbnail: book.image
        } : null,
        language: book.language || 'en',
        previewLink: `https://isbndb.com/book/${book.isbn13 || book.isbn}`,
        infoLink: `https://isbndb.com/book/${book.isbn13 || book.isbn}`
      }
    }))
  };
}

async function lookupISBNISBNdb(isbn, env) {
  const apiKey = env.ISBNdb1;
  
  if (!apiKey) {
    throw new Error('ISBNdb API key not configured');
  }
  
  const response = await fetch(`https://api2.isbndb.com/book/${isbn}`, {
    headers: {
      'X-API-KEY': apiKey,
      'Content-Type': 'application/json'
    }
  });
  
  if (!response.ok) {
    if (response.status === 404) {
      return null;
    }
    throw new Error(`ISBNdb ISBN API error: ${response.status}`);
  }
  
  const data = await response.json();
  const book = data.book;
  
  if (!book) {
    return null;
  }
  
  return {
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
      pageCount: book.pages ? parseInt(book.pages) : null,
      categories: book.subjects || [],
      imageLinks: book.image ? {
        thumbnail: book.image,
        smallThumbnail: book.image
      } : null,
      language: book.language || 'en',
      previewLink: `https://isbndb.com/book/${book.isbn13 || book.isbn}`,
      infoLink: `https://isbndb.com/book/${book.isbn13 || book.isbn}`
    }
  };
}

// UTILITY FUNCTIONS

function getCORSHeaders(contentType = 'application/json') {
  return {
    'Content-Type': contentType,
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Requested-With',
    'Access-Control-Max-Age': '86400',
  };
}

function handleCORS() {
  return new Response(null, {
    status: 204,
    headers: getCORSHeaders()
  });
}

function validateSearchParams(url) {
  const query = url.searchParams.get('q');
  const maxResults = url.searchParams.get('maxResults');
  const sortBy = url.searchParams.get('orderBy');
  const langRestrict = url.searchParams.get('langRestrict');
  
  const errors = [];
  const sanitized = {};
  
  if (!query || typeof query !== 'string') {
    errors.push('Query parameter "q" is required');
  } else if (query.trim().length === 0) {
    errors.push('Query parameter "q" cannot be empty');
  } else if (query.length > 500) {
    errors.push('Query too long (max 500 characters)');
  } else {
    sanitized.query = query.trim();
  }
  
  sanitized.maxResults = maxResults ? Math.min(parseInt(maxResults), 40) : 20;
  sanitized.sortBy = sortBy || 'relevance';
  sanitized.includeTranslations = langRestrict !== 'en';
  
  return { errors, sanitized };
}

function validateISBN(isbn) {
  if (!isbn || typeof isbn !== 'string') {
    return { error: 'ISBN parameter is required' };
  }
  
  const cleaned = isbn.replace(/[-\s]/g, '').replace(/[^0-9X]/gi, '').toUpperCase();
  
  if (cleaned.length !== 10 && cleaned.length !== 13) {
    return { error: 'ISBN must be 10 or 13 characters' };
  }

  return { sanitized: cleaned };
}

async function checkRateLimit(request, env) {
  const clientIP = request.headers.get('CF-Connecting-IP') || 'unknown';
  const rateLimitKey = `ratelimit:${clientIP}`;
  
  const current = await env.BOOKS_CACHE?.get(rateLimitKey);
  const count = current ? parseInt(current) : 0;
  const limit = 100; // per hour
  
  if (count >= limit) {
    return { allowed: false, retryAfter: 3600 };
  }

  await env.BOOKS_CACHE?.put(rateLimitKey, (count + 1).toString(), { expirationTtl: 3600 });
  return { allowed: true, count: count + 1, remaining: limit - count - 1 };
}