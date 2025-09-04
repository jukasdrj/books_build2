// API Quota Optimization System for CloudFlare Workers
// Maximizes daily API usage through intelligent batching and prioritization

export class QuotaOptimizationManager {
  constructor(env, ctx) {
    this.env = env;
    this.ctx = ctx;
    
    // API quotas and costs (daily limits)
    this.quotas = {
      googleBooks: {
        free: { limit: 1000, cost: 0, currentUsed: 0 },
        paid: { limit: 100000, cost: 0.001, currentUsed: 0 } // $1 per 1000 queries
      },
      isbndb: {
        starter: { limit: 500, cost: 0, currentUsed: 0 },
        premium: { limit: 10000, cost: 49, currentUsed: 0 }, // $49/month
        pro: { limit: 100000, cost: 199, currentUsed: 0 }    // $199/month
      },
      openLibrary: {
        free: { limit: Infinity, cost: 0, currentUsed: 0 } // No explicit limits, be respectful
      }
    };

    // Batch processing configuration
    this.batchConfig = {
      maxBatchSize: 50,
      maxConcurrent: 3,
      priorityLevels: ['critical', 'high', 'normal', 'low', 'background']
    };
  }

  // Intelligent quota management and provider selection
  async selectOptimalProvider(requestType, priority = 'normal', metadata = {}) {
    const quotaStatus = await this.getCurrentQuotaStatus();
    const providers = await this.rankProviders(requestType, quotaStatus, priority, metadata);
    
    return providers[0]; // Return best option
  }

  // Get current quota usage across all providers
  async getCurrentQuotaStatus() {
    const status = {};
    const today = new Date().toISOString().split('T')[0];

    for (const [provider, tiers] of Object.entries(this.quotas)) {
      status[provider] = {};
      
      for (const [tier, config] of Object.entries(tiers)) {
        const usageKey = `quota:${provider}:${tier}:${today}`;
        const used = await this.env.BOOKS_CACHE?.get(usageKey);
        
        status[provider][tier] = {
          ...config,
          currentUsed: used ? parseInt(used) : 0,
          remaining: config.limit - (used ? parseInt(used) : 0),
          percentUsed: config.limit > 0 ? ((used ? parseInt(used) : 0) / config.limit) * 100 : 0
        };
      }
    }

    return status;
  }

  // Rank providers based on quota, cost, and quality
  async rankProviders(requestType, quotaStatus, priority, metadata) {
    const providers = [];

    // Google Books evaluation
    const gbPaid = quotaStatus.googleBooks.paid;
    const gbFree = quotaStatus.googleBooks.free;
    
    if (gbPaid.remaining > 0) {
      providers.push({
        name: 'google-books',
        tier: 'paid',
        score: this.calculateProviderScore('googleBooks', 'paid', gbPaid, priority, metadata),
        quota: gbPaid,
        quality: 9, // High quality metadata
        speed: 8,   // Fast response times
        coverage: 9 // Excellent coverage
      });
    } else if (gbFree.remaining > 0) {
      providers.push({
        name: 'google-books',
        tier: 'free',
        score: this.calculateProviderScore('googleBooks', 'free', gbFree, priority, metadata),
        quota: gbFree,
        quality: 9,
        speed: 8,
        coverage: 9
      });
    }

    // ISBNdb evaluation
    const isbndbPro = quotaStatus.isbndb.pro;
    const isbndbPremium = quotaStatus.isbndb.premium;
    const isbndbStarter = quotaStatus.isbndb.starter;

    if (isbndbPro.remaining > 0) {
      providers.push({
        name: 'isbndb',
        tier: 'pro',
        score: this.calculateProviderScore('isbndb', 'pro', isbndbPro, priority, metadata),
        quota: isbndbPro,
        quality: 8, // Good metadata
        speed: 7,   // Moderate speed
        coverage: 8 // Good coverage
      });
    } else if (isbndbPremium.remaining > 0) {
      providers.push({
        name: 'isbndb',
        tier: 'premium',
        score: this.calculateProviderScore('isbndb', 'premium', isbndbPremium, priority, metadata),
        quota: isbndbPremium,
        quality: 8,
        speed: 7,
        coverage: 8
      });
    } else if (isbndbStarter.remaining > 0) {
      providers.push({
        name: 'isbndb',
        tier: 'starter',
        score: this.calculateProviderScore('isbndb', 'starter', isbndbStarter, priority, metadata),
        quota: isbndbStarter,
        quality: 8,
        speed: 7,
        coverage: 8
      });
    }

    // Open Library (always available as fallback)
    const olFree = quotaStatus.openLibrary.free;
    providers.push({
      name: 'open-library',
      tier: 'free',
      score: this.calculateProviderScore('openLibrary', 'free', olFree, priority, metadata),
      quota: olFree,
      quality: 6, // Variable quality
      speed: 5,   // Slower responses
      coverage: 7 // Decent coverage
    });

    // Sort by score (highest first)
    return providers.sort((a, b) => b.score - a.score);
  }

  // Calculate provider score based on multiple factors
  calculateProviderScore(provider, tier, quotaInfo, priority, metadata) {
    let score = 0;

    // Base score from quality and coverage
    const qualityScores = {
      googleBooks: 90,
      isbndb: 80,
      openLibrary: 60
    };
    score += qualityScores[provider] || 50;

    // Quota availability bonus (0-20 points)
    const quotaRatio = quotaInfo.remaining / quotaInfo.limit;
    score += quotaRatio * 20;

    // Cost efficiency (favor free/cheaper options for non-critical requests)
    if (quotaInfo.cost === 0) {
      score += priority === 'background' ? 30 : 10; // Prefer free for background tasks
    } else {
      score -= priority === 'background' ? quotaInfo.cost * 0.1 : quotaInfo.cost * 0.05;
    }

    // Priority-based adjustments
    if (priority === 'critical' && provider === 'googleBooks') {
      score += 25; // Prefer Google Books for critical requests
    } else if (priority === 'low' || priority === 'background') {
      score += provider === 'openLibrary' ? 15 : -5; // Prefer Open Library for low priority
    }

    // Metadata-based adjustments
    if (metadata.requestType === 'search' && provider === 'googleBooks') {
      score += 10; // Google Books excels at search
    } else if (metadata.requestType === 'isbn' && provider === 'isbndb') {
      score += 5; // ISBNdb is good for ISBN lookups
    }

    return Math.max(0, score); // Ensure non-negative score
  }

  // Smart batch processing with priority queuing
  async processBatchRequest(requests, options = {}) {
    const {
      maxConcurrency = 3,
      priority = 'normal',
      timeout = 30000
    } = options;

    // Organize requests by provider and priority
    const requestQueues = await this.organizeRequests(requests, priority);
    const results = [];
    const errors = [];

    // Process each provider queue
    for (const [provider, providerRequests] of Object.entries(requestQueues)) {
      try {
        const providerResults = await this.processProviderBatch(
          provider,
          providerRequests,
          { maxConcurrency, timeout }
        );
        
        results.push(...providerResults.successful);
        errors.push(...providerResults.failed);
      } catch (error) {
        console.error(`Batch processing failed for ${provider}:`, error.message);
        errors.push({
          provider,
          error: error.message,
          requestCount: providerRequests.length
        });
      }
    }

    return {
      successful: results,
      failed: errors,
      total: requests.length,
      providers: Object.keys(requestQueues)
    };
  }

  // Organize requests by optimal provider
  async organizeRequests(requests, priority) {
    const queues = {};

    for (const request of requests) {
      const optimalProvider = await this.selectOptimalProvider(
        request.type || 'isbn',
        priority,
        request.metadata || {}
      );

      const providerName = `${optimalProvider.name}-${optimalProvider.tier}`;
      
      if (!queues[providerName]) {
        queues[providerName] = {
          provider: optimalProvider.name,
          tier: optimalProvider.tier,
          requests: []
        };
      }

      queues[providerName].requests.push(request);
    }

    return queues;
  }

  // Process batch for specific provider with concurrency control
  async processProviderBatch(providerKey, providerData, options) {
    const { requests } = providerData;
    const { maxConcurrency, timeout } = options;

    const successful = [];
    const failed = [];
    const semaphore = new Array(maxConcurrency).fill(false);

    // Process requests with concurrency limiting
    const processingPromises = requests.map(async (request) => {
      // Wait for available slot
      const slotIndex = await this.acquireSemaphore(semaphore);
      
      try {
        const result = await this.processIndividualRequest(
          request, 
          providerData.provider, 
          providerData.tier,
          timeout
        );
        
        successful.push({
          requestId: request.id,
          data: result,
          provider: providerData.provider,
          tier: providerData.tier
        });
      } catch (error) {
        failed.push({
          requestId: request.id,
          error: error.message,
          provider: providerData.provider
        });
      } finally {
        // Release slot
        semaphore[slotIndex] = false;
      }
    });

    await Promise.allSettled(processingPromises);

    // Update quota usage
    await this.updateQuotaUsage(providerData.provider, providerData.tier, requests.length);

    return { successful, failed };
  }

  // Acquire semaphore slot for concurrency control
  async acquireSemaphore(semaphore) {
    return new Promise((resolve) => {
      const checkForSlot = () => {
        const availableIndex = semaphore.findIndex(slot => !slot);
        if (availableIndex !== -1) {
          semaphore[availableIndex] = true;
          resolve(availableIndex);
        } else {
          setTimeout(checkForSlot, 10); // Wait 10ms and try again
        }
      };
      checkForSlot();
    });
  }

  // Process individual request
  async processIndividualRequest(request, provider, tier, timeout) {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), timeout);

    try {
      let result;

      switch (provider) {
        case 'google-books':
          result = await this.processGoogleBooksRequest(request, controller.signal);
          break;
        case 'isbndb':
          result = await this.processISBNdbRequest(request, tier, controller.signal);
          break;
        case 'open-library':
          result = await this.processOpenLibraryRequest(request, controller.signal);
          break;
        default:
          throw new Error(`Unknown provider: ${provider}`);
      }

      clearTimeout(timeoutId);
      return result;
    } catch (error) {
      clearTimeout(timeoutId);
      if (error.name === 'AbortError') {
        throw new Error(`Request timeout for ${provider}`);
      }
      throw error;
    }
  }

  // Update quota usage tracking
  async updateQuotaUsage(provider, tier, requestCount) {
    const today = new Date().toISOString().split('T')[0];
    const usageKey = `quota:${provider}:${tier}:${today}`;
    
    try {
      const currentUsage = await this.env.BOOKS_CACHE?.get(usageKey);
      const newUsage = (currentUsage ? parseInt(currentUsage) : 0) + requestCount;
      
      // Store with 25-hour expiration (handles timezone edge cases)
      await this.env.BOOKS_CACHE?.put(
        usageKey,
        newUsage.toString(),
        { expirationTtl: 90000 } // 25 hours
      );

      console.log(`📊 QUOTA UPDATE: ${provider}-${tier} = ${newUsage} requests today`);
    } catch (error) {
      console.error(`Failed to update quota for ${provider}-${tier}:`, error.message);
    }
  }

  // Background quota optimization - runs periodically
  async performBackgroundOptimization() {
    const optimizationTasks = [
      this.preloadPopularContent(),
      this.optimizeQuotaDistribution(),
      this.cleanupExpiredQuotaTracking(),
      this.generateQuotaReport()
    ];

    try {
      const results = await Promise.allSettled(optimizationTasks);
      console.log('📈 BACKGROUND OPTIMIZATION: Completed', results.length, 'tasks');
      
      return {
        completed: results.filter(r => r.status === 'fulfilled').length,
        failed: results.filter(r => r.status === 'rejected').length,
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      console.error('Background optimization failed:', error.message);
      return { error: error.message };
    }
  }

  // Preload popular content during low-usage hours
  async preloadPopularContent() {
    // Get popular search terms from last 7 days
    const popularSearches = await this.getPopularSearchTerms();
    const recentISBNs = await this.getRecentPopularISBNs();

    // Use lower-priority providers for preloading
    const preloadTasks = [];

    // Preload popular searches using Open Library (free)
    for (const searchTerm of popularSearches.slice(0, 10)) { // Top 10
      preloadTasks.push(
        this.preloadSearch(searchTerm, 'open-library', 'background')
      );
    }

    // Preload ISBN data using available quota efficiently
    for (const isbn of recentISBNs.slice(0, 20)) { // Top 20
      preloadTasks.push(
        this.preloadISBN(isbn, 'background')
      );
    }

    const results = await Promise.allSettled(preloadTasks);
    const successful = results.filter(r => r.status === 'fulfilled').length;
    
    console.log(`🔥 PRELOADED: ${successful} items (${preloadTasks.length} attempted)`);
    return { preloaded: successful, attempted: preloadTasks.length };
  }

  // Get popular search terms from analytics
  async getPopularSearchTerms() {
    // This would analyze your cache logs and return popular searches
    // For now, return some common book search terms
    return [
      'bestsellers 2024',
      'science fiction novels',
      'mystery thriller books',
      'romance novels',
      'fantasy series',
      'non fiction books',
      'classic literature',
      'young adult novels',
      'biography books',
      'cooking books'
    ];
  }

  // Get recently popular ISBNs
  async getRecentPopularISBNs() {
    // This would analyze recent requests and return frequently requested ISBNs
    // For now, return empty array - you'd populate this from real data
    return [];
  }

  // Preload search results
  async preloadSearch(searchTerm, provider, priority) {
    try {
      const optimalProvider = await this.selectOptimalProvider('search', priority);
      
      if (optimalProvider.quota.remaining < 10) {
        return; // Skip if quota is low
      }

      // Check if already cached
      const cacheKey = `search/${btoa(searchTerm).replace(/[/+=]/g, '_').substring(0, 32)}/20/relevance/any.json`;
      const cached = await this.env.BOOKS_CACHE?.get(cacheKey);
      
      if (cached) {
        return; // Already cached
      }

      // Perform the search to populate cache
      // This would call your actual search implementation
      console.log(`🔥 PRELOADING SEARCH: "${searchTerm}" via ${optimalProvider.name}`);
      
    } catch (error) {
      console.error(`Failed to preload search for "${searchTerm}":`, error.message);
    }
  }

  // Generate daily quota utilization report
  async generateQuotaReport() {
    const quotaStatus = await this.getCurrentQuotaStatus();
    const today = new Date().toISOString().split('T')[0];
    
    const report = {
      date: today,
      timestamp: new Date().toISOString(),
      providers: {},
      summary: {
        totalRequests: 0,
        totalCost: 0,
        efficiency: 0
      }
    };

    for (const [provider, tiers] of Object.entries(quotaStatus)) {
      report.providers[provider] = {};
      
      for (const [tier, status] of Object.entries(tiers)) {
        report.providers[provider][tier] = {
          used: status.currentUsed,
          limit: status.limit,
          remaining: status.remaining,
          percentUsed: status.percentUsed,
          cost: status.cost,
          efficiency: status.limit > 0 ? (status.currentUsed / status.limit) * 100 : 0
        };

        report.summary.totalRequests += status.currentUsed;
        report.summary.totalCost += status.cost;
      }
    }

    // Calculate overall efficiency
    const totalQuota = Object.values(quotaStatus).reduce((sum, provider) => 
      sum + Object.values(provider).reduce((providerSum, tier) => 
        providerSum + (tier.limit === Infinity ? 0 : tier.limit), 0), 0);
    
    report.summary.efficiency = totalQuota > 0 ? (report.summary.totalRequests / totalQuota) * 100 : 0;

    // Store report for dashboard
    const reportKey = `quota-report:${today}`;
    await this.env.BOOKS_CACHE?.put(
      reportKey,
      JSON.stringify(report),
      { expirationTtl: 2592000 } // 30 days
    );

    console.log(`📊 QUOTA REPORT: ${report.summary.totalRequests} requests, $${report.summary.totalCost.toFixed(2)} cost, ${report.summary.efficiency.toFixed(1)}% efficiency`);
    
    return report;
  }
}