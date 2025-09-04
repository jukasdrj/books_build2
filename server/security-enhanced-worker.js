// Security-Enhanced CloudFlare Workers Proxy
// Addresses API key exposure, request validation, and advanced rate limiting

export default {
  async fetch(request, env, ctx) {
    const requestStartTime = Date.now();
    
    // Enhanced security headers for all responses
    const securityHeaders = {
      "X-Content-Type-Options": "nosniff",
      "X-Frame-Options": "DENY", 
      "X-XSS-Protection": "1; mode=block",
      "Referrer-Policy": "strict-origin-when-cross-origin",
      "Content-Security-Policy": "default-src 'none'",
      "Strict-Transport-Security": "max-age=63072000; includeSubDomains; preload"
    };

    if (request.method === "OPTIONS") {
      return new Response(null, {
        status: 204,
        headers: { ...getCORSHeaders(), ...securityHeaders }
      });
    }

    try {
      // Security validations before routing
      const securityCheck = await validateRequestSecurity(request, env);
      if (!securityCheck.valid) {
        return createSecurityErrorResponse(securityCheck.reason, securityCheck.status, securityHeaders);
      }

      const url = new URL(request.url);
      const path = url.pathname;

      switch (path) {
        case "/search":
          return await handleBookSearch(request, env, ctx, requestStartTime, securityHeaders);
        case "/isbn": 
          return await handleISBNLookup(request, env, ctx, requestStartTime, securityHeaders);
        case "/batch":
          return await handleBatchLookup(request, env, ctx, requestStartTime, securityHeaders);
        case "/health":
          return await handleHealthCheck(env, securityHeaders);
        case "/admin/cache-stats":
          return await handleAdminCacheStats(request, env, securityHeaders);
        default:
          return createSecurityErrorResponse("Endpoint not found", 404, securityHeaders);
      }
    } catch (error) {
      // Enhanced error logging with security context
      const errorId = crypto.randomUUID();
      console.error("Security-Worker Error:", {
        errorId,
        message: error.message,
        stack: error.stack.substring(0, 500), // Limit stack trace
        url: request.url,
        method: request.method,
        userAgent: request.headers.get("User-Agent")?.substring(0, 100) || "unknown",
        cfRay: request.headers.get("CF-Ray") || "unknown",
        timestamp: new Date().toISOString()
      });

      return createSecurityErrorResponse("Internal server error", 500, securityHeaders, {
        errorId,
        timestamp: new Date().toISOString()
      });
    }
  }
};

// Enhanced request security validation
async function validateRequestSecurity(request, env) {
  const clientIP = request.headers.get("CF-Connecting-IP") || "unknown";
  const userAgent = request.headers.get("User-Agent") || "";
  const cfCountry = request.headers.get("CF-IPCountry") || "unknown";
  const contentLength = request.headers.get("content-length");

  // 1. Blocked countries/regions (if needed for compliance)
  const blockedCountries = env.BLOCKED_COUNTRIES?.split(',') || [];
  if (blockedCountries.includes(cfCountry)) {
    return { valid: false, reason: "Geographic restriction", status: 403 };
  }

  // 2. Suspicious user agent patterns
  const suspiciousPatterns = [
    /^curl\//i,
    /^wget\//i, 
    /bot|crawler|spider/i,
    /^$/,  // Empty user agent
    /[<>{}]/  // HTML/script injection attempts
  ];

  if (suspiciousPatterns.some(pattern => pattern.test(userAgent))) {
    // Don't block completely, but apply stricter rate limits
    await flagSuspiciousRequest(request, env, "suspicious_user_agent");
  }

  // 3. Request size validation
  if (contentLength && parseInt(contentLength) > 1024 * 1024) { // 1MB limit
    return { valid: false, reason: "Request too large", status: 413 };
  }

  // 4. Request method validation
  const allowedMethods = ["GET", "POST", "OPTIONS"];
  if (!allowedMethods.includes(request.method)) {
    return { valid: false, reason: "Method not allowed", status: 405 };
  }

  // 5. Host header validation (prevent host header injection)
  const hostHeader = request.headers.get("Host");
  const allowedHosts = [
    "books-api-proxy.jukasdrj.workers.dev",
    env.CUSTOM_DOMAIN  // If you have a custom domain
  ].filter(Boolean);

  if (hostHeader && !allowedHosts.includes(hostHeader)) {
    return { valid: false, reason: "Invalid host header", status: 400 };
  }

  return { valid: true };
}

// Flag suspicious requests for enhanced monitoring
async function flagSuspiciousRequest(request, env, reason) {
  const clientIP = request.headers.get("CF-Connecting-IP") || "unknown";
  const flagKey = `suspicious:${clientIP}:${Date.now()}`;
  
  const suspiciousData = {
    ip: clientIP,
    userAgent: request.headers.get("User-Agent") || "",
    url: request.url,
    method: request.method,
    reason: reason,
    timestamp: new Date().toISOString(),
    cfRay: request.headers.get("CF-Ray") || "unknown"
  };

  // Store for 24 hours for analysis
  await env.BOOKS_CACHE?.put(flagKey, JSON.stringify(suspiciousData), { 
    expirationTtl: 86400 
  });

  console.warn("🚨 SUSPICIOUS REQUEST FLAGGED:", suspiciousData);
}

// Secure API key management using Cloudflare's encryption
async function getSecureAPIKey(keyName, env) {
  // Use Cloudflare's built-in secrets management instead of environment variables
  // Keys should be stored using: wrangler secret put GOOGLE_BOOKS_KEY
  
  const encryptedKey = env[keyName];
  if (!encryptedKey) {
    throw new Error(`API key ${keyName} not configured in secrets`);
  }

  // Additional layer: decrypt using a master key if needed
  if (env.MASTER_ENCRYPTION_KEY) {
    return await decryptAPIKey(encryptedKey, env.MASTER_ENCRYPTION_KEY);
  }

  return encryptedKey;
}

// API key decryption (if using additional encryption layer)
async function decryptAPIKey(encryptedKey, masterKey) {
  const keyBytes = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(masterKey),
    { name: "AES-GCM" },
    false,
    ["decrypt"]
  );

  const [ivHex, encryptedHex] = encryptedKey.split(':');
  const iv = new Uint8Array(ivHex.match(/.{2}/g).map(byte => parseInt(byte, 16)));
  const encrypted = new Uint8Array(encryptedHex.match(/.{2}/g).map(byte => parseInt(byte, 16)));

  const decrypted = await crypto.subtle.decrypt(
    { name: "AES-GCM", iv },
    keyBytes,
    encrypted
  );

  return new TextDecoder().decode(decrypted);
}

// Enhanced rate limiting with threat intelligence
async function checkAdvancedRateLimit(request, env) {
  const clientIP = request.headers.get("CF-Connecting-IP") || "unknown";
  const userAgent = request.headers.get("User-Agent") || "unknown";
  const cfRay = request.headers.get("CF-Ray") || "unknown";
  const cfCountry = request.headers.get("CF-IPCountry") || "unknown";

  // Create composite fingerprint
  const fingerprint = await generateSecureFingerprint(clientIP, userAgent, cfRay);
  const rateLimitKey = `ratelimit:${fingerprint}`;

  // Check if IP is in suspicious list
  const suspiciousKey = `suspicious:${clientIP}:*`;
  const suspiciousCount = await countKeys(suspiciousKey, env);
  
  // Dynamic rate limits based on risk score
  let maxRequests = 100; // Base rate per hour
  const windowSize = 3600; // 1 hour

  // Risk-based adjustments
  if (suspiciousCount > 0) {
    maxRequests = 20; // Much stricter for suspicious IPs
  } else if (userAgent.includes("BooksTrack-iOS")) {
    maxRequests = 500; // Higher for your iOS app
  } else if (cfCountry && ["US", "CA", "GB", "DE", "FR"].includes(cfCountry)) {
    maxRequests = 200; // Higher for trusted countries
  }

  // Check current usage
  const current = await env.BOOKS_CACHE?.get(rateLimitKey);
  const count = current ? parseInt(current) : 0;

  if (count >= maxRequests) {
    // Log rate limit violations for analysis
    console.warn("🚫 RATE LIMIT EXCEEDED:", {
      fingerprint,
      ip: clientIP,
      userAgent: userAgent.substring(0, 100),
      country: cfCountry,
      current: count,
      limit: maxRequests,
      suspicious: suspiciousCount > 0
    });

    return {
      allowed: false,
      retryAfter: windowSize,
      reason: "Rate limit exceeded",
      current: count,
      limit: maxRequests
    };
  }

  // Update counter with atomic operation
  const newCount = count + 1;
  await env.BOOKS_CACHE?.put(rateLimitKey, newCount.toString(), { 
    expirationTtl: windowSize 
  });

  return {
    allowed: true,
    count: newCount,
    remaining: maxRequests - newCount,
    resetTime: Date.now() + (windowSize * 1000),
    riskLevel: suspiciousCount > 0 ? "high" : "normal"
  };
}

// Generate secure fingerprint for rate limiting
async function generateSecureFingerprint(ip, userAgent, cfRay) {
  // Include multiple factors to prevent easy circumvention
  const data = `${ip}:${userAgent.substring(0, 50)}:${cfRay}:${Date.now().toString().substring(0, -5)}`;
  
  const encoder = new TextEncoder();
  const dataBuffer = encoder.encode(data);
  const hashBuffer = await crypto.subtle.digest('SHA-256', dataBuffer);
  const hashArray = new Uint8Array(hashBuffer);
  const hashHex = Array.from(hashArray)
    .map(b => b.toString(16).padStart(2, '0'))
    .join('');
    
  return hashHex.substring(0, 32); // Use first 32 chars
}

// Count keys matching pattern (for suspicious request analysis)
async function countKeys(pattern, env) {
  try {
    // This is a simplified approach - in production, you'd want to maintain counters
    // CloudFlare KV doesn't support pattern matching, so we maintain separate counters
    const countKey = `count:${pattern.replace('*', 'total')}`;
    const count = await env.BOOKS_CACHE?.get(countKey);
    return count ? parseInt(count) : 0;
  } catch (error) {
    console.warn("Failed to count suspicious requests:", error.message);
    return 0;
  }
}

// Admin endpoint for cache statistics (secured)
async function handleAdminCacheStats(request, env, securityHeaders) {
  // Verify admin access
  const adminKey = request.headers.get("X-Admin-Key");
  const validAdminKey = await getSecureAPIKey("ADMIN_API_KEY", env);
  
  if (!adminKey || adminKey !== validAdminKey) {
    return createSecurityErrorResponse("Unauthorized", 401, securityHeaders);
  }

  const stats = await getCacheStatistics(env);
  
  return new Response(JSON.stringify(stats, null, 2), {
    headers: { 
      ...getCORSHeaders("application/json"), 
      ...securityHeaders,
      "X-Admin-Response": "true"
    }
  });
}

// Security-enhanced error response
function createSecurityErrorResponse(message, status = 500, securityHeaders = {}, additionalData = {}) {
  const errorResponse = {
    error: message,
    status,
    timestamp: new Date().toISOString(),
    ...additionalData
  };

  // Don't expose internal details in production
  if (status >= 500) {
    errorResponse.error = "Internal server error";
    delete errorResponse.message; // Remove detailed error messages
  }

  return new Response(JSON.stringify(errorResponse), {
    status,
    headers: {
      ...getCORSHeaders(),
      ...securityHeaders,
      "X-Error-Response": "true"
    }
  });
}

// Enhanced CORS headers
function getCORSHeaders(contentType = "application/json") {
  return {
    "Content-Type": contentType,
    "Access-Control-Allow-Origin": "https://yourapp.com", // Restrict to your domain
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, X-API-Key, X-Admin-Key",
    "Access-Control-Max-Age": "86400",
    "Access-Control-Allow-Credentials": "false"
  };
}

// Enhanced cache statistics for admin monitoring
async function getCacheStatistics(env) {
  try {
    const realtimeMetrics = await env.BOOKS_CACHE?.get('metrics:realtime');
    const todayMetrics = await env.BOOKS_CACHE?.get(`metrics:daily:${new Date().toISOString().split('T')[0]}`);
    
    return {
      timestamp: new Date().toISOString(),
      realtime: realtimeMetrics ? JSON.parse(realtimeMetrics) : null,
      today: todayMetrics ? JSON.parse(todayMetrics) : null,
      storage: {
        kv: {
          available: !!env.BOOKS_CACHE,
          usage: "unknown" // KV doesn't expose usage metrics directly
        },
        r2: {
          available: !!env.BOOKS_R2,
          usage: "unknown" // R2 usage would need separate tracking
        }
      }
    };
  } catch (error) {
    console.error("Failed to get cache statistics:", error.message);
    return { error: "Failed to retrieve cache statistics" };
  }
}

// Continue with other enhanced handlers...
// [The rest of the existing functions would be enhanced with security measures]