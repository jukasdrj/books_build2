// Production-Ready CloudFlare Worker with Enhanced Logging
// ISBNdb Primary → Google Books → Open Library
// All bulletproof features + detailed cache analytics

export default {
  async fetch(request, env, ctx) {
    if (request.method === "OPTIONS") {
      return handleCORS();
    }
    
    try {
      validateEnvironment(env);
      const url = new URL(request.url);
      const path = url.pathname;
      
      // Enhanced request logging
      console.log(`📥 REQUEST: ${request.method} ${url.pathname}${url.search}`, {
        userAgent: request.headers.get('User-Agent')?.slice(0, 50),
        cfRay: request.headers.get('CF-Ray'),
        clientIP: request.headers.get('CF-Connecting-IP'),
        timestamp: new Date().toISOString()
      });
      
      if (path === "/search") {
        return await handleBookSearch(request, env, ctx);
      } else if (path === "/isbn") {
        return await handleISBNLookup(request, env, ctx);
      } else if (path === "/health") {
        console.log(`💓 HEALTH CHECK: healthy`);
        return new Response(JSON.stringify({
          status: "healthy",
          timestamp: (new Date()).toISOString(),
          providers: ["isbndb", "google-books", "open-library"],
          priority: "ISBNdb → Google Books → Open Library",
          environment: {
            ISBNdb1: env.ISBNdb1 ? "configured" : "missing",
            google1: env.google1 ? "configured" : "missing", 
            google2: env.google2 ? "configured" : "missing"
          },
          cache: {
            system: env.BOOKS_R2 ? "R2+KV-Hybrid" : "KV-Only",
            kv: env.BOOKS_CACHE ? "available" : "missing",
            r2: env.BOOKS_R2 ? "available" : "missing"
          }
        }), {
          headers: getCORSHeaders("application/json")
        });
      } else {
        console.log(`❌ UNKNOWN ENDPOINT: ${path}`);
        return new Response(JSON.stringify({ error: "Endpoint not found" }), {
          status: 404,
          headers: getCORSHeaders("application/json")
        });
      }
    } catch (error) {
      console.error("🚨 WORKER ERROR:", {
        message: error.message,
        stack: error.stack,
        url: request.url,
        method: request.method,
        timestamp: new Date().toISOString()
      });
      return new Response(JSON.stringify({
        error: "Internal server error",
        message: error.message
      }), {
        status: 500,
        headers: getCORSHeaders("application/json")
      });
    }
  }
};

// Environment validation
function validateEnvironment(env) {
  if (!env || typeof env !== 'object') {
    throw new Error('Environment not available');
  }
  return true;
}

// Enhanced CORS headers with security
function getCORSHeaders(contentType = "application/json") {
  return {
    "Content-Type": contentType,
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Requested-With",
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

function validateSearchParams(url) {
  const query = url.searchParams.get("q");
  const maxResults = url.searchParams.get("maxResults");
  const sortBy = url.searchParams.get("orderBy");
  const langRestrict = url.searchParams.get("langRestrict");
  const provider = url.searchParams.get("provider");
  
  const errors = [];
  const sanitized = {};
  
  // Query validation
  if (!query || typeof query !== "string") {
    errors.push('Query parameter "q" is required and must be a string');
  } else if (query.trim().length === 0) {
    errors.push('Query parameter "q" cannot be empty');
  } else if (query.length > 500) {
    errors.push('Query parameter "q" must be less than 500 characters');
  } else {
    const sanitizedQuery = query.replace(/[<>]/g, "").replace(/['"]/g, "").replace(/[\x00-\x1F\x7F]/g, "").trim();
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
  
  // SortBy validation
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
  
  // Provider validation
  if (provider !== null) {
    const validProviders = ["isbndb", "google", "openlibrary", "auto"];
    if (!validProviders.includes(provider)) {
      errors.push('provider must be one of: isbndb, google, openlibrary, auto');
    } else {
      sanitized.provider = provider;
    }
  } else {
    sanitized.provider = "auto"; // Default to auto (ISBNdb first)
  }
  
  sanitized.includeTranslations = sanitized.langRestrict !== "en";
  
  return { errors, sanitized };
}

function validateISBN(isbn) {
  if (!isbn || typeof isbn !== "string") {
    return { error: "ISBN parameter is required and must be a string" };
  }
  
  const cleanedISBN = isbn.replace(/^=+/, "").replace(/[-\s]/g, "").replace(/[^0-9X]/gi, "").toUpperCase();
  
  if (cleanedISBN.length !== 10 && cleanedISBN.length !== 13) {
    return { error: "ISBN must be 10 or 13 characters long" };
  }
  
  if (cleanedISBN.length === 10) {
    if (!/^\d{9}[\dX]$/.test(cleanedISBN)) {
      return { error: "Invalid ISBN-10 format" };
    }
  } else {
    if (!/^\d{13}$/.test(cleanedISBN)) {
      return { error: "Invalid ISBN-13 format" };
    }
  }
  
  return { sanitized: cleanedISBN };
}

async function checkRateLimitEnhanced(request, env) {
  const clientIP = request.headers.get("CF-Connecting-IP") || "unknown";
  const userAgent = request.headers.get("User-Agent") || "unknown";
  const rateLimitKey = `ratelimit:${clientIP}:${btoa(userAgent).slice(0, 8)}`;
  
  let maxRequests = 100;
  const windowSize = 3600;
  
  if (userAgent.length < 10 || userAgent === "unknown") {
    maxRequests = 20;
  }
  
  try {
    const current = await env.BOOKS_CACHE?.get(rateLimitKey);
    const count = current ? parseInt(current) : 0;
    
    if (count >= maxRequests) {
      console.log(`🚫 RATE LIMIT EXCEEDED: ${clientIP} (${count}/${maxRequests})`);
      return {
        allowed: false,
        retryAfter: windowSize,
        reason: "Rate limit exceeded"
      };
    }
    
    const newCount = count + 1;
    await env.BOOKS_CACHE?.put(rateLimitKey, newCount.toString(), { expirationTtl: windowSize });
    
    console.log(`✅ RATE LIMIT OK: ${clientIP} (${newCount}/${maxRequests})`);
    return {
      allowed: true,
      count: newCount,
      remaining: maxRequests - newCount
    };
  } catch (error) {
    console.warn('Rate limiting unavailable, allowing request:', error.message);
    return { allowed: true, count: 0, remaining: 100 };
  }
}

// Crypto-based cache key generation to prevent collisions
async function generateCacheKey(type, ...params) {
  const input = JSON.stringify({ type, params, timestamp: Math.floor(Date.now() / 86400000) }); // Daily rotation
  const encoder = new TextEncoder();
  const data = encoder.encode(input);
  const hashBuffer = await crypto.subtle.digest('SHA-256', data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  const hashHex = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
  return `${type}/${hashHex.slice(0, 24)}.json`;
}

// ENHANCED CACHE FUNCTIONS WITH DETAILED LOGGING
async function getCachedData(cacheKey, env) {
  const startTime = Date.now();
  
  try {
    // Check KV (hot cache) first
    const kvData = await env.BOOKS_CACHE?.get(cacheKey);
    if (kvData) {
      try {
        const parsedData = JSON.parse(kvData);
        const duration = Date.now() - startTime;
        
        console.log(`🔥 CACHE HIT (KV-HOT): ${cacheKey}`, {
          duration: `${duration}ms`,
          size: `${kvData.length} bytes`,
          timestamp: new Date().toISOString()
        });
        
        return {
          data: parsedData,
          source: "KV-HOT",
          duration
        };
      } catch (parseError) {
        console.warn(`💥 KV CACHE PARSE ERROR: ${cacheKey}`, parseError.message);
        await env.BOOKS_CACHE?.delete(cacheKey);
      }
    }
    
    // Check R2 (cold cache) if available
    if (env.BOOKS_R2) {
      const r2Object = await env.BOOKS_R2.get(cacheKey);
      if (r2Object) {
        try {
          const jsonData = await r2Object.text();
          const data = JSON.parse(jsonData);
          const duration = Date.now() - startTime;
          
          // Check TTL
          const metadata = r2Object.customMetadata;
          if (metadata?.ttl) {
            const ttl = parseInt(metadata.ttl);
            if (!isNaN(ttl) && Date.now() > ttl) {
              console.log(`⏰ R2 CACHE EXPIRED: ${cacheKey}`);
              await env.BOOKS_R2.delete(cacheKey);
              return null;
            }
          }
          
          console.log(`❄️ CACHE HIT (R2-COLD): ${cacheKey}`, {
            duration: `${duration}ms`,
            size: `${jsonData.length} bytes`,
            promoted: true,
            timestamp: new Date().toISOString()
          });
          
          // Promote to KV cache
          const promoteData = JSON.stringify(data);
          env.waitUntil(env.BOOKS_CACHE?.put(cacheKey, promoteData, { expirationTtl: 86400 }));
          
          return {
            data,
            source: "R2-COLD",
            duration
          };
        } catch (parseError) {
          console.warn(`💥 R2 CACHE PARSE ERROR: ${cacheKey}`, parseError.message);
          await env.BOOKS_R2.delete(cacheKey);
        }
      }
    }
    
    const duration = Date.now() - startTime;
    console.log(`❌ CACHE MISS: ${cacheKey}`, {
      duration: `${duration}ms`,
      timestamp: new Date().toISOString()
    });
    
    return null;
  } catch (error) {
    const duration = Date.now() - startTime;
    console.warn(`🚨 CACHE ERROR: ${cacheKey}`, {
      error: error.message,
      duration: `${duration}ms`,
      timestamp: new Date().toISOString()
    });
    return null;
  }
}

async function setCachedData(cacheKey, data, ttlSeconds, env, ctx) {
  const startTime = Date.now();
  
  try {
    const jsonData = JSON.stringify(data);
    const promises = [];
    
    // Store in R2 if available
    if (env.BOOKS_R2) {
      promises.push(
        env.BOOKS_R2.put(cacheKey, jsonData, {
          httpMetadata: {
            contentType: "application/json",
            cacheControl: `max-age=${ttlSeconds}`
          },
          customMetadata: {
            ttl: (Date.now() + ttlSeconds * 1000).toString(),
            created: Date.now().toString(),
            type: cacheKey.startsWith("search") ? "search" : "isbn"
          }
        })
      );
    }
    
    // Store in KV with limited TTL
    const kvTtl = Math.min(ttlSeconds, 86400);
    promises.push(
      env.BOOKS_CACHE?.put(cacheKey, jsonData, { expirationTtl: kvTtl })
    );
    
    if (ctx && ctx.waitUntil) {
      ctx.waitUntil(Promise.all(promises.filter(Boolean)));
    } else {
      await Promise.all(promises.filter(Boolean));
    }
    
    const duration = Date.now() - startTime;
    console.log(`💾 CACHE SET: ${cacheKey}`, {
      duration: `${duration}ms`,
      size: `${jsonData.length} bytes`,
      ttl: `${ttlSeconds}s`,
      stores: env.BOOKS_R2 ? 'R2+KV' : 'KV',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    const duration = Date.now() - startTime;
    console.warn(`🚨 CACHE SET ERROR: ${cacheKey}`, {
      error: error.message,
      duration: `${duration}ms`,
      timestamp: new Date().toISOString()
    });
  }
}

// Production-safe result validation
function isValidResult(result) {
  return result && 
         result.items && 
         Array.isArray(result.items) && 
         result.items.length > 0 &&
         result.items.some(item => 
           item && 
           item.volumeInfo && 
           item.volumeInfo.title && 
           typeof item.volumeInfo.title === 'string' &&
           item.volumeInfo.title.trim().length > 0
         );
}

// Memory-safe fetch with size limits
const MAX_RESPONSE_SIZE = 5 * 1024 * 1024; // 5MB

async function safeFetch(url, options = {}) {
  const response = await fetch(url, options);
  
  if (!response.ok) {
    throw new Error(`API error: ${response.status} - ${response.statusText}`);
  }
  
  const contentLength = response.headers.get('content-length');
  if (contentLength && parseInt(contentLength) > MAX_RESPONSE_SIZE) {
    throw new Error('Response too large');
  }
  
  const text = await response.text();
  if (text.length > MAX_RESPONSE_SIZE) {
    throw new Error('Response too large');
  }
  
  try {
    return JSON.parse(text);
  } catch (parseError) {
    throw new Error(`Invalid JSON response: ${parseError.message}`);
  }
}

// Enhanced search handler with detailed logging
async function handleBookSearch(request, env, ctx) {
  const url = new URL(request.url);
  const validation = validateSearchParams(url);
  
  if (validation.errors.length > 0) {
    console.log(`❌ SEARCH VALIDATION ERROR:`, validation.errors);
    return new Response(JSON.stringify({
      error: "Invalid parameters",
      details: validation.errors
    }), {
      status: 400,
      headers: getCORSHeaders()
    });
  }
  
  const { query, maxResults, sortBy, includeTranslations, provider } = validation.sanitized;
  
  console.log(`🔍 SEARCH REQUEST:`, {
    query: query.slice(0, 50),
    maxResults,
    sortBy,
    provider,
    timestamp: new Date().toISOString()
  });
  
  const rateLimitResult = await checkRateLimitEnhanced(request, env);
  if (!rateLimitResult.allowed) {
    return new Response(JSON.stringify({
      error: "Rate limit exceeded",
      retryAfter: rateLimitResult.retryAfter
    }), {
      status: 429,
      headers: {
        ...getCORSHeaders(),
        "Retry-After": rateLimitResult.retryAfter.toString()
      }
    });
  }
  
  // Use crypto-based cache key generation
  const cacheKey = await generateCacheKey("search", query, maxResults, sortBy, includeTranslations, provider);
  const cached = await getCachedData(cacheKey, env);
  if (cached) {
    return new Response(JSON.stringify(cached.data), {
      headers: {
        ...getCORSHeaders(),
        "X-Cache": `HIT-${cached.source}`,
        "X-Cache-Source": cached.source,
        "X-Cache-Duration": `${cached.duration}ms`
      }
    });
  }
  
  let result = null;
  let usedProvider = null;
  let errors = [];
  
  // Provider routing logic with enhanced logging
  if (provider === "isbndb") {
    // Force ISBNdb only
    try {
      console.log(`🎯 FORCED PROVIDER: ISBNdb`);
      result = await searchISBNdb(query, maxResults, env);
      if (isValidResult(result)) {
        usedProvider = "isbndb";
        console.log(`✅ ISBNdb SUCCESS: ${result.items?.length || 0} results`);
      } else {
        throw new Error("ISBNdb returned invalid results");
      }
    } catch (error) {
      console.error(`❌ ISBNdb FAILED:`, error.message);
      errors.push(`ISBNdb: ${error.message}`);
    }
  } else if (provider === "google") {
    // Force Google Books only
    try {
      console.log(`🎯 FORCED PROVIDER: Google Books`);
      result = await searchGoogleBooks(query, maxResults, sortBy, includeTranslations, env);
      if (isValidResult(result)) {
        usedProvider = "google-books";
        console.log(`✅ Google Books SUCCESS: ${result.items?.length || 0} results`);
      } else {
        throw new Error("Google Books returned invalid results");
      }
    } catch (error) {
      console.error(`❌ Google Books FAILED:`, error.message);
      errors.push(`Google Books: ${error.message}`);
    }
  } else if (provider === "openlibrary") {
    // Force Open Library only
    try {
      console.log(`🎯 FORCED PROVIDER: Open Library`);
      result = await searchOpenLibrary(query, maxResults, env);
      if (isValidResult(result)) {
        usedProvider = "open-library";
        console.log(`✅ Open Library SUCCESS: ${result.items?.length || 0} results`);
      } else {
        throw new Error("Open Library returned invalid results");
      }
    } catch (error) {
      console.error(`❌ Open Library FAILED:`, error.message);
      errors.push(`Open Library: ${error.message}`);
    }
  } else {
    // Auto mode: ISBNdb → Google Books → Open Library with enhanced logging
    
    // 1. Try ISBNdb FIRST
    console.log(`🔄 AUTO MODE: Trying ISBNdb first`);
    try {
      result = await searchISBNdb(query, maxResults, env);
      if (isValidResult(result)) {
        usedProvider = "isbndb";
        console.log(`✅ ISBNdb SUCCESS: ${result.items?.length || 0} results`);
      } else {
        throw new Error("ISBNdb returned empty/invalid results");
      }
    } catch (error) {
      console.error(`❌ ISBNdb FAILED:`, error.message);
      errors.push(`ISBNdb: ${error.message}`);
      result = null;
    }
    
    // 2. Fallback to Google Books if ISBNdb failed
    if (!isValidResult(result)) {
      console.log(`🔄 FALLBACK: Trying Google Books`);
      try {
        result = await searchGoogleBooks(query, maxResults, sortBy, includeTranslations, env);
        if (isValidResult(result)) {
          usedProvider = "google-books";
          console.log(`✅ Google Books SUCCESS: ${result.items?.length || 0} results`);
        } else {
          throw new Error("Google Books returned empty/invalid results");
        }
      } catch (error) {
        console.error(`❌ Google Books FAILED:`, error.message);
        errors.push(`Google Books: ${error.message}`);
        result = null;
      }
    }
    
    // 3. Final fallback to Open Library
    if (!isValidResult(result)) {
      console.log(`🔄 FALLBACK: Trying Open Library`);
      try {
        result = await searchOpenLibrary(query, maxResults, env);
        if (isValidResult(result)) {
          usedProvider = "open-library";
          console.log(`✅ Open Library SUCCESS: ${result.items?.length || 0} results`);
        } else {
          throw new Error("Open Library returned empty/invalid results");
        }
      } catch (error) {
        console.error(`❌ Open Library FAILED:`, error.message);
        errors.push(`Open Library: ${error.message}`);
        result = null;
      }
    }
  }
  
  if (!isValidResult(result)) {
    console.log(`💀 ALL PROVIDERS FAILED:`, errors);
    return new Response(JSON.stringify({
      error: "All book providers failed or returned no valid results",
      details: errors,
      items: []
    }), {
      status: 503,
      headers: getCORSHeaders()
    });
  }
  
  result.provider = usedProvider;
  result.cached = false;
  
  const response = JSON.stringify(result);
  
  // Cache successful results
  setCachedData(cacheKey, result, 2592000, env, ctx); // 30 days
  
  console.log(`🎉 SEARCH SUCCESS:`, {
    provider: usedProvider,
    results: result.items?.length || 0,
    cached: false,
    timestamp: new Date().toISOString()
  });
  
  return new Response(response, {
    headers: {
      ...getCORSHeaders(),
      "X-Cache": "MISS",
      "X-Provider": usedProvider,
      "X-Cache-System": env.BOOKS_R2 ? "R2+KV-Hybrid" : "KV-Only",
      "X-Rate-Limit-Remaining": rateLimitResult.remaining.toString(),
      "X-Debug-Errors": errors.length > 0 ? errors.join("; ") : "none",
      "X-Results-Count": result.items?.length?.toString() || "0"
    }
  });
}

// Enhanced ISBN lookup handler
async function handleISBNLookup(request, env, ctx) {
  const url = new URL(request.url);
  const rawISBN = url.searchParams.get("isbn");
  const provider = url.searchParams.get("provider") || "auto";
  
  const validation = validateISBN(rawISBN);
  if (validation.error) {
    console.log(`❌ ISBN VALIDATION ERROR: ${validation.error}`);
    return new Response(JSON.stringify({
      error: validation.error
    }), {
      status: 400,
      headers: getCORSHeaders()
    });
  }
  
  const isbn = validation.sanitized;
  console.log(`📖 ISBN LOOKUP: ${isbn} (provider: ${provider})`);
  
  // Use crypto-based cache key generation
  const cacheKey = await generateCacheKey("isbn", isbn, provider);
  const cached = await getCachedData(cacheKey, env);
  if (cached) {
    return new Response(JSON.stringify(cached.data), {
      headers: {
        ...getCORSHeaders(),
        "X-Cache": `HIT-${cached.source}`,
        "X-Cache-Source": cached.source,
        "X-Cache-Duration": `${cached.duration}ms`
      }
    });
  }
  
  let result = null;
  let usedProvider = null;
  let errors = [];
  
  // Provider routing for ISBN lookup with enhanced logging
  if (provider === "isbndb") {
    // Force ISBNdb only
    try {
      console.log(`🎯 FORCED ISBN PROVIDER: ISBNdb`);
      result = await lookupISBNISBNdb(isbn, env);
      usedProvider = "isbndb";
    } catch (error) {
      console.error(`❌ ISBNdb ISBN FAILED:`, error.message);
      errors.push(`ISBNdb: ${error.message}`);
    }
  } else if (provider === "google") {
    // Force Google Books only
    try {
      console.log(`🎯 FORCED ISBN PROVIDER: Google Books`);
      result = await lookupISBNGoogle(isbn, env);
      usedProvider = "google-books";
    } catch (error) {
      console.error(`❌ Google Books ISBN FAILED:`, error.message);
      errors.push(`Google Books: ${error.message}`);
    }
  } else if (provider === "openlibrary") {
    // Force Open Library only
    try {
      console.log(`🎯 FORCED ISBN PROVIDER: Open Library`);
      result = await lookupISBNOpenLibrary(isbn, env);
      usedProvider = "open-library";
    } catch (error) {
      console.error(`❌ Open Library ISBN FAILED:`, error.message);
      errors.push(`Open Library: ${error.message}`);
    }
  } else {
    // Auto mode: ISBNdb → Google Books → Open Library
    
    // 1. Try ISBNdb FIRST
    console.log(`🔄 AUTO ISBN MODE: Trying ISBNdb first`);
    try {
      result = await lookupISBNISBNdb(isbn, env);
      if (result) {
        usedProvider = "isbndb";
        console.log(`✅ ISBNdb ISBN SUCCESS: ${result.volumeInfo?.title || 'unknown'}`);
      }
    } catch (error) {
      console.error(`❌ ISBNdb ISBN FAILED:`, error.message);
      errors.push(`ISBNdb: ${error.message}`);
    }
    
    // 2. Fallback to Google Books
    if (!result) {
      console.log(`🔄 ISBN FALLBACK: Trying Google Books`);
      try {
        result = await lookupISBNGoogle(isbn, env);
        if (result) {
          usedProvider = "google-books";
          console.log(`✅ Google Books ISBN SUCCESS: ${result.volumeInfo?.title || 'unknown'}`);
        }
      } catch (error) {
        console.error(`❌ Google Books ISBN FAILED:`, error.message);
        errors.push(`Google Books: ${error.message}`);
      }
    }
    
    // 3. Final fallback to Open Library
    if (!result) {
      console.log(`🔄 ISBN FALLBACK: Trying Open Library`);
      try {
        result = await lookupISBNOpenLibrary(isbn, env);
        if (result) {
          usedProvider = "open-library";
          console.log(`✅ Open Library ISBN SUCCESS: ${result.volumeInfo?.title || 'unknown'}`);
        }
      } catch (error) {
        console.error(`❌ Open Library ISBN FAILED:`, error.message);
        errors.push(`Open Library: ${error.message}`);
      }
    }
  }
  
  if (!result) {
    console.log(`💀 ISBN NOT FOUND: ${isbn}`, errors);
    return new Response(JSON.stringify({
      error: "ISBN not found in any provider",
      isbn,
      details: errors
    }), {
      status: 404,
      headers: {
        ...getCORSHeaders(),
        "X-Debug-Errors": errors.join("; ")
      }
    });
  }
  
  result.provider = usedProvider;
  
  const response = JSON.stringify(result);
  setCachedData(cacheKey, result, 31536000, env, ctx); // 1 year for ISBN lookups
  
  console.log(`🎉 ISBN SUCCESS:`, {
    isbn,
    provider: usedProvider,
    title: result.volumeInfo?.title || 'unknown',
    timestamp: new Date().toISOString()
  });
  
  return new Response(response, {
    headers: {
      ...getCORSHeaders(),
      "X-Cache": "MISS",
      "X-Provider": usedProvider,
      "X-Cache-System": env.BOOKS_R2 ? "R2+KV-Hybrid" : "KV-Only"
    }
  });
}

// Production-ready ISBNdb rate limiting with distributed KV storage
async function waitForISBNdbRateLimit(env) {
  const rateLimitKey = "isbndb:last_request";
  const now = Date.now();
  
  try {
    const lastRequest = await env.BOOKS_CACHE?.get(rateLimitKey);
    const lastRequestTime = lastRequest ? parseInt(lastRequest) : 0;
    
    const timeSinceLastRequest = now - lastRequestTime;
    if (timeSinceLastRequest < 1000) {
      const waitTime = 1000 - timeSinceLastRequest + 50; // Add 50ms buffer
      console.log(`⏳ ISBNdb RATE LIMIT: Waiting ${waitTime}ms`);
      await new Promise(resolve => setTimeout(resolve, waitTime));
    }
    
    // Update last request time atomically
    const updatedTime = Date.now();
    await env.BOOKS_CACHE?.put(rateLimitKey, updatedTime.toString(), { expirationTtl: 3600 });
    
    return true;
  } catch (error) {
    console.warn('ISBNdb rate limiting unavailable:', error.message);
    // Fallback to local delay if KV is unavailable
    await new Promise(resolve => setTimeout(resolve, 1100));
    return false;
  }
}

// ISBNdb Search (PRIMARY PROVIDER) - Production hardened with logging
async function searchISBNdb(query, maxResults, env) {
  const apiKey = env.ISBNdb1;
  if (!apiKey) {
    throw new Error("ISBNdb API key not configured (env.ISBNdb1)");
  }
  
  // Use distributed KV-based rate limiting
  await waitForISBNdbRateLimit(env);
  
  console.log(`🔍 ISBNdb SEARCH: ${query.slice(0, 50)}`);
  
  const baseUrl = "https://api2.isbndb.com";
  let endpoint;
  
  // Check if query looks like an ISBN
  const isISBN = query.match(/^\d{10}(\d{3})?$/);
  if (isISBN) {
    endpoint = `/book/${query}`;
  } else {
    // Use the books search endpoint for text queries
    endpoint = `/books/${encodeURIComponent(query)}`;
  }
  
  const params = new URLSearchParams({
    pageSize: Math.min(maxResults, 1000).toString(),
    page: "1"
  });
  
  const url = `${baseUrl}${endpoint}?${params}`;
  
  // Use safeFetch with memory protection
  try {
    const data = await safeFetch(url, {
      method: 'GET',
      headers: {
        "Authorization": apiKey,
        "Content-Type": "application/json",
        "User-Agent": "CloudflareWorker/BooksProxy"
      },
      signal: AbortSignal.timeout(15000)
    });
    
    // Handle both single book and multiple books responses
    let books = [];
    if (data.book) {
      // Single book response (direct ISBN lookup)
      books = [data.book];
    } else if (data.books && Array.isArray(data.books)) {
      // Multiple books response (search)
      books = data.books;
    } else {
      console.log(`⚠️ ISBNdb UNEXPECTED FORMAT:`, Object.keys(data));
      books = [];
    }
    
    console.log(`📊 ISBNdb FOUND: ${books.length} books`);
    
    return {
      kind: "books#volumes",
      totalItems: data.total || books.length,
      items: books.map((book) => ({
        kind: "books#volume",
        id: book.isbn13 || book.isbn || book.title?.substring(0, 20) || "unknown",
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
    if (error.message.includes('401')) {
      throw new Error("ISBNdb authentication failed - check API key");
    } else if (error.message.includes('403')) {
      throw new Error("ISBNdb access forbidden - check API permissions");
    } else if (error.message.includes('429')) {
      throw new Error("ISBNdb rate limit exceeded");
    } else {
      throw new Error(`ISBNdb API error: ${error.message}`);
    }
  }
}

// ISBNdb ISBN Lookup (PRIMARY PROVIDER) - Production hardened with logging
async function lookupISBNISBNdb(isbn, env) {
  const apiKey = env.ISBNdb1;
  if (!apiKey) {
    throw new Error("ISBNdb API key not configured (env.ISBNdb1)");
  }
  
  // Use distributed KV-based rate limiting
  await waitForISBNdbRateLimit(env);
  
  console.log(`🔍 ISBNdb ISBN: ${isbn}`);
  
  try {
    const data = await safeFetch(`https://api2.isbndb.com/book/${isbn}`, {
      method: 'GET',
      headers: {
        "Authorization": apiKey,
        "Content-Type": "application/json",
        "User-Agent": "CloudflareWorker/BooksProxy"
      },
      signal: AbortSignal.timeout(15000)
    });
    
    const book = data.book;
    if (!book) {
      console.log(`❌ ISBNdb ISBN NOT FOUND: ${isbn}`);
      return null;
    }
    
    console.log(`📖 ISBNdb ISBN FOUND: ${book.title || 'unknown'}`);
    
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
    if (error.message.includes('404')) {
      console.log(`❌ ISBNdb ISBN NOT FOUND: ${isbn}`);
      return null; // ISBN not found
    } else if (error.message.includes('401')) {
      throw new Error("ISBNdb authentication failed - check API key");
    } else if (error.message.includes('403')) {
      throw new Error("ISBNdb access forbidden - check API permissions");
    } else {
      throw new Error(`ISBNdb ISBN API error: ${error.message}`);
    }
  }
}

// Google Books Search (SECONDARY PROVIDER) - Memory protected with logging
async function searchGoogleBooks(query, maxResults, sortBy, includeTranslations, env) {
  const apiKey = env.google1 || env.google2;
  if (!apiKey) {
    throw new Error("Google Books API key not configured");
  }
  
  console.log(`🔍 Google Books SEARCH: ${query.slice(0, 50)}`);
  
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
  
  const data = await safeFetch(`https://www.googleapis.com/books/v1/volumes?${params}`, {
    signal: AbortSignal.timeout(10000)
  });
  
  console.log(`📊 Google Books FOUND: ${data.items?.length || 0} books`);
  return data;
}

// Google Books ISBN Lookup (SECONDARY PROVIDER) - Memory protected with logging
async function lookupISBNGoogle(isbn, env) {
  const apiKey = env.google1 || env.google2;
  if (!apiKey) {
    throw new Error("Google Books API key not configured");
  }
  
  console.log(`🔍 Google Books ISBN: ${isbn}`);
  
  const params = new URLSearchParams({
    q: `isbn:${isbn}`,
    maxResults: "1",
    printType: "books",
    projection: "full",
    key: apiKey
  });
  
  const data = await safeFetch(`https://www.googleapis.com/books/v1/volumes?${params}`, {
    signal: AbortSignal.timeout(10000)
  });
  
  const result = data.items?.[0] || null;
  console.log(`📖 Google Books ISBN: ${result ? result.volumeInfo?.title || 'found' : 'not found'}`);
  
  return result;
}

// Open Library Search (TERTIARY PROVIDER) - Memory protected with logging
async function searchOpenLibrary(query, maxResults, env) {
  console.log(`🔍 Open Library SEARCH: ${query.slice(0, 50)}`);
  
  const params = new URLSearchParams({
    q: query,
    limit: maxResults.toString(),
    fields: "key,title,author_name,first_publish_year,isbn,publisher,language,subject,cover_i,edition_count",
    format: "json"
  });
  
  const data = await safeFetch(`https://openlibrary.org/search.json?${params}`, {
    signal: AbortSignal.timeout(20000)
  });
  
  console.log(`📊 Open Library FOUND: ${data.docs?.length || 0} books`);
  
  return {
    kind: "books#volumes",
    totalItems: data.numFound,
    items: data.docs.map((doc) => ({
      kind: "books#volume",
      id: doc.key?.replace("/works/", "") || "",
      volumeInfo: {
        title: doc.title || "",
        authors: doc.author_name || [],
        publishedDate: doc.first_publish_year?.toString() || "",
        publisher: Array.isArray(doc.publisher) ? doc.publisher[0] : doc.publisher || "",
        description: "", // Open Library doesn't provide descriptions in search
        industryIdentifiers: doc.isbn ? doc.isbn.slice(0, 2).map((isbn) => ({
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
}

// Open Library ISBN Lookup (TERTIARY PROVIDER) - Memory protected with logging
async function lookupISBNOpenLibrary(isbn, env) {
  console.log(`🔍 Open Library ISBN: ${isbn}`);
  
  const data = await safeFetch(`https://openlibrary.org/api/books?bibkeys=ISBN:${isbn}&format=json&jscmd=data`, {
    signal: AbortSignal.timeout(20000)
  });
  
  const bookData = data[`ISBN:${isbn}`];
  if (!bookData) {
    console.log(`❌ Open Library ISBN NOT FOUND: ${isbn}`);
    return null;
  }
  
  console.log(`📖 Open Library ISBN FOUND: ${bookData.title || 'unknown'}`);
  
  return {
    kind: "books#volume",
    id: bookData.key?.replace("/books/", "") || isbn,
    volumeInfo: {
      title: bookData.title || "",
      authors: bookData.authors?.map((author) => author.name) || [],
      publishedDate: bookData.publish_date || "",
      publisher: bookData.publishers?.[0]?.name || "",
      description: bookData.notes || "",
      industryIdentifiers: [{
        type: isbn.length === 13 ? "ISBN_13" : "ISBN_10",
        identifier: isbn
      }],
      pageCount: bookData.number_of_pages || null,
      categories: bookData.subjects?.map((subject) => subject.name).slice(0, 3) || [],
      imageLinks: bookData.cover ? {
        thumbnail: bookData.cover.medium,
        smallThumbnail: bookData.cover.small
      } : null,
      language: "en", // Open Library doesn't always provide language
      previewLink: bookData.url,
      infoLink: bookData.url
    }
  };
}