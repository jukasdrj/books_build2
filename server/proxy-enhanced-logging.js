// Enhanced CloudFlare Workers Proxy with Cache Hit Logging
// Implements console logging and structured cache analytics

export default {
  async fetch(request, env, ctx) {
    // Handle preflight CORS requests
    if (request.method === "OPTIONS") {
      return handleCORS();
    }

    try {
      const url = new URL(request.url);
      const path = url.pathname;

      // Log request details
      console.log(`📥 REQUEST: ${request.method} ${url.pathname}${url.search}`, {
        userAgent: request.headers.get('User-Agent')?.slice(0, 50),
        cfRay: request.headers.get('CF-Ray'),
        timestamp: new Date().toISOString()
      });

      // Route handling with enhanced logging
      switch (path) {
        case "/search":
          return await handleBookSearch(request, env, ctx);
        case "/isbn":
          return await handleISBNLookup(request, env, ctx);
        case "/health":
          return await handleHealthCheck(env);
        default:
          console.log(`❌ UNKNOWN ENDPOINT: ${path}`);
          return createErrorResponse("Endpoint not found", 404);
      }
    } catch (error) {
      console.error("🚨 WORKER ERROR:", {
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
    "Access-Control-Allow-Origin": "*",
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

// Enhanced input validation
function validateSearchParams(url) {
  const query = url.searchParams.get("q");
  const maxResults = url.searchParams.get("maxResults");
  const sortBy = url.searchParams.get("orderBy");
  const langRestrict = url.searchParams.get("langRestrict");
  const provider = url.searchParams.get("provider");

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
    const sanitizedQuery = query
      .replace(/[<>]/g, "")
      .replace(/['"]/g, "")
      .replace(/[\x00-\x1F\x7F]/g, "")
      .replace(/javascript:/gi, "")
      .replace(/data:/gi, "")
      .replace(/vbscript:/gi, "")
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
    sanitized.provider = "auto";
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

// Enhanced rate limiting
async function checkAdvancedRateLimit(request, env) {
  const clientIP = request.headers.get("CF-Connecting-IP") || "unknown";
  const userAgent = request.headers.get("User-Agent") || "unknown";
  const apiKey = request.headers.get("X-API-Key");
  const cfRay = request.headers.get("CF-Ray") || "unknown";

  const userFingerprint = await generateUserFingerprint(clientIP, userAgent, cfRay);
  const rateLimitKey = `ratelimit:${userFingerprint}`;

  let maxRequests = 100;
  const windowSize = 3600;

  if (userAgent.length < 10 || userAgent === "unknown" || 
      userAgent.includes("bot") || userAgent.includes("curl")) {
    maxRequests = 20;
  }

  if (apiKey && await validateAPIKey(apiKey, env)) {
    maxRequests = 1000;
  }

  const current = await env.BOOKS_CACHE?.get(rateLimitKey);
  const count = current ? parseInt(current) : 0;

  if (count >= maxRequests) {
    console.log(`🚫 RATE LIMIT EXCEEDED: ${userFingerprint} (${count}/${maxRequests})`);
    return {
      allowed: false,
      retryAfter: windowSize,
      reason: "Rate limit exceeded",
      current: count,
      limit: maxRequests
    };
  }

  const newCount = count + 1;
  await env.BOOKS_CACHE?.put(rateLimitKey, newCount.toString(), { 
    expirationTtl: windowSize 
  });

  console.log(`✅ RATE LIMIT OK: ${userFingerprint} (${newCount}/${maxRequests})`);
  return {
    allowed: true,
    count: newCount,
    remaining: maxRequests - newCount,
    resetTime: Date.now() + (windowSize * 1000)
  };
}

async function generateUserFingerprint(ip, userAgent, cfRay) {
  const data = `${ip}:${userAgent.slice(0, 50)}:${cfRay}`;
  const encoder = new TextEncoder();
  const dataBuffer = encoder.encode(data);
  const hashBuffer = await crypto.subtle.digest('SHA-256', dataBuffer);
  const hashArray = new Uint8Array(hashBuffer);
  const hashHex = Array.from(hashArray)
    .map(b => b.toString(16).padStart(2, '0'))
    .join('');
  return hashHex.slice(0, 16);
}

async function validateAPIKey(apiKey, env) {
  const validKey = await env.BOOKS_CACHE?.get(`apikey:${apiKey}`);
  return validKey === "valid";
}

// Enhanced cache key generation with crypto
async function generateCacheKey(type, ...params) {
  const input = JSON.stringify({ type, params, timestamp: Math.floor(Date.now() / 86400000) });
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

// Health check handler
async function handleHealthCheck(env) {
  const health = {
    status: "healthy",
    timestamp: new Date().toISOString(),
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
  };

  console.log(`💓 HEALTH CHECK: ${health.status}`);

  return new Response(JSON.stringify(health), {
    headers: getCORSHeaders("application/json")
  });
}

// Enhanced search handler with detailed logging
async function handleBookSearch(request, env, ctx) {
  const url = new URL(request.url);
  const validation = validateSearchParams(url);

  if (validation.errors.length > 0) {
    console.log(`❌ SEARCH VALIDATION ERROR:`, validation.errors);
    return createErrorResponse("Invalid parameters", 400, { details: validation.errors });
  }

  const { query, maxResults, sortBy, includeTranslations, provider } = validation.sanitized;

  console.log(`🔍 SEARCH REQUEST:`, {
    query: query.slice(0, 50),
    maxResults,
    sortBy,
    provider,
    timestamp: new Date().toISOString()
  });

  const rateLimitResult = await checkAdvancedRateLimit(request, env);
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

  // Continue with provider logic...
  let result = null;
  let usedProvider = null;
  let errors = [];

  // Provider routing with enhanced logging
  if (provider === "isbndb") {
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
  } else {
    // Auto mode: ISBNdb → Google Books → Open Library
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

    // Fallback to Google Books if ISBNdb failed
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
    return createErrorResponse(validation.error, 400);
  }

  const isbn = validation.sanitized;
  console.log(`📖 ISBN LOOKUP: ${isbn} (provider: ${provider})`);

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

  // ISBN lookup with provider routing
  if (provider === "auto") {
    console.log(`🔄 AUTO MODE: Trying ISBNdb first`);
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

    if (!result) {
      console.log(`🔄 FALLBACK: Trying Google Books`);
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
  }

  if (!result) {
    console.log(`💀 ISBN NOT FOUND: ${isbn}`, errors);
    return new Response(JSON.stringify({
      error: "ISBN not found in any provider",
      isbn,
      details: errors
    }), {
      status: 404,
      headers: getCORSHeaders()
    });
  }

  result.provider = usedProvider;
  setCachedData(cacheKey, result, 31536000, env, ctx); // 1 year

  console.log(`🎉 ISBN SUCCESS:`, {
    isbn,
    provider: usedProvider,
    title: result.volumeInfo?.title || 'unknown',
    timestamp: new Date().toISOString()
  });

  return new Response(JSON.stringify(result), {
    headers: {
      ...getCORSHeaders(),
      "X-Cache": "MISS",
      "X-Provider": usedProvider,
      "X-Cache-System": env.BOOKS_R2 ? "R2+KV-Hybrid" : "KV-Only"
    }
  });
}

// Placeholder provider functions - you'll need to implement these based on your existing logic
function isValidResult(result) {
  return result && result.items && Array.isArray(result.items) && result.items.length > 0;
}

async function searchISBNdb(query, maxResults, env) {
  // Your existing ISBNdb search implementation
  throw new Error("ISBNdb search not implemented");
}

async function searchGoogleBooks(query, maxResults, sortBy, includeTranslations, env) {
  // Your existing Google Books search implementation
  throw new Error("Google Books search not implemented");
}

async function lookupISBNISBNdb(isbn, env) {
  // Your existing ISBNdb ISBN lookup implementation
  throw new Error("ISBNdb ISBN lookup not implemented");
}

async function lookupISBNGoogle(isbn, env) {
  // Your existing Google Books ISBN lookup implementation
  throw new Error("Google Books ISBN lookup not implemented");
}