// Books API Proxy Tail Worker
// Processes cache hit analytics and performance metrics in real-time

export default {
  async tail(events, env, ctx) {
    const processedEvents = [];
    
    for (const event of events) {
      try {
        // Extract cache-related logs and metrics
        const cacheMetrics = await extractCacheMetrics(event);
        const performanceMetrics = await extractPerformanceMetrics(event);
        const errorMetrics = await extractErrorMetrics(event);
        
        if (cacheMetrics.length > 0 || performanceMetrics || errorMetrics.length > 0) {
          processedEvents.push({
            timestamp: event.eventTimestamp,
            requestId: event.event?.request?.cf?.requestId || 'unknown',
            url: event.event?.request?.url || 'unknown',
            method: event.event?.request?.method || 'unknown',
            userAgent: event.event?.request?.headers?.['user-agent']?.slice(0, 50) || 'unknown',
            cfRay: event.event?.request?.headers?.['cf-ray'] || 'unknown',
            responseStatus: event.event?.response?.status || 0,
            cacheMetrics,
            performanceMetrics,
            errorMetrics,
            scriptName: event.scriptName,
            outcome: event.outcome
          });
        }
      } catch (processingError) {
        console.error('Tail worker processing error:', processingError.message);
      }
    }
    
    if (processedEvents.length > 0) {
      // Process analytics in parallel
      const promises = [
        // Store cache analytics
        storeCacheAnalytics(processedEvents, env, ctx),
        // Send to external analytics if configured
        sendToExternalAnalytics(processedEvents, env, ctx),
        // Update real-time metrics
        updateRealTimeMetrics(processedEvents, env, ctx)
      ];
      
      ctx.waitUntil(Promise.allSettled(promises));
    }
  }
};

// Extract cache-related metrics from logs
async function extractCacheMetrics(event) {
  const cacheEvents = [];
  
  if (event.logs) {
    for (const log of event.logs) {
      const message = Array.isArray(log.message) ? log.message.join(' ') : log.message;
      
      if (typeof message === 'string') {
        // Parse cache hit logs
        if (message.includes('CACHE HIT (KV-HOT)')) {
          const match = message.match(/🔥 CACHE HIT \(KV-HOT\): ([^\s]+)/);
          const cacheKey = match ? match[1] : 'unknown';
          const durationMatch = message.match(/duration: (\d+)ms/);
          const sizeMatch = message.match(/size: (\d+) bytes/);
          
          cacheEvents.push({
            type: 'hit',
            tier: 'KV-HOT',
            cacheKey,
            duration: durationMatch ? parseInt(durationMatch[1]) : null,
            size: sizeMatch ? parseInt(sizeMatch[1]) : null,
            timestamp: log.timestamp
          });
        }
        
        if (message.includes('CACHE HIT (R2-COLD)')) {
          const match = message.match(/❄️ CACHE HIT \(R2-COLD\): ([^\s]+)/);
          const cacheKey = match ? match[1] : 'unknown';
          const durationMatch = message.match(/duration: (\d+)ms/);
          const sizeMatch = message.match(/size: (\d+) bytes/);
          
          cacheEvents.push({
            type: 'hit',
            tier: 'R2-COLD',
            cacheKey,
            duration: durationMatch ? parseInt(durationMatch[1]) : null,
            size: sizeMatch ? parseInt(sizeMatch[1]) : null,
            promoted: message.includes('promoted: true'),
            timestamp: log.timestamp
          });
        }
        
        if (message.includes('CACHE MISS')) {
          const match = message.match(/❌ CACHE MISS: ([^\s]+)/);
          const cacheKey = match ? match[1] : 'unknown';
          const durationMatch = message.match(/duration: (\d+)ms/);
          
          cacheEvents.push({
            type: 'miss',
            tier: 'none',
            cacheKey,
            duration: durationMatch ? parseInt(durationMatch[1]) : null,
            timestamp: log.timestamp
          });
        }
        
        if (message.includes('CACHE SET')) {
          const match = message.match(/💾 CACHE SET: ([^\s]+)/);
          const cacheKey = match ? match[1] : 'unknown';
          const durationMatch = message.match(/duration: (\d+)ms/);
          const sizeMatch = message.match(/size: (\d+) bytes/);
          const ttlMatch = message.match(/ttl: (\d+)s/);
          const storesMatch = message.match(/stores: ([^,\s]+)/);
          
          cacheEvents.push({
            type: 'set',
            tier: storesMatch ? storesMatch[1] : 'unknown',
            cacheKey,
            duration: durationMatch ? parseInt(durationMatch[1]) : null,
            size: sizeMatch ? parseInt(sizeMatch[1]) : null,
            ttl: ttlMatch ? parseInt(ttlMatch[1]) : null,
            timestamp: log.timestamp
          });
        }
      }
    }
  }
  
  return cacheEvents;
}

// Extract performance metrics
async function extractPerformanceMetrics(event) {
  let metrics = null;
  
  if (event.logs) {
    for (const log of event.logs) {
      const message = Array.isArray(log.message) ? log.message.join(' ') : log.message;
      
      if (typeof message === 'string') {
        // Extract search success metrics
        if (message.includes('SEARCH SUCCESS')) {
          const providerMatch = message.match(/provider: ([^,\s]+)/);
          const resultsMatch = message.match(/results: (\d+)/);
          
          metrics = {
            type: 'search',
            provider: providerMatch ? providerMatch[1] : 'unknown',
            resultCount: resultsMatch ? parseInt(resultsMatch[1]) : 0,
            timestamp: log.timestamp
          };
        }
        
        // Extract ISBN success metrics
        if (message.includes('ISBN SUCCESS')) {
          const providerMatch = message.match(/provider: ([^,\s]+)/);
          const titleMatch = message.match(/title: ([^,]+)/);
          
          metrics = {
            type: 'isbn',
            provider: providerMatch ? providerMatch[1] : 'unknown',
            title: titleMatch ? titleMatch[1].trim() : 'unknown',
            timestamp: log.timestamp
          };
        }
        
        // Extract rate limiting info
        if (message.includes('RATE LIMIT')) {
          const okMatch = message.match(/✅ RATE LIMIT OK: ([^\s]+) \((\d+)\/(\d+)\)/);
          const exceededMatch = message.match(/🚫 RATE LIMIT EXCEEDED: ([^\s]+) \((\d+)\/(\d+)\)/);
          
          if (okMatch) {
            metrics = {
              type: 'rate_limit',
              status: 'ok',
              fingerprint: okMatch[1],
              current: parseInt(okMatch[2]),
              limit: parseInt(okMatch[3]),
              timestamp: log.timestamp
            };
          } else if (exceededMatch) {
            metrics = {
              type: 'rate_limit',
              status: 'exceeded',
              fingerprint: exceededMatch[1],
              current: parseInt(exceededMatch[2]),
              limit: parseInt(exceededMatch[3]),
              timestamp: log.timestamp
            };
          }
        }
      }
    }
  }
  
  return metrics;
}

// Extract error metrics
async function extractErrorMetrics(event) {
  const errorEvents = [];
  
  // Check for exceptions
  if (event.exceptions && event.exceptions.length > 0) {
    for (const exception of event.exceptions) {
      errorEvents.push({
        type: 'exception',
        name: exception.name,
        message: exception.message,
        timestamp: exception.timestamp
      });
    }
  }
  
  // Check for error logs
  if (event.logs) {
    for (const log of event.logs) {
      const message = Array.isArray(log.message) ? log.message.join(' ') : log.message;
      
      if (typeof message === 'string' && (message.includes('ERROR') || message.includes('FAILED'))) {
        if (message.includes('ISBNdb FAILED')) {
          errorEvents.push({
            type: 'provider_error',
            provider: 'isbndb',
            message: message,
            timestamp: log.timestamp
          });
        } else if (message.includes('Google Books FAILED')) {
          errorEvents.push({
            type: 'provider_error',
            provider: 'google',
            message: message,
            timestamp: log.timestamp
          });
        } else if (message.includes('VALIDATION ERROR')) {
          errorEvents.push({
            type: 'validation_error',
            message: message,
            timestamp: log.timestamp
          });
        }
      }
    }
  }
  
  return errorEvents;
}

// Store cache analytics in KV for dashboard
async function storeCacheAnalytics(events, env, ctx) {
  if (!env.BOOKS_CACHE) return;
  
  try {
    const timestamp = new Date().toISOString();
    const analyticsKey = `analytics:${Date.now()}`;
    
    const analytics = {
      timestamp,
      summary: {
        totalEvents: events.length,
        cacheHits: events.reduce((sum, e) => sum + e.cacheMetrics.filter(m => m.type === 'hit').length, 0),
        cacheMisses: events.reduce((sum, e) => sum + e.cacheMetrics.filter(m => m.type === 'miss').length, 0),
        errors: events.reduce((sum, e) => sum + e.errorMetrics.length, 0),
        rateLimitExceeded: events.reduce((sum, e) => 
          sum + (e.performanceMetrics?.type === 'rate_limit' && e.performanceMetrics?.status === 'exceeded' ? 1 : 0), 0
        )
      },
      events: events.map(event => ({
        timestamp: event.timestamp,
        url: event.url,
        method: event.method,
        responseStatus: event.responseStatus,
        outcome: event.outcome,
        cacheMetrics: event.cacheMetrics,
        performanceMetrics: event.performanceMetrics,
        errorMetrics: event.errorMetrics
      }))
    };
    
    // Store with 7-day expiration
    await env.BOOKS_CACHE.put(analyticsKey, JSON.stringify(analytics), { expirationTtl: 604800 });
    
    // Update aggregate metrics
    await updateAggregateMetrics(analytics.summary, env);
    
    console.log(`📊 STORED ANALYTICS: ${events.length} events, ${analytics.summary.cacheHits} hits, ${analytics.summary.cacheMisses} misses`);
  } catch (error) {
    console.error('Failed to store cache analytics:', error.message);
  }
}

// Update aggregate metrics for dashboard
async function updateAggregateMetrics(summary, env) {
  if (!env.BOOKS_CACHE) return;
  
  try {
    const today = new Date().toISOString().split('T')[0]; // YYYY-MM-DD
    const metricsKey = `metrics:daily:${today}`;
    
    const existing = await env.BOOKS_CACHE.get(metricsKey);
    const metrics = existing ? JSON.parse(existing) : {
      date: today,
      totalEvents: 0,
      cacheHits: 0,
      cacheMisses: 0,
      errors: 0,
      rateLimitExceeded: 0,
      cacheHitRate: 0
    };
    
    // Update metrics
    metrics.totalEvents += summary.totalEvents;
    metrics.cacheHits += summary.cacheHits;
    metrics.cacheMisses += summary.cacheMisses;
    metrics.errors += summary.errors;
    metrics.rateLimitExceeded += summary.rateLimitExceeded;
    
    // Calculate cache hit rate
    const totalCacheAttempts = metrics.cacheHits + metrics.cacheMisses;
    metrics.cacheHitRate = totalCacheAttempts > 0 ? (metrics.cacheHits / totalCacheAttempts) * 100 : 0;
    
    // Store with 30-day expiration
    await env.BOOKS_CACHE.put(metricsKey, JSON.stringify(metrics), { expirationTtl: 2592000 });
    
  } catch (error) {
    console.error('Failed to update aggregate metrics:', error.message);
  }
}

// Send analytics to external service (optional)
async function sendToExternalAnalytics(events, env, ctx) {
  // Only send if external analytics endpoint is configured
  if (!env.ANALYTICS_ENDPOINT) return;
  
  try {
    const payload = {
      source: 'books-api-proxy',
      timestamp: new Date().toISOString(),
      events: events.map(event => ({
        timestamp: event.timestamp,
        url: event.url,
        method: event.method,
        userAgent: event.userAgent,
        responseStatus: event.responseStatus,
        outcome: event.outcome,
        cacheHitRate: event.cacheMetrics.length > 0 ? 
          event.cacheMetrics.filter(m => m.type === 'hit').length / event.cacheMetrics.length : null,
        provider: event.performanceMetrics?.provider,
        errors: event.errorMetrics.length
      }))
    };
    
    const response = await fetch(env.ANALYTICS_ENDPOINT, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': env.ANALYTICS_API_KEY ? `Bearer ${env.ANALYTICS_API_KEY}` : undefined
      },
      body: JSON.stringify(payload)
    });
    
    if (!response.ok) {
      throw new Error(`Analytics endpoint returned ${response.status}`);
    }
    
    console.log(`📈 SENT TO ANALYTICS: ${events.length} events`);
  } catch (error) {
    console.error('Failed to send to external analytics:', error.message);
  }
}

// Update real-time metrics for monitoring
async function updateRealTimeMetrics(events, env, ctx) {
  if (!env.BOOKS_CACHE) return;
  
  try {
    const now = Date.now();
    const metricsKey = 'metrics:realtime';
    
    // Calculate current metrics
    const cacheHits = events.reduce((sum, e) => sum + e.cacheMetrics.filter(m => m.type === 'hit').length, 0);
    const cacheMisses = events.reduce((sum, e) => sum + e.cacheMetrics.filter(m => m.type === 'miss').length, 0);
    const errors = events.reduce((sum, e) => sum + e.errorMetrics.length, 0);
    
    const realTimeMetrics = {
      timestamp: now,
      lastUpdate: new Date().toISOString(),
      events: events.length,
      cacheHits,
      cacheMisses,
      errors,
      cacheHitRate: (cacheHits + cacheMisses) > 0 ? (cacheHits / (cacheHits + cacheMisses)) * 100 : 0,
      providers: {
        isbndb: events.filter(e => e.performanceMetrics?.provider === 'isbndb').length,
        google: events.filter(e => e.performanceMetrics?.provider === 'google-books').length,
        openlibrary: events.filter(e => e.performanceMetrics?.provider === 'open-library').length
      }
    };
    
    // Store with 1-hour expiration
    await env.BOOKS_CACHE.put(metricsKey, JSON.stringify(realTimeMetrics), { expirationTtl: 3600 });
    
    console.log(`⚡ REAL-TIME METRICS: ${realTimeMetrics.cacheHitRate.toFixed(1)}% cache hit rate`);
  } catch (error) {
    console.error('Failed to update real-time metrics:', error.message);
  }
}