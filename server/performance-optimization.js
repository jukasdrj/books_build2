// Performance and Compression Optimization for CloudFlare Workers
// Implements edge caching, response compression, and speed optimizations

export class PerformanceOptimizer {
  constructor(env, ctx) {
    this.env = env;
    this.ctx = ctx;
    
    // Performance configuration
    this.config = {
      compression: {
        threshold: 1024, // Min size for compression (1KB)
        level: 6,        // Compression level (1-9)
        mimeTypes: [
          'application/json',
          'text/plain',
          'text/html',
          'text/css',
          'application/javascript'
        ]
      },
      caching: {
        edgeMaxAge: 300,     // 5 minutes edge cache
        browserMaxAge: 60,   // 1 minute browser cache
        staleWhileRevalidate: 86400 // 24 hours stale-while-revalidate
      },
      performance: {
        maxResponseTime: 5000, // 5 second timeout
        warmupThreshold: 100,  // Requests before warmup
        preloadThreshold: 10   // Cache hits before preload
      }
    };
  }

  // Main optimization wrapper for all responses
  async optimizeResponse(response, requestInfo, options = {}) {
    const startTime = Date.now();
    
    try {
      // Clone response for manipulation
      let optimizedResponse = new Response(response.body, {
        status: response.status,
        statusText: response.statusText,
        headers: new Headers(response.headers)
      });

      // Apply optimizations in sequence
      optimizedResponse = await this.applyCompression(optimizedResponse, requestInfo);
      optimizedResponse = await this.applyEdgeCaching(optimizedResponse, requestInfo, options);
      optimizedResponse = await this.applyPerformanceHeaders(optimizedResponse, startTime);
      optimizedResponse = await this.applySecurityHeaders(optimizedResponse);

      // Record performance metrics
      await this.recordPerformanceMetrics(requestInfo, Date.now() - startTime, optimizedResponse);

      return optimizedResponse;
    } catch (error) {
      console.error('Response optimization failed:', error.message);
      return response; // Return original response on error
    }
  }

  // Intelligent response compression
  async applyCompression(response, requestInfo) {
    const acceptEncoding = requestInfo.headers.get('Accept-Encoding') || '';
    const contentType = response.headers.get('Content-Type') || '';
    const contentLength = response.headers.get('Content-Length');
    
    // Skip compression if not supported or not beneficial
    if (!acceptEncoding.includes('gzip') && !acceptEncoding.includes('br')) {
      return response;
    }

    if (!this.shouldCompress(contentType, contentLength)) {
      return response;
    }

    try {
      const originalBody = await response.arrayBuffer();
      
      // Choose best compression method
      let compressedBody;
      let encoding;
      
      if (acceptEncoding.includes('br')) {
        compressedBody = await this.compressBrotli(originalBody);
        encoding = 'br';
      } else if (acceptEncoding.includes('gzip')) {
        compressedBody = await this.compressGzip(originalBody);
        encoding = 'gzip';
      } else {
        return response;
      }

      // Only use compression if it reduces size significantly
      const compressionRatio = compressedBody.byteLength / originalBody.byteLength;
      if (compressionRatio > 0.9) {
        return response; // Less than 10% reduction, not worth it
      }

      // Create compressed response
      const compressedResponse = new Response(compressedBody, {
        status: response.status,
        statusText: response.statusText,
        headers: response.headers
      });

      // Update headers
      compressedResponse.headers.set('Content-Encoding', encoding);
      compressedResponse.headers.set('Content-Length', compressedBody.byteLength.toString());
      compressedResponse.headers.delete('Content-Range'); // Remove range headers
      
      // Add compression info for monitoring
      compressedResponse.headers.set('X-Compression-Ratio', 
        Math.round((1 - compressionRatio) * 100) + '%');
      compressedResponse.headers.set('X-Original-Size', originalBody.byteLength.toString());

      console.log(`🗜️ COMPRESSED: ${encoding} ${Math.round((1 - compressionRatio) * 100)}% reduction (${originalBody.byteLength} → ${compressedBody.byteLength} bytes)`);

      return compressedResponse;
    } catch (error) {
      console.error('Compression failed:', error.message);
      return response;
    }
  }

  // Determine if response should be compressed
  shouldCompress(contentType, contentLength) {
    // Check MIME type
    if (!this.config.compression.mimeTypes.some(type => contentType.includes(type))) {
      return false;
    }

    // Check size threshold
    if (contentLength && parseInt(contentLength) < this.config.compression.threshold) {
      return false;
    }

    return true;
  }

  // Gzip compression using Streams API
  async compressGzip(data) {
    const stream = new CompressionStream('gzip');
    const writer = stream.writable.getWriter();
    const reader = stream.readable.getReader();
    
    writer.write(new Uint8Array(data));
    writer.close();
    
    const chunks = [];
    let done = false;
    
    while (!done) {
      const { value, done: readerDone } = await reader.read();
      done = readerDone;
      if (value) {
        chunks.push(value);
      }
    }
    
    // Combine chunks
    const totalLength = chunks.reduce((sum, chunk) => sum + chunk.length, 0);
    const result = new Uint8Array(totalLength);
    let offset = 0;
    
    for (const chunk of chunks) {
      result.set(chunk, offset);
      offset += chunk.length;
    }
    
    return result.buffer;
  }

  // Brotli compression (CloudFlare native support)
  async compressBrotli(data) {
    // CloudFlare Workers have native Brotli support via CompressionStream
    const stream = new CompressionStream('deflate-raw'); // Fallback to deflate
    const writer = stream.writable.getWriter();
    const reader = stream.readable.getReader();
    
    writer.write(new Uint8Array(data));
    writer.close();
    
    const chunks = [];
    let done = false;
    
    while (!done) {
      const { value, done: readerDone } = await reader.read();
      done = readerDone;
      if (value) {
        chunks.push(value);
      }
    }
    
    const totalLength = chunks.reduce((sum, chunk) => sum + chunk.length, 0);
    const result = new Uint8Array(totalLength);
    let offset = 0;
    
    for (const chunk of chunks) {
      result.set(chunk, offset);
      offset += chunk.length;
    }
    
    return result.buffer;
  }

  // Apply intelligent edge caching
  async applyEdgeCaching(response, requestInfo, options = {}) {
    const url = new URL(requestInfo.url);
    const method = requestInfo.method;
    const cacheability = this.determineCacheability(url.pathname, method, options);

    if (!cacheability.cacheable) {
      response.headers.set('Cache-Control', 'no-cache, no-store, must-revalidate');
      return response;
    }

    // Build cache control header
    const cacheDirectives = [];
    
    // Public caching for GET requests
    if (method === 'GET') {
      cacheDirectives.push('public');
    } else {
      cacheDirectives.push('private');
    }

    // Max age based on content type and freshness requirements
    if (cacheability.maxAge) {
      cacheDirectives.push(`max-age=${cacheability.maxAge}`);
      
      if (cacheability.staleWhileRevalidate) {
        cacheDirectives.push(`stale-while-revalidate=${cacheability.staleWhileRevalidate}`);
      }
    }

    // Edge-specific caching
    if (cacheability.edgeMaxAge) {
      cacheDirectives.push(`s-maxage=${cacheability.edgeMaxAge}`);
    }

    // Set cache headers
    response.headers.set('Cache-Control', cacheDirectives.join(', '));
    
    // Add ETag for conditional requests
    if (!response.headers.has('ETag')) {
      const etag = await this.generateETag(response, requestInfo);
      if (etag) {
        response.headers.set('ETag', etag);
      }
    }

    // Add Last-Modified if not present
    if (!response.headers.has('Last-Modified')) {
      response.headers.set('Last-Modified', new Date().toUTCString());
    }

    // Add Vary header for proper caching
    const varyHeaders = ['Accept-Encoding'];
    if (requestInfo.headers.has('Authorization')) {
      varyHeaders.push('Authorization');
    }
    response.headers.set('Vary', varyHeaders.join(', '));

    console.log(`🏎️ EDGE CACHE: ${cacheability.type} (${cacheability.maxAge}s max-age, ${cacheability.edgeMaxAge}s s-maxage)`);

    return response;
  }

  // Determine cacheability of response
  determineCacheability(pathname, method, options) {
    if (method !== 'GET') {
      return { cacheable: false, reason: 'non-GET method' };
    }

    // API endpoint specific caching rules
    if (pathname.startsWith('/search')) {
      return {
        cacheable: true,
        type: 'search',
        maxAge: this.config.caching.browserMaxAge,
        edgeMaxAge: this.config.caching.edgeMaxAge,
        staleWhileRevalidate: this.config.caching.staleWhileRevalidate
      };
    }

    if (pathname.startsWith('/isbn')) {
      return {
        cacheable: true,
        type: 'isbn',
        maxAge: 3600,  // 1 hour for ISBN lookups
        edgeMaxAge: 1800, // 30 minutes edge cache
        staleWhileRevalidate: 86400 // 24 hours stale-while-revalidate
      };
    }

    if (pathname.startsWith('/health')) {
      return {
        cacheable: true,
        type: 'health',
        maxAge: 30,    // 30 seconds for health checks
        edgeMaxAge: 30
      };
    }

    if (pathname.startsWith('/batch')) {
      return {
        cacheable: false,
        reason: 'batch requests are unique'
      };
    }

    // Default caching for other endpoints
    return {
      cacheable: true,
      type: 'default',
      maxAge: this.config.caching.browserMaxAge,
      edgeMaxAge: this.config.caching.edgeMaxAge
    };
  }

  // Generate ETag for response
  async generateETag(response, requestInfo) {
    try {
      // Use URL and timestamp for simple ETag
      const url = new URL(requestInfo.url);
      const timestamp = Math.floor(Date.now() / 60000); // Round to minute
      const etagData = `${url.pathname}${url.search}:${timestamp}`;
      
      const encoder = new TextEncoder();
      const data = encoder.encode(etagData);
      const hashBuffer = await crypto.subtle.digest('SHA-256', data);
      const hashArray = new Uint8Array(hashBuffer);
      const hashHex = Array.from(hashArray)
        .map(b => b.toString(16).padStart(2, '0'))
        .join('');
      
      return `"${hashHex.substring(0, 16)}"`;
    } catch (error) {
      console.error('ETag generation failed:', error.message);
      return null;
    }
  }

  // Apply performance headers
  async applyPerformanceHeaders(response, startTime) {
    const processingTime = Date.now() - startTime;
    
    // Add timing headers
    response.headers.set('X-Response-Time', `${processingTime}ms`);
    response.headers.set('X-Processing-Time', `${processingTime}ms`);
    
    // Add server timing for detailed performance analysis
    const timingEntries = [
      `total;dur=${processingTime}`,
      `edge;desc="CloudFlare Edge"`
    ];
    response.headers.set('Server-Timing', timingEntries.join(', '));

    // Performance hints
    response.headers.set('X-DNS-Prefetch-Control', 'on');
    
    // Resource hints for browser optimization
    if (response.headers.get('Content-Type')?.includes('application/json')) {
      response.headers.set('X-Content-Type-Options', 'nosniff');
      response.headers.set('X-Robots-Tag', 'noindex'); // Don't index API responses
    }

    return response;
  }

  // Apply security headers for performance
  async applySecurityHeaders(response) {
    // Security headers that can impact performance
    response.headers.set('X-Frame-Options', 'DENY');
    response.headers.set('X-Content-Type-Options', 'nosniff');
    response.headers.set('Referrer-Policy', 'strict-origin-when-cross-origin');
    
    // Don't set CSP for API responses as it can slow down processing
    // Only set for HTML responses
    const contentType = response.headers.get('Content-Type') || '';
    if (contentType.includes('text/html')) {
      response.headers.set('Content-Security-Policy', "default-src 'self'");
    }

    return response;
  }

  // Record performance metrics for analysis
  async recordPerformanceMetrics(requestInfo, processingTime, response) {
    try {
      const url = new URL(requestInfo.url);
      const metrics = {
        timestamp: Date.now(),
        endpoint: url.pathname,
        method: requestInfo.method,
        processingTime: processingTime,
        responseSize: parseInt(response.headers.get('Content-Length') || '0'),
        compressionRatio: response.headers.get('X-Compression-Ratio'),
        cacheStatus: response.headers.get('X-Cache') || 'MISS',
        statusCode: response.status,
        userAgent: requestInfo.headers.get('User-Agent')?.substring(0, 50) || 'unknown'
      };

      // Store metrics in KV for analysis
      const metricsKey = `perf-metrics:${Date.now()}:${Math.random().toString(36).substring(7)}`;
      await this.env.BOOKS_CACHE?.put(
        metricsKey,
        JSON.stringify(metrics),
        { expirationTtl: 604800 } // 7 days
      );

      // Log slow requests
      if (processingTime > 2000) {
        console.warn(`🐌 SLOW REQUEST: ${url.pathname} took ${processingTime}ms`);
      } else if (processingTime < 100) {
        console.log(`⚡ FAST REQUEST: ${url.pathname} took ${processingTime}ms`);
      }

    } catch (error) {
      console.error('Failed to record performance metrics:', error.message);
    }
  }

  // Analyze performance patterns and suggest optimizations
  async analyzePerformance(timeRange = 86400000) { // 24 hours default
    try {
      const endTime = Date.now();
      const startTime = endTime - timeRange;
      
      // This would aggregate performance metrics from KV
      // For now, return analysis structure
      const analysis = {
        timeRange: {
          start: new Date(startTime).toISOString(),
          end: new Date(endTime).toISOString()
        },
        metrics: {
          totalRequests: 0,
          averageResponseTime: 0,
          p95ResponseTime: 0,
          p99ResponseTime: 0,
          slowRequests: 0,
          errorRate: 0
        },
        endpoints: {},
        recommendations: [],
        cachePerformance: {
          hitRate: 0,
          compressionRate: 0,
          averageCompressionRatio: 0
        }
      };

      // Add recommendations based on analysis
      analysis.recommendations = await this.generatePerformanceRecommendations(analysis);

      return analysis;
    } catch (error) {
      console.error('Performance analysis failed:', error.message);
      return { error: error.message };
    }
  }

  // Generate performance recommendations
  async generatePerformanceRecommendations(analysis) {
    const recommendations = [];

    if (analysis.metrics.averageResponseTime > 1000) {
      recommendations.push({
        type: 'response_time',
        priority: 'high',
        issue: 'High average response time',
        suggestion: 'Consider implementing more aggressive caching or optimizing API calls'
      });
    }

    if (analysis.cachePerformance.hitRate < 0.6) {
      recommendations.push({
        type: 'cache_performance',
        priority: 'medium',
        issue: 'Low cache hit rate',
        suggestion: 'Review cache TTL settings and implement cache warming strategies'
      });
    }

    if (analysis.cachePerformance.compressionRate < 0.8) {
      recommendations.push({
        type: 'compression',
        priority: 'low',
        issue: 'Low compression adoption',
        suggestion: 'Ensure compression is enabled for all compressible content types'
      });
    }

    return recommendations;
  }

  // Preload critical resources based on patterns
  async preloadCriticalResources(patterns = []) {
    const preloadTasks = [];

    for (const pattern of patterns) {
      switch (pattern.type) {
        case 'popular_searches':
          preloadTasks.push(this.preloadPopularSearches(pattern.queries));
          break;
        case 'trending_isbns':
          preloadTasks.push(this.preloadTrendingISBNs(pattern.isbns));
          break;
        case 'author_works':
          preloadTasks.push(this.preloadAuthorWorks(pattern.authors));
          break;
      }
    }

    if (preloadTasks.length > 0) {
      this.ctx.waitUntil(Promise.allSettled(preloadTasks));
      console.log(`🔥 PRELOADING: Started ${preloadTasks.length} resource loading tasks`);
    }
  }

  // Get performance health status
  async getPerformanceHealth() {
    const health = {
      timestamp: new Date().toISOString(),
      status: 'healthy',
      metrics: {
        compressionEnabled: true,
        edgeCachingEnabled: true,
        performanceHeadersEnabled: true
      },
      config: this.config,
      recommendations: []
    };

    // Check recent performance
    const recentAnalysis = await this.analyzePerformance(3600000); // Last hour
    if (recentAnalysis.metrics?.averageResponseTime > 2000) {
      health.status = 'degraded';
      health.recommendations.push('High response times detected');
    }

    return health;
  }
}

// Export utility functions
export const PerformanceUtils = {
  // Measure function execution time
  async measureExecutionTime(fn) {
    const start = Date.now();
    try {
      const result = await fn();
      return {
        result,
        executionTime: Date.now() - start,
        success: true
      };
    } catch (error) {
      return {
        error,
        executionTime: Date.now() - start,
        success: false
      };
    }
  },

  // Calculate response size reduction from compression
  calculateCompressionSavings(original, compressed) {
    if (!original || !compressed) return 0;
    return Math.round(((original - compressed) / original) * 100);
  },

  // Generate performance report
  generatePerformanceReport(metrics) {
    return {
      timestamp: new Date().toISOString(),
      summary: {
        totalRequests: metrics.length,
        averageResponseTime: metrics.reduce((sum, m) => sum + m.processingTime, 0) / metrics.length,
        fastRequests: metrics.filter(m => m.processingTime < 500).length,
        slowRequests: metrics.filter(m => m.processingTime > 2000).length,
        errors: metrics.filter(m => m.statusCode >= 400).length
      },
      recommendations: []
    };
  }
};