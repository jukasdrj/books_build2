// Enhanced CloudFlare Workers Proxy with Provider-Specific Routing
// Supports targeting specific APIs for different use cases

export default {
  async fetch(request, env, ctx) {
    if (request.method === "OPTIONS") {
      return handleCORS();
    }

    try {
      const url = new URL(request.url);
      const path = url.pathname;

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

// Enhanced search handler with provider routing
async function handleBookSearch(request, env, ctx) {
  const url = new URL(request.url);
  const validation = validateSearchParams(url);
  
  if (validation.errors.length > 0) {
    return createErrorResponse("Invalid parameters", 400, { 
      details: validation.errors 
    });
  }

  const { query, maxResults, sortBy, includeTranslations, provider } = validation.sanitized;

  // Rate limiting check
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
        "X-RateLimit-Remaining": rateLimitResult.remaining?.toString() || "0"
      }
    });
  }

  // Enhanced cache key includes provider preference
  const cacheKey = CACHE_KEYS.search(query, maxResults, sortBy, includeTranslations, provider);
  const cached = await getCachedData(cacheKey, env);
  
  if (cached) {
    return new Response(JSON.stringify(cached.data), {
      headers: {
        ...getCORSHeaders(),
        "X-Cache": `HIT-${cached.source}`,
        "X-Cache-Age": Math.floor(cached.age / 1000).toString(),
        "X-Provider": cached.data.provider || "cached",
        "X-Rate-Limit-Remaining": rateLimitResult.remaining?.toString() || "0"
      }
    });
  }

  // Provider-specific routing
  let result = null;
  let actualProvider = null;
  const providerErrors = [];

  if (provider) {
    // Force specific provider
    try {
      result = await callSpecificProvider(provider, 'search', {
        query, maxResults, sortBy, includeTranslations
      }, env);
      actualProvider = provider;
    } catch (error) {
      providerErrors.push({ provider, error: error.message });
      console.error(`Forced provider ${provider} failed:`, error.message);
      
      // If forced provider fails, return error (no fallback for explicit requests)
      return createErrorResponse(`Provider ${provider} failed`, 503, {
        provider,
        error: error.message,
        available: ["google", "isbndb", "openlibrary"]
      });
    }
  } else {
    // Use automatic fallback chain
    const providers = ["google-books", "isbndb", "open-library"];
    
    for (const providerName of providers) {
      try {
        result = await callSpecificProvider(providerName, 'search', {
          query, maxResults, sortBy, includeTranslations
        }, env);
        actualProvider = providerName;
        break;
      } catch (error) {
        providerErrors.push({ provider: providerName, error: error.message });
        console.error(`Provider ${providerName} failed:`, error.message);
      }
    }
  }

  if (!result) {
    return createErrorResponse("All providers failed", 503, {
      providers: providerErrors,
      items: []
    });
  }

  // Enrich response
  result.provider = actualProvider;
  result.cached = false;
  result.requestId = crypto.randomUUID();
  result.providerForced = !!provider;

  // Cache successful results
  if (result.items?.length > 0) {
    setCachedData(cacheKey, result, 2592000, env, ctx); // 30 days
  }

  return new Response(JSON.stringify(result), {
    headers: {
      ...getCORSHeaders(),
      "X-Cache": "MISS",
      "X-Provider": actualProvider,
      "X-Provider-Forced": provider ? "true" : "false",
      "X-Request-ID": result.requestId,
      "X-Rate-Limit-Remaining": rateLimitResult.remaining?.toString() || "0"
    }
  });
}

// Enhanced ISBN lookup with provider routing
async function handleISBNLookup(request, env, ctx) {
  const url = new URL(request.url);
  const rawISBN = url.searchParams.get("isbn");
  const provider = url.searchParams.get("provider");
  
  const validation = validateISBN(rawISBN);
  if (validation.error) {
    return createErrorResponse(validation.error, 400);
  }

  const isbn = validation.sanitized;
  const cacheKey = CACHE_KEYS.isbn(isbn, provider);
  const cached = await getCachedData(cacheKey, env);

  if (cached) {
    return new Response(JSON.stringify(cached.data), {
      headers: {
        ...getCORSHeaders(),
        "X-Cache": `HIT-${cached.source}`,
        "X-Cache-Age": Math.floor(cached.age / 1000).toString(),
        "X-Provider": cached.data.provider || "cached"
      }
    });
  }

  let result = null;
  let actualProvider = null;

  if (provider) {
    // Force specific provider
    try {
      result = await callSpecificProvider(provider, 'isbn', { isbn }, env);
      actualProvider = provider;
    } catch (error) {
      console.error(`Forced provider ${provider} failed:`, error.message);
      return createErrorResponse(`Provider ${provider} failed`, 503, {
        provider,
        error: error.message,
        isbn
      });
    }
  } else {
    // Use automatic fallback chain
    const providers = ["google-books", "isbndb", "open-library"];
    
    for (const providerName of providers) {
      try {
        result = await callSpecificProvider(providerName, 'isbn', { isbn }, env);
        actualProvider = providerName;
        break;
      } catch (error) {
        console.error(`Provider ${providerName} failed:`, error.message);
      }
    }
  }

  if (!result) {
    return createErrorResponse("ISBN not found in any provider", 404, { isbn });
  }

  result.provider = actualProvider;
  result.requestId = crypto.randomUUID();
  result.providerForced = !!provider;

  // Cache successful ISBN lookups for longer (1 year)
  setCachedData(cacheKey, result, 31536000, env, ctx);

  return new Response(JSON.stringify(result), {
    headers: {
      ...getCORSHeaders(),
      "X-Cache": "MISS",
      "X-Provider": actualProvider,
      "X-Provider-Forced": provider ? "true" : "false",
      "X-Request-ID": result.requestId
    }
  });
}

// Universal provider caller
async function callSpecificProvider(provider, type, params, env) {
  switch (provider) {
    case "google":
    case "google-books":
      if (type === 'search') {
        return await searchGoogleBooks(
          params.query, 
          params.maxResults, 
          params.sortBy, 
          params.includeTranslations, 
          env
        );
      } else if (type === 'isbn') {
        return await lookupISBNGoogle(params.isbn, env);
      }
      break;
      
    case "isbndb":
      if (type === 'search') {
        return await searchISBNdb(params.query, params.maxResults, env);
      } else if (type === 'isbn') {
        return await lookupISBNISBNdb(params.isbn, env);
      }
      break;
      
    case "openlibrary":
    case "open-library":
      if (type === 'search') {
        return await searchOpenLibrary(params.query, params.maxResults, env);
      } else if (type === 'isbn') {
        return await lookupISBNOpenLibrary(params.isbn, env);
      }
      break;
      
    default:
      throw new Error(`Unknown provider: ${provider}`);
  }
  
  throw new Error(`Provider ${provider} does not support ${type}`);
}

// Enhanced validation with provider parameter
function validateSearchParams(url) {
  const query = url.searchParams.get("q");
  const maxResults = url.searchParams.get("maxResults");
  const sortBy = url.searchParams.get("orderBy");
  const langRestrict = url.searchParams.get("langRestrict");
  const provider = url.searchParams.get("provider");

  const errors = [];
  const sanitized = {};

  // Query validation (existing logic)
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

  // Provider validation
  if (provider !== null) {
    const validProviders = ["google", "google-books", "isbndb", "openlibrary", "open-library"];
    if (!validProviders.includes(provider.toLowerCase())) {
      errors.push(`Provider must be one of: ${validProviders.join(", ")}`);
    } else {
      sanitized.provider = provider.toLowerCase();
    }
  }

  // Other validations (maxResults, sortBy, langRestrict) - same as before
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

// Enhanced cache keys with provider consideration
const CACHE_KEYS = {
  search: (query, maxResults, sortBy, translations, provider) => {
    const queryHash = btoa(query).replace(/[/+=]/g, "_").slice(0, 32);
    const providerSuffix = provider ? `_${provider}` : "";
    return `search/${queryHash}/${maxResults}/${sortBy}/${translations}${providerSuffix}.json`;
  },
  isbn: (isbn, provider) => {
    const providerSuffix = provider ? `_${provider}` : "";
    return `isbn/${isbn}${providerSuffix}.json`;
  }
};

// Enhanced health check with provider testing
async function handleHealthCheck(env) {
  const checks = {
    timestamp: new Date().toISOString(),
    status: "healthy",
    version: "2.1",
    routing: "provider-specific",
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
    features: {
      providerRouting: "enabled",
      rateLimit: "enabled",
      inputValidation: "enabled",
      checksumValidation: "enabled",
      cachePromotion: "enabled"
    },
    usage: {
      endpoints: [
        "GET /search?q={query}&provider={google|isbndb|openlibrary}",
        "GET /isbn?isbn={isbn}&provider={google|isbndb|openlibrary}",
        "GET /health"
      ]
    }
  };

  return new Response(JSON.stringify(checks, null, 2), {
    headers: getCORSHeaders("application/json")
  });
}

// Utility functions (CORS, rate limiting, etc.) - same as optimized version
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

function validateISBN(isbn) {
  if (!isbn || typeof isbn !== "string") {
    return { error: "ISBN parameter is required and must be a string" };
  }

  const cleanedISBN = isbn
    .replace(/^=+/, "")
    .replace(/[-\s]/g, "")
    .replace(/[^0-9X]/gi, "")
    .toUpperCase();

  if (cleanedISBN.length !== 10 && cleanedISBN.length !== 13) {
    return { error: "ISBN must be 10 or 13 characters long" };
  }

  // ISBN validation logic (same as optimized version)
  if (cleanedISBN.length === 10) {
    if (!/^\d{9}[\dX]$/.test(cleanedISBN)) {
      return { error: "Invalid ISBN-10 format" };
    }
    
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

// Include all the provider functions (searchGoogleBooks, lookupISBNGoogle, etc.)
// and utility functions from the optimized version...
// [Provider implementations would be included here - same as proxy-optimized.js]

async function checkAdvancedRateLimit(request, env) {
  // Same implementation as optimized version
  const clientIP = request.headers.get("CF-Connecting-IP") || "unknown";
  const userAgent = request.headers.get("User-Agent") || "unknown";
  const userFingerprint = await generateUserFingerprint(clientIP, userAgent, "");
  const rateLimitKey = `ratelimit:${userFingerprint}`;

  let maxRequests = 100;
  const windowSize = 3600;

  if (userAgent.length < 10 || userAgent === "unknown" || 
      userAgent.includes("bot") || userAgent.includes("curl")) {
    maxRequests = 20;
  }

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

// Cache functions and provider implementations would continue here...
// [Include all functions from proxy-optimized.js]

async function getCachedData(cacheKey, env) {
  // Same implementation as optimized version
  try {
    const kvData = await env.BOOKS_CACHE?.get(cacheKey);
    if (kvData) {
      const parsed = JSON.parse(kvData);
      return {
        data: parsed,
        source: "KV-HOT",
        age: parsed._cached ? Date.now() - parsed._cached.timestamp : 0
      };
    }

    if (env.BOOKS_R2) {
      const r2Object = await env.BOOKS_R2.get(cacheKey);
      if (r2Object) {
        const jsonData = await r2Object.text();
        const data = JSON.parse(jsonData);
        const metadata = r2Object.customMetadata;

        if (metadata?.ttl && Date.now() > parseInt(metadata.ttl)) {
          await env.BOOKS_R2.delete(cacheKey);
          return null;
        }

        const promoteData = JSON.stringify(data);
        env.waitUntil(env.BOOKS_CACHE?.put(cacheKey, promoteData, { expirationTtl: 86400 }));

        return {
          data,
          source: "R2-COLD",
          age: metadata?.created ? Date.now() - parseInt(metadata.created) : 0
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
  // Same implementation as optimized version
  const enrichedData = {
    ...data,
    _cached: {
      timestamp: Date.now(),
      ttl: ttlSeconds * 1000,
      version: "2.1"
    }
  };

  const jsonData = JSON.stringify(enrichedData);
  const promises = [];

  try {
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
            type: cacheKey.startsWith("search") ? "search" : "isbn",
            version: "2.1"
          }
        })
      );
    }

    const kvTtl = Math.min(ttlSeconds, 86400);
    promises.push(
      env.BOOKS_CACHE?.put(cacheKey, jsonData, { expirationTtl: kvTtl })
    );

    if (ctx?.waitUntil) {
      ctx.waitUntil(Promise.all(promises.filter(Boolean)));
    } else {
      await Promise.all(promises.filter(Boolean));
    }
  } catch (error) {
    console.warn(`Cache write error for key ${cacheKey}:`, error.message);
  }
}

async function testProvider(provider, env) {
  try {
    switch (provider) {
      case "google-books":
        return env.google1 || env.google2 ? "configured" : "missing-key";
      case "isbndb":
        return env.ISBNdb1 ? "configured" : "missing-key";
      case "open-library":
        return "available";
      default:
        return "unknown";
    }
  } catch (error) {
    return "error";
  }
}

// Provider implementation functions would continue here...
// [All the searchGoogleBooks, searchISBNdb, etc. functions from proxy-optimized.js]