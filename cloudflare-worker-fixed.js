// Fixed Cloudflare Worker Code - ISBNdb integration corrected
// Change: env2.ISBNdb1 → env2.isbndb1 (lowercase)

var __defProp = Object.defineProperty;
var __name = (target, value) => __defProp(target, "name", { value, configurable: true });

// [Previous polyfill code remains the same - truncated for brevity]

// src/index.js
var index_default = {
  async fetch(request, env2, ctx) {
    if (request.method === "OPTIONS") {
      return handleCORS();
    }
    try {
      const url = new URL(request.url);
      const path = url.pathname;
      if (path === "/search") {
        return await handleBookSearch(request, env2, ctx);
      } else if (path === "/isbn") {
        return await handleISBNLookup(request, env2, ctx);
      } else if (path === "/health") {
        return new Response(JSON.stringify({
          status: "healthy",
          timestamp: (new Date()).toISOString(),
          providers: ["google-books", "isbndb", "open-library"],
          cache: {
            system: env2.BOOKS_R2 ? "R2+KV-Hybrid" : "KV-Only",
            kv: env2.BOOKS_CACHE ? "available" : "missing",
            r2: env2.BOOKS_R2 ? "available" : "missing"
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
    } catch (error3) {
      console.error("Worker error:", error3);
      return new Response(JSON.stringify({
        error: "Internal server error",
        message: error3.message
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
__name(getCORSHeaders, "getCORSHeaders");

function handleCORS() {
  return new Response(null, {
    status: 204,
    headers: getCORSHeaders()
  });
}
__name(handleCORS, "handleCORS");

function validateSearchParams(url) {
  const query = url.searchParams.get("q");
  const maxResults = url.searchParams.get("maxResults");
  const sortBy = url.searchParams.get("orderBy");
  const langRestrict = url.searchParams.get("langRestrict");
  const errors = [];
  const sanitized = {};
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
__name(validateSearchParams, "validateSearchParams");

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
__name(validateISBN, "validateISBN");

async function checkRateLimitEnhanced(request, env2) {
  const clientIP = request.headers.get("CF-Connecting-IP") || "unknown";
  const userAgent = request.headers.get("User-Agent") || "unknown";
  const rateLimitKey = `ratelimit:${clientIP}:${btoa(userAgent).slice(0, 8)}`;
  let maxRequests = 100;
  const windowSize = 3600;
  if (userAgent.length < 10 || userAgent === "unknown") {
    maxRequests = 20;
  }
  const current = await env2.BOOKS_CACHE?.get(rateLimitKey);
  const count3 = current ? parseInt(current) : 0;
  if (count3 >= maxRequests) {
    return {
      allowed: false,
      retryAfter: windowSize,
      reason: "Rate limit exceeded"
    };
  }
  const newCount = count3 + 1;
  await env2.BOOKS_CACHE?.put(rateLimitKey, newCount.toString(), { expirationTtl: windowSize });
  return {
    allowed: true,
    count: newCount,
    remaining: maxRequests - newCount
  };
}
__name(checkRateLimitEnhanced, "checkRateLimitEnhanced");

var CACHE_KEYS = {
  search: __name((query, maxResults, sortBy, translations) => `search/${btoa(query).replace(/[/+=]/g, "_")}/${maxResults}/${sortBy}/${translations}.json`, "search"),
  isbn: __name((isbn) => `isbn/${isbn}.json`, "isbn")
};

async function getCachedData(cacheKey, env2) {
  try {
    const kvData = await env2.BOOKS_CACHE?.get(cacheKey);
    if (kvData) {
      return {
        data: JSON.parse(kvData),
        source: "KV-HOT"
      };
    }
    if (env2.BOOKS_R2) {
      const r2Object = await env2.BOOKS_R2.get(cacheKey);
      if (r2Object) {
        const jsonData = await r2Object.text();
        const data = JSON.parse(jsonData);
        const metadata = r2Object.customMetadata;
        if (metadata?.ttl && Date.now() > parseInt(metadata.ttl)) {
          await env2.BOOKS_R2.delete(cacheKey);
          return null;
        }
        const promoteData = JSON.stringify(data);
        env2.waitUntil(env2.BOOKS_CACHE?.put(cacheKey, promoteData, { expirationTtl: 86400 }));
        return {
          data,
          source: "R2-COLD"
        };
      }
    }
    return null;
  } catch (error3) {
    console.warn(`Cache read error for key ${cacheKey}:`, error3.message);
    return null;
  }
}
__name(getCachedData, "getCachedData");

async function setCachedData(cacheKey, data, ttlSeconds, env2, ctx) {
  const jsonData = JSON.stringify(data);
  const promises = [];
  try {
    if (env2.BOOKS_R2) {
      promises.push(
        env2.BOOKS_R2.put(cacheKey, jsonData, {
          httpMetadata: {
            contentType: "application/json",
            cacheControl: `max-age=${ttlSeconds}`
          },
          customMetadata: {
            ttl: (Date.now() + ttlSeconds * 1e3).toString(),
            created: Date.now().toString(),
            type: cacheKey.startsWith("search") ? "search" : "isbn"
          }
        })
      );
    }
    const kvTtl = Math.min(ttlSeconds, 86400);
    promises.push(
      env2.BOOKS_CACHE?.put(cacheKey, jsonData, { expirationTtl: kvTtl })
    );
    if (ctx && ctx.waitUntil) {
      ctx.waitUntil(Promise.all(promises.filter(Boolean)));
    } else {
      await Promise.all(promises.filter(Boolean));
    }
  } catch (error3) {
    console.warn(`Cache write error for key ${cacheKey}:`, error3.message);
  }
}
__name(setCachedData, "setCachedData");

async function handleBookSearch(request, env2, ctx) {
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
  const { query, maxResults, sortBy, includeTranslations } = validation.sanitized;
  const rateLimitResult = await checkRateLimitEnhanced(request, env2);
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
  const cacheKey = CACHE_KEYS.search(query, maxResults, sortBy, includeTranslations);
  const cached = await getCachedData(cacheKey, env2);
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
  let provider = null;
  try {
    result = await searchGoogleBooks(query, maxResults, sortBy, includeTranslations, env2);
    provider = "google-books";
  } catch (error3) {
    console.error("Google Books failed:", error3.message);
  }
  if (!result || result.items?.length === 0) {
    try {
      result = await searchISBNdb(query, maxResults, env2);
      provider = "isbndb";
    } catch (error3) {
      console.error("ISBNdb failed:", error3.message);
    }
  }
  if (!result || result.items?.length === 0) {
    try {
      result = await searchOpenLibrary(query, maxResults, env2);
      provider = "open-library";
    } catch (error3) {
      console.error("Open Library failed:", error3.message);
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
  result.provider = provider;
  result.cached = false;
  const response = JSON.stringify(result);
  if (result.items?.length > 0) {
    setCachedData(cacheKey, result, 2592e3, env2, ctx);
  }
  return new Response(response, {
    headers: {
      ...getCORSHeaders(),
      "X-Cache": "MISS",
      "X-Provider": provider,
      "X-Cache-System": env2.BOOKS_R2 ? "R2+KV-Hybrid" : "KV-Only"
    }
  });
}
__name(handleBookSearch, "handleBookSearch");

async function handleISBNLookup(request, env2, ctx) {
  const url = new URL(request.url);
  const rawISBN = url.searchParams.get("isbn");
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
  const cacheKey = CACHE_KEYS.isbn(isbn);
  const cached = await getCachedData(cacheKey, env2);
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
  let provider = null;
  try {
    result = await lookupISBNGoogle(isbn, env2);
    provider = "google-books";
  } catch (error3) {
    console.error("Google Books ISBN lookup failed:", error3.message);
  }
  if (!result) {
    try {
      result = await lookupISBNISBNdb(isbn, env2);
      provider = "isbndb";
    } catch (error3) {
      console.error("ISBNdb ISBN lookup failed:", error3.message);
    }
  }
  if (!result) {
    try {
      result = await lookupISBNOpenLibrary(isbn, env2);
      provider = "open-library";
    } catch (error3) {
      console.error("Open Library ISBN lookup failed:", error3.message);
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
  result.provider = provider;
  const response = JSON.stringify(result);
  setCachedData(cacheKey, result, 31536e3, env2, ctx);
  return new Response(response, {
    headers: {
      ...getCORSHeaders(),
      "X-Cache": "MISS",
      "X-Provider": provider,
      "X-Cache-System": env2.BOOKS_R2 ? "R2+KV-Hybrid" : "KV-Only"
    }
  });
}
__name(handleISBNLookup, "handleISBNLookup");

async function searchGoogleBooks(query, maxResults, sortBy, includeTranslations, env2) {
  const apiKey = env2.google1 || env2.google2;
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
  const response = await fetch(`https://www.googleapis.com/books/v1/volumes?${params}`);
  if (!response.ok) {
    throw new Error(`Google Books API error: ${response.status}`);
  }
  return await response.json();
}
__name(searchGoogleBooks, "searchGoogleBooks");

async function lookupISBNGoogle(isbn, env2) {
  const apiKey = env2.google1 || env2.google2;
  const params = new URLSearchParams({
    q: `isbn:${isbn}`,
    maxResults: "1",
    printType: "books",
    projection: "full",
    key: apiKey
  });
  const response = await fetch(`https://www.googleapis.com/books/v1/volumes?${params}`);
  if (!response.ok) {
    throw new Error(`Google Books ISBN API error: ${response.status}`);
  }
  const data = await response.json();
  return data.items?.[0] || null;
}
__name(lookupISBNGoogle, "lookupISBNGoogle");

async function searchOpenLibrary(query, maxResults, env2) {
  const params = new URLSearchParams({
    q: query,
    limit: maxResults.toString(),
    fields: "key,title,author_name,first_publish_year,isbn,publisher,language,subject,cover_i,edition_count",
    format: "json"
  });
  const response = await fetch(`https://openlibrary.org/search.json?${params}`);
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
        description: "",
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
__name(searchOpenLibrary, "searchOpenLibrary");

async function lookupISBNOpenLibrary(isbn, env2) {
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
      language: "en",
      previewLink: bookData.url,
      infoLink: bookData.url
    }
  };
}
__name(lookupISBNOpenLibrary, "lookupISBNOpenLibrary");

// FIXED: Changed env2.ISBNdb1 to env2.isbndb1 (lowercase)
async function searchISBNdb(query, maxResults, env2) {
  const apiKey = env2.isbndb1;  // ← FIXED: lowercase
  if (!apiKey) {
    throw new Error("ISBNdb API key not configured (isbndb1)");
  }
  const baseUrl = "https://api2.isbndb.com";
  const endpoint = query.match(/^\d{10}(\d{3})?$/) ? `/book/${query}` : `/books/${encodeURIComponent(query)}`;
  const params = new URLSearchParams({
    pageSize: Math.min(maxResults, 20).toString(),
    page: "1"
  });
  const url = `${baseUrl}${endpoint}?${params}`;
  const response = await fetch(url, {
    headers: {
      "X-API-KEY": apiKey,
      "Content-Type": "application/json"
    }
  });
  if (!response.ok) {
    throw new Error(`ISBNdb API error: ${response.status}`);
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
__name(searchISBNdb, "searchISBNdb");

// FIXED: Changed env2.ISBNdb1 to env2.isbndb1 (lowercase)
async function lookupISBNISBNdb(isbn, env2) {
  const apiKey = env2.isbndb1;  // ← FIXED: lowercase
  if (!apiKey) {
    throw new Error("ISBNdb API key not configured (isbndb1)");
  }
  const response = await fetch(`https://api2.isbndb.com/book/${isbn}`, {
    headers: {
      "X-API-KEY": apiKey,
      "Content-Type": "application/json"
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
__name(lookupISBNISBNdb, "lookupISBNISBNdb");

export {
  index_default as default
};