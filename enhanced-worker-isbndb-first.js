// Enhanced Cloudflare Worker - ISBNdb First with Provider Routing
// Priority: ISBNdb → Google Books → Open Library
// Supports explicit provider routing via ?provider= parameter

export default {
  async fetch(request, env, ctx) {
    if (request.method === "OPTIONS") {
      return handleCORS();
    }
    
    try {
      const url = new URL(request.url);
      const path = url.pathname;
      
      if (path === "/search") {
        return await handleBookSearch(request, env, ctx);
      } else if (path === "/isbn") {
        return await handleISBNLookup(request, env, ctx);
      } else if (path === "/health") {
        return new Response(JSON.stringify({
          status: "healthy",
          timestamp: (new Date()).toISOString(),
          providers: ["isbndb", "google-books", "open-library"],
          priority: "ISBNdb → Google Books → Open Library",
          cache: {
            system: env.BOOKS_R2 ? "R2+KV-Hybrid" : "KV-Only",
            kv: env.BOOKS_CACHE ? "available" : "missing",
            r2: env.BOOKS_R2 ? "available" : "missing"
          }
        }), {
          headers: getCORSHeaders("application/json")
        });
      } else {
        return new Response(JSON.stringify({ error: "Endpoint not found" }), {
          status: 404,
          headers: getCORSHeaders("application/json")
        });
      }
    } catch (error) {
      console.error("Worker error:", error);
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

function getCORSHeaders(contentType = "application/json") {
  return {
    "Content-Type": contentType,
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Requested-With",
    "Access-Control-Max-Age": "86400"
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
  const provider = url.searchParams.get("provider"); // NEW: Provider routing
  
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
  
  // NEW: Provider validation
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
  
  const current = await env.BOOKS_CACHE?.get(rateLimitKey);
  const count = current ? parseInt(current) : 0;
  
  if (count >= maxRequests) {
    return {
      allowed: false,
      retryAfter: windowSize,
      reason: "Rate limit exceeded"
    };
  }
  
  const newCount = count + 1;
  await env.BOOKS_CACHE?.put(rateLimitKey, newCount.toString(), { expirationTtl: windowSize });
  
  return {
    allowed: true,
    count: newCount,
    remaining: maxRequests - newCount
  };
}

const CACHE_KEYS = {
  search: (query, maxResults, sortBy, translations, provider) => 
    `search/${btoa(query).replace(/[/+=]/g, "_")}/${maxResults}/${sortBy}/${translations}/${provider}.json`,
  isbn: (isbn, provider) => `isbn/${isbn}/${provider}.json`
};

async function getCachedData(cacheKey, env) {
  try {
    // Check KV (hot cache) first
    const kvData = await env.BOOKS_CACHE?.get(cacheKey);
    if (kvData) {
      return {
        data: JSON.parse(kvData),
        source: "KV-HOT"
      };
    }
    
    // Check R2 (cold cache) if available
    if (env.BOOKS_R2) {
      const r2Object = await env.BOOKS_R2.get(cacheKey);
      if (r2Object) {
        const jsonData = await r2Object.text();
        const data = JSON.parse(jsonData);
        
        // Check TTL
        const metadata = r2Object.customMetadata;
        if (metadata?.ttl && Date.now() > parseInt(metadata.ttl)) {
          await env.BOOKS_R2.delete(cacheKey);
          return null;
        }
        
        // Promote to KV cache
        const promoteData = JSON.stringify(data);
        env.waitUntil(env.BOOKS_CACHE?.put(cacheKey, promoteData, { expirationTtl: 86400 }));
        
        return {
          data,
          source: "R2-COLD"
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
  } catch (error) {
    console.warn(`Cache write error for key ${cacheKey}:`, error.message);
  }
}

// NEW: Enhanced search handler with provider routing
async function handleBookSearch(request, env, ctx) {
  const url = new URL(request.url);
  const validation = validateSearchParams(url);
  
  if (validation.errors.length > 0) {
    return new Response(JSON.stringify({
      error: "Invalid parameters",
      details: validation.errors
    }), {
      status: 400,
      headers: getCORSHeaders()
    });
  }
  
  const { query, maxResults, sortBy, includeTranslations, provider } = validation.sanitized;
  
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
  
  const cacheKey = CACHE_KEYS.search(query, maxResults, sortBy, includeTranslations, provider);
  const cached = await getCachedData(cacheKey, env);
  if (cached) {
    return new Response(JSON.stringify(cached.data), {
      headers: {
        ...getCORSHeaders(),
        "X-Cache": `HIT-${cached.source}`,
        "X-Cache-Source": cached.source
      }
    });
  }
  
  let result = null;
  let usedProvider = null;
  
  // NEW: Provider routing logic
  if (provider === "isbndb") {
    // Force ISBNdb only
    try {
      result = await searchISBNdb(query, maxResults, env);
      usedProvider = "isbndb";
    } catch (error) {
      console.error("Forced ISBNdb search failed:", error.message);
    }
  } else if (provider === "google") {
    // Force Google Books only
    try {
      result = await searchGoogleBooks(query, maxResults, sortBy, includeTranslations, env);
      usedProvider = "google-books";
    } catch (error) {
      console.error("Forced Google Books search failed:", error.message);
    }
  } else if (provider === "openlibrary") {
    // Force Open Library only
    try {
      result = await searchOpenLibrary(query, maxResults, env);
      usedProvider = "open-library";
    } catch (error) {
      console.error("Forced Open Library search failed:", error.message);
    }
  } else {
    // Auto mode: ISBNdb → Google Books → Open Library (NEW PRIORITY ORDER)
    
    // 1. Try ISBNdb FIRST
    try {
      result = await searchISBNdb(query, maxResults, env);
      usedProvider = "isbndb";
      console.log("✅ ISBNdb search successful");
    } catch (error) {
      console.error("ISBNdb failed:", error.message);
    }
    
    // 2. Fallback to Google Books if ISBNdb failed or returned no results
    if (!result || result.items?.length === 0) {
      try {
        result = await searchGoogleBooks(query, maxResults, sortBy, includeTranslations, env);
        usedProvider = "google-books";
        console.log("📚 Google Books fallback used");
      } catch (error) {
        console.error("Google Books failed:", error.message);
      }
    }
    
    // 3. Final fallback to Open Library
    if (!result || result.items?.length === 0) {
      try {
        result = await searchOpenLibrary(query, maxResults, env);
        usedProvider = "open-library";
        console.log("📖 Open Library fallback used");
      } catch (error) {
        console.error("Open Library failed:", error.message);
      }
    }
  }
  
  if (!result) {
    return new Response(JSON.stringify({
      error: "All book providers failed",
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
  if (result.items?.length > 0) {
    setCachedData(cacheKey, result, 2592000, env, ctx); // 30 days
  }
  
  return new Response(response, {
    headers: {
      ...getCORSHeaders(),
      "X-Cache": "MISS",
      "X-Provider": usedProvider,
      "X-Cache-System": env.BOOKS_R2 ? "R2+KV-Hybrid" : "KV-Only",
      "X-Rate-Limit-Remaining": rateLimitResult.remaining.toString()
    }
  });
}

// NEW: Enhanced ISBN lookup with provider routing
async function handleISBNLookup(request, env, ctx) {
  const url = new URL(request.url);
  const rawISBN = url.searchParams.get("isbn");
  const provider = url.searchParams.get("provider") || "auto";
  
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
  const cacheKey = CACHE_KEYS.isbn(isbn, provider);
  const cached = await getCachedData(cacheKey, env);
  if (cached) {
    return new Response(JSON.stringify(cached.data), {
      headers: {
        ...getCORSHeaders(),
        "X-Cache": `HIT-${cached.source}`,
        "X-Cache-Source": cached.source
      }
    });
  }
  
  let result = null;
  let usedProvider = null;
  
  // Provider routing for ISBN lookup
  if (provider === "isbndb") {
    // Force ISBNdb only
    try {
      result = await lookupISBNISBNdb(isbn, env);
      usedProvider = "isbndb";
    } catch (error) {
      console.error("Forced ISBNdb ISBN lookup failed:", error.message);
    }
  } else if (provider === "google") {
    // Force Google Books only
    try {
      result = await lookupISBNGoogle(isbn, env);
      usedProvider = "google-books";
    } catch (error) {
      console.error("Forced Google Books ISBN lookup failed:", error.message);
    }
  } else if (provider === "openlibrary") {
    // Force Open Library only
    try {
      result = await lookupISBNOpenLibrary(isbn, env);
      usedProvider = "open-library";
    } catch (error) {
      console.error("Forced Open Library ISBN lookup failed:", error.message);
    }
  } else {
    // Auto mode: ISBNdb → Google Books → Open Library (NEW PRIORITY ORDER)
    
    // 1. Try ISBNdb FIRST
    try {
      result = await lookupISBNISBNdb(isbn, env);
      usedProvider = "isbndb";
      console.log("✅ ISBNdb ISBN lookup successful");
    } catch (error) {
      console.error("ISBNdb ISBN lookup failed:", error.message);
    }
    
    // 2. Fallback to Google Books
    if (!result) {
      try {
        result = await lookupISBNGoogle(isbn, env);
        usedProvider = "google-books";
        console.log("📚 Google Books ISBN fallback used");
      } catch (error) {
        console.error("Google Books ISBN lookup failed:", error.message);
      }
    }
    
    // 3. Final fallback to Open Library
    if (!result) {
      try {
        result = await lookupISBNOpenLibrary(isbn, env);
        usedProvider = "open-library";
        console.log("📖 Open Library ISBN fallback used");
      } catch (error) {
        console.error("Open Library ISBN lookup failed:", error.message);
      }
    }
  }
  
  if (!result) {
    return new Response(JSON.stringify({
      error: "ISBN not found in any provider",
      isbn
    }), {
      status: 404,
      headers: getCORSHeaders()
    });
  }
  
  result.provider = usedProvider;
  
  const response = JSON.stringify(result);
  setCachedData(cacheKey, result, 31536000, env, ctx); // 1 year for ISBN lookups
  
  return new Response(response, {
    headers: {
      ...getCORSHeaders(),
      "X-Cache": "MISS",
      "X-Provider": usedProvider,
      "X-Cache-System": env.BOOKS_R2 ? "R2+KV-Hybrid" : "KV-Only"
    }
  });
}

// Provider Functions (ISBNdb functions come first now)

// ISBNdb Search (PRIMARY PROVIDER)
async function searchISBNdb(query, maxResults, env) {
  const apiKey = env.ISBNdb1;
  if (!apiKey) {
    throw new Error("ISBNdb API key not configured (ISBNdb1)");
  }
  
  const baseUrl = "https://api2.isbndb.com";
  const endpoint = query.match(/^\d{10}(\d{3})?$/) ? `/book/${query}` : `/books/${encodeURIComponent(query)}`;
  
  const params = new URLSearchParams({
    pageSize: Math.min(maxResults, 20).toString(), // ISBNdb has limits
    page: "1"
  });
  
  const url = `${baseUrl}${endpoint}?${params}`;
  
  const response = await fetch(url, {
    headers: {
      "X-API-KEY": apiKey,
      "Content-Type": "application/json"
    },
    // Add timeout for ISBNdb
    timeout: 15000
  });
  
  if (!response.ok) {
    throw new Error(`ISBNdb API error: ${response.status} - ${response.statusText}`);
  }
  
  const data = await response.json();
  const books = data.books || [data.book].filter(Boolean);
  
  return {
    kind: "books#volumes",
    totalItems: data.total || books.length,
    items: books.map((book) => ({
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
}

// ISBNdb ISBN Lookup (PRIMARY PROVIDER)
async function lookupISBNISBNdb(isbn, env) {
  const apiKey = env.ISBNdb1;
  if (!apiKey) {
    throw new Error("ISBNdb API key not configured (ISBNdb1)");
  }
  
  const response = await fetch(`https://api2.isbndb.com/book/${isbn}`, {
    headers: {
      "X-API-KEY": apiKey,
      "Content-Type": "application/json"
    },
    timeout: 15000
  });
  
  if (!response.ok) {
    if (response.status === 404) {
      return null;
    }
    throw new Error(`ISBNdb ISBN API error: ${response.status} - ${response.statusText}`);
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
}

// Google Books Search (SECONDARY PROVIDER)
async function searchGoogleBooks(query, maxResults, sortBy, includeTranslations, env) {
  const apiKey = env.google1 || env.google2;
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
  
  const response = await fetch(`https://www.googleapis.com/books/v1/volumes?${params}`, {
    timeout: 10000
  });
  
  if (!response.ok) {
    throw new Error(`Google Books API error: ${response.status}`);
  }
  
  return await response.json();
}

// Google Books ISBN Lookup (SECONDARY PROVIDER)
async function lookupISBNGoogle(isbn, env) {
  const apiKey = env.google1 || env.google2;
  const params = new URLSearchParams({
    q: `isbn:${isbn}`,
    maxResults: "1",
    printType: "books",
    projection: "full",
    key: apiKey
  });
  
  const response = await fetch(`https://www.googleapis.com/books/v1/volumes?${params}`, {
    timeout: 10000
  });
  
  if (!response.ok) {
    throw new Error(`Google Books ISBN API error: ${response.status}`);
  }
  
  const data = await response.json();
  return data.items?.[0] || null;
}

// Open Library Search (TERTIARY PROVIDER)
async function searchOpenLibrary(query, maxResults, env) {
  const params = new URLSearchParams({
    q: query,
    limit: maxResults.toString(),
    fields: "key,title,author_name,first_publish_year,isbn,publisher,language,subject,cover_i,edition_count",
    format: "json"
  });
  
  const response = await fetch(`https://openlibrary.org/search.json?${params}`, {
    timeout: 20000
  });
  
  if (!response.ok) {
    throw new Error(`Open Library API error: ${response.status}`);
  }
  
  const data = await response.json();
  
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

// Open Library ISBN Lookup (TERTIARY PROVIDER)
async function lookupISBNOpenLibrary(isbn, env) {
  const response = await fetch(`https://openlibrary.org/api/books?bibkeys=ISBN:${isbn}&format=json&jscmd=data`, {
    timeout: 20000
  });
  
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