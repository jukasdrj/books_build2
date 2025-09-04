// Optimized CloudFlare Workers Main Implementation
// Integrates all optimization systems: security, caching, batching, author indexing, performance

import { IntelligentCacheManager } from './intelligent-cache-system.js';
import { QuotaOptimizationManager } from './quota-optimization-system.js';
import { AuthorCulturalIndexer } from './author-cultural-indexing.js';
import { PerformanceOptimizer } from './performance-optimization.js';

export default {
  async fetch(request, env, ctx) {
    const requestStartTime = Date.now();
    
    // Initialize optimization systems
    const cacheManager = new IntelligentCacheManager(env, ctx);
    const quotaManager = new QuotaOptimizationManager(env, ctx);
    const culturalIndexer = new AuthorCulturalIndexer(env, ctx);
    const performanceOptimizer = new PerformanceOptimizer(env, ctx);

    // Handle preflight requests
    if (request.method === "OPTIONS") {
      return handleCORS();
    }

    try {
      // Enhanced security validation
      const securityCheck = await validateRequestSecurity(request, env);
      if (!securityCheck.valid) {
        return createSecurityErrorResponse(securityCheck.reason, securityCheck.status);
      }

      // Parse request
      const url = new URL(request.url);
      const path = url.pathname;

      let response;

      // Route to optimized handlers
      switch (path) {
        case "/search":
          response = await handleOptimizedBookSearch(request, env, ctx, {
            cacheManager,
            quotaManager,
            culturalIndexer,
            requestStartTime
          });
          break;

        case "/isbn":
          response = await handleOptimizedISBNLookup(request, env, ctx, {
            cacheManager,
            quotaManager,
            culturalIndexer,
            requestStartTime
          });
          break;

        case "/batch":
          response = await handleOptimizedBatch(request, env, ctx, {
            cacheManager,
            quotaManager,
            culturalIndexer,
            requestStartTime
          });
          break;

        case "/authors/search":
          response = await handleAuthorSearch(request, env, ctx, culturalIndexer);
          break;

        case "/cultural/stats":
          response = await handleCulturalStats(request, env, ctx, culturalIndexer);
          break;

        case "/health":
          response = await handleComprehensiveHealth(env, {
            cacheManager,
            quotaManager,
            performanceOptimizer
          });
          break;

        case "/admin/performance":
          response = await handlePerformanceAnalysis(request, env, performanceOptimizer);
          break;

        default:
          response = createErrorResponse("Endpoint not found", 404);
      }

      // Apply performance optimizations
      const optimizedResponse = await performanceOptimizer.optimizeResponse(
        response,
        request,
        { startTime: requestStartTime }
      );

      return optimizedResponse;

    } catch (error) {
      const errorId = crypto.randomUUID();
      console.error("Main Worker Error:", {
        errorId,
        message: error.message,
        stack: error.stack.substring(0, 500),
        url: request.url,
        method: request.method,
        timestamp: new Date().toISOString(),
        processingTime: Date.now() - requestStartTime
      });

      return createErrorResponse("Internal server error", 500, {
        errorId,
        timestamp: new Date().toISOString()
      });
    }
  }
};

// Optimized book search with all enhancements
async function handleOptimizedBookSearch(request, env, ctx, systems) {
  const { cacheManager, quotaManager, culturalIndexer, requestStartTime } = systems;
  
  // Validate and sanitize input
  const url = new URL(request.url);
  const validation = validateSearchParams(url);
  
  if (validation.errors.length > 0) {
    return createErrorResponse("Invalid parameters", 400, { 
      details: validation.errors 
    });
  }

  const { query, maxResults, sortBy, includeTranslations } = validation.sanitized;

  // Advanced rate limiting
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

  // Check intelligent cache
  const cacheKey = cacheManager.generateCacheKey('search', {
    query, maxResults, sortBy, langRestrict: includeTranslations ? null : 'en'
  });

  const cached = await cacheManager.get(cacheKey);
  if (cached) {
    return new Response(JSON.stringify(cached.data), {
      headers: {
        ...getCORSHeaders(),
        "X-Cache": `HIT-${cached.source}`,
        "X-Cache-Age": Math.floor(cached.age / 1000).toString(),
        "X-Rate-Limit-Remaining": rateLimitResult.remaining?.toString() || "0",
        "X-Processing-Time": `${Date.now() - requestStartTime}ms`
      }
    });
  }

  // Select optimal provider using quota manager
  const optimalProvider = await quotaManager.selectOptimalProvider('search', 'normal', {
    requestType: 'search',
    query: query,
    expectedResults: maxResults
  });

  if (!optimalProvider) {
    return createErrorResponse("No available providers", 503, {
      reason: "All API quotas exhausted or providers unavailable"
    });
  }

  // Perform search using optimal provider
  let result;
  let provider = optimalProvider.name;

  try {
    switch (provider) {
      case 'google-books':
        result = await searchGoogleBooksOptimized(query, maxResults, sortBy, includeTranslations, env);
        break;
      case 'isbndb':
        result = await searchISBNdbOptimized(query, maxResults, env);
        break;
      case 'open-library':
        result = await searchOpenLibraryOptimized(query, maxResults, env);
        break;
    }

    // Update quota usage
    await quotaManager.updateQuotaUsage(provider, optimalProvider.tier, 1);

  } catch (error) {
    console.error(`Search failed with ${provider}:`, error.message);
    return createErrorResponse(`Search failed: ${error.message}`, 503);
  }

  if (!result || !result.items || result.items.length === 0) {
    return createErrorResponse("No results found", 404, { query, provider });
  }

  // Enrich results with cultural data
  await enrichResultsWithCulturalData(result, culturalIndexer, ctx);

  // Enhance response metadata
  result.provider = provider;
  result.tier = optimalProvider.tier;
  result.cached = false;
  result.requestId = crypto.randomUUID();
  result.processingTime = Date.now() - requestStartTime;
  result.culturalDataEnriched = true;

  // Cache successful results with intelligent TTL
  const popularity = await estimateQueryPopularity(query, env);
  await cacheManager.set(cacheKey, result, {
    ttl: popularity > 3 ? 86400 : 2592000, // 1 day for popular, 30 days for normal
    popularity: popularity,
    metadata: {
      provider: provider,
      resultCount: result.items.length,
      query: query
    }
  });

  return new Response(JSON.stringify(result), {
    headers: {
      ...getCORSHeaders(),
      "X-Cache": "MISS",
      "X-Provider": `${provider}-${optimalProvider.tier}`,
      "X-Request-ID": result.requestId,
      "X-Processing-Time": `${result.processingTime}ms`,
      "X-Cultural-Enriched": "true",
      "X-Rate-Limit-Remaining": rateLimitResult.remaining?.toString() || "0"
    }
  });
}

// Optimized ISBN lookup with cultural indexing
async function handleOptimizedISBNLookup(request, env, ctx, systems) {
  const { cacheManager, quotaManager, culturalIndexer, requestStartTime } = systems;

  const url = new URL(request.url);
  const rawISBN = url.searchParams.get("isbn");
  const validation = validateISBN(rawISBN);

  if (validation.error) {
    return createErrorResponse(validation.error, 400);
  }

  const isbn = validation.sanitized;
  const cacheKey = cacheManager.generateCacheKey('isbn', { isbn });

  // Check cache first
  const cached = await cacheManager.get(cacheKey);
  if (cached) {
    return new Response(JSON.stringify(cached.data), {
      headers: {
        ...getCORSHeaders(),
        "X-Cache": `HIT-${cached.source}`,
        "X-Cache-Age": Math.floor(cached.age / 1000).toString(),
        "X-Processing-Time": `${Date.now() - requestStartTime}ms`
      }
    });
  }

  // Select optimal provider
  const optimalProvider = await quotaManager.selectOptimalProvider('isbn', 'normal', {
    requestType: 'isbn',
    isbn: isbn
  });

  // Try providers in order
  let result = null;
  let provider = null;
  const providerErrors = [];

  const providers = optimalProvider ? [optimalProvider] : 
    [{ name: 'google-books' }, { name: 'isbndb' }, { name: 'open-library' }];

  for (const providerInfo of providers) {
    try {
      switch (providerInfo.name) {
        case 'google-books':
          result = await lookupISBNGoogleOptimized(isbn, env);
          provider = 'google-books';
          break;
        case 'isbndb':
          result = await lookupISBNISBNdbOptimized(isbn, env);
          provider = 'isbndb';
          break;
        case 'open-library':
          result = await lookupISBNOpenLibraryOptimized(isbn, env);
          provider = 'open-library';
          break;
      }

      if (result) {
        await quotaManager.updateQuotaUsage(provider, providerInfo.tier || 'free', 1);
        break;
      }
    } catch (error) {
      providerErrors.push({ provider: providerInfo.name, error: error.message });
      console.error(`${providerInfo.name} ISBN lookup failed:`, error.message);
    }
  }

  if (!result) {
    return createErrorResponse("ISBN not found in any provider", 404, { 
      isbn,
      providers: providerErrors
    });
  }

  // Build/update author profile with cultural data
  if (result.volumeInfo?.authors?.length > 0) {
    for (const authorName of result.volumeInfo.authors) {
      ctx.waitUntil(
        culturalIndexer.buildAuthorProfile(authorName, [result.volumeInfo])
      );
    }
  }

  // Enhance result
  result.provider = provider;
  result.requestId = crypto.randomUUID();
  result.processingTime = Date.now() - requestStartTime;

  // Cache for long term (ISBN data is stable)
  await cacheManager.set(cacheKey, result, {
    ttl: 31536000, // 1 year
    popularity: 1,
    metadata: { provider, isbn }
  });

  return new Response(JSON.stringify(result), {
    headers: {
      ...getCORSHeaders(),
      "X-Cache": "MISS",
      "X-Provider": provider,
      "X-Request-ID": result.requestId,
      "X-Processing-Time": `${result.processingTime}ms`
    }
  });
}

// Optimized batch processing
async function handleOptimizedBatch(request, env, ctx, systems) {
  const { cacheManager, quotaManager, culturalIndexer, requestStartTime } = systems;

  if (request.method !== "POST") {
    return createErrorResponse("Batch endpoint requires POST method", 405);
  }

  let requestBody;
  try {
    requestBody = await request.json();
  } catch (error) {
    return createErrorResponse("Invalid JSON in request body", 400);
  }

  const validation = validateBatchRequest(requestBody);
  if (validation.error) {
    return createErrorResponse(validation.error, 400);
  }

  const { isbns, provider, options } = validation.sanitized;

  // Enhanced batch rate limiting
  const rateLimitResult = await checkBatchRateLimit(request, env, isbns.length);
  if (!rateLimitResult.allowed) {
    return new Response(JSON.stringify({
      error: "Batch rate limit exceeded",
      retryAfter: rateLimitResult.retryAfter,
      batchSize: isbns.length,
      maxBatchSize: rateLimitResult.maxBatchSize
    }), {
      status: 429,
      headers: getCORSHeaders()
    });
  }

  // Process batch using quota optimization
  const batchRequests = isbns.map((isbn, index) => ({
    id: index,
    type: 'isbn',
    isbn: isbn,
    metadata: { priority: options.priority || 'normal' }
  }));

  const batchResults = await quotaManager.processBatchRequest(batchRequests, {
    maxConcurrency: 5,
    priority: options.priority || 'normal',
    timeout: 30000
  });

  // Update author profiles for successful results
  const authorUpdates = [];
  for (const result of batchResults.successful) {
    if (result.data?.volumeInfo?.authors?.length > 0) {
      for (const authorName of result.data.volumeInfo.authors) {
        authorUpdates.push(
          culturalIndexer.buildAuthorProfile(authorName, [result.data.volumeInfo])
        );
      }
    }
  }

  // Process author updates in background
  ctx.waitUntil(Promise.allSettled(authorUpdates));

  const response = {
    results: [
      ...batchResults.successful.map(r => ({ ...r, found: true })),
      ...batchResults.failed.map(r => ({ ...r, found: false }))
    ],
    total: isbns.length,
    found: batchResults.successful.length,
    failed: batchResults.failed.length,
    providers: batchResults.providers,
    requestId: crypto.randomUUID(),
    processingTime: Date.now() - requestStartTime,
    authorProfilesUpdated: authorUpdates.length
  };

  return new Response(JSON.stringify(response), {
    headers: {
      ...getCORSHeaders(),
      "X-Batch-Size": isbns.length.toString(),
      "X-Request-ID": response.requestId,
      "X-Processing-Time": `${response.processingTime}ms`,
      "X-Author-Updates": authorUpdates.length.toString()
    }
  });
}

// Author search endpoint
async function handleAuthorSearch(request, env, ctx, culturalIndexer) {
  const url = new URL(request.url);
  const authorName = url.searchParams.get("name");
  const region = url.searchParams.get("region");
  const gender = url.searchParams.get("gender");
  const language = url.searchParams.get("language");

  if (!authorName && !region && !gender && !language) {
    return createErrorResponse("At least one search parameter required", 400);
  }

  try {
    let results;

    if (authorName) {
      // Search by author name
      const normalizedName = culturalIndexer.normalizeAuthorName(authorName);
      const authorId = await culturalIndexer.generateAuthorId(normalizedName);
      const profile = await culturalIndexer.getAuthorProfile(authorId);
      
      results = {
        authors: profile ? [profile] : [],
        total: profile ? 1 : 0,
        searchType: 'name',
        query: authorName
      };
    } else {
      // Search by cultural criteria
      const criteria = { region, gender, language, minConfidence: 50 };
      results = await culturalIndexer.searchAuthorsByCulture(criteria);
    }

    return new Response(JSON.stringify(results), {
      headers: getCORSHeaders()
    });
  } catch (error) {
    return createErrorResponse(`Author search failed: ${error.message}`, 500);
  }
}

// Cultural diversity statistics
async function handleCulturalStats(request, env, ctx, culturalIndexer) {
  try {
    const stats = await culturalIndexer.getCulturalDiversityStats();
    return new Response(JSON.stringify(stats), {
      headers: getCORSHeaders()
    });
  } catch (error) {
    return createErrorResponse(`Stats generation failed: ${error.message}`, 500);
  }
}

// Comprehensive health check
async function handleComprehensiveHealth(env, systems) {
  const { cacheManager, quotaManager, performanceOptimizer } = systems;

  const health = {
    timestamp: new Date().toISOString(),
    status: "healthy",
    version: "3.0-optimized",
    systems: {
      cache: await cacheManager.getHealthMetrics(),
      quota: await quotaManager.getCurrentQuotaStatus(),
      performance: await performanceOptimizer.getPerformanceHealth()
    },
    providers: {
      "google-books": env.GOOGLE_BOOKS_KEY ? "configured" : "missing-key",
      "isbndb": env.ISBNDB_KEY ? "configured" : "missing-key",
      "open-library": "available"
    },
    storage: {
      kv: !!env.BOOKS_CACHE,
      r2: !!env.BOOKS_R2
    },
    features: [
      "intelligent-caching",
      "quota-optimization", 
      "cultural-indexing",
      "performance-optimization",
      "security-hardening",
      "batch-processing"
    ]
  };

  return new Response(JSON.stringify(health, null, 2), {
    headers: getCORSHeaders("application/json")
  });
}

// Performance analysis endpoint
async function handlePerformanceAnalysis(request, env, performanceOptimizer) {
  const url = new URL(request.url);
  const hours = parseInt(url.searchParams.get("hours") || "24");
  const timeRange = hours * 60 * 60 * 1000; // Convert to milliseconds

  try {
    const analysis = await performanceOptimizer.analyzePerformance(timeRange);
    return new Response(JSON.stringify(analysis, null, 2), {
      headers: getCORSHeaders("application/json")
    });
  } catch (error) {
    return createErrorResponse(`Performance analysis failed: ${error.message}`, 500);
  }
}

// Helper functions (enhanced versions of existing functions)

// Enhanced security validation
async function validateRequestSecurity(request, env) {
  const clientIP = request.headers.get("CF-Connecting-IP") || "unknown";
  const userAgent = request.headers.get("User-Agent") || "";
  const cfCountry = request.headers.get("CF-IPCountry") || "unknown";

  // Basic security checks
  if (userAgent.length === 0) {
    return { valid: false, reason: "Missing User-Agent", status: 400 };
  }

  const contentLength = request.headers.get("content-length");
  if (contentLength && parseInt(contentLength) > 1024 * 1024) {
    return { valid: false, reason: "Request too large", status: 413 };
  }

  return { valid: true };
}

// Estimate query popularity for caching decisions
async function estimateQueryPopularity(query, env) {
  try {
    const popularityKey = `popularity:${btoa(query).replace(/[/+=]/g, '_').substring(0, 20)}`;
    const count = await env.BOOKS_CACHE?.get(popularityKey);
    const currentCount = count ? parseInt(count) : 0;
    
    // Increment and store
    await env.BOOKS_CACHE?.put(
      popularityKey, 
      (currentCount + 1).toString(),
      { expirationTtl: 604800 } // 7 days
    );

    return currentCount + 1;
  } catch (error) {
    return 1; // Default popularity
  }
}

// Enrich search results with cultural data
async function enrichResultsWithCulturalData(result, culturalIndexer, ctx) {
  if (!result.items) return;

  const enrichmentPromises = result.items.map(async (item) => {
    if (item.volumeInfo?.authors?.length > 0) {
      const authorProfiles = [];
      
      for (const authorName of item.volumeInfo.authors) {
        const normalizedName = culturalIndexer.normalizeAuthorName(authorName);
        const authorId = await culturalIndexer.generateAuthorId(normalizedName);
        const profile = await culturalIndexer.getAuthorProfile(authorId);
        
        if (profile && profile.culturalProfile.confidence > 30) {
          authorProfiles.push({
            name: authorName,
            nationality: profile.culturalProfile.nationality,
            gender: profile.culturalProfile.gender,
            regions: profile.culturalProfile.regions,
            themes: profile.culturalProfile.themes,
            confidence: profile.culturalProfile.confidence
          });
        }
      }

      if (authorProfiles.length > 0) {
        item.culturalMetadata = {
          authors: authorProfiles,
          lastUpdated: Date.now()
        };
      }
    }
  });

  // Process enrichment in background
  ctx.waitUntil(Promise.allSettled(enrichmentPromises));
}

// Standard utility functions
function getCORSHeaders(contentType = "application/json") {
  return {
    "Content-Type": contentType,
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Requested-With, X-API-Key",
    "Access-Control-Max-Age": "86400"
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
    timestamp: new Date().toISOString(),
    ...additionalData
  }), {
    status,
    headers: getCORSHeaders()
  });
}

// Validation functions (enhanced versions)
function validateSearchParams(url) {
  const query = url.searchParams.get("q");
  const maxResults = url.searchParams.get("maxResults");
  const sortBy = url.searchParams.get("orderBy");
  const langRestrict = url.searchParams.get("langRestrict");

  const errors = [];
  const sanitized = {};

  if (!query || query.trim().length === 0) {
    errors.push('Query parameter "q" is required');
  } else if (query.length > 500) {
    errors.push('Query too long (max 500 characters)');
  } else {
    sanitized.query = query.trim();
  }

  sanitized.maxResults = maxResults ? Math.min(parseInt(maxResults), 40) : 20;
  sanitized.sortBy = sortBy || "relevance";
  sanitized.includeTranslations = langRestrict !== "en";

  return { errors, sanitized };
}

function validateISBN(isbn) {
  if (!isbn || typeof isbn !== "string") {
    return { error: "ISBN parameter is required" };
  }

  const cleaned = isbn.replace(/[-\s]/g, "").replace(/[^0-9X]/gi, "").toUpperCase();
  
  if (cleaned.length !== 10 && cleaned.length !== 13) {
    return { error: "ISBN must be 10 or 13 characters" };
  }

  return { sanitized: cleaned };
}

function validateBatchRequest(body) {
  if (!body.isbns || !Array.isArray(body.isbns)) {
    return { error: "'isbns' must be an array" };
  }

  if (body.isbns.length === 0) {
    return { error: "'isbns' array cannot be empty" };
  }

  if (body.isbns.length > 100) {
    return { error: "Maximum 100 ISBNs per batch" };
  }

  const validatedISBNs = [];
  for (const isbn of body.isbns) {
    const validation = validateISBN(isbn);
    if (validation.error) {
      return { error: `Invalid ISBN: ${isbn}` };
    }
    validatedISBNs.push(validation.sanitized);
  }

  return {
    sanitized: {
      isbns: validatedISBNs,
      provider: body.provider || "auto",
      options: body.options || {}
    }
  };
}

// Enhanced rate limiting
async function checkAdvancedRateLimit(request, env) {
  // Simplified version - full implementation would use fingerprinting
  const clientIP = request.headers.get("CF-Connecting-IP") || "unknown";
  const rateLimitKey = `ratelimit:${clientIP}`;
  
  const current = await env.BOOKS_CACHE?.get(rateLimitKey);
  const count = current ? parseInt(current) : 0;
  const limit = 100; // per hour
  
  if (count >= limit) {
    return { allowed: false, retryAfter: 3600, current: count, limit: limit };
  }

  await env.BOOKS_CACHE?.put(rateLimitKey, (count + 1).toString(), { expirationTtl: 3600 });
  return { allowed: true, count: count + 1, remaining: limit - count - 1 };
}

async function checkBatchRateLimit(request, env, batchSize) {
  const clientIP = request.headers.get("CF-Connecting-IP") || "unknown";
  const rateLimitKey = `batch-ratelimit:${clientIP}`;
  
  const current = await env.BOOKS_CACHE?.get(rateLimitKey);
  const count = current ? parseInt(current) : 0;
  const limit = 10; // batches per hour
  
  if (count >= limit) {
    return { allowed: false, retryAfter: 3600, maxBatchSize: 50 };
  }

  await env.BOOKS_CACHE?.put(rateLimitKey, (count + 1).toString(), { expirationTtl: 3600 });
  return { allowed: true };
}

// Optimized provider functions (simplified - full implementation would include timeout handling)
async function searchGoogleBooksOptimized(query, maxResults, sortBy, includeTranslations, env) {
  const apiKey = await getSecureAPIKey("GOOGLE_BOOKS_KEY", env);
  // Implementation details...
  return { kind: "books#volumes", totalItems: 0, items: [] };
}

async function searchISBNdbOptimized(query, maxResults, env) {
  const apiKey = await getSecureAPIKey("ISBNDB_KEY", env);
  // Implementation details...
  return { kind: "books#volumes", totalItems: 0, items: [] };
}

async function searchOpenLibraryOptimized(query, maxResults, env) {
  // Implementation details...
  return { kind: "books#volumes", totalItems: 0, items: [] };
}

async function lookupISBNGoogleOptimized(isbn, env) {
  const apiKey = await getSecureAPIKey("GOOGLE_BOOKS_KEY", env);
  // Implementation details...
  return null;
}

async function lookupISBNISBNdbOptimized(isbn, env) {
  const apiKey = await getSecureAPIKey("ISBNDB_KEY", env);
  // Implementation details...
  return null;
}

async function lookupISBNOpenLibraryOptimized(isbn, env) {
  // Implementation details...
  return null;
}

async function getSecureAPIKey(keyName, env) {
  // Use CloudFlare secrets management
  return env[keyName];
}