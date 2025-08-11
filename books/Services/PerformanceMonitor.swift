import Foundation

/// Performance monitoring and adaptive rate limiting for API requests
/// Phase 3 Enhancement: Dynamic concurrency adjustment based on API health
@MainActor
class PerformanceMonitor: ObservableObject {
    
    // MARK: - Performance Metrics
    
    struct PerformanceMetrics {
        var averageResponseTime: TimeInterval = 0
        var successRate: Double = 1.0
        var recentResponseTimes: [TimeInterval] = []
        var recentSuccesses: [Bool] = []
        var lastUpdateTime: Date = Date()
        var currentConcurrency: Int = 5
        var recommendedConcurrency: Int = 5
        
        // Telemetry
        var totalRequests: Int = 0
        var successfulRequests: Int = 0
        var failedRequests: Int = 0
        var throttledRequests: Int = 0
        var averageQueueDepth: Double = 0
        var peakConcurrency: Int = 5
        
        mutating func reset() {
            averageResponseTime = 0
            successRate = 1.0
            recentResponseTimes = []
            recentSuccesses = []
            lastUpdateTime = Date()
            currentConcurrency = 5
            recommendedConcurrency = 5
            totalRequests = 0
            successfulRequests = 0
            failedRequests = 0
            throttledRequests = 0
            averageQueueDepth = 0
            peakConcurrency = 5
        }
    }
    
    // MARK: - Configuration
    
    struct Configuration {
        /// Minimum concurrent requests allowed
        let minConcurrency: Int = 3
        
        /// Maximum concurrent requests allowed
        let maxConcurrency: Int = 8
        
        /// Target success rate for optimal performance
        let targetSuccessRate: Double = 0.95
        
        /// Target response time in seconds
        let targetResponseTime: TimeInterval = 1.0
        
        /// Number of recent samples to track
        let sampleWindowSize: Int = 20
        
        /// Minimum samples before adjusting concurrency
        let minSamplesForAdjustment: Int = 10
        
        /// Time between concurrency adjustments
        let adjustmentInterval: TimeInterval = 5.0
        
        /// Aggressiveness of concurrency changes (0.0-1.0)
        let adjustmentSensitivity: Double = 0.3
    }
    
    // MARK: - Properties
    
    @Published private(set) var metrics = PerformanceMetrics()
    private let configuration = Configuration()
    nonisolated(unsafe) private var adjustmentTimer: Timer?
    private let metricsQueue = DispatchQueue(label: "com.books.performance.metrics", attributes: .concurrent)
    
    // MARK: - Initialization
    
    init() {
        startMonitoring()
    }
    
    deinit {
        adjustmentTimer?.invalidate()
        adjustmentTimer = nil
    }
    
    // MARK: - Public Interface
    
    /// Record a successful API request
    func recordSuccess(responseTime: TimeInterval) {
        metricsQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.metrics.totalRequests += 1
                self.metrics.successfulRequests += 1
                
                // Update recent samples
                self.metrics.recentResponseTimes.append(responseTime)
                self.metrics.recentSuccesses.append(true)
                
                // Maintain window size
                if self.metrics.recentResponseTimes.count > self.configuration.sampleWindowSize {
                    self.metrics.recentResponseTimes.removeFirst()
                }
                if self.metrics.recentSuccesses.count > self.configuration.sampleWindowSize {
                    self.metrics.recentSuccesses.removeFirst()
                }
                
                // Update averages
                self.updateMetrics()
            }
        }
    }
    
    /// Record a failed API request
    func recordFailure(responseTime: TimeInterval? = nil, isThrottled: Bool = false) {
        metricsQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.metrics.totalRequests += 1
                self.metrics.failedRequests += 1
                
                if isThrottled {
                    self.metrics.throttledRequests += 1
                }
                
                // Record response time if available (even for failures)
                if let responseTime = responseTime {
                    self.metrics.recentResponseTimes.append(responseTime)
                }
                self.metrics.recentSuccesses.append(false)
                
                // Maintain window size
                if self.metrics.recentResponseTimes.count > self.configuration.sampleWindowSize {
                    self.metrics.recentResponseTimes.removeFirst()
                }
                if self.metrics.recentSuccesses.count > self.configuration.sampleWindowSize {
                    self.metrics.recentSuccesses.removeFirst()
                }
                
                // Update averages
                self.updateMetrics()
            }
        }
    }
    
    /// Get the current recommended concurrency level
    func getRecommendedConcurrency() -> Int {
        return metrics.recommendedConcurrency
    }
    
    /// Update queue depth for monitoring
    func updateQueueDepth(_ depth: Int) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            let currentAverage = self.metrics.averageQueueDepth
            let sampleCount = Double(self.metrics.totalRequests)
            self.metrics.averageQueueDepth = (currentAverage * sampleCount + Double(depth)) / (sampleCount + 1)
        }
    }
    
    /// Get current performance report
    func getPerformanceReport() -> String {
        """
        === Performance Report ===
        Total Requests: \(metrics.totalRequests)
        Success Rate: \(String(format: "%.1f%%", metrics.successRate * 100))
        Average Response Time: \(String(format: "%.2fs", metrics.averageResponseTime))
        Current Concurrency: \(metrics.currentConcurrency)
        Recommended Concurrency: \(metrics.recommendedConcurrency)
        Peak Concurrency: \(metrics.peakConcurrency)
        Throttled Requests: \(metrics.throttledRequests)
        Average Queue Depth: \(String(format: "%.1f", metrics.averageQueueDepth))
        """
    }
    
    /// Reset all metrics
    func resetMetrics() {
        Task { @MainActor [weak self] in
            self?.metrics.reset()
        }
    }
    
    // MARK: - Private Implementation
    
    private func startMonitoring() {
        adjustmentTimer = Timer.scheduledTimer(withTimeInterval: configuration.adjustmentInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.adjustConcurrency()
            }
        }
    }
    
    private func stopMonitoring() {
        adjustmentTimer?.invalidate()
        adjustmentTimer = nil
    }
    
    private func updateMetrics() {
        // Calculate average response time
        if !metrics.recentResponseTimes.isEmpty {
            metrics.averageResponseTime = metrics.recentResponseTimes.reduce(0, +) / Double(metrics.recentResponseTimes.count)
        }
        
        // Calculate success rate
        if !metrics.recentSuccesses.isEmpty {
            let successCount = metrics.recentSuccesses.filter { $0 }.count
            metrics.successRate = Double(successCount) / Double(metrics.recentSuccesses.count)
        }
        
        metrics.lastUpdateTime = Date()
    }
    
    private func adjustConcurrency() {
        // Need minimum samples before adjusting
        guard metrics.recentSuccesses.count >= configuration.minSamplesForAdjustment else { return }
        
        var newConcurrency = metrics.currentConcurrency
        
        // Performance scoring (0.0 = worst, 1.0 = best)
        let successScore = min(metrics.successRate / configuration.targetSuccessRate, 1.0)
        let responseScore = min(configuration.targetResponseTime / max(metrics.averageResponseTime, 0.01), 1.0)
        let overallScore = (successScore * 0.7) + (responseScore * 0.3) // Weight success rate more heavily
        
        // Determine adjustment direction and magnitude
        if overallScore > 0.95 {
            // Excellent performance - try increasing concurrency
            let increase = Int(ceil(Double(configuration.maxConcurrency - metrics.currentConcurrency) * configuration.adjustmentSensitivity))
            newConcurrency = min(metrics.currentConcurrency + max(1, increase), configuration.maxConcurrency)
        } else if overallScore < 0.8 {
            // Poor performance - reduce concurrency
            let decrease = Int(ceil(Double(metrics.currentConcurrency - configuration.minConcurrency) * configuration.adjustmentSensitivity))
            newConcurrency = max(metrics.currentConcurrency - max(1, decrease), configuration.minConcurrency)
        }
        
        // Apply throttling penalty
        if metrics.throttledRequests > 0 {
            let throttlePenalty = min(metrics.throttledRequests / 5, 2) // Reduce by 1 for every 5 throttled requests
            newConcurrency = max(newConcurrency - throttlePenalty, configuration.minConcurrency)
        }
        
        // Update metrics
        if newConcurrency != metrics.currentConcurrency {
            metrics.currentConcurrency = newConcurrency
            metrics.recommendedConcurrency = newConcurrency
            
            if newConcurrency > metrics.peakConcurrency {
                metrics.peakConcurrency = newConcurrency
            }
            
            print("[PerformanceMonitor] Adjusted concurrency: \(metrics.currentConcurrency) (Score: \(String(format: "%.2f", overallScore)))")
        }
    }
}

// MARK: - Adaptive Rate Limiter

/// Intelligent rate limiter that adapts to API conditions
actor AdaptiveRateLimiter {
    
    // MARK: - Configuration
    
    struct AdaptiveConfiguration {
        var baseRequestsPerSecond: Double = 10.0
        var minRequestsPerSecond: Double = 2.0
        var maxRequestsPerSecond: Double = 20.0
        var burstCapacity: Int = 5
        var adaptationRate: Double = 0.2
    }
    
    // MARK: - State
    
    private var configuration: AdaptiveConfiguration
    private var currentRate: Double
    private var tokens: Double
    private var lastRefillTime: Date
    private weak var performanceMonitor: PerformanceMonitor?
    
    // MARK: - Initialization
    
    init(configuration: AdaptiveConfiguration = AdaptiveConfiguration()) {
        self.configuration = configuration
        self.currentRate = configuration.baseRequestsPerSecond
        self.tokens = Double(configuration.burstCapacity)
        self.lastRefillTime = Date()
    }
    
    // MARK: - Public Interface
    
    /// Set the performance monitor for adaptive adjustments
    func setPerformanceMonitor(_ monitor: PerformanceMonitor) {
        self.performanceMonitor = monitor
    }
    
    /// Wait for permission to make a request
    func waitForPermission() async {
        while true {
            refillTokens()
            
            if tokens >= 1.0 {
                tokens -= 1.0
                return
            }
            
            // Calculate wait time
            let tokensNeeded = 1.0 - tokens
            let waitTime = tokensNeeded / currentRate
            
            // Wait and retry
            try? await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
        }
    }
    
    /// Adapt rate based on performance feedback
    func adaptRate(successRate: Double, averageResponseTime: TimeInterval) {
        // Calculate performance score
        let targetSuccessRate = 0.95
        let targetResponseTime: TimeInterval = 1.0
        
        let successScore = min(successRate / targetSuccessRate, 1.0)
        let responseScore = min(targetResponseTime / max(averageResponseTime, 0.01), 1.0)
        let performanceScore = (successScore * 0.6) + (responseScore * 0.4)
        
        // Adjust rate based on performance
        if performanceScore > 0.9 {
            // Good performance - increase rate
            let increase = (configuration.maxRequestsPerSecond - currentRate) * configuration.adaptationRate
            currentRate = min(currentRate + increase, configuration.maxRequestsPerSecond)
        } else if performanceScore < 0.7 {
            // Poor performance - decrease rate
            let decrease = (currentRate - configuration.minRequestsPerSecond) * configuration.adaptationRate
            currentRate = max(currentRate - decrease, configuration.minRequestsPerSecond)
        }
    }
    
    /// Get current rate limit
    func getCurrentRate() -> Double {
        return currentRate
    }
    
    /// Reset to base configuration
    func reset() {
        currentRate = configuration.baseRequestsPerSecond
        tokens = Double(configuration.burstCapacity)
        lastRefillTime = Date()
    }
    
    // MARK: - Private Implementation
    
    private func refillTokens() {
        let now = Date()
        let timePassed = now.timeIntervalSince(lastRefillTime)
        
        // Add tokens based on time passed and current rate
        let tokensToAdd = timePassed * currentRate
        tokens = min(tokens + tokensToAdd, Double(configuration.burstCapacity))
        
        lastRefillTime = now
    }
}