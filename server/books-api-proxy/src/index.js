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
      } else if (path === '/cache/warm') {
        return await handleCacheWarm(request, env, ctx);
      } else if (path.startsWith('/cache/warm/')) {
        // Format-specific cache warming endpoints
        const format = path.split('/')[3]; // /cache/warm/books, /cache/warm/audiobooks, etc.
        return await handleFormatSpecificCacheWarm(format, request, env, ctx);
      } else if (path === '/author/enhance') {
        return await handleAuthorEnhancement(request, env, ctx);
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
  
  // Quality filtering parameters
  const minPages = url.searchParams.get('minPages');
  const excludeCollections = url.searchParams.get('excludeCollections');
  const excludeStudyGuides = url.searchParams.get('excludeStudyGuides');
  const qualityFilter = url.searchParams.get('qualityFilter');
  
  // ISBNdb-specific parameters
  const subject = url.searchParams.get('subject');
  const author = url.searchParams.get('author');
  
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
  
  // Validate quality filtering parameters
  if (minPages !== null) {
    const minPagesInt = parseInt(minPages);
    if (isNaN(minPagesInt) || minPagesInt < 1 || minPagesInt > 5000) {
      errors.push('minPages must be a number between 1 and 5000');
    } else {
      sanitized.minPages = minPagesInt;
    }
  } else {
    sanitized.minPages = null; // No minimum filter
  }
  
  // Parse boolean quality filters
  sanitized.excludeCollections = excludeCollections === 'true';
  sanitized.excludeStudyGuides = excludeStudyGuides === 'true';
  
  // Validate qualityFilter
  if (qualityFilter !== null) {
    const validQualityOptions = ['standard', 'high', 'premium'];
    if (!validQualityOptions.includes(qualityFilter)) {
      errors.push('qualityFilter must be "standard", "high", or "premium"');
    } else {
      sanitized.qualityFilter = qualityFilter;
    }
  } else {
    sanitized.qualityFilter = 'standard'; // Default
  }
  
  // Calculate includeTranslations
  sanitized.includeTranslations = sanitized.langRestrict !== 'en';
  
  // Add ISBNdb-specific search parameters
  sanitized.subject = subject;
  sanitized.author = author;
  
  return { errors, sanitized };
}

/**
 * Calculate quality score for a book result
 */
function calculateBookQualityScore(book, originalQuery) {
  let score = 0;
  const volumeInfo = book.volumeInfo || {};
  const title = volumeInfo.title || '';
  const authors = volumeInfo.authors || [];
  const pageCount = volumeInfo.pageCount || 0;
  const categories = volumeInfo.categories || [];
  const publisher = volumeInfo.publisher || '';
  const description = volumeInfo.description || '';
  
  // Base score for having essential metadata
  if (title) score += 10;
  if (authors.length > 0) score += 10;
  if (pageCount > 0) score += 5;
  if (publisher) score += 5;
  if (description) score += 5;
  
  // Page count scoring (higher = better quality)
  if (pageCount >= 200) score += 15;
  else if (pageCount >= 100) score += 10;
  else if (pageCount >= 50) score += 5;
  else if (pageCount > 0 && pageCount < 50) score -= 10; // Penalize very short books
  
  // Publisher reputation scoring
  const prestigiousPublishers = [
    'penguin', 'random house', 'harpercollins', 'simon & schuster', 'macmillan',
    'oxford university press', 'cambridge university press', 'yale university press',
    'harvard university press', 'mit press', 'norton', 'doubleday', 'knopf',
    'ballantine', 'bantam', 'crown', 'farrar', 'little brown', 'scribner'
  ];
  
  if (prestigiousPublishers.some(pub => publisher.toLowerCase().includes(pub))) {
    score += 10;
  }
  
  // Penalize low-quality content indicators
  const lowQualityTerms = [
    'summary', 'study guide', 'sparknotes', 'cliffsnotes', 'quick read',
    'analysis', 'companion', 'workbook', 'test prep', 'exam guide',
    'collection set', 'bundle', '3-book', '4-book', '5-book',
    'movie tie in', 'movie tie-in', 'classroom edition', 'tie-in edition', 'movie edition', 'film tie-in'
  ];
  
  const titleLower = title.toLowerCase();
  const descriptionLower = description.toLowerCase();
  
  for (const term of lowQualityTerms) {
    if (titleLower.includes(term) || descriptionLower.includes(term)) {
      score -= 15;
    }
  }
  
  // Category scoring (penalize study aids and reference)
  const lowQualityCategories = ['study aids', 'reference', 'test preparation', 'education'];
  for (const category of categories) {
    if (lowQualityCategories.some(lq => category.toLowerCase().includes(lq))) {
      score -= 10;
    }
  }
  
  // Author name exact match bonus
  const queryLower = originalQuery.toLowerCase();
  for (const author of authors) {
    if (queryLower.includes(author.toLowerCase())) {
      score += 20;
    }
  }
  
  // Title relevance scoring
  const titleWords = titleLower.split(' ');
  const queryWords = queryLower.split(' ');
  let relevanceScore = 0;
  
  for (const queryWord of queryWords) {
    if (queryWord.length > 2) { // Only score meaningful words
      for (const titleWord of titleWords) {
        if (titleWord.includes(queryWord) || queryWord.includes(titleWord)) {
          relevanceScore += 5;
        }
      }
    }
  }
  
  score += Math.min(relevanceScore, 25); // Cap relevance bonus
  
  return Math.max(0, score); // Ensure non-negative score
}

/**
 * Filter and sort search results based on quality parameters
 */
function filterAndSortResults(results, qualityParams, originalQuery) {
  const { minPages, excludeCollections, excludeStudyGuides, qualityFilter } = qualityParams;
  
  let filteredResults = results.filter(book => {
    const volumeInfo = book.volumeInfo || {};
    const title = volumeInfo.title || '';
    const pageCount = volumeInfo.pageCount || 0;
    
    // Apply minPages filter
    if (minPages && pageCount > 0 && pageCount < minPages) {
      return false;
    }
    
    // Apply collections filter
    if (excludeCollections) {
      const collectionTerms = ['collection', 'set', 'bundle', '3-book', '4-book', '5-book', 'boxed'];
      if (collectionTerms.some(term => title.toLowerCase().includes(term))) {
        return false;
      }
    }
    
    // Apply study guides filter
    if (excludeStudyGuides) {
      const studyTerms = ['study guide', 'sparknotes', 'cliffsnotes', 'summary', 'analysis', 'companion', 'movie tie in', 'movie tie-in', 'classroom edition', 'tie-in edition', 'movie edition', 'film tie-in'];
      if (studyTerms.some(term => title.toLowerCase().includes(term))) {
        return false;
      }
    }
    
    return true;
  });
  
  // Calculate quality scores and sort
  const scoredResults = filteredResults.map(book => ({
    ...book,
    _qualityScore: calculateBookQualityScore(book, originalQuery)
  }));
  
  // Apply quality filter thresholds
  let qualityThreshold = 0;
  switch (qualityFilter) {
    case 'high':
      qualityThreshold = 30;
      break;
    case 'premium':
      qualityThreshold = 50;
      break;
    case 'standard':
    default:
      qualityThreshold = 0;
      break;
  }
  
  const qualityFilteredResults = scoredResults.filter(book => book._qualityScore >= qualityThreshold);
  
  // Sort by quality score (highest first)
  qualityFilteredResults.sort((a, b) => b._qualityScore - a._qualityScore);
  
  // Remove the internal quality score before returning
  return qualityFilteredResults.map(book => {
    const { _qualityScore, ...cleanBook } = book;
    return cleanBook;
  });
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

// Generate cache keys for different request types and formats
const CACHE_KEYS = {
  search: (query, maxResults, sortBy, translations, format = 'book') => 
    `search/${format}/${btoa(query).replace(/[/+=]/g, '_')}/${maxResults}/${sortBy}/${translations}.json`,
  isbn: (isbn, format = 'book') => `isbn/${format}/${isbn}.json`,
  author: (authorName) => `author/${btoa(authorName).replace(/[/+=]/g, '_')}.json`
};

// Format-specific search parameters - simplified to books only
const FORMAT_CONFIGS = {
  book: {
    searchModifier: '',
    printType: 'books',
    identifier: 'isbn'
  }
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
  
  const { query, maxResults, sortBy, includeTranslations, minPages, excludeCollections, excludeStudyGuides, qualityFilter, subject, author } = validation.sanitized;

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
    // Apply quality filtering to cached results as well
    const cachedResult = cached.data;
    if (cachedResult.items?.length > 0) {
      const qualityParams = { minPages, excludeCollections, excludeStudyGuides, qualityFilter };
      cachedResult.items = filterAndSortResults(cachedResult.items, qualityParams, query);
      cachedResult.totalItems = cachedResult.items.length;
    }
    
    return new Response(JSON.stringify(cachedResult), {
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

  // 1. ISBNdb API (primary)
  try {
    result = await searchISBNdb(query, maxResults, env, null, subject, author);
    provider = 'isbndb';
  } catch (error) {
    console.error('ISBNdb failed:', error.message);
  }

  // 2. Google Books API (fallback)
  if (!result || result.items?.length === 0) {
    try {
      result = await searchGoogleBooks(query, maxResults, sortBy, includeTranslations, env);
      provider = 'google-books';
    } catch (error) {
      console.error('Google Books failed:', error.message);
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

  // Apply quality filtering and sorting if requested
  if (result.items?.length > 0) {
    const qualityParams = { minPages, excludeCollections, excludeStudyGuides, qualityFilter };
    result.items = filterAndSortResults(result.items, qualityParams, query);
    result.totalItems = result.items.length; // Update total after filtering
  }

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

// ========================================
// MANUAL CACHE WARMING SYSTEM
// ========================================

/**
 * Comprehensive cache warming strategy for 1500+ books across all formats
 * Phase 1: Top 500 Books (2024-2025) - Print editions with focus on recent releases
 * Phase 2: Top 500 Audiobooks - Audio-specific editions with narrator data  
 * Phase 3: Top 500 Ebooks - Digital editions with format specifications
 * Phase 4: Enhanced metadata with Google Knowledge Graph integration
 */

// ========================================
// COMPREHENSIVE CACHE WARMING BOOK LISTS
// ========================================

/**
 * Phase 1: Top 500 Books from 2024-2025 (Print Focus)
 * Recent bestsellers, award winners, culturally diverse titles
 */
const CACHE_WARM_BOOKS_2024_2025 = [
  // 2025 Current Bestsellers & New Releases (125 books)
  "Fourth Wing Rebecca Yarros",
  "Iron Flame Rebecca Yarros",
  "Tomorrow and Tomorrow and Tomorrow Gabrielle Zevin",
  "The Atlas Six Olivie Blake",
  "Beach Read Emily Henry",
  "People We Meet on Vacation Emily Henry",
  "Book Lovers Emily Henry",
  "The House in the Cerulean Sea TJ Klune",
  "Under the Whispering Door TJ Klune",
  "In the Lives of Puppets TJ Klune",
  "The Invisible Life of Addie LaRue V.E. Schwab",
  "The Ten Thousand Doors of January Alix E. Harrow",
  "The Once and Future Witches Alix E. Harrow",
  "Mexican Gothic Silvia Moreno-Garcia",
  "The Midnight Library Matt Haig",
  "Klara and the Sun Kazuo Ishiguro",
  "The Seven Husbands of Evelyn Hugo Taylor Jenkins Reid",
  "Malibu Rising Taylor Jenkins Reid",
  "Carrie Soto Is Back Taylor Jenkins Reid",
  "Daisy Jones & The Six Taylor Jenkins Reid",
  "The Silent Patient Alex Michaelides",
  "The Maidens Alex Michaelides",
  "The Thursday Murder Club Richard Osman",
  "The Man Who Died Twice Richard Osman",
  "The Bullet That Missed Richard Osman",
  "The Last Thing He Told Me Laura Dave",
  "The Guest List Lucy Foley",
  "The Hunting Party Lucy Foley",
  "The Paris Apartment Lucy Foley",
  "Where the Crawdads Sing Delia Owens",
  "It Ends with Us Colleen Hoover",
  "It Starts with Us Colleen Hoover",
  "Verity Colleen Hoover",
  "November 9 Colleen Hoover",
  "Ugly Love Colleen Hoover",
  "Too Late Colleen Hoover",
  "Reminders of Him Colleen Hoover",
  "Heart Bones Colleen Hoover",
  "Layla Colleen Hoover",
  "Without Merit Colleen Hoover",
  "All Your Perfects Colleen Hoover",
  "Maybe Someday Colleen Hoover",
  "Atomic Habits James Clear",
  "Educated Tara Westover",
  "Becoming Michelle Obama",
  "The Body Keeps the Score Bessel van der Kolk",
  "Untamed Glennon Doyle",
  "The 48 Laws of Power Robert Greene",
  "Can't Hurt Me David Goggins",
  "The Subtle Art of Not Giving a F*ck Mark Manson",
  "12 Rules for Life Jordan Peterson",
  "Think Again Adam Grant",
  "The Power of Now Eckhart Tolle",
  "Big Magic Elizabeth Gilbert",
  "The Gifts of Imperfection Brené Brown",
  "Daring Greatly Brené Brown",
  "Rising Strong Brené Brown",
  "Braving the Wilderness Brené Brown",
  "The Alchemist Paulo Coelho",
  "The Four Agreements Don Miguel Ruiz",
  "A New Earth Eckhart Tolle",
  "The 7 Habits of Highly Effective People Stephen Covey",
  
  // Diverse & Cultural Fiction (125 books)
  "Beloved Toni Morrison",
  "Song of Solomon Toni Morrison",
  "The Bluest Eye Toni Morrison",
  "Sula Toni Morrison",
  "Jazz Toni Morrison",
  "Americanah Chimamanda Ngozi Adichie",
  "Half of a Yellow Sun Chimamanda Ngozi Adichie",
  "Purple Hibiscus Chimamanda Ngozi Adichie",
  "The Joy Luck Club Amy Tan",
  "The Woman Warrior Maxine Hong Kingston",
  "Everything I Never Told You Celeste Ng",
  "Little Fires Everywhere Celeste Ng",
  "Our Missing Hearts Celeste Ng",
  "Crazy Rich Asians Kevin Kwan",
  "China Rich Girlfriend Kevin Kwan",
  "Rich People Problems Kevin Kwan",
  "The Namesake Jhumpa Lahiri",
  "Interpreter of Maladies Jhumpa Lahiri",
  "The Lowland Jhumpa Lahiri",
  "Unaccustomed Earth Jhumpa Lahiri",
  "The God of Small Things Arundhati Roy",
  "White Teeth Zadie Smith",
  "On Beauty Zadie Smith",
  "NW Zadie Smith",
  "Swing Time Zadie Smith",
  "The Signature of All Things Zadie Smith",
  "The Brief Wondrous Life of Oscar Wao Junot Díaz",
  "This Is How You Lose Her Junot Díaz",
  "Drown Junot Díaz",
  "The House on Mango Street Sandra Cisneros",
  "Woman Hollering Creek Sandra Cisneros",
  "Caramelo Sandra Cisneros",
  "How the García Girls Lost Their Accents Julia Alvarez",
  "In the Time of the Butterflies Julia Alvarez",
  "The Spirit Catches You and You Fall Down Anne Fadiman",
  "Born a Crime Trevor Noah",
  "Homegoing Yaa Gyasi",
  "Transcendent Kingdom Yaa Gyasi",
  "The Water Dancer Ta-Nehisi Coates",
  "Between the World and Me Ta-Nehisi Coates",
  "We Were Eight Years in Power Ta-Nehisi Coates",
  "Such a Fun Age Kiley Reid",
  "Real Life Brandon Taylor",
  "The Vanishing Half Brit Bennett",
  "The Mothers Brit Bennett",
  "An American Marriage Tayari Jones",
  "Silver Sparrow Tayari Jones",
  "The Book of Lost Names Kristin Harmel",
  "The Nightingale Kristin Hannah",
  "The Four Winds Kristin Hannah",
  "Firefly Lane Kristin Hannah",
  "The Great Alone Kristin Hannah",
  "Winter Garden Kristin Hannah",
  "The Light We Lost Jill Santopolo",
  "Eleanor Oliphant Is Completely Fine Gail Honeyman",
  "A Man Called Ove Fredrik Backman",
  "Beartown Fredrik Backman",
  "Us Against You Fredrik Backman",
  "My Grandmother Asked Me to Tell You She's Sorry Fredrik Backman",
  "Anxious People Fredrik Backman",
  "The 100-Year-Old Man Who Climbed Out of the Window Jonas Jonasson",
  "The Girl with the Dragon Tattoo Stieg Larsson",
  "The Girl Who Played with Fire Stieg Larsson",
  "The Girl Who Kicked the Hornets' Nest Stieg Larsson",
  "A Gentleman in Moscow Amor Towles",
  "Rules of Civility Amor Towles",
  "The Lincoln Highway Amor Towles",
  "All the Light We Cannot See Anthony Doerr",
  "Cloud Cuckoo Land Anthony Doerr",
  "The Book Thief Markus Zusak",
  "I Am the Messenger Markus Zusak",
  "Bridge of Clay Markus Zusak",
  "Life of Pi Yann Martel",
  "The Kite Runner Khaled Hosseini",
  "A Thousand Splendid Suns Khaled Hosseini",
  "And the Mountains Echoed Khaled Hosseini",
  "The Sea and Poison Shusaku Endo",
  "Norwegian Wood Haruki Murakami",
  "Kafka on the Shore Haruki Murakami",
  "The Wind-Up Bird Chronicle Haruki Murakami",
  "Hard-Boiled Wonderland and the End of the World Haruki Murakami",
  "1Q84 Haruki Murakami",
  "Colorless Tsukuru Tazaki Haruki Murakami",
  "Killing Commendatore Haruki Murakami",
  "Men Without Women Haruki Murakami",
  "Never Let Me Go Kazuo Ishiguro",
  "The Remains of the Day Kazuo Ishiguro",
  "When We Were Orphans Kazuo Ishiguro",
  "The Buried Giant Kazuo Ishiguro",
  "An Artist of the Floating World Kazuo Ishiguro",
  
  // Popular Genre Fiction & Fantasy (125 books)
  "Dune Frank Herbert",
  "Dune Messiah Frank Herbert",
  "Children of Dune Frank Herbert",
  "God Emperor of Dune Frank Herbert",
  "The Foundation Isaac Asimov",
  "Foundation and Empire Isaac Asimov",
  "Second Foundation Isaac Asimov",
  "I, Robot Isaac Asimov",
  "The Caves of Steel Isaac Asimov",
  "The Naked Sun Isaac Asimov",
  "Ender's Game Orson Scott Card",
  "Speaker for the Dead Orson Scott Card",
  "Xenocide Orson Scott Card",
  "The Hitchhiker's Guide to the Galaxy Douglas Adams",
  "The Restaurant at the End of the Universe Douglas Adams",
  "Life, the Universe and Everything Douglas Adams",
  "So Long, and Thanks for All the Fish Douglas Adams",
  "Mostly Harmless Douglas Adams",
  "Neuromancer William Gibson",
  "Count Zero William Gibson",
  "Mona Lisa Overdrive William Gibson",
  "The Matrix William Gibson",
  "Brave New World Aldous Huxley",
  "1984 George Orwell",
  "Animal Farm George Orwell",
  "Fahrenheit 451 Ray Bradbury",
  "The Martian Chronicles Ray Bradbury",
  "Something Wicked This Way Comes Ray Bradbury",
  "Dandelion Wine Ray Bradbury",
  "The Handmaid's Tale Margaret Atwood",
  "The Testaments Margaret Atwood",
  "Oryx and Crake Margaret Atwood",
  "The Year of the Flood Margaret Atwood",
  "MaddAddam Margaret Atwood",
  "The Hunger Games Suzanne Collins",
  "Catching Fire Suzanne Collins",
  "Mockingjay Suzanne Collins",
  "The Ballad of Songbirds and Snakes Suzanne Collins",
  "Divergent Veronica Roth",
  "Insurgent Veronica Roth",
  "Allegiant Veronica Roth",
  "The Maze Runner James Dashner",
  "The Scorch Trials James Dashner",
  "The Death Cure James Dashner",
  "The Kill Order James Dashner",
  "The Fever Code James Dashner",
  "The Giver Lois Lowry",
  "Gathering Blue Lois Lowry",
  "Messenger Lois Lowry",
  "Son Lois Lowry",
  "A Game of Thrones George R.R. Martin",
  "A Clash of Kings George R.R. Martin",
  "A Storm of Swords George R.R. Martin",
  "A Feast for Crows George R.R. Martin",
  "A Dance with Dragons George R.R. Martin",
  "The Winds of Winter George R.R. Martin",
  "A Dream of Spring George R.R. Martin",
  "Fire and Blood George R.R. Martin",
  "The World of Ice and Fire George R.R. Martin",
  "The Princess and the Queen George R.R. Martin",
  "The Rogue Prince George R.R. Martin",
  "The Sons of the Dragon George R.R. Martin",
  "The Lord of the Rings J.R.R. Tolkien",
  "The Fellowship of the Ring J.R.R. Tolkien",
  "The Two Towers J.R.R. Tolkien",
  "The Return of the King J.R.R. Tolkien",
  "The Hobbit J.R.R. Tolkien",
  "The Silmarillion J.R.R. Tolkien",
  "Unfinished Tales J.R.R. Tolkien",
  "The Children of Húrin J.R.R. Tolkien",
  "Beren and Lúthien J.R.R. Tolkien",
  "The Fall of Gondolin J.R.R. Tolkien",
  "The Nature of Middle-earth J.R.R. Tolkien",
  "The Fall of Númenor J.R.R. Tolkien",
  "Harry Potter and the Philosopher's Stone J.K. Rowling",
  "Harry Potter and the Chamber of Secrets J.K. Rowling",
  "Harry Potter and the Prisoner of Azkaban J.K. Rowling",
  "Harry Potter and the Goblet of Fire J.K. Rowling",
  "Harry Potter and the Order of the Phoenix J.K. Rowling",
  "Harry Potter and the Half-Blood Prince J.K. Rowling",
  "Harry Potter and the Deathly Hallows J.K. Rowling",
  "The Tales of Beedle the Bard J.K. Rowling",
  "Fantastic Beasts and Where to Find Them J.K. Rowling",
  "Quidditch Through the Ages J.K. Rowling",
  "The Casual Vacancy J.K. Rowling",
  "The Cuckoo's Calling Robert Galbraith",
  "The Silkworm Robert Galbraith",
  "Career of Evil Robert Galbraith",
  "Lethal White Robert Galbraith",
  "Troubled Blood Robert Galbraith",
  "The Ink Black Heart Robert Galbraith",
  "The Running Grave Robert Galbraith",
  
  // 2024 Award Winners & Notable Releases (125 books)
  "The Heaven & Earth Grocery Store James McBride",
  "Demon Copperhead Barbara Kingsolver",
  "Trust Hernan Diaz",
  "The School for Good Mothers Jessamine Chan",
  "Lessons Ian McEwan",
  "The Candy House Jennifer Egan",
  "Sea of Tranquility Emily St. John Mandel",
  "The Atlas of Reds and Blues Devi S. Laskar",
  "Hamnet Maggie O'Farrell",
  "The Mirror & the Light Hilary Mantel",
  "Wolf Hall Hilary Mantel",
  "Bring Up the Bodies Hilary Mantel",
  "The Committed Viet Thanh Nguyen",
  "The Sympathizer Viet Thanh Nguyen",
  "The Refugees Viet Thanh Nguyen",
  "My Name Is Lucy Barton Elizabeth Strout",
  "Oh William! Elizabeth Strout",
  "Lucy by the Sea Elizabeth Strout",
  "Olive Kitteridge Elizabeth Strout",
  "Olive, Again Elizabeth Strout",
  "The Underground Railroad Colson Whitehead",
  "The Nickel Boys Colson Whitehead",
  "Harlem Shuffle Colson Whitehead",
  "Crook Manifesto Colson Whitehead",
  "Station Eleven Emily St. John Mandel",
  "The Glass Hotel Emily St. John Mandel"
];

// Removed audiobook caching - focusing on book-only optimization

// Removed ebook caching - focusing on book-only optimization
const CACHE_WARM_EBOOKS_2024_2025 = [
  // Digital-First/Popular Ebooks
  "Fourth Wing Rebecca Yarros",
  "Iron Flame Rebecca Yarros", 
  "It Ends with Us Colleen Hoover",
  "It Starts with Us Colleen Hoover",
  "Verity Colleen Hoover",
  "Reminders of Him Colleen Hoover",
  "November 9 Colleen Hoover",
  "Ugly Love Colleen Hoover",
  "All Your Perfects Colleen Hoover",
  "Maybe Someday Colleen Hoover",
  
  // Romance Ebooks (High Digital Sales)
  "Beach Read Emily Henry",
  "Book Lovers Emily Henry", 
  "People We Meet on Vacation Emily Henry",
  "The Seven Husbands of Evelyn Hugo",
  "Malibu Rising Taylor Jenkins Reid",
  "Daisy Jones & The Six",
  "The Spanish Love Deception",
  "The Hating Game Sally Thorne",
  "Red, White & Royal Blue",
  "The Kiss Quotient Helen Hoang",
  
  // Thriller/Mystery Ebooks
  "The Silent Patient Alex Michaelides",
  "The Guest List Lucy Foley",
  "The Last Thing He Told Me",
  "The Thursday Murder Club",
  "Gone Girl Gillian Flynn",
  "The Girl on the Train",
  "In the Woods Tana French",
  "The Cuckoo's Calling",
  "Big Little Lies Liane Moriarty",
  "The Woman in the Window",
  
  // Fantasy/Sci-Fi Ebooks
  "The House in the Cerulean Sea",
  "The Invisible Life of Addie LaRue",
  "Mexican Gothic Silvia Moreno-Garcia",
  "The Ten Thousand Doors of January",
  "The Once and Future Witches",
  "Klara and the Sun Kazuo Ishiguro",
  "The Midnight Library Matt Haig",
  "Project Hail Mary Andy Weir",
  "The Martian Andy Weir",
  "Ready Player One Ernest Cline",
  
  // Literary Fiction Ebooks
  "Tomorrow and Tomorrow and Tomorrow",
  "The Atlas Six Olivie Blake",
  "Lessons in Chemistry Bonnie Garmus",
  "Where the Crawdads Sing",
  "Eleanor Oliphant Is Completely Fine",
  "A Man Called Ove Fredrik Backman",
  "Educated Tara Westover",
  "Becoming Michelle Obama",
  "Untamed Glennon Doyle",
  "Atomic Habits James Clear"
];

/**
 * Phase 4: Cultural Diversity & International Focus (Cross-Format)
 * Books emphasizing diverse voices and international perspectives
 */
const CACHE_WARM_DIVERSE_INTERNATIONAL = [
  // African/African-American Voices
  "Homecoming Yaa Gyasi",
  "Transcendent Kingdom Yaa Gyasi", 
  "Born a Crime Trevor Noah",
  "Americanah Chimamanda Ngozi Adichie",
  "Half of a Yellow Sun Chimamanda Ngozi Adichie",
  "Purple Hibiscus Chimamanda Ngozi Adichie",
  "The Water Dancer Ta-Nehisi Coates",
  "Between the World and Me Ta-Nehisi Coates",
  "Such a Fun Age Kiley Reid",
  "The Vanishing Half Brit Bennett",
  "An American Marriage Tayari Jones",
  "Beloved Toni Morrison",
  "Song of Solomon Toni Morrison",
  
  // Asian Voices
  "Everything I Never Told You Celeste Ng",
  "Little Fires Everywhere Celeste Ng",
  "Our Missing Hearts Celeste Ng",
  "Crazy Rich Asians Kevin Kwan",
  "The Namesake Jhumpa Lahiri",
  "Interpreter of Maladies Jhumpa Lahiri",
  "The Joy Luck Club Amy Tan",
  "Norwegian Wood Haruki Murakami",
  "Kafka on the Shore Haruki Murakami",
  "Never Let Me Go Kazuo Ishiguro",
  "Klara and the Sun Kazuo Ishiguro",
  "The Sympathizer Viet Thanh Nguyen",
  "The Committed Viet Thanh Nguyen",
  
  // Latin American/Latino Voices
  "The House on Mango Street Sandra Cisneros",
  "The Brief Wondrous Life of Oscar Wao Junot Díaz",
  "How the García Girls Lost Their Accents Julia Alvarez",
  "In the Time of the Butterflies Julia Alvarez", 
  "Mexican Gothic Silvia Moreno-Garcia",
  "Gods of Jade and Shadow Silvia Moreno-Garcia",
  
  // European/International Voices
  "Elena Ferrante Neapolitan Novels",
  "The Girl with the Dragon Tattoo Stieg Larsson",
  "A Man Called Ove Fredrik Backman",
  "Anxious People Fredrik Backman",
  "The 100-Year-Old Man Jonas Jonasson",
  "My Struggle Karl Ove Knausgård",
  "2666 Roberto Bolaño",
  "The Savage Detectives Roberto Bolaño"
];

/**
 * Handle manual cache warming requests
 * POST /cache/warm - Trigger comprehensive cache warming (all formats)
 * GET /cache/warm/status - Check warming progress
 * POST /cache/warm/books - Warm book cache specifically  
 * POST /cache/warm/audiobooks - Warm cache specifically
 * POST /cache/warm/ebooks - Warm cache specifically
 * POST /cache/warm/diverse - Warm diverse/international titles
 */
async function handleCacheWarm(request, env, ctx) {
  const url = new URL(request.url);
  
  if (request.method === 'POST') {
    // Trigger comprehensive cache warming (all formats)
    return await triggerCacheWarm(request, env, ctx);
  } else if (request.method === 'GET') {
    // Return cache warming status and metrics
    return await getCacheWarmStatus(env);
  } else {
    return new Response(JSON.stringify({ 
      error: 'Method not allowed. Use POST to trigger warming or GET for status.' 
    }), {
      status: 405,
      headers: getCORSHeaders()
    });
  }
}

/**
 * Handle format-specific cache warming
 * /cache/warm/books - Books only
 * /cache/warm/audiobooks - Audiobooks only  
 * /cache/warm/ebooks - Ebooks only
 * /cache/warm/diverse - Diverse/international titles
 */
async function handleFormatSpecificCacheWarm(format, request, env, ctx) {
  if (request.method !== 'POST') {
    return new Response(JSON.stringify({ 
      error: 'Method not allowed. Use POST to trigger format-specific warming.' 
    }), {
      status: 405,
      headers: getCORSHeaders()
    });
  }
  
  // Select appropriate book list based on format
  let bookList, formatType;
  switch(format) {
    case 'books':
      bookList = CACHE_WARM_BOOKS_2024_2025;
      formatType = 'book';
      break;
    case 'audiobooks':
      bookList = CACHE_WARM_AUDIOBOOKS_2024_2025;
      formatType = 'audiobook';
      break;
    case 'ebooks':
      bookList = CACHE_WARM_EBOOKS_2024_2025;
      formatType = 'ebook';
      break;
    case 'diverse':
      bookList = CACHE_WARM_DIVERSE_INTERNATIONAL;
      formatType = 'book'; // Default to book format for diverse titles
      break;
    default:
      return new Response(JSON.stringify({ 
        error: `Unknown format: ${format}. Valid formats: books,s,s, diverse` 
      }), {
        status: 400,
        headers: getCORSHeaders()
      });
  }
  
  return await triggerFormatSpecificCacheWarm(bookList, formatType, format, env, ctx);
}

/**
 * Author enhancement using Google Knowledge Graph API
 * POST /author/enhance - Enhance author metadata with cultural data
 */
async function handleAuthorEnhancement(request, env, ctx) {
  if (request.method !== 'POST') {
    return new Response(JSON.stringify({ 
      error: 'Method not allowed. Use POST to enhance author data.' 
    }), {
      status: 405,
      headers: getCORSHeaders()
    });
  }
  
  try {
    const requestBody = await request.json();
    const authorName = requestBody.author;
    
    if (!authorName) {
      return new Response(JSON.stringify({ 
        error: 'Author name required in request body: {"author": "Author Name"}' 
      }), {
        status: 400,
        headers: getCORSHeaders()
      });
    }
    
    // Check cache first
    const cacheKey = CACHE_KEYS.author(authorName);
    const cached = await getCachedData(cacheKey, env);
    if (cached) {
      return new Response(JSON.stringify(cached.data), {
        headers: {
          ...getCORSHeaders(),
          'X-Cache': `HIT-${cached.source}`
        }
      });
    }
    
    // Enhance author data using Google APIs
    const enhancedAuthor = await enhanceAuthorData(authorName, env);
    
    // Cache the enhanced data for 7 days 
    await setCachedData(cacheKey, enhancedAuthor, 604800, env, ctx);
    
    return new Response(JSON.stringify(enhancedAuthor), {
      headers: {
        ...getCORSHeaders(),
        'X-Cache': 'MISS',
        'X-Enhancement-Source': 'google-apis'
      }
    });
    
  } catch (error) {
    console.error('Author enhancement error:', error);
    return new Response(JSON.stringify({ 
      error: 'Author enhancement failed', 
      message: error.message 
    }), {
      status: 500,
      headers: getCORSHeaders()
    });
  }
}

/**
 * Trigger format-specific cache warming
 */
async function triggerFormatSpecificCacheWarm(bookList, formatType, formatName, env, ctx) {
  try {
    const startTime = Date.now();
    const results = {
      started: new Date().toISOString(),
      format: formatName,
      formatType: formatType,
      totalBooks: bookList.length,
      cached: 0,
      failed: 0,
      skipped: 0,
      errors: [],
      performance: {
        averageTime: 0,
        fastest: null,
        slowest: null
      }
    };
    
    const times = [];
    const formatConfig = FORMAT_CONFIGS[formatType];
    
    // Optimized batch processing for CloudFlare Workers
    const BATCH_SIZE = 2; // Smaller batches to avoid timeouts
    const BATCH_DELAY = 2000; // 2 seconds between batches for API rate limiting
    const MAX_BOOKS_PER_RUN = 25; // Limit per invocation to stay within worker limits
    
    const booksToProcess = bookList.slice(0, MAX_BOOKS_PER_RUN);
    
    for (let i = 0; i < booksToProcess.length; i += BATCH_SIZE) {
      const batch = booksToProcess.slice(i, i + BATCH_SIZE);
      
      // Process batch with format-specific logic
      const batchPromises = batch.map(async (bookQuery) => {
        const bookStartTime = Date.now();
        
        try {
          // Create format-specific query
          const enhancedQuery = bookQuery + formatConfig.searchModifier;
          
          // Check if already cached with format-specific key
          const cacheKey = CACHE_KEYS.search(enhancedQuery, 5, 'relevance', true, formatType);
          const existing = await getCachedData(cacheKey, env);
          
          if (existing) {
            results.skipped++;
            return { query: bookQuery, status: 'skipped', reason: 'already cached', format: formatType };
          }
          
          // Use higher-limit API keys for comprehensive search
          let searchResult = await searchWithHigherLimits(enhancedQuery, 5, formatConfig, env);
          
          if (searchResult && searchResult.items && searchResult.items.length > 0) {
            // Add format metadata
            searchResult.format = formatType;
            searchResult.formatConfig = formatConfig;
            searchResult.cached = false;
            
            await setCachedData(cacheKey, searchResult, 2592000, env, ctx); // 30 days TTL
            
            const bookTime = Date.now() - bookStartTime;
            times.push(bookTime);
            results.cached++;
            
            return { 
              query: bookQuery, 
              status: 'cached', 
              provider: searchResult.provider,
              format: formatType,
              results: searchResult.items.length,
              time: bookTime
            };
          } else {
            results.failed++;
            const error = `No results found for "${bookQuery}" (${formatType})`;
            results.errors.push(error);
            return { query: bookQuery, status: 'failed', reason: 'no results', format: formatType };
          }
          
        } catch (error) {
          results.failed++;
          const errorMsg = `Error processing "${bookQuery}" (${formatType}): ${error.message}`;
          results.errors.push(errorMsg);
          console.error(errorMsg);
          return { query: bookQuery, status: 'error', reason: error.message, format: formatType };
        }
      });
      
      // Wait for batch to complete
      const batchResults = await Promise.all(batchPromises);
      
      // Log progress
      console.log(`${formatName} cache warming batch ${Math.floor(i/BATCH_SIZE) + 1}/${Math.ceil(booksToProcess.length/BATCH_SIZE)} completed`);
      
      // Delay between batches
      if (i + BATCH_SIZE < booksToProcess.length) {
        await new Promise(resolve => setTimeout(resolve, BATCH_DELAY));
      }
    }
    
    // Calculate performance metrics
    if (times.length > 0) {
      results.performance.averageTime = Math.round(times.reduce((a, b) => a + b, 0) / times.length);
      results.performance.fastest = Math.min(...times);
      results.performance.slowest = Math.max(...times);
    }
    
    const totalTime = Date.now() - startTime;
    results.completed = new Date().toISOString();
    results.totalTime = totalTime;
    results.booksProcessed = booksToProcess.length;
    results.successRate = ((results.cached / booksToProcess.length) * 100).toFixed(1) + '%';
    
    // Store results
    const statusKey = `cache_warm_status_${formatName}`;
    await env.BOOKS_CACHE?.put(statusKey, JSON.stringify(results), { expirationTtl: 86400 });
    
    return new Response(JSON.stringify({
      status: 'completed',
      message: `${formatName} cache warming completed! Successfully cached ${results.cached}/${results.booksProcessed} books.`,
      results: results
    }), {
      headers: {
        ...getCORSHeaders(),
        'X-Cache-Warm': 'COMPLETED',
        'X-Cache-Format': formatType,
        'X-Cache-Success': results.cached.toString()
      }
    });
    
  } catch (error) {
    console.error(`${formatName} cache warming failed:`, error);
    return new Response(JSON.stringify({ 
      error: `${formatName} cache warming failed`, 
      message: error.message 
    }), {
      status: 500,
      headers: getCORSHeaders()
    });
  }
}

/**
 * Trigger comprehensive cache warming for all formats
 */
async function triggerCacheWarm(request, env, ctx) {
  try {
    const startTime = Date.now();
    const results = {
      started: new Date().toISOString(),
      totalBooks: CACHE_WARM_BOOKS_2024_2025.length,
      cached: 0,
      failed: 0,
      skipped: 0,
      errors: [],
      performance: {
        averageTime: 0,
        fastest: null,
        slowest: null
      }
    };
    
    const times = [];
    
    // Rate limiting for cache warming - CloudFlare worker limits
    const BATCH_SIZE = 3;
    const BATCH_DELAY = 1000; // 1 second between batches
    const MAX_BOOKS_PER_RUN = 50; // Limit to 50 books per single invocation to avoid timeouts
    
    // Process only a subset of books per invocation to avoid CloudFlare limits
    // Trigger all format-specific warming in sequence with delays
    const allResults = [];
    
    // Process books first (core content)
    try {
      const booksResult = await triggerFormatSpecificCacheWarm(
        CACHE_WARM_BOOKS_2024_2025.slice(0, 15), 'book', 'books', env, ctx
      );
      allResults.push({ format: 'books', result: JSON.parse(await booksResult.text()) });
    } catch (error) {
      allResults.push({ format: 'books', error: error.message });
    }
    
    // Delay between formats
    await new Promise(resolve => setTimeout(resolve, 5000));
    
    // Processs
    try {
      constsResult = await triggerFormatSpecificCacheWarm(
        CACHE_WARM_AUDIOBOOKS_2024_2025.slice(0, 15), 'audiobook', 'audiobooks', env, ctx
      );
      allResults.push({ format: 'audiobooks', result: JSON.parse(awaitsResult.text()) });
    } catch (error) {
      allResults.push({ format: 'audiobooks', error: error.message });
    }
    
    // Delay between formats
    await new Promise(resolve => setTimeout(resolve, 5000));
    
    // Processs
    try {
      constsResult = await triggerFormatSpecificCacheWarm(
        CACHE_WARM_EBOOKS_2024_2025.slice(0, 15), 'ebook', 'ebooks', env, ctx
      );
      allResults.push({ format: 'ebooks', result: JSON.parse(awaitsResult.text()) });
    } catch (error) {
      allResults.push({ format: 'ebooks', error: error.message });
    }
    
    const totalTime = Date.now() - startTime;
    const overallResults = {
      started: new Date().toISOString(),
      completed: new Date().toISOString(),
      totalTime: totalTime,
      formats: allResults,
      totalCached: allResults.reduce((sum, r) => sum + (r.result?.results?.cached || 0), 0),
      strategy: 'comprehensive-multi-format'
    };
    
    // Store comprehensive results 
    const statusKey = 'cache_warm_status_comprehensive';
    await env.BOOKS_CACHE?.put(statusKey, JSON.stringify(overallResults), { expirationTtl: 86400 });
    
    return new Response(JSON.stringify({
      status: 'completed',
      message: `Comprehensive cache warming completed! Processed ${overallResults.formats.length} formats with ${overallResults.totalCached} total books cached.`,
      results: overallResults
    }), {
      headers: {
        ...getCORSHeaders(),
        'X-Cache-Warm': 'COMPREHENSIVE-COMPLETED',
        'X-Cache-Total-Formats': overallResults.formats.length.toString(),
        'X-Cache-Total-Success': overallResults.totalCached.toString()
      }
    });
    
  } catch (error) {
    console.error('Comprehensive cache warming failed:', error);
    return new Response(JSON.stringify({ 
      error: 'Comprehensive cache warming failed', 
      message: error.message 
    }), {
      status: 500,
      headers: getCORSHeaders()
    });
  }
}

/**
 * Get cache warming status and metrics
 */
async function getCacheWarmStatus(env) {
  try {
    // Get last warming results
    const statusKey = 'cache_warm_status';
    const lastResults = await env.BOOKS_CACHE?.get(statusKey);
    
    // Get cache statistics
    const cacheStats = {
      system: env.BOOKS_R2 ? 'R2+KV-Hybrid' : 'KV-Only',
      kvAvailable: !!env.BOOKS_CACHE,
      r2Available: !!env.BOOKS_R2,
      totalBooksAvailable: CACHE_WARM_BOOKS_2024_2025.length,
      lastWarmingResults: lastResults ? JSON.parse(lastResults) : null
    };
    
    return new Response(JSON.stringify({
      status: 'active',
      timestamp: new Date().toISOString(),
      cacheSystem: cacheStats,
      warmingEndpoint: '/cache/warm',
      usage: {
        triggerWarming: 'POST /cache/warm',
        checkStatus: 'GET /cache/warm'
      }
    }), {
      headers: getCORSHeaders()
    });
    
  } catch (error) {
    console.error('Error getting cache warm status:', error);
    return new Response(JSON.stringify({ 
      error: 'Failed to get cache status', 
      message: error.message 
    }), {
      status: 500,
      headers: getCORSHeaders()
    });
  }
}

// ========================================
// ENHANCED API INTEGRATIONS WITH HIGHER LIMITS
// ========================================

/**
 * Search with higher-limit API keys in rotation
 * Uses google1, google2, ISBNdb1, ISBNdb2 for maximum throughput
 */
async function searchWithHigherLimits(query, maxResults, formatConfig, env) {
  const providers = [
    { name: 'google-books-hardoooe', func: () => searchGoogleBooks(query, maxResults, 'relevance', true, env, 'GOOGLE_BOOKS_HARDOOOE') },
    { name: 'google-books-ioskey', func: () => searchGoogleBooks(query, maxResults, 'relevance', true, env, 'GOOGLE_BOOKS_IOSKEY') },
    { name: 'isbndb-search', func: () => searchISBNdb(query, maxResults, env, 'ISBN_SEARCH_KEY') },
    { name: 'open-library', func: () => searchOpenLibrary(query, maxResults, env) }
  ];
  
  for (const provider of providers) {
    try {
      const result = await provider.func();
      if (result && result.items && result.items.length > 0) {
        result.provider = provider.name;
        return result;
      }
    } catch (error) {
      console.warn(`${provider.name} failed for "${query}":`, error.message);
      continue;
    }
  }
  
  return null;
}

/**
 * Enhance author data using Google Knowledge Graph API + Custom Search API
 */
async function enhanceAuthorData(authorName, env) {
  const results = {
    name: authorName,
    culturalData: {},
    sources: [],
    confidence: 0,
    enhanced: new Date().toISOString()
  };
  
  try {
    // 1. Google Knowledge Graph API
    const kgData = await queryGoogleKnowledgeGraph(authorName, env);
    if (kgData) {
      results.culturalData = { ...results.culturalData, ...kgData };
      results.sources.push('google-knowledge-graph');
      results.confidence += 0.4;
    }
    
    // 2. Google Custom Search API for biographical data
    const searchData = await queryGoogleCustomSearch(authorName, env);
    if (searchData) {
      results.culturalData = { ...results.culturalData, ...searchData };
      results.sources.push('google-custom-search');
      results.confidence += 0.3;
    }
    
    // 3. Existing book API data enhancement
    const bookData = await queryAuthorBooks(authorName, env);
    if (bookData) {
      results.culturalData = { ...results.culturalData, ...bookData };
      results.sources.push('book-apis');
      results.confidence += 0.2;
    }
    
    // 4. Wikipedia/Literary database parsing
    const wikiData = await parseWikipediaData(authorName, env);
    if (wikiData) {
      results.culturalData = { ...results.culturalData, ...wikiData };
      results.sources.push('wikipedia');
      results.confidence += 0.1;
    }
    
    return results;
    
  } catch (error) {
    console.error(`Author enhancement failed for ${authorName}:`, error);
    return {
      name: authorName,
      culturalData: {},
      error: error.message,
      enhanced: new Date().toISOString()
    };
  }
}

/**
 * Query Google Knowledge Graph API
 */
async function queryGoogleKnowledgeGraph(authorName, env) {
  try {
    const apiKey = (await env.GOOGLE_BOOKS_HARDOOOE.get()) || (await env.GOOGLE_BOOKS_IOSKEY.get());
    if (!apiKey) return null;
    
    const params = new URLSearchParams({
      query: authorName,
      key: apiKey,
      limit: 1,
      indent: true
    });
    
    const response = await fetch(`https://kgsearch.googleapis.com/v1/entities:search?${params}`);
    if (!response.ok) return null;
    
    const data = await response.json();
    const entity = data.itemListElement?.[0]?.result;
    
    if (entity) {
      return {
        nationality: entity.detailedDescription?.articleBody?.match(/\b(?:American|British|French|German|Japanese|Chinese|Indian|African|Canadian|Australian|Italian|Spanish|Russian|Brazilian|Mexican)\b/i)?.[0],
        birthPlace: entity.birthPlace?.name,
        description: entity.description,
        types: entity['@type'],
        knowledgeGraphId: entity['@id']
      };
    }
    
    return null;
  } catch (error) {
    console.warn('Google Knowledge Graph query failed:', error.message);
    return null;
  }
}

/**
 * Query Google Custom Search API for biographical data
 */
async function queryGoogleCustomSearch(authorName, env) {
  try {
    const apiKey = await env.GOOGLE_SEARCH_API_KEY.get();
    const searchEngineId = env.GOOGLE_SEARCH_ENGINE_ID || '017576662512468239146:omuauf_lfve'; // Generic search
    
    if (!apiKey) return null;
    
    const searchQuery = `"${authorName}" author biography nationality gender ethnicity`;
    const params = new URLSearchParams({
      key: apiKey,
      cx: searchEngineId,
      q: searchQuery,
      num: 3
    });
    
    const response = await fetch(`https://www.googleapis.com/customsearch/v1?${params}`);
    if (!response.ok) return null;
    
    const data = await response.json();
    const items = data.items || [];
    
    // Parse biographical information from search results
    let culturalInfo = {};
    for (const item of items) {
      const text = (item.snippet + ' ' + item.title).toLowerCase();
      
      // Gender detection
      if (!culturalInfo.gender) {
        if (text.match(/\b(she|her|woman|female|daughter)\b/)) culturalInfo.gender = 'Female';
        else if (text.match(/\b(he|him|man|male|son)\b/)) culturalInfo.gender = 'Male';
      }
      
      // Nationality detection  
      if (!culturalInfo.nationality) {
        const nationalityMatch = text.match(/\b(american|british|french|german|japanese|chinese|indian|canadian|australian|italian|spanish|russian|brazilian|mexican|african|nigerian|ghanaian|kenyan)\b/i);
        if (nationalityMatch) culturalInfo.nationality = nationalityMatch[0];
      }
      
      // Regional categorization
      if (culturalInfo.nationality && !culturalInfo.region) {
        const nat = culturalInfo.nationality.toLowerCase();
        if (['american', 'canadian', 'brazilian', 'mexican'].includes(nat)) culturalInfo.region = 'Americas';
        else if (['british', 'french', 'german', 'italian', 'spanish', 'russian'].includes(nat)) culturalInfo.region = 'Europe';
        else if (['japanese', 'chinese', 'indian'].includes(nat)) culturalInfo.region = 'Asia';
        else if (['nigerian', 'ghanaian', 'kenyan', 'african'].includes(nat)) culturalInfo.region = 'Africa';
      }
    }
    
    return Object.keys(culturalInfo).length > 0 ? culturalInfo : null;
    
  } catch (error) {
    console.warn('Google Custom Search failed:', error.message);
    return null;
  }
}

/**
 * Query author books for additional cultural context
 */
async function queryAuthorBooks(authorName, env) {
  try {
    // Use our existing book search to find author's works
    const searchResult = await searchGoogleBooks(`author:"${authorName}"`, 10, 'relevance', true, env);
    
    if (searchResult?.items?.length > 0) {
      return {
        bookCount: searchResult.items.length,
        publishers: [...new Set(searchResult.items.map(item => item.volumeInfo?.publisher).filter(Boolean))].slice(0, 3),
        languages: [...new Set(searchResult.items.map(item => item.volumeInfo?.language).filter(Boolean))],
        categories: [...new Set(searchResult.items.flatMap(item => item.volumeInfo?.categories || []))].slice(0, 5)
      };
    }
    
    return null;
  } catch (error) {
    console.warn('Author books query failed:', error.message);
    return null;
  }
}

/**
 * Parse Wikipedia data for cultural information
 */
async function parseWikipediaData(authorName, env) {
  try {
    // Search Wikipedia API
    const searchParams = new URLSearchParams({
      action: 'opensearch',
      search: authorName + ' author',
      limit: 1,
      format: 'json'
    });
    
    const searchResponse = await fetch(`https://en.wikipedia.org/w/api.php?${searchParams}`);
    if (!searchResponse.ok) return null;
    
    const searchData = await searchResponse.json();
    const title = searchData[1]?.[0];
    
    if (!title) return null;
    
    // Get article extract
    const extractParams = new URLSearchParams({
      action: 'query',
      format: 'json',
      titles: title,
      prop: 'extracts',
      exintro: true,
      explaintext: true,
      exsectionformat: 'plain'
    });
    
    const extractResponse = await fetch(`https://en.wikipedia.org/w/api.php?${extractParams}`);
    if (!extractResponse.ok) return null;
    
    const extractData = await extractResponse.json();
    const pages = extractData.query?.pages || {};
    const extract = Object.values(pages)[0]?.extract || '';
    
    if (extract) {
      // Basic cultural data extraction from Wikipedia text
      const culturalInfo = {};
      
      // Birth/death dates
      const dateMatch = extract.match(/(\d{4})\s*[–-]\s*(\d{4}|present)?/);
      if (dateMatch) {
        culturalInfo.birthYear = dateMatch[1];
        if (dateMatch[2] && dateMatch[2] !== 'present') culturalInfo.deathYear = dateMatch[2];
      }
      
      return Object.keys(culturalInfo).length > 0 ? culturalInfo : null;
    }
    
    return null;
  } catch (error) {
    console.warn('Wikipedia parsing failed:', error.message);
    return null;
  }
}

// Enhanced Google Books API with key rotation
async function searchGoogleBooks(query, maxResults, sortBy, includeTranslations, env, keyOverride = null) {
  // Use specific key if provided, otherwise use rotation
  const apiKeyBinding = keyOverride ? env[keyOverride] : (env.GOOGLE_BOOKS_HARDOOOE || env.GOOGLE_BOOKS_IOSKEY);
  
  // Get actual secret value from Secrets Store
  const apiKey = await apiKeyBinding.get();
  
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
  // Use your CloudFlare secrets: GOOGLE_BOOKS_HARDOOOE as primary, GOOGLE_BOOKS_IOSKEY as fallback
  const apiKey = (await env.GOOGLE_BOOKS_HARDOOOE.get()) || (await env.GOOGLE_BOOKS_IOSKEY.get());
  
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

// Enhanced ISBNdb API with key rotation
async function searchISBNdb(query, maxResults, env, keyOverride = null, subject = null, author = null) {
  const apiKeyBinding = keyOverride ? env[keyOverride] : env.ISBN_SEARCH_KEY;
  
  if (!apiKeyBinding) {
    throw new Error('ISBNdb API key not configured (ISBN_SEARCH_KEY)');
  }
  
  // Get actual secret value from Secrets Store
  const apiKey = await apiKeyBinding.get();
  
  if (!apiKey) {
    throw new Error('ISBNdb API key value not found in Secrets Store');
  }
  
  // ISBNdb supports different search endpoints
  const baseUrl = 'https://api2.isbndb.com';
  const isISBN = query.match(/^\d{10}(\d{3})?$/);
  
  let url;
  if (isISBN) {
    // Direct ISBN lookup - only use with_prices parameter
    const endpoint = `/book/${query}`;
    const params = new URLSearchParams({
      with_prices: '0' // Don't include pricing data
    });
    url = `${baseUrl}${endpoint}?${params}`;
  } else if (subject) {
    // Subject search - use /search/books endpoint with subject parameter
    const endpoint = '/search/books';
    const params = new URLSearchParams({
      pageSize: Math.min(maxResults, 50).toString(),
      subject: encodeURIComponent(subject)
    });
    url = `${baseUrl}${endpoint}?${params}`;
  } else if (author) {
    // Author search - use books endpoint with author column
    const endpoint = `/books/${encodeURIComponent(author)}`;
    const params = new URLSearchParams({
      pageSize: Math.min(maxResults, 50).toString(), // ISBNdb allows up to 50
      page: '1',
      column: 'author', // Search in author field
      language: 'en', // English books
      shouldMatchAll: '1' // Require all search terms to match
    });
    url = `${baseUrl}${endpoint}?${params}`;
  } else {
    // Title search - use full search parameters
    const endpoint = `/books/${encodeURIComponent(query)}`;
    const params = new URLSearchParams({
      pageSize: Math.min(maxResults, 50).toString(), // ISBNdb allows up to 50
      page: '1',
      column: 'title', // Search in title field
      language: 'en', // English books
      shouldMatchAll: '1' // Require all search terms to match
    });
    url = `${baseUrl}${endpoint}?${params}`;
  }
  
  const response = await fetch(url, {
    headers: {
      'Authorization': apiKey,
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
  const apiKey = await env.ISBN_SEARCH_KEY.get();
  
  if (!apiKey) {
    throw new Error('ISBNdb API key not configured (ISBN_SEARCH_KEY)');
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