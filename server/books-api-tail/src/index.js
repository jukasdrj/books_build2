/**
 * Books API Proxy Tail Worker
 * Monitors logs, performance metrics, and error patterns from the main books API proxy
 */

export default {
  async tail(events, env, ctx) {
    const processedEvents = [];
    
    for (const event of events) {
      try {
        const processedEvent = await processEvent(event);
        if (processedEvent) {
          processedEvents.push(processedEvent);
        }
      } catch (error) {
        console.error('Error processing tail event:', error);
      }
    }

    // Batch process events for efficiency
    if (processedEvents.length > 0) {
      await Promise.allSettled([
        sendToAnalytics(processedEvents, env),
        checkForAlerts(processedEvents, env),
        updateMetrics(processedEvents, env)
      ]);
    }
  }
};

/**
 * Process individual tail event from books API proxy
 */
async function processEvent(event) {
  const { outcome, logs, exceptions, eventTimestamp, event: eventData } = event;
  
  // Extract request details
  const request = eventData?.request;
  const response = eventData?.response;
  
  if (!request) return null;

  const url = new URL(request.url);
  const method = request.method;
  const userAgent = request.headers?.['User-Agent'] || 'unknown';
  
  // Process logs for structured data
  const structuredLogs = logs.map(log => {
    try {
      // Try to parse JSON logs from the main worker
      if (log.message && typeof log.message === 'string' && log.message.startsWith('{')) {
        return { ...log, parsedMessage: JSON.parse(log.message) };
      }
    } catch (e) {
      // Not JSON, keep original
    }
    return log;
  });

  // Extract performance metrics
  const performanceMetrics = extractPerformanceMetrics(structuredLogs);
  
  // Extract cache metrics
  const cacheMetrics = extractCacheMetrics(structuredLogs);
  
  // Extract API usage patterns
  const apiUsage = extractAPIUsagePattern(url, method, structuredLogs);

  return {
    timestamp: eventTimestamp,
    outcome: outcome,
    request: {
      method: method,
      url: url.pathname + url.search,
      userAgent: sanitizeUserAgent(userAgent),
      country: request.cf?.country || 'unknown',
      colo: request.cf?.colo || 'unknown'
    },
    response: {
      status: response?.status,
      headers: response?.headers ? Object.keys(response.headers) : []
    },
    performance: performanceMetrics,
    cache: cacheMetrics,
    apiUsage: apiUsage,
    logs: structuredLogs,
    exceptions: exceptions,
    errorDetails: exceptions?.length > 0 ? exceptions[0] : null
  };
}

/**
 * Extract performance metrics from worker logs
 */
function extractPerformanceMetrics(logs) {
  const metrics = {
    totalDuration: null,
    cacheHit: false,
    cacheType: null,
    apiCallsCount: 0,
    apiDuration: null
  };

  for (const log of logs) {
    const msg = log.parsedMessage || log.message;
    
    if (typeof msg === 'object') {
      if (msg.type === 'performance') {
        metrics.totalDuration = msg.duration;
      } else if (msg.type === 'cache') {
        metrics.cacheHit = msg.hit;
        metrics.cacheType = msg.type;
      } else if (msg.type === 'api_call') {
        metrics.apiCallsCount++;
        metrics.apiDuration = (metrics.apiDuration || 0) + (msg.duration || 0);
      }
    } else if (typeof msg === 'string') {
      // Parse string-based performance logs
      if (msg.includes('Cache HIT')) {
        metrics.cacheHit = true;
        metrics.cacheType = 'kv';
      } else if (msg.includes('R2 Cache HIT')) {
        metrics.cacheHit = true;
        metrics.cacheType = 'r2';
      } else if (msg.includes('API call to')) {
        metrics.apiCallsCount++;
      }
    }
  }

  return metrics;
}

/**
 * Extract cache performance metrics
 */
function extractCacheMetrics(logs) {
  const metrics = {
    kvReads: 0,
    kvWrites: 0,
    r2Reads: 0,
    r2Writes: 0,
    hitRate: null,
    missReason: null
  };

  for (const log of logs) {
    const msg = log.parsedMessage || log.message;
    
    if (typeof msg === 'string') {
      if (msg.includes('KV read')) metrics.kvReads++;
      if (msg.includes('KV write')) metrics.kvWrites++;
      if (msg.includes('R2 read')) metrics.r2Reads++;
      if (msg.includes('R2 write')) metrics.r2Writes++;
      if (msg.includes('Cache MISS:')) {
        metrics.missReason = msg.split('Cache MISS: ')[1]?.split(' ')[0];
      }
    }
  }

  return metrics;
}

/**
 * Extract API usage patterns
 */
function extractAPIUsagePattern(url, method, logs) {
  const searchParams = new URLSearchParams(url.search);
  
  return {
    endpoint: url.pathname,
    method: method,
    searchQuery: searchParams.get('q') ? 'present' : 'none',
    searchType: searchParams.get('type') || 'books',
    hasFilters: searchParams.has('author') || searchParams.has('subject'),
    language: searchParams.get('lang') || 'all',
    cacheWarming: searchParams.has('cache_warming'),
    apiProvider: extractAPIProvider(logs)
  };
}

/**
 * Determine which API provider was used
 */
function extractAPIProvider(logs) {
  for (const log of logs) {
    const msg = log.message || '';
    if (msg.includes('googleapis.com')) return 'google_books';
    if (msg.includes('isbndb.com')) return 'isbndb';
    if (msg.includes('openlibrary.org')) return 'open_library';
  }
  return 'unknown';
}

/**
 * Sanitize user agent for privacy
 */
function sanitizeUserAgent(userAgent) {
  // Keep only general browser/app info, remove detailed versions
  return userAgent
    .replace(/\/[\d.]+/g, '/x.x.x')  // Remove version numbers
    .substring(0, 100);  // Limit length
}

/**
 * Send processed events to analytics
 */
async function sendToAnalytics(events, env) {
  try {
    // Store hourly aggregated metrics in KV
    const hour = new Date().toISOString().substring(0, 13); // YYYY-MM-DDTHH
    const key = `analytics:${hour}`;
    
    // Get existing metrics or initialize
    let hourlyMetrics = {};
    try {
      const existing = await env.TAIL_ANALYTICS?.get(key);
      hourlyMetrics = existing ? JSON.parse(existing) : {};
    } catch (e) {
      console.warn('Could not read existing analytics:', e);
    }

    // Aggregate new events
    for (const event of events) {
      aggregateMetrics(hourlyMetrics, event);
    }

    // Store updated metrics (TTL: 7 days)
    await env.TAIL_ANALYTICS?.put(key, JSON.stringify(hourlyMetrics), {
      expirationTtl: 7 * 24 * 60 * 60
    });

  } catch (error) {
    console.error('Analytics storage failed:', error);
  }
}

/**
 * Aggregate event metrics into hourly summaries
 */
function aggregateMetrics(hourlyMetrics, event) {
  // Initialize if needed
  if (!hourlyMetrics.requests) {
    hourlyMetrics.requests = 0;
    hourlyMetrics.errors = 0;
    hourlyMetrics.cacheHits = 0;
    hourlyMetrics.cacheMisses = 0;
    hourlyMetrics.totalDuration = 0;
    hourlyMetrics.apiCalls = 0;
    hourlyMetrics.countries = {};
    hourlyMetrics.endpoints = {};
    hourlyMetrics.providers = {};
  }

  // Aggregate metrics
  hourlyMetrics.requests++;
  
  if (event.outcome !== 'ok') {
    hourlyMetrics.errors++;
  }

  if (event.cache?.cacheHit) {
    hourlyMetrics.cacheHits++;
  } else {
    hourlyMetrics.cacheMisses++;
  }

  if (event.performance?.totalDuration) {
    hourlyMetrics.totalDuration += event.performance.totalDuration;
  }

  if (event.performance?.apiCallsCount) {
    hourlyMetrics.apiCalls += event.performance.apiCallsCount;
  }

  // Track geographic distribution
  const country = event.request?.country || 'unknown';
  hourlyMetrics.countries[country] = (hourlyMetrics.countries[country] || 0) + 1;

  // Track endpoint usage
  const endpoint = event.apiUsage?.endpoint || 'unknown';
  hourlyMetrics.endpoints[endpoint] = (hourlyMetrics.endpoints[endpoint] || 0) + 1;

  // Track API provider usage
  const provider = event.apiUsage?.apiProvider || 'unknown';
  hourlyMetrics.providers[provider] = (hourlyMetrics.providers[provider] || 0) + 1;
}

/**
 * Check for alert conditions
 */
async function checkForAlerts(events, env) {
  const alerts = [];
  
  // Count various conditions
  let errorCount = 0;
  let slowRequestCount = 0;
  let cacheMissCount = 0;
  
  for (const event of events) {
    if (event.outcome !== 'ok') {
      errorCount++;
    }
    
    if (event.performance?.totalDuration > 5000) { // >5s
      slowRequestCount++;
    }
    
    if (!event.cache?.cacheHit) {
      cacheMissCount++;
    }
  }

  // Alert thresholds
  const totalEvents = events.length;
  const errorRate = errorCount / totalEvents;
  const slowRate = slowRequestCount / totalEvents;
  const missRate = cacheMissCount / totalEvents;

  if (errorRate > 0.1) { // >10% error rate
    alerts.push({
      type: 'high_error_rate',
      severity: 'critical',
      message: `High error rate: ${(errorRate * 100).toFixed(1)}% (${errorCount}/${totalEvents})`,
      timestamp: new Date().toISOString()
    });
  }

  if (slowRate > 0.2) { // >20% slow requests
    alerts.push({
      type: 'slow_requests',
      severity: 'warning',
      message: `High slow request rate: ${(slowRate * 100).toFixed(1)}% (${slowRequestCount}/${totalEvents})`,
      timestamp: new Date().toISOString()
    });
  }

  if (missRate > 0.5) { // >50% cache miss rate
    alerts.push({
      type: 'cache_performance',
      severity: 'info',
      message: `High cache miss rate: ${(missRate * 100).toFixed(1)}% (${cacheMissCount}/${totalEvents})`,
      timestamp: new Date().toISOString()
    });
  }

  // Store alerts if any
  if (alerts.length > 0) {
    console.log('📢 ALERTS DETECTED:', JSON.stringify(alerts, null, 2));
    
    // Store latest alerts in KV for dashboard access
    try {
      await env.TAIL_ANALYTICS?.put('alerts:latest', JSON.stringify({
        timestamp: new Date().toISOString(),
        alerts: alerts
      }), {
        expirationTtl: 24 * 60 * 60 // 24 hours
      });
    } catch (error) {
      console.error('Failed to store alerts:', error);
    }
  }
}

/**
 * Update real-time metrics
 */
async function updateMetrics(events, env) {
  try {
    const now = new Date();
    const minute = now.toISOString().substring(0, 16); // YYYY-MM-DDTHHMM
    
    // Real-time metrics (short TTL)
    const realtimeMetrics = {
      timestamp: now.toISOString(),
      requestCount: events.length,
      errorCount: events.filter(e => e.outcome !== 'ok').length,
      cacheHitCount: events.filter(e => e.cache?.cacheHit).length,
      avgDuration: events.reduce((sum, e) => sum + (e.performance?.totalDuration || 0), 0) / events.length || 0
    };

    await env.TAIL_ANALYTICS?.put(`realtime:${minute}`, JSON.stringify(realtimeMetrics), {
      expirationTtl: 60 * 60 // 1 hour
    });

  } catch (error) {
    console.error('Real-time metrics update failed:', error);
  }
}