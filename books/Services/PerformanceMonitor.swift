import Foundation
import SwiftUI
import os.log

/// Enhanced performance monitoring and adaptive rate limiting for API requests
/// Phase 3 Enhancement: Dynamic concurrency adjustment based on API health
/// Performance Optimization: Comprehensive monitoring for JSON, memory, and scrolling
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
    
    // MARK: - Enhanced Performance Monitoring Properties
    
    private let logger = Logger(subsystem: "com.books.performance", category: "monitor")
    private var measurements: [String: CFAbsoluteTime] = [:]
    private var memoryBaseline: UInt64 = 0
    
    // Enhanced metrics for comprehensive monitoring
    @Published private(set) var enhancedMetrics = EnhancedPerformanceMetrics()
    
    // Memory monitoring
    nonisolated(unsafe) private var memoryTimer: Timer?
    private var isMemoryMonitoring = false
    
    // MARK: - Initialization
    
    init() {
        memoryBaseline = getCurrentMemoryUsage()
        startMonitoring()
        startMemoryMonitoring()
    }
    
    deinit {
        adjustmentTimer?.invalidate()
        adjustmentTimer = nil
        memoryTimer?.invalidate()
        memoryTimer = nil
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
            self?.enhancedMetrics = EnhancedPerformanceMetrics()
        }
    }
    
    // MARK: - Enhanced Performance Monitoring Interface
    
    /// Start timing a performance-critical operation
    func startTiming(_ operation: String) {
        measurements[operation] = CFAbsoluteTimeGetCurrent()
        logger.info("Started timing: \(operation)")
    }
    
    /// End timing and record the result
    func endTiming(_ operation: String) {
        guard let startTime = measurements[operation] else {
            logger.error("No start time found for operation: \(operation)")
            return
        }
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        measurements.removeValue(forKey: operation)
        
        recordOperationTime(operation: operation, duration: duration)
        logger.info("Completed timing: \(operation) - \(String(format: "%.3f", duration * 1000))ms")
    }
    
    /// Record JSON parsing performance
    func recordJSONParsing(operation: String, itemCount: Int, duration: TimeInterval, cacheHit: Bool) {
        let metric = JSONPerformanceMetric(
            operation: operation,
            itemCount: itemCount,
            duration: duration,
            cacheHit: cacheHit,
            timestamp: Date()
        )
        
        enhancedMetrics.jsonMetrics.append(metric)
        if enhancedMetrics.jsonMetrics.count > 100 {
            enhancedMetrics.jsonMetrics.removeFirst(50) // Keep last 100 entries
        }
        
        logger.info("JSON \(operation): \(itemCount) items, \(String(format: "%.3f", duration * 1000))ms, cache: \(cacheHit ? "HIT" : "MISS")")
    }
    
    /// Record virtual scrolling performance
    func recordScrollingPerformance(visibleItems: Int, totalItems: Int, updateDuration: TimeInterval) {
        let metric = ScrollingPerformanceMetric(
            visibleItems: visibleItems,
            totalItems: totalItems,
            updateDuration: updateDuration,
            timestamp: Date()
        )
        
        enhancedMetrics.scrollingMetrics.append(metric)
        if enhancedMetrics.scrollingMetrics.count > 50 {
            enhancedMetrics.scrollingMetrics.removeFirst(25)
        }
    }
    
    /// Record library filtering performance
    func recordFilteringPerformance(bookCount: Int, duration: TimeInterval, cached: Bool) {
        let metric = FilteringPerformanceMetric(
            bookCount: bookCount,
            duration: duration,
            cached: cached,
            timestamp: Date()
        )
        
        enhancedMetrics.filteringMetrics.append(metric)
        if enhancedMetrics.filteringMetrics.count > 50 {
            enhancedMetrics.filteringMetrics.removeFirst(25)
        }
    }
    
    /// Get current memory usage
    nonisolated func getCurrentMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        return kerr == KERN_SUCCESS ? info.resident_size : 0
    }
    
    /// Generate comprehensive performance report
    func generateEnhancedReport() -> EnhancedPerformanceReport {
        let currentMemory = getCurrentMemoryUsage()
        let memoryIncrease = currentMemory > memoryBaseline ? currentMemory - memoryBaseline : 0
        
        return EnhancedPerformanceReport(
            memoryBaseline: memoryBaseline,
            currentMemory: currentMemory,
            memoryIncrease: memoryIncrease,
            metrics: enhancedMetrics,
            generatedAt: Date()
        )
    }
    
    /// Convenience method for timing closures
    func time<T>(_ operation: String, closure: () throws -> T) rethrows -> T {
        startTiming(operation)
        defer { endTiming(operation) }
        return try closure()
    }
    
    /// Convenience method for timing async closures
    func timeAsync<T>(_ operation: String, closure: @Sendable () async throws -> T) async rethrows -> T where T: Sendable {
        startTiming(operation)
        defer { endTiming(operation) }
        return try await closure()
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

// MARK: - Enhanced Performance Monitoring Implementation

extension PerformanceMonitor {
    
    private func recordOperationTime(operation: String, duration: TimeInterval) {
        let metric = OperationPerformanceMetric(
            operation: operation,
            duration: duration,
            timestamp: Date()
        )
        
        enhancedMetrics.operationMetrics.append(metric)
        if enhancedMetrics.operationMetrics.count > 100 {
            enhancedMetrics.operationMetrics.removeFirst(50)
        }
    }
    
    private func startMemoryMonitoring() {
        guard !isMemoryMonitoring else { return }
        
        isMemoryMonitoring = true
        let baseline = memoryBaseline // Capture baseline value
        
        memoryTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            let currentMemory = self.getCurrentMemoryUsage()
            let memoryMB = Double(currentMemory) / (1024 * 1024)
            
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.enhancedMetrics.currentMemoryUsage = currentMemory
                self.enhancedMetrics.memoryHistory.append(MemorySnapshot(usage: currentMemory, timestamp: Date()))
                
                // Keep last 60 snapshots (5 minutes at 5-second intervals)
                if self.enhancedMetrics.memoryHistory.count > 60 {
                    self.enhancedMetrics.memoryHistory.removeFirst(30)
                }
            }
            
            // Log significant memory increases
            if currentMemory > baseline + (100 * 1024 * 1024) { // 100MB increase
                self.logger.warning("Significant memory increase detected: \(String(format: "%.1f", memoryMB))MB")
            }
        }
    }
}

// MARK: - Enhanced Performance Data Models

struct EnhancedPerformanceMetrics {
    var jsonMetrics: [JSONPerformanceMetric] = []
    var scrollingMetrics: [ScrollingPerformanceMetric] = []
    var filteringMetrics: [FilteringPerformanceMetric] = []
    var operationMetrics: [OperationPerformanceMetric] = []
    var memoryHistory: [MemorySnapshot] = []
    var currentMemoryUsage: UInt64 = 0
}

struct JSONPerformanceMetric {
    let operation: String
    let itemCount: Int
    let duration: TimeInterval
    let cacheHit: Bool
    let timestamp: Date
    
    var performanceScore: Double {
        // Lower is better - duration per item in milliseconds
        return (duration * 1000) / Double(max(itemCount, 1))
    }
}

struct ScrollingPerformanceMetric {
    let visibleItems: Int
    let totalItems: Int
    let updateDuration: TimeInterval
    let timestamp: Date
    
    var efficiency: Double {
        return Double(visibleItems) / Double(totalItems)
    }
}

struct FilteringPerformanceMetric {
    let bookCount: Int
    let duration: TimeInterval
    let cached: Bool
    let timestamp: Date
    
    var itemsPerSecond: Double {
        return Double(bookCount) / duration
    }
}

struct OperationPerformanceMetric {
    let operation: String
    let duration: TimeInterval
    let timestamp: Date
}

struct MemorySnapshot {
    let usage: UInt64
    let timestamp: Date
    
    var usageMB: Double {
        return Double(usage) / (1024 * 1024)
    }
}

struct EnhancedPerformanceReport {
    let memoryBaseline: UInt64
    let currentMemory: UInt64
    let memoryIncrease: UInt64
    let metrics: EnhancedPerformanceMetrics
    let generatedAt: Date
    
    var memoryEfficiency: String {
        let baselineMB = Double(memoryBaseline) / (1024 * 1024)
        let currentMB = Double(currentMemory) / (1024 * 1024)
        let increaseMB = Double(memoryIncrease) / (1024 * 1024)
        
        return """
        Memory Usage Report:
        Baseline: \(String(format: "%.1f", baselineMB))MB
        Current: \(String(format: "%.1f", currentMB))MB
        Increase: \(String(format: "%.1f", increaseMB))MB
        """
    }
    
    var jsonOptimizationSummary: String {
        let recentJSON = metrics.jsonMetrics.suffix(20)
        let cacheHitRate = recentJSON.isEmpty ? 0.0 : 
            Double(recentJSON.filter { $0.cacheHit }.count) / Double(recentJSON.count)
        let avgDuration = recentJSON.isEmpty ? 0.0 :
            recentJSON.map { $0.duration }.reduce(0, +) / Double(recentJSON.count)
        
        return """
        JSON Performance Summary:
        Cache Hit Rate: \(String(format: "%.1f", cacheHitRate * 100))%
        Avg Parse Time: \(String(format: "%.3f", avgDuration * 1000))ms
        Recent Operations: \(recentJSON.count)
        """
    }
    
    var virtualScrollingSummary: String {
        let recentScrolling = metrics.scrollingMetrics.suffix(10)
        let avgEfficiency = recentScrolling.isEmpty ? 0.0 :
            recentScrolling.map { $0.efficiency }.reduce(0, +) / Double(recentScrolling.count)
        let avgUpdateTime = recentScrolling.isEmpty ? 0.0 :
            recentScrolling.map { $0.updateDuration }.reduce(0, +) / Double(recentScrolling.count)
        
        return """
        Virtual Scrolling Summary:
        Avg Efficiency: \(String(format: "%.1f", avgEfficiency * 100))%
        Avg Update Time: \(String(format: "%.3f", avgUpdateTime * 1000))ms
        Recent Updates: \(recentScrolling.count)
        """
    }
}