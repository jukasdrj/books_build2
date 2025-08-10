import XCTest
@testable import books

/// Tests for Phase 3: Adaptive Rate Limiting System
final class AdaptiveRateLimitingTests: XCTestCase {
    
    var performanceMonitor: PerformanceMonitor!
    var rateLimiter: AdaptiveRateLimiter!
    
    override func setUp() async throws {
        await MainActor.run {
            performanceMonitor = PerformanceMonitor()
        }
        rateLimiter = AdaptiveRateLimiter()
    }
    
    override func tearDown() async throws {
        await MainActor.run {
            performanceMonitor = nil
        }
        rateLimiter = nil
    }
    
    // MARK: - Performance Monitor Tests
    
    func testPerformanceMonitorRecordsSuccess() async {
        await MainActor.run {
            // Record successful requests
            performanceMonitor.recordSuccess(responseTime: 0.5)
            performanceMonitor.recordSuccess(responseTime: 0.7)
            performanceMonitor.recordSuccess(responseTime: 0.6)
            
            // Verify metrics
            XCTAssertEqual(performanceMonitor.metrics.totalRequests, 3)
            XCTAssertEqual(performanceMonitor.metrics.successfulRequests, 3)
            XCTAssertEqual(performanceMonitor.metrics.failedRequests, 0)
            XCTAssertGreaterThan(performanceMonitor.metrics.averageResponseTime, 0)
            XCTAssertEqual(performanceMonitor.metrics.successRate, 1.0)
        }
    }
    
    func testPerformanceMonitorRecordsFailure() async {
        await MainActor.run {
            // Record mixed results
            performanceMonitor.recordSuccess(responseTime: 0.5)
            performanceMonitor.recordFailure(responseTime: 1.0, isThrottled: false)
            performanceMonitor.recordSuccess(responseTime: 0.6)
            performanceMonitor.recordFailure(responseTime: nil, isThrottled: true)
            
            // Verify metrics
            XCTAssertEqual(performanceMonitor.metrics.totalRequests, 4)
            XCTAssertEqual(performanceMonitor.metrics.successfulRequests, 2)
            XCTAssertEqual(performanceMonitor.metrics.failedRequests, 2)
            XCTAssertEqual(performanceMonitor.metrics.throttledRequests, 1)
            XCTAssertEqual(performanceMonitor.metrics.successRate, 0.5, accuracy: 0.01)
        }
    }
    
    func testConcurrencyAdjustmentOnGoodPerformance() async {
        await MainActor.run {
            // Simulate excellent performance
            for _ in 0..<15 {
                performanceMonitor.recordSuccess(responseTime: 0.3)
            }
            
            // Wait for adjustment interval
            let expectation = XCTestExpectation(description: "Concurrency adjustment")
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.5) {
                expectation.fulfill()
            }
            
            await fulfillment(of: [expectation], timeout: 6.0)
            
            // Should recommend higher concurrency
            let recommended = performanceMonitor.getRecommendedConcurrency()
            XCTAssertGreaterThan(recommended, 5) // Default is 5
        }
    }
    
    func testConcurrencyAdjustmentOnPoorPerformance() async {
        await MainActor.run {
            // Simulate poor performance
            for _ in 0..<10 {
                performanceMonitor.recordFailure(responseTime: 2.0, isThrottled: false)
            }
            
            // Wait for adjustment interval
            let expectation = XCTestExpectation(description: "Concurrency adjustment")
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.5) {
                expectation.fulfill()
            }
            
            await fulfillment(of: [expectation], timeout: 6.0)
            
            // Should recommend lower concurrency
            let recommended = performanceMonitor.getRecommendedConcurrency()
            XCTAssertLessThanOrEqual(recommended, 5) // Should be 5 or less
        }
    }
    
    func testThrottlingPenalty() async {
        await MainActor.run {
            // Simulate throttling
            for _ in 0..<5 {
                performanceMonitor.recordFailure(responseTime: 0.5, isThrottled: true)
            }
            
            // Wait for adjustment
            let expectation = XCTestExpectation(description: "Throttling penalty")
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.5) {
                expectation.fulfill()
            }
            
            await fulfillment(of: [expectation], timeout: 6.0)
            
            // Should significantly reduce concurrency
            let recommended = performanceMonitor.getRecommendedConcurrency()
            XCTAssertLessThanOrEqual(recommended, 3) // Minimum is 3
        }
    }
    
    func testPerformanceReport() async {
        await MainActor.run {
            // Add some data
            performanceMonitor.recordSuccess(responseTime: 0.5)
            performanceMonitor.recordSuccess(responseTime: 0.7)
            performanceMonitor.recordFailure(responseTime: 1.0, isThrottled: false)
            performanceMonitor.updateQueueDepth(3)
            
            // Get report
            let report = performanceMonitor.getPerformanceReport()
            
            // Verify report contains expected elements
            XCTAssertTrue(report.contains("Performance Report"))
            XCTAssertTrue(report.contains("Total Requests: 3"))
            XCTAssertTrue(report.contains("Success Rate:"))
            XCTAssertTrue(report.contains("Average Response Time:"))
            XCTAssertTrue(report.contains("Current Concurrency:"))
        }
    }
    
    // MARK: - Adaptive Rate Limiter Tests
    
    func testRateLimiterWaitsForPermission() async {
        await rateLimiter.reset()
        
        // Measure time for multiple requests
        let startTime = Date()
        
        // Make rapid requests
        for _ in 0..<5 {
            await rateLimiter.waitForPermission()
        }
        
        let elapsed = Date().timeIntervalSince(startTime)
        
        // Should take some time due to rate limiting
        XCTAssertGreaterThan(elapsed, 0.1) // At least some delay
    }
    
    func testRateLimiterAdaptsToGoodPerformance() async {
        let initialRate = await rateLimiter.getCurrentRate()
        
        // Simulate good performance
        await rateLimiter.adaptRate(successRate: 0.98, averageResponseTime: 0.3)
        
        let newRate = await rateLimiter.getCurrentRate()
        
        // Rate should increase
        XCTAssertGreaterThan(newRate, initialRate)
    }
    
    func testRateLimiterAdaptsToPoorPerformance() async {
        let initialRate = await rateLimiter.getCurrentRate()
        
        // Simulate poor performance
        await rateLimiter.adaptRate(successRate: 0.5, averageResponseTime: 3.0)
        
        let newRate = await rateLimiter.getCurrentRate()
        
        // Rate should decrease
        XCTAssertLessThan(newRate, initialRate)
    }
    
    func testRateLimiterRespectsMinMaxBounds() async {
        // Try to set very high rate through good performance
        for _ in 0..<10 {
            await rateLimiter.adaptRate(successRate: 1.0, averageResponseTime: 0.1)
        }
        
        let maxRate = await rateLimiter.getCurrentRate()
        XCTAssertLessThanOrEqual(maxRate, 20.0) // Max is 20
        
        // Reset and try to set very low rate
        await rateLimiter.reset()
        
        for _ in 0..<10 {
            await rateLimiter.adaptRate(successRate: 0.1, averageResponseTime: 10.0)
        }
        
        let minRate = await rateLimiter.getCurrentRate()
        XCTAssertGreaterThanOrEqual(minRate, 2.0) // Min is 2
    }
    
    // MARK: - Integration Tests
    
    func testPerformanceMonitorWithRateLimiter() async {
        // Connect performance monitor to rate limiter
        await rateLimiter.setPerformanceMonitor(performanceMonitor)
        
        await MainActor.run {
            // Simulate requests
            for i in 0..<10 {
                if i % 3 == 0 {
                    performanceMonitor.recordFailure(responseTime: 2.0, isThrottled: false)
                } else {
                    performanceMonitor.recordSuccess(responseTime: 0.5)
                }
            }
        }
        
        // Rate limiter should adapt based on performance
        let metrics = await MainActor.run { performanceMonitor.metrics }
        await rateLimiter.adaptRate(
            successRate: metrics.successRate,
            averageResponseTime: metrics.averageResponseTime
        )
        
        // Verify adaptation occurred
        let currentRate = await rateLimiter.getCurrentRate()
        XCTAssertNotEqual(currentRate, 10.0) // Should have changed from default
    }
    
    func testMetricsReset() async {
        await MainActor.run {
            // Add data
            performanceMonitor.recordSuccess(responseTime: 0.5)
            performanceMonitor.recordFailure(responseTime: 1.0, isThrottled: true)
            
            // Reset
            performanceMonitor.resetMetrics()
            
            // Verify reset
            XCTAssertEqual(performanceMonitor.metrics.totalRequests, 0)
            XCTAssertEqual(performanceMonitor.metrics.successfulRequests, 0)
            XCTAssertEqual(performanceMonitor.metrics.failedRequests, 0)
            XCTAssertEqual(performanceMonitor.metrics.throttledRequests, 0)
            XCTAssertEqual(performanceMonitor.metrics.averageResponseTime, 0)
        }
    }
    
    func testQueueDepthTracking() async {
        await MainActor.run {
            // Update queue depth multiple times
            performanceMonitor.updateQueueDepth(5)
            performanceMonitor.updateQueueDepth(10)
            performanceMonitor.updateQueueDepth(3)
            
            // Average should be tracked
            XCTAssertGreaterThan(performanceMonitor.metrics.averageQueueDepth, 0)
        }
    }
}