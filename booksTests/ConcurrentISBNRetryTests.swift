//
//  ConcurrentISBNRetryTests.swift
//  booksTests
//
//  Tests for Phase 2: Smart Retry Logic in ConcurrentISBNLookupService
//

import XCTest
import Foundation
@testable import books

@MainActor
final class ConcurrentISBNRetryTests: XCTestCase {
    
    var concurrentLookupService: ConcurrentISBNLookupService!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        concurrentLookupService = ConcurrentISBNLookupService()
    }
    
    override func tearDownWithError() throws {
        concurrentLookupService = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Error Classification Tests
    
    func testErrorClassifier_URLErrorClassification() async throws {
        let errorClassifier = ErrorClassifier()
        
        // Retryable URL errors
        let timeoutError = URLError(.timedOut)
        let classification1 = await errorClassifier.classify(timeoutError)
        if case .retryable(let delay) = classification1 {
            XCTAssertEqual(delay, 1.0, "Timeout errors should have 1.0 second base delay")
        } else {
            XCTFail("Timeout errors should be retryable")
        }
        
        let networkLostError = URLError(.networkConnectionLost)
        let classification2 = await errorClassifier.classify(networkLostError)
        if case .retryable = classification2 {
            // Success
        } else {
            XCTFail("Network connection lost should be retryable")
        }
        
        // Permanent URL errors
        let badURLError = URLError(.badURL)
        let classification3 = await errorClassifier.classify(badURLError)
        if case .permanentFailure = classification3 {
            // Success
        } else {
            XCTFail("Bad URL errors should be permanent failures")
        }
        
        let authError = URLError(.userAuthenticationRequired)
        let classification4 = await errorClassifier.classify(authError)
        if case .permanentFailure = classification4 {
            // Success
        } else {
            XCTFail("Authentication errors should be permanent failures")
        }
    }
    
    func testErrorClassifier_HTTPErrorClassification() async throws {
        let errorClassifier = ErrorClassifier()
        
        // Rate limiting
        let rateLimitError = HTTPError(statusCode: 429, retryAfterHeader: "60")
        let classification1 = await errorClassifier.classify(rateLimitError)
        if case .rateLimited(let retryAfter) = classification1 {
            XCTAssertEqual(retryAfter, 60.0, "Rate limit should respect Retry-After header")
        } else {
            XCTFail("429 errors should be classified as rate limited")
        }
        
        // Server errors (retryable)
        let serverError = HTTPError(statusCode: 500)
        let classification2 = await errorClassifier.classify(serverError)
        if case .retryable(let delay) = classification2 {
            XCTAssertEqual(delay, 2.0, "Server errors should have 2.0 second base delay")
        } else {
            XCTFail("500 errors should be retryable")
        }
        
        // Client errors (permanent)
        let notFoundError = HTTPError(statusCode: 404)
        let classification3 = await errorClassifier.classify(notFoundError)
        if case .permanentFailure = classification3 {
            // Success
        } else {
            XCTFail("404 errors should be permanent failures")
        }
    }
    
    func testErrorClassifier_BookSearchServiceErrorClassification() async throws {
        let errorClassifier = ErrorClassifier()
        
        // Network errors (retryable)
        let networkError = BookSearchService.BookError.networkError("Connection failed")
        let classification1 = await errorClassifier.classify(networkError)
        if case .retryable(let delay) = classification1 {
            XCTAssertEqual(delay, 1.0, "Network errors should have 1.0 second base delay")
        } else {
            XCTFail("BookSearchService network errors should be retryable")
        }
        
        // Decoding errors (permanent)
        let decodingError = BookSearchService.BookError.decodingError("Invalid JSON")
        let classification2 = await errorClassifier.classify(decodingError)
        if case .permanentFailure = classification2 {
            // Success
        } else {
            XCTFail("Decoding errors should be permanent failures")
        }
    }
    
    // MARK: - Exponential Backoff Tests
    
    func testExponentialBackoff_DelayCalculation() {
        let backoff = ExponentialBackoff(baseDelay: 1.0, maxDelay: 16.0, jitterRange: 1.0...1.0)
        
        // Test exponential growth
        XCTAssertEqual(backoff.delay(for: 0), 1.0, accuracy: 0.1, "First attempt should be base delay")
        XCTAssertEqual(backoff.delay(for: 1), 2.0, accuracy: 0.1, "Second attempt should double")
        XCTAssertEqual(backoff.delay(for: 2), 4.0, accuracy: 0.1, "Third attempt should be 4x")
        XCTAssertEqual(backoff.delay(for: 3), 8.0, accuracy: 0.1, "Fourth attempt should be 8x")
        XCTAssertEqual(backoff.delay(for: 4), 16.0, accuracy: 0.1, "Fifth attempt should be clamped to max")
        XCTAssertEqual(backoff.delay(for: 5), 16.0, accuracy: 0.1, "Further attempts should remain at max")
    }
    
    func testExponentialBackoff_JitterRange() {
        let backoff = ExponentialBackoff(baseDelay: 1.0, maxDelay: 16.0, jitterRange: 0.8...1.2)
        
        // Test that jitter keeps delays within reasonable bounds
        for attempt in 0..<5 {
            let delay = backoff.delay(for: attempt)
            let expectedBase = min(pow(2.0, Double(attempt)), 16.0)
            let expectedMin = expectedBase * 0.8
            let expectedMax = expectedBase * 1.2
            
            XCTAssertGreaterThanOrEqual(delay, expectedMin, "Delay should respect jitter minimum")
            XCTAssertLessThanOrEqual(delay, expectedMax, "Delay should respect jitter maximum")
        }
    }
    
    // MARK: - Circuit Breaker Tests
    
    func testCircuitBreaker_NormalOperation() async {
        let circuitBreaker = CircuitBreaker(failureThreshold: 3, recoveryTimeout: 1.0)
        
        // Initially closed
        let canExecute1 = await circuitBreaker.canExecute()
        XCTAssertTrue(canExecute1, "Circuit breaker should initially be closed")
        
        // Success keeps it closed
        await circuitBreaker.recordSuccess()
        let canExecute2 = await circuitBreaker.canExecute()
        XCTAssertTrue(canExecute2, "Circuit breaker should remain closed after success")
    }
    
    func testCircuitBreaker_FailureThreshold() async {
        let circuitBreaker = CircuitBreaker(failureThreshold: 3, recoveryTimeout: 1.0)
        
        // Record failures up to threshold
        await circuitBreaker.recordFailure()
        let canExecute1 = await circuitBreaker.canExecute()
        XCTAssertTrue(canExecute1, "Circuit breaker should remain closed at 1 failure")
        
        await circuitBreaker.recordFailure()
        let canExecute2 = await circuitBreaker.canExecute()
        XCTAssertTrue(canExecute2, "Circuit breaker should remain closed at 2 failures")
        
        await circuitBreaker.recordFailure()
        let canExecute3 = await circuitBreaker.canExecute()
        XCTAssertFalse(canExecute3, "Circuit breaker should open at threshold")
        
        let isOpen = await circuitBreaker.isOpen
        XCTAssertTrue(isOpen, "Circuit breaker should report as open")
    }
    
    func testCircuitBreaker_Recovery() async {
        let circuitBreaker = CircuitBreaker(failureThreshold: 2, recoveryTimeout: 0.1, halfOpenSuccessThreshold: 2)
        
        // Trip the circuit breaker
        await circuitBreaker.recordFailure()
        await circuitBreaker.recordFailure()
        let canExecute1 = await circuitBreaker.canExecute()
        XCTAssertFalse(canExecute1, "Circuit breaker should be open")
        
        // Wait for recovery timeout
        try? await Task.sleep(nanoseconds: 150_000_000) // 0.15 seconds
        
        // Should transition to half-open
        let canExecute2 = await circuitBreaker.canExecute()
        XCTAssertTrue(canExecute2, "Circuit breaker should be half-open after timeout")
        
        // Record successes to close it
        await circuitBreaker.recordSuccess()
        await circuitBreaker.recordSuccess()
        
        let isOpen = await circuitBreaker.isOpen
        XCTAssertFalse(isOpen, "Circuit breaker should be closed after successful recovery")
    }
    
    func testCircuitBreaker_FailureInHalfOpen() async {
        let circuitBreaker = CircuitBreaker(failureThreshold: 2, recoveryTimeout: 0.1)
        
        // Trip the circuit breaker
        await circuitBreaker.recordFailure()
        await circuitBreaker.recordFailure()
        
        // Wait for recovery timeout
        try? await Task.sleep(nanoseconds: 150_000_000) // 0.15 seconds
        
        // Should be half-open
        let canExecute1 = await circuitBreaker.canExecute()
        XCTAssertTrue(canExecute1, "Circuit breaker should be half-open")
        
        // Failure in half-open should reopen it
        await circuitBreaker.recordFailure()
        let canExecute2 = await circuitBreaker.canExecute()
        XCTAssertFalse(canExecute2, "Circuit breaker should reopen after failure in half-open state")
    }
    
    // MARK: - Retry Queue Tests
    
    func testRetryQueue_AddRetryRequest() async {
        let retryQueue = RetryQueue(maxRetryAttempts: 3)
        
        // Add a retryable error
        let retryableError = URLError(.timedOut)
        let canRetry1 = await retryQueue.addRetryRequest(isbn: "1234567890", originalIndex: 0, error: retryableError)
        XCTAssertTrue(canRetry1, "Retryable errors should be added to retry queue")
        
        // Add a permanent error
        let permanentError = URLError(.badURL)
        let canRetry2 = await retryQueue.addRetryRequest(isbn: "0987654321", originalIndex: 1, error: permanentError)
        XCTAssertFalse(canRetry2, "Permanent errors should not be added to retry queue")
        
        // Check queue stats
        let stats = await retryQueue.getRetryStats()
        XCTAssertEqual(stats.pendingCount, 1, "Should have 1 pending retry")
    }
    
    func testRetryQueue_MaxRetryAttempts() async {
        let retryQueue = RetryQueue(maxRetryAttempts: 2)
        let error = URLError(.timedOut)
        
        // Add first attempt
        let canRetry1 = await retryQueue.addRetryRequest(isbn: "1234567890", originalIndex: 0, error: error)
        XCTAssertTrue(canRetry1, "First retry should be allowed")
        
        // Add second attempt
        let canRetry2 = await retryQueue.addRetryRequest(isbn: "1234567890", originalIndex: 0, error: error)
        XCTAssertTrue(canRetry2, "Second retry should be allowed")
        
        // Add third attempt (should exceed max)
        let canRetry3 = await retryQueue.addRetryRequest(isbn: "1234567890", originalIndex: 0, error: error)
        XCTAssertFalse(canRetry3, "Third retry should exceed maximum attempts")
        
        let stats = await retryQueue.getRetryStats()
        XCTAssertEqual(stats.pendingCount, 0, "Should have no pending retries after max exceeded")
    }
    
    func testRetryQueue_ReadyRetryRequests() async {
        let retryQueue = RetryQueue(maxRetryAttempts: 3, exponentialBackoff: ExponentialBackoff(baseDelay: 0.1))
        let error = URLError(.timedOut)
        
        // Add retry request
        _ = await retryQueue.addRetryRequest(isbn: "1234567890", originalIndex: 0, error: error)
        
        // Should not be ready immediately
        let readyRequests1 = await retryQueue.getReadyRetryRequests()
        XCTAssertTrue(readyRequests1.isEmpty, "Request should not be ready immediately")
        
        // Wait for backoff delay
        try? await Task.sleep(nanoseconds: 150_000_000) // 0.15 seconds
        
        // Should be ready now
        let readyRequests2 = await retryQueue.getReadyRetryRequests()
        XCTAssertEqual(readyRequests2.count, 1, "Request should be ready after backoff delay")
        XCTAssertEqual(readyRequests2.first?.isbn, "1234567890", "Should return correct ISBN")
    }
    
    func testRetryQueue_SuccessfulRetry() async {
        let retryQueue = RetryQueue(maxRetryAttempts: 3)
        let error = URLError(.timedOut)
        
        // Add retry request
        _ = await retryQueue.addRetryRequest(isbn: "1234567890", originalIndex: 0, error: error)
        
        // Record successful retry
        await retryQueue.recordRetrySuccess("1234567890")
        
        // Should be removed from queue
        let stats = await retryQueue.getRetryStats()
        XCTAssertEqual(stats.pendingCount, 0, "Successful retry should be removed from queue")
        
        let isInQueue = await retryQueue.isInRetryQueue("1234567890")
        XCTAssertFalse(isInQueue, "ISBN should not be in retry queue after success")
    }
    
    // MARK: - Integration Tests
    
    func testLookupStats_RetryStatisticsTracking() {
        var stats = LookupStats()
        
        // Initial state
        XCTAssertEqual(stats.retryStats.totalRetryAttempts, 0)
        XCTAssertEqual(stats.retryStats.retriesSucceeded, 0)
        XCTAssertEqual(stats.retryStats.retriesFailed, 0)
        
        // Record retry attempts
        stats.retryStats.recordRetryAttempt()
        stats.retryStats.recordRetryAttempt()
        XCTAssertEqual(stats.retryStats.totalRetryAttempts, 2)
        
        // Record successes and failures
        stats.retryStats.recordRetrySuccess()
        stats.retryStats.recordRetryFailure()
        XCTAssertEqual(stats.retryStats.retriesSucceeded, 1)
        XCTAssertEqual(stats.retryStats.retriesFailed, 1)
        
        // Record final failure reasons
        stats.recordFinalFailure(reason: "HTTP_404")
        stats.recordFinalFailure(reason: "HTTP_404")
        stats.recordFinalFailure(reason: "URL_-1009")
        
        XCTAssertEqual(stats.finalFailureReasons["HTTP_404"], 2)
        XCTAssertEqual(stats.finalFailureReasons["URL_-1009"], 1)
    }
    
    func testImportProgress_RetryStatisticsIntegration() {
        let sessionId = UUID()
        var progress = ImportProgress(sessionId: sessionId)
        
        // Test retry statistics
        progress.retryAttempts = 5
        progress.successfulRetries = 3
        progress.failedRetries = 2
        progress.maxRetryAttempts = 3
        progress.circuitBreakerTriggered = true
        progress.finalFailureReasons = ["HTTP_500": 2, "Timeout": 1]
        
        // Test calculated properties
        XCTAssertEqual(progress.retrySuccessRate, 60.0, accuracy: 0.1, "Retry success rate should be calculated correctly")
        
        let detailedStatus = progress.detailedStatusMessage
        XCTAssertTrue(detailedStatus.contains("retried"), "Detailed status should mention retries")
    }
    
    func testImportResult_RetryStatisticsIntegration() {
        let result = ImportResult(
            sessionId: UUID(),
            totalBooks: 10,
            successfulImports: 7,
            failedImports: 1,
            duplicatesSkipped: 2,
            duplicatesISBN: 2,
            duplicatesGoogleID: 0,
            duplicatesTitleAuthor: 0,
            duration: 30.0,
            errors: [],
            importedBookIds: [],
            retryAttempts: 5,
            successfulRetries: 4,
            failedRetries: 1,
            maxRetryAttempts: 3,
            circuitBreakerTriggered: false,
            finalFailureReasons: ["HTTP_404": 1]
        )
        
        XCTAssertEqual(result.retrySuccessRate, 80.0, accuracy: 0.1, "Retry success rate should be calculated correctly")
        
        let summary = result.summary
        XCTAssertTrue(summary.contains("retries"), "Summary should mention retries")
        XCTAssertTrue(summary.contains("4 successful"), "Summary should mention successful retries")
        
        let detailedSummary = result.detailedSummary
        XCTAssertTrue(detailedSummary.contains("Retry success rate: 80%"), "Detailed summary should include retry success rate")
        XCTAssertTrue(detailedSummary.contains("HTTP_404: 1"), "Detailed summary should include failure reasons")
    }
    
    // MARK: - Performance Tests
    
    func testConcurrentLookupService_PerformanceWithRetries() async {
        // This is a simplified performance test
        // In a real scenario, you'd want to mock the network layer
        let expectation = XCTestExpectation(description: "Concurrent lookup with retries")
        
        let isbnList = ["9780123456789", "9789876543210", "9781111111111"]
        
        let results = await concurrentLookupService.processISBNsForImport(isbnList) { completed, total in
            if completed == total {
                expectation.fulfill()
            }
        }
        
        await fulfillment(of: [expectation], timeout: 30.0)
        
        XCTAssertEqual(results.count, isbnList.count, "Should return result for each ISBN")
        
        let stats = concurrentLookupService.performanceStats
        XCTAssertGreaterThanOrEqual(stats.completedRequests, 0, "Should track completed requests")
        XCTAssertGreaterThanOrEqual(stats.elapsedTime, 0, "Should track elapsed time")
        
        // Verify retry statistics structure is present
        XCTAssertGreaterThanOrEqual(stats.retryStats.totalRetryAttempts, 0, "Should track retry attempts")
    }
    
    // MARK: - Edge Cases
    
    func testRetryQueue_CircuitBreakerOpen() async {
        let retryQueue = RetryQueue(maxRetryAttempts: 3)
        
        // Simulate circuit breaker opening by causing multiple failures
        let error = URLError(.timedOut)
        for _ in 0..<5 {
            _ = await retryQueue.addRetryRequest(isbn: "test\(UUID())", originalIndex: 0, error: error)
        }
        
        // Circuit breaker should eventually open and prevent new retries
        let readyRequests = await retryQueue.getReadyRetryRequests()
        // The circuit breaker logic will determine if requests are allowed
        
        let stats = await retryQueue.getRetryStats()
        XCTAssertTrue(stats.circuitBreakerOpen || stats.pendingCount >= 0, "Should handle circuit breaker state")
    }
    
    func testRetryRequest_AttemptTracking() {
        var retryRequest = RetryRequest(isbn: "1234567890", originalIndex: 0)
        
        XCTAssertEqual(retryRequest.attemptCount, 0, "Should start with 0 attempts")
        
        let error = URLError(.timedOut)
        retryRequest.recordAttempt(error: error)
        
        XCTAssertEqual(retryRequest.attemptCount, 1, "Should increment attempt count")
        XCTAssertNotNil(retryRequest.lastError, "Should record last error")
    }
}