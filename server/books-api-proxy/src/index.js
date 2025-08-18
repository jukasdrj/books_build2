/**
 * Books API Proxy - CloudFlare Worker
 * 
 * Multi-provider book search API with intelligent fallbacks:
 * 1. Google Books API (primary) - comprehensive data
 * 2. ISBNdb API (fallback) - 31+ million ISBNs, 19 data points
 * 3. Open Library API (fallback) - free, extensive catalog
 * 
 * Features:
 * - Rate limiting per IP
 * - Hybrid R2 + KV caching (hot/cold cache tiers)
 * - Provider fallbacks
 * - Request analytics
 * - CORS support
 */

export default {
  async fetch(request, env, ctx) {
    // Handle CORS preflight
    if (request.method === 'OPTIONS') {
      return handleCORS();
    }

    try {
      const url = new URL(request.url);
      const path = url.pathname;

      // Route requests
      if (path === '/search') {
        return await handleBookSearch(request, env, ctx);
      } else if (path === '/isbn') {
        return await handleISBNLookup(request, env, ctx);
      } else if (path === '/health') {
        return new Response(JSON.stringify({ 
          status: 'healthy', 
          timestamp: new Date().toISOString(),
          providers: ['google-books', 'isbndb', 'open-library'],
          cache: {
            system: env.BOOKS_R2 ? 'R2+KV-Hybrid' : 'KV-Only',
            kv: env.BOOKS_CACHE ? 'available' : 'missing',
            r2: env.BOOKS_R2 ? 'available' : 'missing'
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

// CORS headers
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

// ========================================
// INPUT VALIDATION & SECURITY
// ========================================

/**
 * Validate and sanitize search query parameters
 */
function validateSearchParams(url) {
  const query = url.searchParams.get('q');
  const maxResults = url.searchParams.get('maxResults');
  const sortBy = url.searchParams.get('orderBy');
  const langRestrict = url.searchParams.get('langRestrict');
  
  const errors = [];
  const sanitized = {};
  
  // Validate and sanitize query
  if (!query || typeof query !== 'string') {
    errors.push('Query parameter "q" is required and must be a string');
  } else if (query.trim().length === 0) {
    errors.push('Query parameter "q" cannot be empty');
  } else if (query.length > 500) {
    errors.push('Query parameter "q" must be less than 500 characters');
  } else {
    // Sanitize query - remove potentially dangerous characters
    const sanitizedQuery = query
      .replace(/[<>]/g, '') // Remove HTML brackets
      .replace(/['"]/g, '') // Remove quotes that could break JSON
      .replace(/[\x00-\x1F\x7F]/g, '') // Remove control characters
      .trim();
    
    if (sanitizedQuery.length === 0) {
      errors.push('Query contains only invalid characters');
    } else {
      sanitized.query = sanitizedQuery;
    }
  }
  
  // Validate maxResults
  if (maxResults !== null) {
    const maxResultsInt = parseInt(maxResults);
    if (isNaN(maxResultsInt) || maxResultsInt < 1 || maxResultsInt > 40) {
      errors.push('maxResults must be a number between 1 and 40');
    } else {
      sanitized.maxResults = maxResultsInt;
    }
  } else {
    sanitized.maxResults = 20; // Default
  }
  
  // Validate sortBy
  if (sortBy !== null) {
    const validSortOptions = ['relevance', 'newest'];
    if (!validSortOptions.includes(sortBy)) {
      errors.push('orderBy must be either "relevance" or "newest"');
    } else {
      sanitized.sortBy = sortBy;
    }
  } else {
    sanitized.sortBy = 'relevance'; // Default
  }
  
  // Validate langRestrict
  if (langRestrict !== null) {
    // Allow common language codes (2-3 characters, letters only)
    if (!/^[a-z]{2,3}$/i.test(langRestrict)) {
      errors.push('langRestrict must be a valid 2-3 character language code');
    } else {
      sanitized.langRestrict = langRestrict.toLowerCase();
    }
  }
  
  // Calculate includeTranslations
  sanitized.includeTranslations = sanitized.langRestrict !== 'en';
  
  return { errors, sanitized };
}

/**
 * Validate and sanitize ISBN parameter
 */
function validateISBN(isbn) {
  if (!isbn || typeof isbn !== 'string') {
    return { error: 'ISBN parameter is required and must be a string' };
  }
  
  // Clean ISBN - remove common separators and leading equals
  const cleanedISBN = isbn
    .replace(/^=+/, '') // Remove leading equals (common in CSV exports)
    .replace(/[-\s]/g, '') // Remove hyphens and spaces
    .replace(/[^0-9X]/gi, '') // Keep only numbers and X
    .toUpperCase();
  
  // Validate ISBN format
  if (cleanedISBN.length !== 10 && cleanedISBN.length !== 13) {
    return { error: 'ISBN must be 10 or 13 characters long' };
  }
  
  // Basic ISBN-10/13 format validation
  if (cleanedISBN.length === 10) {
    // ISBN-10: 9 digits + check digit (0-9 or X)
    if (!/^\d{9}[\dX]$/.test(cleanedISBN)) {
      return { error: 'Invalid ISBN-10 format' };
    }
  } else {
    // ISBN-13: 13 digits only
    if (!/^\d{13}$/.test(cleanedISBN)) {
      return { error: 'Invalid ISBN-13 format' };
    }
  }
  
  return { sanitized: cleanedISBN };
}

/**
 * Rate limiting with enhanced security
 */
async function checkRateLimitEnhanced(request, env) {
  const clientIP = request.headers.get('CF-Connecting-IP') || 'unknown';
  const userAgent = request.headers.get('User-Agent') || 'unknown';
  
  // Enhanced rate limiting key includes IP and basic user agent fingerprint
  const rateLimitKey = `ratelimit:${clientIP}:${btoa(userAgent).slice(0, 8)}`;
  
  // More restrictive limits for suspicious patterns
  let maxRequests = 100;
  const windowSize = 3600; // 1 hour
  
  // Detect suspicious patterns
  if (userAgent.length < 10 || userAgent === 'unknown') {
    maxRequests = 20; // Much lower limit for suspicious requests
  }
  
  const current = await env.BOOKS_CACHE?.get(rateLimitKey);
  const count = current ? parseInt(current) : 0;
  
  if (count >= maxRequests) {
    return { 
      allowed: false, 
      retryAfter: windowSize,
      reason: 'Rate limit exceeded'
    };
  }
  
  // Increment counter
  const newCount = count + 1;
  await env.BOOKS_CACHE?.put(rateLimitKey, newCount.toString(), { expirationTtl: windowSize });
  
  return { 
    allowed: true, 
    count: newCount, 
    remaining: maxRequests - newCount 
  };
}

// ========================================
// HYBRID R2 + KV CACHE SYSTEM
// ========================================

/**
 * Enhanced cache system using R2 (cold cache) + KV (hot cache)
 * - KV: Fast access, limited capacity (100k reads/day, 1GB)
 * - R2: High capacity, slower access (10M reads/month, 10GB free)
 */

// Generate cache keys for different request types
const CACHE_KEYS = {
  search: (query, maxResults, sortBy, translations) => 
    `search/${btoa(query).replace(/[/+=]/g, '_')}/${maxResults}/${sortBy}/${translations}.json`,
  isbn: (isbn) => `isbn/${isbn}.json`
};

/**
 * Get cached data with hot/cold cache fallback
 */
async function getCachedData(cacheKey, env) {
  try {
    // Try hot cache (KV) first - fastest access
    const kvData = await env.BOOKS_CACHE?.get(cacheKey);
    if (kvData) {
      return {
        data: JSON.parse(kvData),
        source: 'KV-HOT'
      };
    }
    
    // Try cold cache (R2) second - higher capacity
    if (env.BOOKS_R2) {
      const r2Object = await env.BOOKS_R2.get(cacheKey);
      if (r2Object) {
        const jsonData = await r2Object.text();
        const data = JSON.parse(jsonData);
        
        // Check if data is still fresh (respect TTL in metadata)
        const metadata = r2Object.customMetadata;
        if (metadata?.ttl && Date.now() > parseInt(metadata.ttl)) {
          // Data expired, remove from R2
          await env.BOOKS_R2.delete(cacheKey);
          return null;
        }
        
        // Promote to hot cache for future requests (1 day hot cache)
        const promoteData = JSON.stringify(data);
        env.waitUntil(env.BOOKS_CACHE?.put(cacheKey, promoteData, { expirationTtl: 86400 }));
        
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

/**
 * Store data in both cache tiers with appropriate TTLs
 */
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
          },
          customMetadata: { 
            ttl: (Date.now() + ttlSeconds * 1000).toString(),
            created: Date.now().toString(),
            type: cacheKey.startsWith('search') ? 'search' : 'isbn'
          }
        })
      );
    }
    
    // Store in KV for hot access with shorter TTL to manage limits
    const kvTtl = Math.min(ttlSeconds, 86400); // Max 1 day in KV to manage capacity
    promises.push(
      env.BOOKS_CACHE?.put(cacheKey, jsonData, { expirationTtl: kvTtl })
    );
    
    // Execute both cache operations
    if (ctx && ctx.waitUntil) {
      ctx.waitUntil(Promise.all(promises.filter(Boolean)));
    } else {
      await Promise.all(promises.filter(Boolean));
    }
    
  } catch (error) {
    console.warn(`Cache write error for key ${cacheKey}:`, error.message);
    // Don't fail the request if caching fails
  }
}

// Main book search handler
async function handleBookSearch(request, env, ctx) {
  const url = new URL(request.url);
  
  // Validate and sanitize input parameters
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

  // Enhanced rate limiting check
  const rateLimitResult = await checkRateLimitEnhanced(request, env);
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

  // Check hybrid cache first (KV hot cache → R2 cold cache)
  const cacheKey = CACHE_KEYS.search(query, maxResults, sortBy, includeTranslations);
  const cached = await getCachedData(cacheKey, env);
  if (cached) {
    return new Response(JSON.stringify(cached.data), {
      headers: {
        ...getCORSHeaders(),
        'X-Cache': `HIT-${cached.source}`,
        'X-Cache-Source': cached.source
      }
    });
  }

  // Try providers in order
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

  // No additional fallbacks - WorldCat removed due to lack of implementation

  if (!result) {
    return new Response(JSON.stringify({ 
      error: 'All book providers failed',
      items: []
    }), {
      status: 503,
      headers: getCORSHeaders()
    });
  }

  // Add provider metadata
  result.provider = provider;
  result.cached = false;

  const response = JSON.stringify(result);

  // Cache successful results using hybrid system
  if (result.items?.length > 0) {
    // 30 days for search results - they rarely change
    setCachedData(cacheKey, result, 2592000, env, ctx);
  }

  return new Response(response, {
    headers: {
      ...getCORSHeaders(),
      'X-Cache': 'MISS',
      'X-Provider': provider,
      'X-Cache-System': env.BOOKS_R2 ? 'R2+KV-Hybrid' : 'KV-Only'
    }
  });
}

// ISBN lookup handler
async function handleISBNLookup(request, env, ctx) {
  const url = new URL(request.url);
  const rawISBN = url.searchParams.get('isbn');
  
  // Validate and sanitize ISBN
  const validation = validateISBN(rawISBN);
  if (validation.error) {
    return new Response(JSON.stringify({ 
      error: validation.error 
    }), {
      status: 400,
      headers: getCORSHeaders()
    });
  }
  
  const isbn = validation.sanitized;

  // Check hybrid cache first (KV hot cache → R2 cold cache)
  const cacheKey = CACHE_KEYS.isbn(isbn);
  const cached = await getCachedData(cacheKey, env);
  if (cached) {
    return new Response(JSON.stringify(cached.data), {
      headers: {
        ...getCORSHeaders(),
        'X-Cache': `HIT-${cached.source}`,
        'X-Cache-Source': cached.source
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
    return new Response(JSON.stringify({ 
      error: 'ISBN not found in any provider',
      isbn: isbn
    }), {
      status: 404,
      headers: getCORSHeaders()
    });
  }

  result.provider = provider;
  const response = JSON.stringify(result);

  // Cache ISBN lookups using hybrid system - 1 year TTL (book metadata is permanent)
  setCachedData(cacheKey, result, 31536000, env, ctx);

  return new Response(response, {
    headers: {
      ...getCORSHeaders(),
      'X-Cache': 'MISS',
      'X-Provider': provider,
      'X-Cache-System': env.BOOKS_R2 ? 'R2+KV-Hybrid' : 'KV-Only'
    }
  });
}

// Google Books API implementation
async function searchGoogleBooks(query, maxResults, sortBy, includeTranslations, env) {
  // Use your CloudFlare secrets: google1 as primary, google2 as fallback
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
  // Use your CloudFlare secrets: google1 as primary, google2 as fallback
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

// Open Library API implementation
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
  
  // Convert Open Library format to Google Books format
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
        description: '', // Open Library doesn't provide descriptions in search
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

  // Convert to Google Books format
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
      language: 'en', // Open Library doesn't always provide language
      previewLink: bookData.url,
      infoLink: bookData.url
    }
  };
}

// ISBNdb API implementation
async function searchISBNdb(query, maxResults, env) {
  const apiKey = env.ISBNdb1;
  
  if (!apiKey) {
    throw new Error('ISBNdb API key not configured (ISBNdb1)');
  }
  
  // ISBNdb supports different search endpoints
  // For general queries, we'll use the title search endpoint
  const baseUrl = 'https://api2.isbndb.com';
  const endpoint = query.match(/^\d{10}(\d{3})?$/) ? `/book/${query}` : `/books/${encodeURIComponent(query)}`;
  
  const params = new URLSearchParams({
    pageSize: Math.min(maxResults, 20).toString(), // ISBNdb has limits
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
  
  // Convert ISBNdb format to Google Books format
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
    throw new Error('ISBNdb API key not configured (ISBNdb1)');
  }
  
  const response = await fetch(`https://api2.isbndb.com/book/${isbn}`, {
    headers: {
      'X-API-KEY': apiKey,
      'Content-Type': 'application/json'
    }
  });
  
  if (!response.ok) {
    if (response.status === 404) {
      return null; // ISBN not found
    }
    throw new Error(`ISBNdb ISBN API error: ${response.status}`);
  }
  
  const data = await response.json();
  const book = data.book;
  
  if (!book) {
    return null;
  }
  
  // Convert to Google Books format
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

// WorldCat integration removed - was placeholder returning empty results

// Rate limiting implementation
async function checkRateLimit(request, env) {
  const clientIP = request.headers.get('CF-Connecting-IP') || 'unknown';
  const rateLimitKey = `ratelimit:${clientIP}`;
  
  // Allow 100 requests per hour per IP
  const maxRequests = 100;
  const windowSize = 3600; // 1 hour
  
  const current = await env.BOOKS_CACHE?.get(rateLimitKey);
  const count = current ? parseInt(current) : 0;
  
  if (count >= maxRequests) {
    return { allowed: false, retryAfter: windowSize };
  }
  
  // Increment counter
  const newCount = count + 1;
  await env.BOOKS_CACHE?.put(rateLimitKey, newCount.toString(), { expirationTtl: windowSize });
  
  return { allowed: true, count: newCount, remaining: maxRequests - newCount };
}