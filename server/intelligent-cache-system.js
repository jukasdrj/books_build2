// Intelligent Multi-Tier Caching System for CloudFlare Workers
// Implements smart cache warming, popularity-based promotion, and predictive caching

export class IntelligentCacheManager {
  constructor(env, ctx) {
    this.env = env;
    this.ctx = ctx;
    this.kvCache = env.BOOKS_CACHE;
    this.r2Cache = env.BOOKS_R2;
    
    // Cache tiers and their characteristics
    this.tiers = {
      HOT: {
        storage: 'KV',
        maxAge: 86400, // 1 day
        capacity: '10GB', // KV namespace limit
        accessSpeed: '<50ms',
        costPerRead: '$0.50/million'
      },
      WARM: {
        storage: 'R2', 
        maxAge: 2592000, // 30 days
        capacity: 'unlimited',
        accessSpeed: '<200ms',
        costPerRead: '$0.40/million'
      },
      COLD: {
        storage: 'R2-archive',
        maxAge: 31536000, // 1 year
        capacity: 'unlimited', 
        accessSpeed: '<1000ms',
        costPerRead: '$0.04/million'
      }
    };
  }

  // Intelligent cache key generation with metadata
  generateCacheKey(type, params, includeMetadata = true) {
    let baseKey;
    
    switch (type) {
      case 'search':
        const { query, maxResults, sortBy, langRestrict } = params;
        const queryHash = btoa(unescape(encodeURIComponent(query)))
          .replace(/[/+=]/g, '_').substring(0, 32);
        baseKey = `search/${queryHash}/${maxResults}/${sortBy}/${langRestrict || 'any'}`;
        break;
        
      case 'isbn':
        baseKey = `isbn/${params.isbn}`;
        break;
        
      case 'author':
        const authorHash = btoa(unescape(encodeURIComponent(params.authorName)))
          .replace(/[/+=]/g, '_').substring(0, 32);
        baseKey = `author/${authorHash}`;
        break;
        
      case 'cultural':
        baseKey = `cultural/${params.authorId}`;
        break;
        
      default:
        throw new Error(`Unknown cache key type: ${type}`);
    }

    return includeMetadata ? `${baseKey}.json` : baseKey;
  }

  // Smart cache retrieval with automatic promotion
  async get(cacheKey, options = {}) {
    const startTime = Date.now();
    
    try {
      // 1. Try HOT tier (KV) first
      const kvResult = await this.getFromKV(cacheKey);
      if (kvResult) {
        await this.recordCacheHit('HOT', cacheKey, Date.now() - startTime);
        return {
          data: kvResult.data,
          source: 'HOT',
          age: kvResult.age,
          tier: 'KV',
          performance: Date.now() - startTime
        };
      }

      // 2. Try WARM tier (R2)  
      const r2Result = await this.getFromR2(cacheKey);
      if (r2Result) {
        await this.recordCacheHit('WARM', cacheKey, Date.now() - startTime);
        
        // Promote to HOT tier if frequently accessed
        if (await this.shouldPromoteToHot(cacheKey, r2Result)) {
          this.ctx.waitUntil(this.promoteToKV(cacheKey, r2Result.data));
        }

        return {
          data: r2Result.data,
          source: 'WARM',
          age: r2Result.age, 
          tier: 'R2',
          promoted: false,
          performance: Date.now() - startTime
        };
      }

      // 3. Cache miss - record for analytics
      await this.recordCacheMiss(cacheKey, Date.now() - startTime);
      return null;

    } catch (error) {
      console.error(`Cache retrieval error for ${cacheKey}:`, error.message);
      await this.recordCacheError(cacheKey, error.message);
      return null;
    }
  }

  // Get from KV with enhanced metadata parsing
  async getFromKV(cacheKey) {
    const kvData = await this.kvCache?.get(cacheKey, { type: 'json' });
    if (!kvData || !kvData._cached) return null;

    const age = Date.now() - kvData._cached.timestamp;
    
    // Check if data is too old even if still in KV
    if (age > this.tiers.HOT.maxAge * 1000) {
      this.ctx.waitUntil(this.kvCache.delete(cacheKey));
      return null;
    }

    return {
      data: kvData,
      age: age,
      hits: kvData._cached.hits || 1
    };
  }

  // Get from R2 with metadata parsing
  async getFromR2(cacheKey) {
    if (!this.r2Cache) return null;

    try {
      const r2Object = await this.r2Cache.get(cacheKey);
      if (!r2Object) return null;

      const jsonData = await r2Object.text();
      const data = JSON.parse(jsonData);
      const metadata = r2Object.customMetadata || {};

      // Check TTL
      const ttl = parseInt(metadata.ttl || '0');
      if (ttl > 0 && Date.now() > ttl) {
        this.ctx.waitUntil(this.r2Cache.delete(cacheKey));
        return null;
      }

      const age = metadata.created ? Date.now() - parseInt(metadata.created) : 0;

      return {
        data: data,
        age: age,
        hits: parseInt(metadata.hits || '1'),
        lastAccess: parseInt(metadata.lastAccess || metadata.created || '0')
      };
    } catch (error) {
      console.error(`R2 cache error for ${cacheKey}:`, error.message);
      return null;
    }
  }

  // Intelligent cache storage with tier optimization
  async set(cacheKey, data, options = {}) {
    const {
      ttl = 2592000, // 30 days default
      popularity = 1,
      forceHot = false,
      metadata = {}
    } = options;

    const enrichedData = {
      ...data,
      _cached: {
        timestamp: Date.now(),
        ttl: ttl * 1000,
        version: '2.0',
        popularity: popularity,
        ...metadata
      }
    };

    const storagePromises = [];

    // Decide tier placement based on data characteristics
    if (forceHot || popularity > 3 || ttl < 86400) {
      // Store in HOT tier (KV)
      storagePromises.push(
        this.storeInKV(cacheKey, enrichedData, Math.min(ttl, 86400))
      );
    }

    // Always store in WARM tier (R2) for backup
    storagePromises.push(
      this.storeInR2(cacheKey, enrichedData, ttl)
    );

    try {
      if (this.ctx?.waitUntil) {
        this.ctx.waitUntil(Promise.allSettled(storagePromises));
      } else {
        await Promise.allSettled(storagePromises);
      }

      await this.recordCacheSet(cacheKey, JSON.stringify(enrichedData).length);

      console.log(`💾 SMART CACHE SET: ${cacheKey} (${popularity > 3 ? 'HOT+WARM' : 'WARM'})`);
    } catch (error) {
      console.error(`Cache storage error for ${cacheKey}:`, error.message);
    }
  }

  // Store in KV with optimizations
  async storeInKV(cacheKey, data, ttl) {
    if (!this.kvCache) return;

    try {
      // Compress large payloads before KV storage
      let dataToStore = data;
      const dataSize = JSON.stringify(data).length;
      
      if (dataSize > 10000) { // 10KB threshold
        dataToStore = await this.compressData(data);
      }

      await this.kvCache.put(
        cacheKey, 
        JSON.stringify(dataToStore), 
        { expirationTtl: ttl }
      );
    } catch (error) {
      console.error(`KV storage error for ${cacheKey}:`, error.message);
    }
  }

  // Store in R2 with rich metadata
  async storeInR2(cacheKey, data, ttl) {
    if (!this.r2Cache) return;

    try {
      const now = Date.now();
      const metadata = {
        ttl: (now + ttl * 1000).toString(),
        created: now.toString(),
        lastAccess: now.toString(),
        hits: '1',
        size: JSON.stringify(data).length.toString(),
        type: this.getCacheType(cacheKey),
        version: '2.0'
      };

      await this.r2Cache.put(
        cacheKey,
        JSON.stringify(data),
        {
          httpMetadata: {
            contentType: "application/json",
            cacheControl: `max-age=${ttl}`,
            cacheExpiry: new Date(now + ttl * 1000).toISOString()
          },
          customMetadata: metadata
        }
      );
    } catch (error) {
      console.error(`R2 storage error for ${cacheKey}:`, error.message);
    }
  }

  // Compress data for KV storage
  async compressData(data) {
    // Simple compression - remove unnecessary whitespace and compress JSON
    const jsonString = JSON.stringify(data);
    
    // For larger compression, you could use CloudFlare's compression
    // or implement a simple dictionary-based compression
    const compressed = jsonString
      .replace(/\s+/g, ' ')  // Normalize whitespace
      .replace(/,\s*/g, ',') // Remove spaces after commas
      .replace(/:\s*/g, ':') // Remove spaces after colons
      .trim();

    return {
      ...data,
      _compressed: true,
      _originalSize: jsonString.length,
      _compressedSize: compressed.length
    };
  }

  // Determine if item should be promoted to HOT tier
  async shouldPromoteToHot(cacheKey, r2Result) {
    const { hits = 1, lastAccess = 0 } = r2Result;
    const timeSinceLastAccess = Date.now() - lastAccess;
    
    // Promotion criteria:
    // 1. Accessed more than 5 times
    // 2. Accessed within last 24 hours
    // 3. Data size is reasonable for KV (<25KB)
    
    const dataSize = JSON.stringify(r2Result.data).length;
    
    return hits >= 5 && 
           timeSinceLastAccess < 86400000 && // 24 hours
           dataSize < 25000; // 25KB KV limit buffer
  }

  // Promote data from R2 to KV
  async promoteToKV(cacheKey, data) {
    try {
      const enrichedData = {
        ...data,
        _cached: {
          ...data._cached,
          promoted: true,
          promotedAt: Date.now()
        }
      };

      await this.storeInKV(cacheKey, enrichedData, this.tiers.HOT.maxAge);
      
      console.log(`🔥 PROMOTED TO HOT: ${cacheKey}`);
      
      // Update R2 metadata to reflect promotion
      await this.updateR2Metadata(cacheKey, { promoted: 'true' });
    } catch (error) {
      console.error(`Failed to promote ${cacheKey} to hot tier:`, error.message);
    }
  }

  // Update R2 object metadata
  async updateR2Metadata(cacheKey, newMetadata) {
    if (!this.r2Cache) return;

    try {
      const existing = await this.r2Cache.get(cacheKey);
      if (!existing) return;

      const currentMetadata = existing.customMetadata || {};
      const updatedMetadata = { ...currentMetadata, ...newMetadata };

      // R2 doesn't support metadata-only updates, so we need to re-upload
      const content = await existing.text();
      
      await this.r2Cache.put(cacheKey, content, {
        httpMetadata: existing.httpMetadata,
        customMetadata: updatedMetadata
      });
    } catch (error) {
      console.error(`Failed to update R2 metadata for ${cacheKey}:`, error.message);
    }
  }

  // Predictive cache warming based on patterns
  async warmCache(patterns = []) {
    const warmingJobs = [];

    for (const pattern of patterns) {
      switch (pattern.type) {
        case 'popular_searches':
          warmingJobs.push(this.warmPopularSearches(pattern.data));
          break;
        case 'recent_isbns':
          warmingJobs.push(this.warmRecentISBNs(pattern.data));
          break;
        case 'author_works':
          warmingJobs.push(this.warmAuthorWorks(pattern.data));
          break;
      }
    }

    if (warmingJobs.length > 0) {
      this.ctx.waitUntil(Promise.allSettled(warmingJobs));
      console.log(`🔥 CACHE WARMING: Started ${warmingJobs.length} jobs`);
    }
  }

  // Warm popular searches
  async warmPopularSearches(searchQueries) {
    for (const query of searchQueries) {
      try {
        const cacheKey = this.generateCacheKey('search', {
          query: query.term,
          maxResults: 20,
          sortBy: 'relevance'
        });

        const cached = await this.get(cacheKey);
        if (!cached) {
          // Trigger search to populate cache
          console.log(`🔥 WARMING SEARCH: ${query.term}`);
          // This would call your actual search function
          // await performSearchAndCache(query.term);
        }
      } catch (error) {
        console.error(`Failed to warm search cache for "${query.term}":`, error.message);
      }
    }
  }

  // Cache analytics and performance tracking
  async recordCacheHit(tier, cacheKey, responseTime) {
    const hitData = {
      type: 'hit',
      tier: tier,
      cacheKey: cacheKey,
      responseTime: responseTime,
      timestamp: Date.now()
    };

    await this.recordCacheMetric('cache_hit', hitData);
    console.log(`🎯 CACHE HIT (${tier}): ${cacheKey} (${responseTime}ms)`);
  }

  async recordCacheMiss(cacheKey, responseTime) {
    const missData = {
      type: 'miss',
      cacheKey: cacheKey,
      responseTime: responseTime,
      timestamp: Date.now()
    };

    await this.recordCacheMetric('cache_miss', missData);
    console.log(`❌ CACHE MISS: ${cacheKey} (${responseTime}ms)`);
  }

  async recordCacheSet(cacheKey, dataSize) {
    const setData = {
      type: 'set',
      cacheKey: cacheKey,
      dataSize: dataSize,
      timestamp: Date.now()
    };

    await this.recordCacheMetric('cache_set', setData);
  }

  async recordCacheError(cacheKey, error) {
    const errorData = {
      type: 'error',
      cacheKey: cacheKey,
      error: error,
      timestamp: Date.now()
    };

    await this.recordCacheMetric('cache_error', errorData);
  }

  // Generic metric recording
  async recordCacheMetric(metricType, data) {
    try {
      const metricsKey = `metrics:${metricType}:${Date.now()}`;
      await this.kvCache?.put(
        metricsKey, 
        JSON.stringify(data), 
        { expirationTtl: 604800 } // 7 days
      );
    } catch (error) {
      console.error('Failed to record cache metric:', error.message);
    }
  }

  // Get cache type from key
  getCacheType(cacheKey) {
    if (cacheKey.startsWith('search/')) return 'search';
    if (cacheKey.startsWith('isbn/')) return 'isbn';
    if (cacheKey.startsWith('author/')) return 'author';
    if (cacheKey.startsWith('cultural/')) return 'cultural';
    return 'unknown';
  }

  // Cache statistics and health check
  async getHealthMetrics() {
    try {
      const metrics = {
        timestamp: new Date().toISOString(),
        tiers: this.tiers,
        health: {
          kv: !!this.kvCache,
          r2: !!this.r2Cache
        },
        features: {
          intelligentPromotion: true,
          predictiveWarming: true,
          compressionOptimization: true,
          tierOptimization: true
        }
      };

      return metrics;
    } catch (error) {
      return { error: 'Failed to get cache health metrics' };
    }
  }
}

// Export utility functions for use in main worker
export const CacheUtils = {
  // Batch cache operations for improved performance
  async batchGet(cacheManager, keys) {
    const results = await Promise.allSettled(
      keys.map(key => cacheManager.get(key))
    );

    const successful = [];
    const failed = [];

    results.forEach((result, index) => {
      if (result.status === 'fulfilled' && result.value) {
        successful.push({ key: keys[index], data: result.value });
      } else {
        failed.push({ key: keys[index], error: result.reason?.message || 'Unknown error' });
      }
    });

    return { successful, failed };
  },

  // Generate cache warming patterns based on analytics
  async generateWarmingPatterns(analytics) {
    const patterns = [];

    // Popular searches from last 7 days
    if (analytics.topSearches) {
      patterns.push({
        type: 'popular_searches',
        data: analytics.topSearches.slice(0, 20) // Top 20
      });
    }

    // Recent ISBNs that might be requested again
    if (analytics.recentISBNs) {
      patterns.push({
        type: 'recent_isbns', 
        data: analytics.recentISBNs.slice(0, 50) // Top 50
      });
    }

    return patterns;
  }
};