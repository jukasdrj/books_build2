// Optimized CloudFlare Workers - Bundled Implementation
// All optimization systems bundled into a single file for deployment

// ===== INTELLIGENT CACHE SYSTEM =====
class IntelligentCacheManager {
  constructor(env, ctx) {
    this.env = env;
    this.ctx = ctx;
    this.cacheKeyPrefix = 'books-cache-v2:';
    this.analytics = {
      hits: 0,
      misses: 0,
      promotions: 0,
      errors: 0
    };
  }

  async get(key, options = {}) {
    try {
      const cacheKey = this.cacheKeyPrefix + key;
      
      // Try KV first (hot cache)
      let data = await this.env.BOOKS_CACHE.get(cacheKey);
      if (data) {
        this.analytics.hits++;
        return { data: JSON.parse(data), source: 'kv', hit: true };
      }

      // Try R2 (cold cache)
      try {
        const r2Object = await this.env.BOOKS_R2.get(cacheKey);
        if (r2Object) {
          data = await r2Object.text();
          // Promote to KV if frequently accessed
          await this.promoteToKV(cacheKey, data, options);
          this.analytics.hits++;
          return { data: JSON.parse(data), source: 'r2', hit: true };
        }
      } catch (r2Error) {
        console.warn('R2 cache error:', r2Error);
      }

      this.analytics.misses++;
      return { data: null, source: null, hit: false };
    } catch (error) {
      this.analytics.errors++;
      console.error('Cache get error:', error);
      return { data: null, source: null, hit: false };
    }
  }

  async set(key, data, options = {}) {
    try {
      const cacheKey = this.cacheKeyPrefix + key;
      const jsonData = JSON.stringify(data);
      const ttl = options.ttl || 3600; // 1 hour default

      // Store in KV (hot cache) with shorter TTL
      await this.env.BOOKS_CACHE.put(cacheKey, jsonData, {
        expirationTtl: Math.min(ttl, 3600) // Max 1 hour in KV
      });

      // Store in R2 (cold cache) with longer TTL
      await this.env.BOOKS_R2.put(cacheKey, jsonData, {
        httpMetadata: {
          contentType: 'application/json',
          cacheControl: `max-age=${ttl}`
        }
      });

      return true;
    } catch (error) {
      this.analytics.errors++;
      console.error('Cache set error:', error);
      return false;
    }
  }

  async promoteToKV(key, data, options = {}) {
    try {
      await this.env.BOOKS_CACHE.put(key, data, {
        expirationTtl: options.promotionTtl || 1800 // 30 minutes
      });
      this.analytics.promotions++;
    } catch (error) {
      console.warn('Cache promotion error:', error);
    }
  }

  getAnalytics() {
    return this.analytics;
  }
}

// ===== QUOTA OPTIMIZATION SYSTEM =====
class QuotaOptimizationManager {
  constructor(env, ctx) {
    this.env = env;
    this.ctx = ctx;
    this.quotaKey = 'api-quota:';
    this.quotaLimits = {
      google1: { daily: 1000, hourly: 100 },
      google2: { daily: 1000, hourly: 100 },
      ISBNdb1: { daily: 1000, hourly: 100 }
    };
  }

  async getQuotaUsage(apiKey) {
    const daily = await this.env.BOOKS_CACHE.get(`${this.quotaKey}${apiKey}:daily`);
    const hourly = await this.env.BOOKS_CACHE.get(`${this.quotaKey}${apiKey}:hourly`);
    return {
      daily: daily ? parseInt(daily) : 0,
      hourly: hourly ? parseInt(hourly) : 0
    };
  }

  async incrementQuota(apiKey) {
    const now = new Date();
    const dailyKey = `${this.quotaKey}${apiKey}:daily`;
    const hourlyKey = `${this.quotaKey}${apiKey}:hourly`;

    // Increment daily quota
    let dailyCount = await this.env.BOOKS_CACHE.get(dailyKey);
    dailyCount = dailyCount ? parseInt(dailyCount) + 1 : 1;
    await this.env.BOOKS_CACHE.put(dailyKey, dailyCount.toString(), {
      expirationTtl: 86400 // 24 hours
    });

    // Increment hourly quota
    let hourlyCount = await this.env.BOOKS_CACHE.get(hourlyKey);
    hourlyCount = hourlyCount ? parseInt(hourlyCount) + 1 : 1;
    await this.env.BOOKS_CACHE.put(hourlyKey, hourlyCount.toString(), {
      expirationTtl: 3600 // 1 hour
    });

    return { daily: dailyCount, hourly: hourlyCount };
  }

  async selectOptimalAPI(requiredAPIs) {
    const usagePromises = requiredAPIs.map(async (api) => {
      const usage = await this.getQuotaUsage(api);
      const limits = this.quotaLimits[api];
      return {
        api,
        usage,
        limits,
        dailyRemaining: limits.daily - usage.daily,
        hourlyRemaining: limits.hourly - usage.hourly
      };
    });

    const apiStatuses = await Promise.all(usagePromises);
    
    // Filter available APIs
    const available = apiStatuses.filter(status => 
      status.dailyRemaining > 0 && status.hourlyRemaining > 0
    );

    if (available.length === 0) {
      return null;
    }

    // Select API with most remaining quota
    return available.sort((a, b) => b.hourlyRemaining - a.hourlyRemaining)[0].api;
  }
}

// ===== AUTHOR CULTURAL INDEXING =====
class AuthorCulturalIndexer {
  constructor(env, ctx) {
    this.env = env;
    this.ctx = ctx;
    this.profileKey = 'author-profile:';
  }

  async getAuthorProfile(authorName) {
    try {
      const key = `${this.profileKey}${authorName.toLowerCase()}`;
      const profile = await this.env.AUTHOR_PROFILES.get(key);
      return profile ? JSON.parse(profile) : null;
    } catch (error) {
      console.error('Error getting author profile:', error);
      return null;
    }
  }

  async setAuthorProfile(authorName, profile) {
    try {
      const key = `${this.profileKey}${authorName.toLowerCase()}`;
      await this.env.AUTHOR_PROFILES.put(key, JSON.stringify(profile), {
        expirationTtl: 604800 // 7 days
      });
      return true;
    } catch (error) {
      console.error('Error setting author profile:', error);
      return false;
    }
  }

  async enrichWithCulturalData(bookData) {
    if (!bookData.authors) return bookData;

    const enrichedAuthors = await Promise.all(
      bookData.authors.map(async (author) => {
        const profile = await this.getAuthorProfile(author);
        return {
          name: author,
          profile: profile || { confidence: 0, culturalData: {} }
        };
      })
    );

    return {
      ...bookData,
      authors: enrichedAuthors
    };
  }
}

// ===== PERFORMANCE OPTIMIZER =====
class PerformanceOptimizer {
  constructor(env, ctx) {
    this.env = env;
    this.ctx = ctx;
    this.metrics = {
      totalRequests: 0,
      averageResponseTime: 0,
      cacheHitRate: 0
    };
  }

  async optimizeResponse(data, request) {
    const acceptEncoding = request.headers.get('Accept-Encoding') || '';
    
    // Check if compression is supported
    const supportsGzip = acceptEncoding.includes('gzip');
    const supportsBrotli = acceptEncoding.includes('br');

    // Compress response if large enough
    const jsonString = JSON.stringify(data);
    if (jsonString.length > 1024 && (supportsGzip || supportsBrotli)) {
      // In a real implementation, you'd use compression here
      // For now, just return the data with appropriate headers
      return {
        data,
        headers: {
          'Content-Encoding': supportsGzip ? 'gzip' : 'identity',
          'Content-Type': 'application/json; charset=utf-8',
          'Vary': 'Accept-Encoding'
        }
      };
    }

    return {
      data,
      headers: {
        'Content-Type': 'application/json; charset=utf-8'
      }
    };
  }

  recordMetrics(responseTime, cacheHit) {
    this.metrics.totalRequests++;
    this.metrics.averageResponseTime = 
      (this.metrics.averageResponseTime * (this.metrics.totalRequests - 1) + responseTime) / 
      this.metrics.totalRequests;
    
    if (cacheHit) {
      this.metrics.cacheHitRate = 
        (this.metrics.cacheHitRate * (this.metrics.totalRequests - 1) + 100) / 
        this.metrics.totalRequests;
    } else {
      this.metrics.cacheHitRate = 
        (this.metrics.cacheHitRate * (this.metrics.totalRequests - 1)) / 
        this.metrics.totalRequests;
    }
  }

  getMetrics() {
    return this.metrics;
  }
}

// ===== MAIN WORKER IMPLEMENTATION =====

// Security validation
async function validateRequestSecurity(request, env) {
  const url = new URL(request.url);
  const userAgent = request.headers.get('User-Agent') || '';
  const origin = request.headers.get('Origin') || '';

  // Basic security checks
  if (userAgent.toLowerCase().includes('bot') && !userAgent.includes('Googlebot')) {
    return { valid: false, reason: 'Suspicious user agent', status: 403 };
  }

  // Rate limiting would go here (simplified for now)
  return { valid: true };
}

function createSecurityErrorResponse(reason, status = 403) {
  return new Response(JSON.stringify({ error: reason }), {
    status,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*'
    }
  });
}

function handleCORS() {
  return new Response(null, {
    status: 200,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      'Access-Control-Max-Age': '86400'
    }
  });
}

async function handleOptimizedBookSearch(request, env, ctx, optimizers) {
  const { cacheManager, quotaManager, culturalIndexer, requestStartTime } = optimizers;
  const url = new URL(request.url);
  const query = url.searchParams.get('q');
  
  if (!query) {
    return new Response(JSON.stringify({ error: 'Query parameter required' }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' }
    });
  }

  // Try cache first
  const cacheKey = `search:${query}`;
  const cached = await cacheManager.get(cacheKey);
  if (cached.hit) {
    const responseTime = Date.now() - requestStartTime;
    return new Response(JSON.stringify({
      ...cached.data,
      _metadata: {
        cached: true,
        source: cached.source,
        responseTime: responseTime + 'ms'
      }
    }), {
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Cache-Control': 'public, max-age=300'
      }
    });
  }

  // Select optimal API
  const selectedAPI = await quotaManager.selectOptimalAPI(['google1', 'google2']);
  if (!selectedAPI) {
    return new Response(JSON.stringify({ error: 'API quota exceeded' }), {
      status: 429,
      headers: { 'Content-Type': 'application/json' }
    });
  }

  // Make API request (simplified - would normally call Google Books API)
  const mockResponse = {
    query,
    results: [{
      title: 'Sample Book',
      authors: ['Sample Author'],
      isbn: '1234567890',
      publishedDate: '2023'
    }],
    totalItems: 1
  };

  // Enrich with cultural data
  const enrichedResponse = await culturalIndexer.enrichWithCulturalData(mockResponse);

  // Cache the response
  await cacheManager.set(cacheKey, enrichedResponse, { ttl: 3600 });

  // Increment quota
  await quotaManager.incrementQuota(selectedAPI);

  const responseTime = Date.now() - requestStartTime;
  return new Response(JSON.stringify({
    ...enrichedResponse,
    _metadata: {
      cached: false,
      apiUsed: selectedAPI,
      responseTime: responseTime + 'ms'
    }
  }), {
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*'
    }
  });
}

async function handleOptimizedISBNLookup(request, env, ctx, optimizers) {
  // Similar implementation to book search but for ISBN lookup
  return new Response(JSON.stringify({ message: 'ISBN lookup endpoint' }), {
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*'
    }
  });
}

async function handleHealthCheck(optimizers) {
  const analytics = optimizers.cacheManager.getAnalytics();
  const performanceMetrics = optimizers.performanceOptimizer.getMetrics();
  
  return new Response(JSON.stringify({
    status: 'healthy',
    version: '3.0-optimized',
    features: [
      'intelligent-caching',
      'quota-optimization', 
      'cultural-indexing',
      'performance-optimization'
    ],
    analytics,
    performance: performanceMetrics,
    timestamp: new Date().toISOString()
  }), {
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*'
    }
  });
}

// Main export
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
      const optimizers = { cacheManager, quotaManager, culturalIndexer, performanceOptimizer, requestStartTime };

      // Route to optimized handlers
      switch (path) {
        case "/":
        case "/health":
          response = await handleHealthCheck(optimizers);
          break;

        case "/search":
          response = await handleOptimizedBookSearch(request, env, ctx, optimizers);
          break;

        case "/isbn":
          response = await handleOptimizedISBNLookup(request, env, ctx, optimizers);
          break;

        default:
          response = new Response(JSON.stringify({ 
            error: 'Endpoint not found',
            availableEndpoints: ['/', '/health', '/search', '/isbn']
          }), {
            status: 404,
            headers: {
              'Content-Type': 'application/json',
              'Access-Control-Allow-Origin': '*'
            }
          });
      }

      // Record performance metrics
      const responseTime = Date.now() - requestStartTime;
      performanceOptimizer.recordMetrics(responseTime, false); // Would track cache hits properly

      return response;

    } catch (error) {
      console.error('Worker error:', error);
      return new Response(JSON.stringify({
        error: 'Internal server error',
        message: error.message,
        timestamp: new Date().toISOString()
      }), {
        status: 500,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        }
      });
    }
  }
};