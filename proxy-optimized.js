// Optimized CloudFlare Workers Proxy for Books API
// Implements security best practices, enhanced rate limiting, and performance optimizations

export default {
  async fetch(request, env, ctx) {
    // Handle preflight CORS requests
    if (request.method === "OPTIONS") {
      return handleCORS();
    }

    try {
      const url = new URL(request.url);
      const path = url.pathname;

      // Route handling with enhanced security
      switch (path) {
        case "/search":
          return await handleBookSearch(request, env, ctx);
        case "/isbn":
          return await handleISBNLookup(request, env, ctx);
        case "/health":
          return await handleHealthCheck(env);
        default:
          return createErrorResponse("Endpoint not found", 404);
      }
    } catch (error) {
      console.error("Worker error:", {
        message: error.message,
        stack: error.stack,
        url: request.url,
        method: request.method,
        timestamp: new Date().toISOString()
      });
      
      return createErrorResponse("Internal server error", 500, {
        requestId: crypto.randomUUID(),
        timestamp: new Date().toISOString()
      });
    }
  }
};

// Enhanced CORS headers with security considerations
function getCORSHeaders(contentType = "application/json") {
  return {
    "Content-Type": contentType,
    "Access-Control-Allow-Origin": "*", // Consider restricting this in production
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Requested-With, X-API-Key",
    "Access-Control-Max-Age": "86400",
    "X-Content-Type-Options": "nosniff",
    "X-Frame-Options": "DENY",
    "X-XSS-Protection": "1; mode=block"
  };
}

function handleCORS() {
  return new Response(null, {
    status: 204,
    headers: getCORSHeaders()
  });
}

function createErrorResponse(message, status = 500, additionalData = {}) {
  return new Response(JSON.stringify({
    error: message,
    status,
    ...additionalData
  }), {
    status,
    headers: getCORSHeaders()
  });
}

// Enhanced input validation with comprehensive security checks
function validateSearchParams(url) {
  const query = url.searchParams.get("q");
  const maxResults = url.searchParams.get("maxResults");
  const sortBy = url.searchParams.get("orderBy");
  const langRestrict = url.searchParams.get("langRestrict");

  const errors = [];
  const sanitized = {};

  // Query validation with enhanced security
  if (!query || typeof query !== "string") {
    errors.push('Query parameter "q" is required and must be a string');
  } else if (query.trim().length === 0) {
    errors.push('Query parameter "q" cannot be empty');
  } else if (query.length > 500) {
    errors.push('Query parameter "q" must be less than 500 characters');
  } else {
    // Enhanced sanitization - remove potentially dangerous characters
    const sanitizedQuery = query
      .replace(/[<>]/g, "") // Remove HTML tags
      .replace(/['"]/g, "") // Remove quotes
      .replace(/[\x00-\x1F\x7F]/g, "") // Remove control characters
      .replace(/javascript:/gi, "") // Remove javascript protocol
      .replace(/data:/gi, "") // Remove data protocol
      .replace(/vbscript:/gi, "") // Remove vbscript protocol
      .trim();

    if (sanitizedQuery.length === 0) {
      errors.push("Query contains only invalid characters");
    } else {
      sanitized.query = sanitizedQuery;
    }
  }

  // MaxResults validation
  if (maxResults !== null) {
    const maxResultsInt = parseInt(maxResults);
    if (isNaN(maxResultsInt) || maxResultsInt < 1 || maxResultsInt > 40) {
      errors.push("maxResults must be a number between 1 and 40");
    } else {
      sanitized.maxResults = maxResultsInt;
    }
  } else {
    sanitized.maxResults = 20;
  }

  // Sort validation
  if (sortBy !== null) {
    const validSortOptions = ["relevance", "newest"];
    if (!validSortOptions.includes(sortBy)) {
      errors.push('orderBy must be either "relevance" or "newest"');
    } else {
      sanitized.sortBy = sortBy;
    }
  } else {
    sanitized.sortBy = "relevance";
  }

  // Language validation
  if (langRestrict !== null) {
    if (!/^[a-z]{2,3}$/i.test(langRestrict)) {
      errors.push("langRestrict must be a valid 2-3 character language code");
    } else {
      sanitized.langRestrict = langRestrict.toLowerCase();
    }
  }

  sanitized.includeTranslations = sanitized.langRestrict !== "en";
  
  return { errors, sanitized };
}

// Enhanced ISBN validation with checksum verification
function validateISBN(isbn) {
  if (!isbn || typeof isbn !== "string") {
    return { error: "ISBN parameter is required and must be a string" };
  }

  // Clean ISBN - remove leading equals, hyphens, spaces, and invalid characters
  const cleanedISBN = isbn
    .replace(/^=+/, "") // Remove leading equals from CSV exports
    .replace(/[-\s]/g, "") // Remove hyphens and spaces
    .replace(/[^0-9X]/gi, "") // Remove non-numeric/X characters
    .toUpperCase();

  if (cleanedISBN.length !== 10 && cleanedISBN.length !== 13) {
    return { error: "ISBN must be 10 or 13 characters long" };
  }

  // Format validation
  if (cleanedISBN.length === 10) {
    if (!/^\d{9}[\dX]$/.test(cleanedISBN)) {
      return { error: "Invalid ISBN-10 format" };
    }
    
    // ISBN-10 checksum validation
    let sum = 0;
    for (let i = 0; i < 9; i++) {
      sum += parseInt(cleanedISBN[i]) * (10 - i);
    }
    const checkDigit = cleanedISBN[9];
    const calculatedCheck = (11 - (sum % 11)) % 11;
    const expectedCheck = calculatedCheck === 10 ? 'X' : calculatedCheck.toString();
    
    if (checkDigit !== expectedCheck) {
      return { error: "Invalid ISBN-10 checksum" };
    }
  } else {
    if (!/^\d{13}$/.test(cleanedISBN)) {
      return { error: "Invalid ISBN-13 format" };
    }
    
    // ISBN-13 checksum validation
    let sum = 0;
    for (let i = 0; i < 12; i++) {
      sum += parseInt(cleanedISBN[i]) * (i % 2 === 0 ? 1 : 3);
    }
    const checkDigit = parseInt(cleanedISBN[12]);
    const calculatedCheck = (10 - (sum % 10)) % 10;
    
    if (checkDigit !== calculatedCheck) {
      return { error: "Invalid ISBN-13 checksum" };
    }
  }

  return { sanitized: cleanedISBN };
}

// Advanced rate limiting with multiple strategies
async function checkAdvancedRateLimit(request, env) {
  const clientIP = request.headers.get("CF-Connecting-IP") || "unknown";
  const userAgent = request.headers.get("User-Agent") || "unknown";
  const apiKey = request.headers.get("X-API-Key");
  const cfRay = request.headers.get("CF-Ray") || "unknown";

  // Create composite rate limit key for better granularity
  const userFingerprint = await generateUserFingerprint(clientIP, userAgent, cfRay);
  const rateLimitKey = `ratelimit:${userFingerprint}`;

  // Determine rate limits based on request characteristics
  let maxRequests = 100; // Default per hour
  const windowSize = 3600; // 1 hour window

  // Adjust limits based on user agent quality
  if (userAgent.length < 10 || userAgent === "unknown" || 
      userAgent.includes("bot") || userAgent.includes("curl")) {
    maxRequests = 20; // Stricter for suspicious agents
  }

  // Premium rate limits for authenticated requests
  if (apiKey && await validateAPIKey(apiKey, env)) {
    maxRequests = 1000; // Much higher for authenticated users
  }

  // Check current usage
  const current = await env.BOOKS_CACHE?.get(rateLimitKey);
  const count = current ? parseInt(current) : 0;

  if (count >= maxRequests) {
    return {
      allowed: false,
      retryAfter: windowSize,
      reason: "Rate limit exceeded",
      current: count,
      limit: maxRequests
    };
  }

  // Update counter
  const newCount = count + 1;
  await env.BOOKS_CACHE?.put(rateLimitKey, newCount.toString(), { 
    expirationTtl: windowSize 
  });

  return {
    allowed: true,
    count: newCount,
    remaining: maxRequests - newCount,
    resetTime: Date.now() + (windowSize * 1000)
  };
}

// Generate user fingerprint for better rate limiting
async function generateUserFingerprint(ip, userAgent, cfRay) {
  const data = `${ip}:${userAgent.slice(0, 50)}:${cfRay}`;
  const encoder = new TextEncoder();
  const dataBuffer = encoder.encode(data);
  const hashBuffer = await crypto.subtle.digest('SHA-256', dataBuffer);
  const hashArray = new Uint8Array(hashBuffer);
  const hashHex = Array.from(hashArray)
    .map(b => b.toString(16).padStart(2, '0'))
    .join('');
  return hashHex.slice(0, 16); // Use first 16 chars
}

// API key validation (placeholder - implement your own logic)
async function validateAPIKey(apiKey, env) {
  // Implement your API key validation logic here
  // For example, check against a KV store of valid keys
  const validKey = await env.BOOKS_CACHE?.get(`apikey:${apiKey}`);
  return validKey === "valid";
}

// Optimized cache key generation
const CACHE_KEYS = {
  search: (query, maxResults, sortBy, translations) => {
    const queryHash = btoa(query).replace(/[/+=]/g, "_").slice(0, 32);
    return `search/${queryHash}/${maxResults}/${sortBy}/${translations}.json`;
  },
  isbn: (isbn) => `isbn/${isbn}.json`
};

// Enhanced caching with intelligent tiering
async function getCachedData(cacheKey, env) {
  try {
    // First check KV (hot cache)
    const kvData = await env.BOOKS_CACHE?.get(cacheKey);
    if (kvData) {
      const parsed = JSON.parse(kvData);
      // Check if data includes freshness metadata
      if (parsed._cached && parsed._cached.timestamp) {
        const age = Date.now() - parsed._cached.timestamp;
        if (age > 86400000) { // 24 hours
          // Data is old, try R2 for fresher copy
          const r2Result = await tryR2Cache(cacheKey, env);
          if (r2Result) return r2Result;
        }
      }
      return {
        data: parsed,
        source: "KV-HOT",
        age: parsed._cached ? Date.now() - parsed._cached.timestamp : 0
      };
    }

    // Try R2 (cold cache)
    return await tryR2Cache(cacheKey, env);
  } catch (error) {
    console.warn(`Cache read error for key ${cacheKey}:`, error.message);
    return null;
  }
}

async function tryR2Cache(cacheKey, env) {
  if (!env.BOOKS_R2) return null;

  try {
    const r2Object = await env.BOOKS_R2.get(cacheKey);
    if (!r2Object) return null;

    const jsonData = await r2Object.text();
    const data = JSON.parse(jsonData);
    const metadata = r2Object.customMetadata;

    // Check TTL
    if (metadata?.ttl && Date.now() > parseInt(metadata.ttl)) {
      // Data expired, delete it
      env.waitUntil(env.BOOKS_R2.delete(cacheKey));
      return null;
    }

    // Promote to KV for faster access
    const promoteData = JSON.stringify(data);
    env.waitUntil(
      env.BOOKS_CACHE?.put(cacheKey, promoteData, { expirationTtl: 86400 })
    );

    return {
      data,
      source: "R2-COLD",
      age: metadata?.created ? Date.now() - parseInt(metadata.created) : 0
    };
  } catch (error) {
    console.warn(`R2 cache error for key ${cacheKey}:`, error.message);
    return null;
  }
}

// Enhanced cache storage with metadata
async function setCachedData(cacheKey, data, ttlSeconds, env, ctx) {
  // Add cache metadata
  const enrichedData = {
    ...data,
    _cached: {
      timestamp: Date.now(),
      ttl: ttlSeconds * 1000,
      version: "1.0"
    }
  };

  const jsonData = JSON.stringify(enrichedData);
  const promises = [];

  try {
    // Store in R2 for long-term caching
    if (env.BOOKS_R2) {
      promises.push(
        env.BOOKS_R2.put(cacheKey, jsonData, {
          httpMetadata: {
            contentType: "application/json",
            cacheControl: `max-age=${ttlSeconds}`,
            cacheExpiry: new Date(Date.now() + ttlSeconds * 1000).toISOString()
          },
          customMetadata: {
            ttl: (Date.now() + ttlSeconds * 1000).toString(),
            created: Date.now().toString(),
            type: cacheKey.startsWith("search") ? "search" : "isbn",
            version: "1.0"
          }
        })
      );
    }

    // Store in KV for hot cache
    const kvTtl = Math.min(ttlSeconds, 86400); // KV max TTL
    promises.push(
      env.BOOKS_CACHE?.put(cacheKey, jsonData, { expirationTtl: kvTtl })
    );

    // Execute cache writes
    if (ctx?.waitUntil) {
      ctx.waitUntil(Promise.all(promises.filter(Boolean)));
    } else {
      await Promise.all(promises.filter(Boolean));
    }
  } catch (error) {
    console.warn(`Cache write error for key ${cacheKey}:`, error.message);
  }
}

// Request size validation
function validateRequestSize(request) {
  const contentLength = request.headers.get("content-length");
  if (contentLength && parseInt(contentLength) > 1024 * 1024) { // 1MB limit
    return { error: "Request too large", maxSize: "1MB" };
  }
  return { valid: true };
}

// Enhanced health check
async function handleHealthCheck(env) {
  const checks = {
    timestamp: new Date().toISOString(),
    status: "healthy",
    version: "2.0",
    providers: {
      "google-books": await testProvider("google-books", env),
      "isbndb": await testProvider("isbndb", env),
      "open-library": await testProvider("open-library", env)
    },
    cache: {
      system: env.BOOKS_R2 ? "R2+KV-Hybrid" : "KV-Only",
      kv: {
        available: !!env.BOOKS_CACHE,
        namespace: env.BOOKS_CACHE ? "BOOKS_CACHE" : "missing"
      },
      r2: {
        available: !!env.BOOKS_R2,
        bucket: env.BOOKS_R2 ? "books-cache" : "missing"
      }
    },
    security: {
      rateLimit: "enabled",
      inputValidation: "enabled",
      checksumValidation: "enabled"
    }
  };

  return new Response(JSON.stringify(checks, null, 2), {
    headers: getCORSHeaders("application/json")
  });
}

async function testProvider(provider, env) {
  try {
    switch (provider) {
      case "google-books":
        return env.google1 || env.google2 ? "configured" : "missing-key";
      case "isbndb":
        return env.ISBNdb1 ? "configured" : "missing-key";
      case "open-library":
        return "available"; // No API key needed
      default:
        return "unknown";
    }
  } catch (error) {
    return "error";
  }
}

// Main search handler with enhanced security
async function handleBookSearch(request, env, ctx) {
  // Validate request size
  const sizeCheck = validateRequestSize(request);
  if (sizeCheck.error) {
    return createErrorResponse(sizeCheck.error, 413, { maxSize: sizeCheck.maxSize });
  }

  const url = new URL(request.url);
  const validation = validateSearchParams(url);
  
  if (validation.errors.length > 0) {
    return createErrorResponse("Invalid parameters", 400, { 
      details: validation.errors 
    });
  }

  const { query, maxResults, sortBy, includeTranslations } = validation.sanitized;

  // Enhanced rate limiting
  const rateLimitResult = await checkAdvancedRateLimit(request, env);
  if (!rateLimitResult.allowed) {
    return new Response(JSON.stringify({
      error: "Rate limit exceeded",
      retryAfter: rateLimitResult.retryAfter,
      current: rateLimitResult.current,
      limit: rateLimitResult.limit
    }), {
      status: 429,
      headers: {
        ...getCORSHeaders(),
        "Retry-After": rateLimitResult.retryAfter.toString(),
        "X-RateLimit-Limit": rateLimitResult.limit?.toString() || "100",
        "X-RateLimit-Remaining": rateLimitResult.remaining?.toString() || "0",
        "X-RateLimit-Reset": rateLimitResult.resetTime?.toString() || ""
      }
    });
  }

  // Check cache
  const cacheKey = CACHE_KEYS.search(query, maxResults, sortBy, includeTranslations);
  const cached = await getCachedData(cacheKey, env);
  
  if (cached) {
    return new Response(JSON.stringify(cached.data), {
      headers: {
        ...getCORSHeaders(),
        "X-Cache": `HIT-${cached.source}`,
        "X-Cache-Age": Math.floor(cached.age / 1000).toString(),
        "X-Rate-Limit-Remaining": rateLimitResult.remaining?.toString() || "0"
      }
    });
  }

  // Try providers with enhanced error handling
  let result = null;
  let provider = null;
  const providerErrors = [];

  // Try Google Books first
  try {
    result = await searchGoogleBooks(query, maxResults, sortBy, includeTranslations, env);
    provider = "google-books";
  } catch (error) {
    providerErrors.push({ provider: "google-books", error: error.message });
    console.error("Google Books failed:", error.message);
  }

  // Fallback to ISBNdb
  if (!result || result.items?.length === 0) {
    try {
      result = await searchISBNdb(query, maxResults, env);
      provider = "isbndb";
    } catch (error) {
      providerErrors.push({ provider: "isbndb", error: error.message });
      console.error("ISBNdb failed:", error.message);
    }
  }

  // Fallback to Open Library
  if (!result || result.items?.length === 0) {
    try {
      result = await searchOpenLibrary(query, maxResults, env);
      provider = "open-library";
    } catch (error) {
      providerErrors.push({ provider: "open-library", error: error.message });
      console.error("Open Library failed:", error.message);
    }
  }

  if (!result) {
    return createErrorResponse("All book providers failed", 503, {
      providers: providerErrors,
      items: []
    });
  }

  // Enrich response
  result.provider = provider;
  result.cached = false;
  result.requestId = crypto.randomUUID();

  // Cache successful results
  if (result.items?.length > 0) {
    setCachedData(cacheKey, result, 2592000, env, ctx); // 30 days
  }

  return new Response(JSON.stringify(result), {
    headers: {
      ...getCORSHeaders(),
      "X-Cache": "MISS",
      "X-Provider": provider,
      "X-Cache-System": env.BOOKS_R2 ? "R2+KV-Hybrid" : "KV-Only",
      "X-Request-ID": result.requestId,
      "X-Rate-Limit-Remaining": rateLimitResult.remaining?.toString() || "0"
    }
  });
}

// Enhanced ISBN lookup handler
async function handleISBNLookup(request, env, ctx) {
  const sizeCheck = validateRequestSize(request);
  if (sizeCheck.error) {
    return createErrorResponse(sizeCheck.error, 413, { maxSize: sizeCheck.maxSize });
  }

  const url = new URL(request.url);
  const rawISBN = url.searchParams.get("isbn");
  const validation = validateISBN(rawISBN);

  if (validation.error) {
    return createErrorResponse(validation.error, 400);
  }

  const isbn = validation.sanitized;
  const cacheKey = CACHE_KEYS.isbn(isbn);
  const cached = await getCachedData(cacheKey, env);

  if (cached) {
    return new Response(JSON.stringify(cached.data), {
      headers: {
        ...getCORSHeaders(),
        "X-Cache": `HIT-${cached.source}`,
        "X-Cache-Age": Math.floor(cached.age / 1000).toString()
      }
    });
  }

  // Try providers for ISBN lookup
  let result = null;
  let provider = null;

  try {
    result = await lookupISBNGoogle(isbn, env);
    provider = "google-books";
  } catch (error) {
    console.error("Google Books ISBN lookup failed:", error.message);
  }

  if (!result) {
    try {
      result = await lookupISBNISBNdb(isbn, env);
      provider = "isbndb";
    } catch (error) {
      console.error("ISBNdb ISBN lookup failed:", error.message);
    }
  }

  if (!result) {
    try {
      result = await lookupISBNOpenLibrary(isbn, env);
      provider = "open-library";
    } catch (error) {
      console.error("Open Library ISBN lookup failed:", error.message);
    }
  }

  if (!result) {
    return createErrorResponse("ISBN not found in any provider", 404, { isbn });
  }

  result.provider = provider;
  result.requestId = crypto.randomUUID();

  // Cache successful ISBN lookups for longer (1 year)
  setCachedData(cacheKey, result, 31536000, env, ctx);

  return new Response(JSON.stringify(result), {
    headers: {
      ...getCORSHeaders(),
      "X-Cache": "MISS",
      "X-Provider": provider,
      "X-Request-ID": result.requestId
    }
  });
}

// Provider implementations (keeping existing logic but with enhanced error handling)

async function searchGoogleBooks(query, maxResults, sortBy, includeTranslations, env) {
  const apiKey = env.google1 || env.google2;
  if (!apiKey) {
    throw new Error("Google Books API key not configured");
  }

  const params = new URLSearchParams({
    q: query,
    maxResults: maxResults.toString(),
    printType: "books",
    projection: "full",
    orderBy: sortBy,
    key: apiKey
  });

  if (!includeTranslations) {
    params.append("langRestrict", "en");
  }

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 10000); // 10 second timeout

  try {
    const response = await fetch(`https://www.googleapis.com/books/v1/volumes?${params}`, {
      signal: controller.signal,
      headers: {
        'User-Agent': 'CloudflareWorker/2.0 BookSearchProxy'
      }
    });

    clearTimeout(timeoutId);

    if (!response.ok) {
      throw new Error(`Google Books API error: ${response.status} ${response.statusText}`);
    }

    return await response.json();
  } catch (error) {
    clearTimeout(timeoutId);
    if (error.name === 'AbortError') {
      throw new Error('Google Books API request timeout');
    }
    throw error;
  }
}

async function lookupISBNGoogle(isbn, env) {
  const apiKey = env.google1 || env.google2;
  if (!apiKey) {
    throw new Error("Google Books API key not configured");
  }

  const params = new URLSearchParams({
    q: `isbn:${isbn}`,
    maxResults: "1",
    printType: "books",
    projection: "full",
    key: apiKey
  });

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 10000);

  try {
    const response = await fetch(`https://www.googleapis.com/books/v1/volumes?${params}`, {
      signal: controller.signal,
      headers: {
        'User-Agent': 'CloudflareWorker/2.0 BookSearchProxy'
      }
    });

    clearTimeout(timeoutId);

    if (!response.ok) {
      throw new Error(`Google Books ISBN API error: ${response.status}`);
    }

    const data = await response.json();
    return data.items?.[0] || null;
  } catch (error) {
    clearTimeout(timeoutId);
    if (error.name === 'AbortError') {
      throw new Error('Google Books ISBN API request timeout');
    }
    throw error;
  }
}

// Similar timeout enhancements for other provider functions...
// [Keeping the existing ISBNdb and OpenLibrary functions but with timeout logic]

async function searchISBNdb(query, maxResults, env) {
  const apiKey = env.ISBNdb1;
  if (!apiKey) {
    throw new Error("ISBNdb API key not configured (ISBNdb1)");
  }

  const baseUrl = "https://api2.isbndb.com";
  const endpoint = query.match(/^\d{10}(\d{3})?$/) ? `/book/${query}` : `/books/${encodeURIComponent(query)}`;
  const params = new URLSearchParams({
    pageSize: Math.min(maxResults, 20).toString(),
    page: "1"
  });

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 15000); // 15 second timeout for ISBNdb

  try {
    const response = await fetch(`${baseUrl}${endpoint}?${params}`, {
      signal: controller.signal,
      headers: {
        "X-API-KEY": apiKey,
        "Content-Type": "application/json",
        'User-Agent': 'CloudflareWorker/2.0 BookSearchProxy'
      }
    });

    clearTimeout(timeoutId);

    if (!response.ok) {
      throw new Error(`ISBNdb API error: ${response.status}`);
    }

    const data = await response.json();
    const books = data.books || [data.book].filter(Boolean);

    return {
      kind: "books#volumes",
      totalItems: data.total || books.length,
      items: books.map(book => ({
        kind: "books#volume",
        id: book.isbn13 || book.isbn || "",
        volumeInfo: {
          title: book.title || "",
          authors: book.authors ? book.authors.filter(Boolean) : [],
          publishedDate: book.date_published || "",
          publisher: book.publisher || "",
          description: book.overview || book.synopsis || "",
          industryIdentifiers: [
            book.isbn13 && { type: "ISBN_13", identifier: book.isbn13 },
            book.isbn && { type: "ISBN_10", identifier: book.isbn }
          ].filter(Boolean),
          pageCount: book.pages ? parseInt(book.pages) : null,
          categories: book.subjects || [],
          imageLinks: book.image ? {
            thumbnail: book.image,
            smallThumbnail: book.image
          } : null,
          language: book.language || "en",
          previewLink: `https://isbndb.com/book/${book.isbn13 || book.isbn}`,
          infoLink: `https://isbndb.com/book/${book.isbn13 || book.isbn}`
        }
      }))
    };
  } catch (error) {
    clearTimeout(timeoutId);
    if (error.name === 'AbortError') {
      throw new Error('ISBNdb API request timeout');
    }
    throw error;
  }
}

async function lookupISBNISBNdb(isbn, env) {
  const apiKey = env.ISBNdb1;
  if (!apiKey) {
    throw new Error("ISBNdb API key not configured (ISBNdb1)");
  }

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 15000);

  try {
    const response = await fetch(`https://api2.isbndb.com/book/${isbn}`, {
      signal: controller.signal,
      headers: {
        "X-API-KEY": apiKey,
        "Content-Type": "application/json",
        'User-Agent': 'CloudflareWorker/2.0 BookSearchProxy'
      }
    });

    clearTimeout(timeoutId);

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
      kind: "books#volume",
      id: book.isbn13 || book.isbn || "",
      volumeInfo: {
        title: book.title || "",
        authors: book.authors ? book.authors.filter(Boolean) : [],
        publishedDate: book.date_published || "",
        publisher: book.publisher || "",
        description: book.overview || book.synopsis || "",
        industryIdentifiers: [
          book.isbn13 && { type: "ISBN_13", identifier: book.isbn13 },
          book.isbn && { type: "ISBN_10", identifier: book.isbn }
        ].filter(Boolean),
        pageCount: book.pages ? parseInt(book.pages) : null,
        categories: book.subjects || [],
        imageLinks: book.image ? {
          thumbnail: book.image,
          smallThumbnail: book.image
        } : null,
        language: book.language || "en",
        previewLink: `https://isbndb.com/book/${book.isbn13 || book.isbn}`,
        infoLink: `https://isbndb.com/book/${book.isbn13 || book.isbn}`
      }
    };
  } catch (error) {
    clearTimeout(timeoutId);
    if (error.name === 'AbortError') {
      throw new Error('ISBNdb API request timeout');
    }
    throw error;
  }
}

async function searchOpenLibrary(query, maxResults, env) {
  const params = new URLSearchParams({
    q: query,
    limit: maxResults.toString(),
    fields: "key,title,author_name,first_publish_year,isbn,publisher,language,subject,cover_i,edition_count",
    format: "json"
  });

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 20000); // 20 second timeout for Open Library

  try {
    const response = await fetch(`https://openlibrary.org/search.json?${params}`, {
      signal: controller.signal,
      headers: {
        'User-Agent': 'CloudflareWorker/2.0 BookSearchProxy'
      }
    });

    clearTimeout(timeoutId);

    if (!response.ok) {
      throw new Error(`Open Library API error: ${response.status}`);
    }

    const data = await response.json();

    return {
      kind: "books#volumes",
      totalItems: data.numFound,
      items: data.docs.map(doc => ({
        kind: "books#volume",
        id: doc.key?.replace("/works/", "") || "",
        volumeInfo: {
          title: doc.title || "",
          authors: doc.author_name || [],
          publishedDate: doc.first_publish_year?.toString() || "",
          publisher: Array.isArray(doc.publisher) ? doc.publisher[0] : doc.publisher || "",
          description: "",
          industryIdentifiers: doc.isbn ? doc.isbn.slice(0, 2).map(isbn => ({
            type: isbn.length === 13 ? "ISBN_13" : "ISBN_10",
            identifier: isbn
          })) : [],
          pageCount: null,
          categories: doc.subject ? doc.subject.slice(0, 3) : [],
          imageLinks: doc.cover_i ? {
            thumbnail: `https://covers.openlibrary.org/b/id/${doc.cover_i}-M.jpg`,
            smallThumbnail: `https://covers.openlibrary.org/b/id/${doc.cover_i}-S.jpg`
          } : null,
          language: Array.isArray(doc.language) ? doc.language[0] : doc.language || "en",
          previewLink: `https://openlibrary.org${doc.key}`,
          infoLink: `https://openlibrary.org${doc.key}`
        }
      }))
    };
  } catch (error) {
    clearTimeout(timeoutId);
    if (error.name === 'AbortError') {
      throw new Error('Open Library API request timeout');
    }
    throw error;
  }
}

async function lookupISBNOpenLibrary(isbn, env) {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 20000);

  try {
    const response = await fetch(`https://openlibrary.org/api/books?bibkeys=ISBN:${isbn}&format=json&jscmd=data`, {
      signal: controller.signal,
      headers: {
        'User-Agent': 'CloudflareWorker/2.0 BookSearchProxy'
      }
    });

    clearTimeout(timeoutId);

    if (!response.ok) {
      throw new Error(`Open Library ISBN API error: ${response.status}`);
    }

    const data = await response.json();
    const bookData = data[`ISBN:${isbn}`];

    if (!bookData) {
      return null;
    }

    return {
      kind: "books#volume",
      id: bookData.key?.replace("/books/", "") || isbn,
      volumeInfo: {
        title: bookData.title || "",
        authors: bookData.authors?.map(author => author.name) || [],
        publishedDate: bookData.publish_date || "",
        publisher: bookData.publishers?.[0]?.name || "",
        description: bookData.notes || "",
        industryIdentifiers: [{
          type: isbn.length === 13 ? "ISBN_13" : "ISBN_10",
          identifier: isbn
        }],
        pageCount: bookData.number_of_pages || null,
        categories: bookData.subjects?.map(subject => subject.name).slice(0, 3) || [],
        imageLinks: bookData.cover ? {
          thumbnail: bookData.cover.medium,
          smallThumbnail: bookData.cover.small
        } : null,
        language: "en",
        previewLink: bookData.url,
        infoLink: bookData.url
      }
    };
  } catch (error) {
    clearTimeout(timeoutId);
    if (error.name === 'AbortError') {
      throw new Error('Open Library ISBN API request timeout');
    }
    throw error;
  }
}