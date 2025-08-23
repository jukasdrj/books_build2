// CloudFlare Workers Proxy with Batch Support for ISBNdb Premium/Pro Plans
// Enhanced version supporting both single and batch ISBN lookups

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
        case "/batch":  // NEW: Batch endpoint
          return await handleBatchLookup(request, env, ctx);
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

// NEW: Batch lookup handler
async function handleBatchLookup(request, env, ctx) {
  // Only allow POST for batch requests
  if (request.method !== "POST") {
    return createErrorResponse("Batch endpoint requires POST method", 405);
  }

  const contentType = request.headers.get("content-type");
  if (!contentType || !contentType.includes("application/json")) {
    return createErrorResponse("Content-Type must be application/json", 400);
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

  // Rate limiting for batch requests (stricter limits)
  const rateLimitResult = await checkBatchRateLimit(request, env, isbns.length);
  if (!rateLimitResult.allowed) {
    return new Response(JSON.stringify({
      error: "Batch rate limit exceeded",
      retryAfter: rateLimitResult.retryAfter,
      batchSize: isbns.length,
      maxBatchSize: rateLimitResult.maxBatchSize
    }), {
      status: 429,
      headers: {
        ...getCORSHeaders(),
        "Retry-After": rateLimitResult.retryAfter.toString()
      }
    });
  }

  // Check cache for batch items
  const { cachedResults, uncachedISBNs } = await checkBatchCache(isbns, provider, env);

  let batchResults = [...cachedResults];
  let actualProvider = provider;

  // Process uncached ISBNs
  if (uncachedISBNs.length > 0) {
    try {
      const freshResults = await processBatchLookup(uncachedISBNs, provider, options, env);
      batchResults.push(...freshResults.results);
      actualProvider = freshResults.provider;

      // Cache fresh results
      for (const result of freshResults.results) {
        if (result.found) {
          const cacheKey = CACHE_KEYS.isbn(result.isbn, provider);
          setCachedData(cacheKey, result.data, 31536000, env, ctx); // 1 year cache
        }
      }
    } catch (error) {
      console.error("Batch lookup failed:", error.message);
      
      // Return partial results if we have cached data
      if (cachedResults.length > 0) {
        return new Response(JSON.stringify({
          results: batchResults,
          partial: true,
          error: `Batch lookup failed: ${error.message}`,
          cached: cachedResults.length,
          failed: uncachedISBNs.length,
          provider: actualProvider,
          requestId: crypto.randomUUID()
        }), {
          status: 207, // Multi-status for partial success
          headers: {
            ...getCORSHeaders(),
            "X-Cache": "PARTIAL",
            "X-Provider": actualProvider
          }
        });
      } else {
        return createErrorResponse(`Batch lookup failed: ${error.message}`, 503);
      }
    }
  }

  const response = {
    results: batchResults,
    total: isbns.length,
    found: batchResults.filter(r => r.found).length,
    cached: cachedResults.length,
    fresh: batchResults.length - cachedResults.length,
    provider: actualProvider,
    requestId: crypto.randomUUID(),
    batchSize: isbns.length,
    processingTime: Date.now() - request.startTime || 0
  };

  return new Response(JSON.stringify(response), {
    headers: {
      ...getCORSHeaders(),
      "X-Cache": cachedResults.length === isbns.length ? "HIT-FULL" : "MIXED",
      "X-Provider": actualProvider,
      "X-Batch-Size": isbns.length.toString(),
      "X-Request-ID": response.requestId
    }
  });
}

// Validate batch request
function validateBatchRequest(body) {
  const errors = [];
  const sanitized = {};

  // Validate ISBNs array
  if (!body.isbns || !Array.isArray(body.isbns)) {
    errors.push("'isbns' must be an array");
  } else if (body.isbns.length === 0) {
    errors.push("'isbns' array cannot be empty");
  } else if (body.isbns.length > 100) { // Reasonable batch limit
    errors.push("'isbns' array cannot exceed 100 items");
  } else {
    // Validate and clean each ISBN
    const validatedISBNs = [];
    for (let i = 0; i < body.isbns.length; i++) {
      const isbn = body.isbns[i];
      const validation = validateISBN(isbn);
      if (validation.error) {
        errors.push(`ISBN at index ${i}: ${validation.error}`);
      } else {
        validatedISBNs.push(validation.sanitized);
      }
    }
    sanitized.isbns = validatedISBNs;
  }

  // Validate provider (optional)
  if (body.provider) {
    const validProviders = ["google", "google-books", "isbndb", "openlibrary", "open-library"];
    if (!validProviders.includes(body.provider.toLowerCase())) {
      errors.push(`Provider must be one of: ${validProviders.join(", ")}`);
    } else {
      sanitized.provider = body.provider.toLowerCase();
    }
  } else {
    sanitized.provider = "auto"; // Default to automatic provider selection
  }

  // Validate options (optional)
  sanitized.options = {
    includeMetadata: body.options?.includeMetadata ?? true,
    includePrices: body.options?.includePrices ?? false,
    timeout: Math.min(body.options?.timeout ?? 30, 60) // Max 60 seconds
  };

  if (errors.length > 0) {
    return { error: errors.join("; ") };
  }

  return { sanitized };
}

// Enhanced rate limiting for batch requests
async function checkBatchRateLimit(request, env, batchSize) {
  const clientIP = request.headers.get("CF-Connecting-IP") || "unknown";
  const userAgent = request.headers.get("User-Agent") || "unknown";
  const userFingerprint = await generateUserFingerprint(clientIP, userAgent, "");
  
  const rateLimitKey = `batch-ratelimit:${userFingerprint}`;
  const windowSize = 3600; // 1 hour window
  
  // Dynamic limits based on batch size and user type
  let maxBatchesPerHour = 10; // Conservative default
  let maxItemsPerHour = 500;  // Total items across all batches
  
  if (userAgent.includes("BooksTrack-iOS")) {
    maxBatchesPerHour = 50;    // Higher limit for the app
    maxItemsPerHour = 2000;    // Higher item limit
  }

  // Check batch count limit
  const batchCountKey = `${rateLimitKey}:count`;
  const currentBatches = await env.BOOKS_CACHE?.get(batchCountKey);
  const batchCount = currentBatches ? parseInt(currentBatches) : 0;

  if (batchCount >= maxBatchesPerHour) {
    return {
      allowed: false,
      retryAfter: windowSize,
      reason: "Batch count limit exceeded",
      maxBatchSize: Math.floor(maxItemsPerHour / maxBatchesPerHour)
    };
  }

  // Check total items limit
  const itemCountKey = `${rateLimitKey}:items`;
  const currentItems = await env.BOOKS_CACHE?.get(itemCountKey);
  const itemCount = currentItems ? parseInt(currentItems) : 0;

  if (itemCount + batchSize > maxItemsPerHour) {
    return {
      allowed: false,
      retryAfter: windowSize,
      reason: "Item count limit exceeded",
      maxBatchSize: maxItemsPerHour - itemCount
    };
  }

  // Update counters
  await env.BOOKS_CACHE?.put(batchCountKey, (batchCount + 1).toString(), { expirationTtl: windowSize });
  await env.BOOKS_CACHE?.put(itemCountKey, (itemCount + batchSize).toString(), { expirationTtl: windowSize });

  return {
    allowed: true,
    remaining: maxBatchesPerHour - batchCount - 1,
    itemsRemaining: maxItemsPerHour - itemCount - batchSize
  };
}

// Check cache for batch items
async function checkBatchCache(isbns, provider, env) {
  const cachedResults = [];
  const uncachedISBNs = [];

  for (const isbn of isbns) {
    const cacheKey = CACHE_KEYS.isbn(isbn, provider);
    const cached = await getCachedData(cacheKey, env);
    
    if (cached) {
      cachedResults.push({
        isbn: isbn,
        found: true,
        data: cached.data,
        source: cached.source
      });
    } else {
      uncachedISBNs.push(isbn);
    }
  }

  return { cachedResults, uncachedISBNs };
}

// Process batch lookup with provider-specific logic
async function processBatchLookup(isbns, provider, options, env) {
  const results = [];
  let actualProvider = provider;

  if (provider === "isbndb" || provider === "auto") {
    // Try ISBNdb batch API first (Premium/Pro plans only)
    try {
      const batchResults = await batchLookupISBNdb(isbns, options, env);
      actualProvider = "isbndb";
      return { results: batchResults, provider: actualProvider };
    } catch (error) {
      console.error("ISBNdb batch lookup failed:", error.message);
      
      if (provider === "isbndb") {
        // If ISBNdb was specifically requested and failed, throw error
        throw new Error(`ISBNdb batch lookup failed: ${error.message}`);
      }
      // If auto mode, fall back to individual lookups
    }
  }

  // Fallback: Individual lookups with concurrency control
  const concurrencyLimit = 5; // Max concurrent requests
  const semaphore = new Array(concurrencyLimit).fill(0);
  
  const lookupPromises = isbns.map(async (isbn) => {
    // Wait for available slot
    await new Promise(resolve => {
      const checkSlot = () => {
        const freeSlot = semaphore.findIndex(slot => slot === 0);
        if (freeSlot !== -1) {
          semaphore[freeSlot] = 1;
          resolve(freeSlot);
        } else {
          setTimeout(checkSlot, 10);
        }
      };
      checkSlot();
    });

    try {
      const result = await lookupIndividualISBN(isbn, provider, env);
      return {
        isbn: isbn,
        found: !!result,
        data: result
      };
    } catch (error) {
      console.error(`Individual ISBN lookup failed for ${isbn}:`, error.message);
      return {
        isbn: isbn,
        found: false,
        error: error.message
      };
    } finally {
      // Release slot
      const usedSlot = semaphore.findIndex(slot => slot === 1);
      if (usedSlot !== -1) semaphore[usedSlot] = 0;
    }
  });

  const batchResults = await Promise.all(lookupPromises);
  actualProvider = provider === "auto" ? "google-books" : provider;
  
  return { results: batchResults, provider: actualProvider };
}

// ISBNdb batch lookup (Premium/Pro plans)
async function batchLookupISBNdb(isbns, options, env) {
  const apiKey = env.ISBNdb1;
  if (!apiKey) {
    throw new Error("ISBNdb API key not configured");
  }

  // ISBNdb batch endpoint - this may need to be adjusted based on actual API
  const batchPayload = {
    isbns: isbns,
    details: options.includeMetadata,
    prices: options.includePrices
  };

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), (options.timeout || 30) * 1000);

  try {
    // Note: This endpoint structure is hypothetical - adjust based on actual ISBNdb batch API
    const response = await fetch(`https://api2.isbndb.com/books/batch`, {
      method: 'POST',
      signal: controller.signal,
      headers: {
        "X-API-KEY": apiKey,
        "Content-Type": "application/json",
        'User-Agent': 'CloudflareWorker/2.1 BookSearchProxy'
      },
      body: JSON.stringify(batchPayload)
    });

    clearTimeout(timeoutId);

    if (!response.ok) {
      throw new Error(`ISBNdb batch API error: ${response.status}`);
    }

    const data = await response.json();
    
    // Transform ISBNdb batch response to our format
    return isbns.map(isbn => {
      const bookData = data.books?.find(book => 
        book.isbn13 === isbn || book.isbn === isbn
      );
      
      if (bookData) {
        return {
          isbn: isbn,
          found: true,
          data: transformISBNdbToBookMetadata(bookData)
        };
      } else {
        return {
          isbn: isbn,
          found: false,
          error: "Not found in ISBNdb"
        };
      }
    });

  } catch (error) {
    clearTimeout(timeoutId);
    if (error.name === 'AbortError') {
      throw new Error('ISBNdb batch API request timeout');
    }
    throw error;
  }
}

// Individual ISBN lookup (fallback)
async function lookupIndividualISBN(isbn, provider, env) {
  if (provider === "auto" || provider === "google" || provider === "google-books") {
    return await lookupISBNGoogle(isbn, env);
  } else if (provider === "isbndb") {
    return await lookupISBNISBNdb(isbn, env);
  } else if (provider === "openlibrary" || provider === "open-library") {
    return await lookupISBNOpenLibrary(isbn, env);
  } else {
    throw new Error(`Unknown provider: ${provider}`);
  }
}

// Transform ISBNdb response to our BookMetadata format
function transformISBNdbToBookMetadata(book) {
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
}

// Enhanced health check with batch capabilities
async function handleHealthCheck(env) {
  const checks = {
    timestamp: new Date().toISOString(),
    status: "healthy",
    version: "2.2-batch",
    features: {
      singleLookup: "enabled",
      batchLookup: "enabled",
      providerRouting: "enabled",
      rateLimit: "enabled",
      caching: "enabled"
    },
    providers: {
      "google-books": await testProvider("google-books", env),
      "isbndb": await testProvider("isbndb", env),
      "open-library": await testProvider("open-library", env)
    },
    batch: {
      maxBatchSize: 100,
      supportedProviders: ["isbndb", "google-books", "open-library"],
      rateLimit: {
        maxBatchesPerHour: 50,
        maxItemsPerHour: 2000
      }
    },
    endpoints: [
      "GET /search?q={query}&provider={provider}",
      "GET /isbn?isbn={isbn}&provider={provider}",
      "POST /batch (JSON: {isbns: [isbn1, isbn2...], provider?, options?})",
      "GET /health"
    ]
  };

  return new Response(JSON.stringify(checks, null, 2), {
    headers: getCORSHeaders("application/json")
  });
}

// Helper functions and existing implementations would continue here...
// [Include all the existing utility functions from previous versions]

// Updated CORS to support POST requests
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

// Continue with existing implementations...
// [All existing functions from proxy-enhanced-routing.js would be included here]