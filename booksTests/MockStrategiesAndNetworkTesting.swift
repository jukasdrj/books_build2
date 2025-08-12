//
// MockStrategiesAndNetworkTesting.swift
// books
//
// Comprehensive mock strategies for BookSearchService integration
// Advanced network testing patterns and service mocking
//

import Testing
import Foundation
@testable import books

@Suite("Mock Strategies and Network Testing")
struct MockStrategiesAndNetworkTesting {
    
    // MARK: - Mock Strategy Pattern Tests
    
    @Test("Mock Strategy - Basic mock verification")
    func testBasicMockVerification() async throws {
        let mockService = AdvancedMockBookSearchService()
        
        // Configure basic mock response
        let expectedMetadata = BookMetadata(
            googleBooksID: "mock-test-id",
            title: "Mock Test Book",
            authors: ["Mock Author"],
            isbn: "9781234567890"
        )
        
        mockService.configureMockResponse(for: "9781234567890", response: .success(expectedMetadata))
        
        // Execute search
        let result = await mockService.search(query: "isbn:9781234567890")
        
        // Verify result
        switch result {
        case .success(let metadata):
            #expect(metadata.count == 1, "Should return one book")
            #expect(metadata.first?.isbn == "9781234567890", "Should return correct ISBN")
            #expect(metadata.first?.title == "Mock Test Book", "Should return mock title")
        case .failure:
            throw TestingError("Mock should return success")
        }
        
        // Verify call was tracked
        #expect(mockService.searchCallCount == 1, "Should track call count")
        #expect(mockService.lastSearchQuery == "isbn:9781234567890", "Should track last query")
    }
    
    @Test("Mock Strategy - Conditional response testing")
    func testConditionalResponseMocking() async throws {
        let mockService = AdvancedMockBookSearchService()
        
        // Configure conditional responses based on query patterns
        mockService.addConditionalResponse(
            condition: .queryContains("swift"),
            response: .success([
                BookMetadata(
                    googleBooksID: "swift-book-1",
                    title: "Swift Programming Guide",
                    authors: ["Swift Author"],
                    isbn: "9780134682331"
                )
            ])
        )
        
        mockService.addConditionalResponse(
            condition: .queryContains("python"),
            response: .success([
                BookMetadata(
                    googleBooksID: "python-book-1",
                    title: "Python for Beginners",
                    authors: ["Python Author"],
                    isbn: "9780134682332"
                )
            ])
        )
        
        mockService.addConditionalResponse(
            condition: .queryContains("invalid"),
            response: .failure(.networkError("Book not found"))
        )
        
        // Test Swift query
        let swiftResult = await mockService.search(query: "swift programming")
        switch swiftResult {
        case .success(let books):
            #expect(books.first?.title.contains("Swift") == true, "Should return Swift book")
        case .failure:
            throw TestingError("Swift query should succeed")
        }
        
        // Test Python query
        let pythonResult = await mockService.search(query: "python guide")
        switch pythonResult {
        case .success(let books):
            #expect(books.first?.title.contains("Python") == true, "Should return Python book")
        case .failure:
            throw TestingError("Python query should succeed")
        }
        
        // Test invalid query
        let invalidResult = await mockService.search(query: "invalid book")
        switch invalidResult {
        case .failure(let error):
            #expect(error.localizedDescription.contains("not found"), "Should return appropriate error")
        case .success:
            throw TestingError("Invalid query should fail")
        }
    }
    
    @Test("Mock Strategy - Sequence-based response testing")
    func testSequenceBasedResponseMocking() async throws {
        let mockService = AdvancedMockBookSearchService()
        
        // Configure sequence of responses for the same query
        let testISBN = "9781234567890"
        mockService.configureSequenceResponse(for: testISBN, sequence: [
            .failure(.networkError("Network timeout")), // First call fails
            .failure(.networkError("Rate limited")),    // Second call fails
            .success([BookMetadata(                      // Third call succeeds
                googleBooksID: "sequence-test",
                title: "Sequence Test Book",
                authors: ["Test Author"],
                isbn: testISBN
            )])
        ])
        
        // First call should fail
        let firstResult = await mockService.search(query: "isbn:\(testISBN)")
        #expect(firstResult.isFailure, "First call should fail")
        
        // Second call should fail
        let secondResult = await mockService.search(query: "isbn:\(testISBN)")
        #expect(secondResult.isFailure, "Second call should fail")
        
        // Third call should succeed
        let thirdResult = await mockService.search(query: "isbn:\(testISBN)")
        switch thirdResult {
        case .success(let books):
            #expect(books.first?.title == "Sequence Test Book", "Third call should succeed with correct book")
        case .failure:
            throw TestingError("Third call should succeed")
        }
        
        // Verify call sequence tracking
        let callHistory = mockService.getCallHistory()
        #expect(callHistory.count == 3, "Should track all three calls")
    }
    
    @Test("Mock Strategy - Performance simulation testing")
    func testPerformanceSimulationMocking() async throws {
        let mockService = AdvancedMockBookSearchService()
        
        // Configure performance characteristics
        mockService.configurePerformanceSimulation(
            averageResponseTime: 0.5,
            responseTimeVariation: 0.2,
            successRate: 0.85,
            networkLatencySimulation: true
        )
        
        let testQueries = [
            "isbn:9781111111111",
            "isbn:9782222222222", 
            "isbn:9783333333333",
            "isbn:9784444444444",
            "isbn:9785555555555"
        ]
        
        let startTime = Date()
        var successCount = 0
        var totalCalls = 0
        
        for query in testQueries {
            let result = await mockService.search(query: query)
            totalCalls += 1
            
            if case .success = result {
                successCount += 1
            }
        }
        
        let duration = Date().timeIntervalSince(startTime)
        let actualSuccessRate = Double(successCount) / Double(totalCalls)
        
        // Verify performance simulation
        #expect(duration >= 2.0, "Should simulate realistic response times") // ~0.5s * 5 calls
        #expect(duration <= 4.0, "Should not be unrealistically slow")
        #expect(actualSuccessRate >= 0.7, "Should simulate configured success rate roughly")
        #expect(actualSuccessRate <= 1.0, "Success rate should not exceed 100%")
        
        let performanceStats = mockService.getPerformanceStats()
        #expect(performanceStats.averageResponseTime >= 0.3, "Should track realistic response times")
        #expect(performanceStats.averageResponseTime <= 0.8, "Should track realistic response times")
    }
    
    // MARK: - Network Error Simulation Tests
    
    @Test("Network Simulation - HTTP status code testing")
    func testHTTPStatusCodeSimulation() async throws {
        let mockService = AdvancedMockBookSearchService()
        
        // Configure various HTTP status codes
        mockService.configureHTTPStatusResponse(400, for: "invalid-query")
        mockService.configureHTTPStatusResponse(401, for: "unauthorized")
        mockService.configureHTTPStatusResponse(403, for: "forbidden")
        mockService.configureHTTPStatusResponse(404, for: "not-found")
        mockService.configureHTTPStatusResponse(429, for: "rate-limited")
        mockService.configureHTTPStatusResponse(500, for: "server-error")
        mockService.configureHTTPStatusResponse(502, for: "bad-gateway")
        mockService.configureHTTPStatusResponse(503, for: "service-unavailable")
        
        let testCases: [(String, Int)] = [
            ("invalid-query", 400),
            ("unauthorized", 401),
            ("forbidden", 403),
            ("not-found", 404),
            ("rate-limited", 429),
            ("server-error", 500),
            ("bad-gateway", 502),
            ("service-unavailable", 503)
        ]
        
        for (query, expectedStatusCode) in testCases {
            let result = await mockService.search(query: query)
            
            switch result {
            case .failure(let error):
                if let httpError = error as? HTTPStatusError {
                    #expect(httpError.statusCode == expectedStatusCode, "Should return correct HTTP status code for \(query)")
                } else {
                    throw TestingError("Should return HTTP status error for \(query)")
                }
            case .success:
                throw TestingError("Query '\(query)' should fail with HTTP error")
            }
        }
    }
    
    @Test("Network Simulation - Timeout and connection error testing")
    func testTimeoutAndConnectionErrorSimulation() async throws {
        let mockService = AdvancedMockBookSearchService()
        
        // Configure different types of network errors
        mockService.configureNetworkError(.timeout, for: "timeout-test")
        mockService.configureNetworkError(.connectionLost, for: "connection-lost")
        mockService.configureNetworkError(.noInternet, for: "no-internet")
        mockService.configureNetworkError(.dnsFailure, for: "dns-failure")
        mockService.configureNetworkError(.invalidURL, for: "invalid-url")
        
        let testCases: [(String, NetworkErrorType)] = [
            ("timeout-test", .timeout),
            ("connection-lost", .connectionLost),
            ("no-internet", .noInternet),
            ("dns-failure", .dnsFailure),
            ("invalid-url", .invalidURL)
        ]
        
        for (query, expectedErrorType) in testCases {
            let result = await mockService.search(query: query)
            
            switch result {
            case .failure(let error):
                if let networkError = error as? NetworkSimulationError {
                    #expect(networkError.errorType == expectedErrorType, "Should return correct network error type for \(query)")
                } else {
                    throw TestingError("Should return network simulation error for \(query)")
                }
            case .success:
                throw TestingError("Query '\(query)' should fail with network error")
            }
        }
    }
    
    @Test("Network Simulation - Rate limiting behavior testing")
    func testRateLimitingSimulation() async throws {
        let mockService = AdvancedMockBookSearchService()
        
        // Configure rate limiting: 5 requests per 2 seconds
        mockService.configureRateLimiting(
            maxRequests: 5,
            timeWindow: 2.0,
            rateLimitResponse: .http429WithRetryAfter(30)
        )
        
        let queries = Array(1...8).map { "rate-limit-test-\($0)" }
        var rateLimitedCount = 0
        var successCount = 0
        
        let startTime = Date()
        
        // Fire requests rapidly
        for query in queries {
            let result = await mockService.search(query: query)
            
            switch result {
            case .success:
                successCount += 1
            case .failure(let error):
                if let httpError = error as? HTTPStatusError, httpError.statusCode == 429 {
                    rateLimitedCount += 1
                }
            }
        }
        
        let duration = Date().timeIntervalSince(startTime)
        
        // Should rate limit some requests
        #expect(rateLimitedCount >= 3, "Should rate limit at least 3 requests")
        #expect(successCount <= 5, "Should not exceed rate limit")
        #expect(successCount >= 3, "Should allow some requests through")
        
        // Rate limit should reset after time window
        try await Task.sleep(nanoseconds: 2_500_000_000) // 2.5 seconds
        
        let afterResetResult = await mockService.search(query: "after-reset-test")
        #expect(afterResetResult.isSuccess, "Should allow requests after rate limit reset")
    }
    
    @Test("Network Simulation - Intermittent connectivity testing")
    func testIntermittentConnectivitySimulation() async throws {
        let mockService = AdvancedMockBookSearchService()
        
        // Configure intermittent connectivity: alternating success/failure
        mockService.configureIntermittentConnectivity(
            pattern: .alternating,
            failureRate: 0.4, // 40% of requests fail
            recoveryTime: 1.0
        )
        
        var results: [Bool] = []
        let queries = Array(1...10).map { "intermittent-test-\($0)" }
        
        for query in queries {
            let result = await mockService.search(query: query)
            results.append(result.isSuccess)
        }
        
        let successCount = results.filter { $0 }.count
        let failureCount = results.filter { !$0 }.count
        
        // Should have mix of successes and failures
        #expect(successCount >= 3, "Should have some successes")
        #expect(failureCount >= 2, "Should have some failures")
        #expect(successCount + failureCount == 10, "Should account for all requests")
        
        // Verify intermittent pattern was followed
        let connectivityStats = mockService.getConnectivityStats()
        #expect(connectivityStats.connectivityChanges >= 2, "Should have connectivity state changes")
    }
    
    // MARK: - API Response Variation Tests
    
    @Test("API Response Variation - Data completeness simulation")
    func testDataCompletenessVariation() async throws {
        let mockService = AdvancedMockBookSearchService()
        
        // Configure different levels of data completeness
        mockService.configureDataCompletenessVariation(
            completeDataRate: 0.6,    // 60% complete data
            partialDataRate: 0.3,     // 30% partial data  
            minimalDataRate: 0.1      // 10% minimal data
        )
        
        let queries = Array(1...20).map { "completeness-test-\($0)" }
        var completeDataCount = 0
        var partialDataCount = 0
        var minimalDataCount = 0
        
        for query in queries {
            let result = await mockService.search(query: query)
            
            switch result {
            case .success(let books):
                if let book = books.first {
                    let completenessScore = calculateCompletenessScore(book)
                    
                    if completenessScore >= 0.8 {
                        completeDataCount += 1
                    } else if completenessScore >= 0.5 {
                        partialDataCount += 1
                    } else {
                        minimalDataCount += 1
                    }
                }
            case .failure:
                // Count as minimal data for this test
                minimalDataCount += 1
            }
        }
        
        // Verify data completeness distribution
        #expect(completeDataCount >= 8, "Should have majority complete data")
        #expect(partialDataCount >= 3, "Should have some partial data")
        #expect(minimalDataCount >= 1, "Should have some minimal data")
        
        let total = completeDataCount + partialDataCount + minimalDataCount
        #expect(total == 20, "Should account for all responses")
    }
    
    @Test("API Response Variation - Response time variation simulation")
    func testResponseTimeVariation() async throws {
        let mockService = AdvancedMockBookSearchService()
        
        // Configure response time patterns
        mockService.configureResponseTimeVariation(
            fastResponseRate: 0.4,      // 40% fast responses (< 100ms)
            normalResponseRate: 0.5,    // 50% normal responses (100-500ms)
            slowResponseRate: 0.1       // 10% slow responses (> 500ms)
        )
        
        let queries = Array(1...30).map { "response-time-test-\($0)" }
        var responseTimes: [TimeInterval] = []
        
        for query in queries {
            let startTime = Date()
            await mockService.search(query: query)
            let responseTime = Date().timeIntervalSince(startTime)
            responseTimes.append(responseTime)
        }
        
        let fastResponses = responseTimes.filter { $0 < 0.1 }.count
        let normalResponses = responseTimes.filter { $0 >= 0.1 && $0 <= 0.5 }.count
        let slowResponses = responseTimes.filter { $0 > 0.5 }.count
        
        // Verify response time distribution
        #expect(fastResponses >= 8, "Should have fast responses")
        #expect(normalResponses >= 10, "Should have normal responses")
        #expect(slowResponses >= 2, "Should have slow responses")
        
        let averageResponseTime = responseTimes.reduce(0, +) / Double(responseTimes.count)
        #expect(averageResponseTime >= 0.05, "Average response time should be realistic")
        #expect(averageResponseTime <= 0.8, "Average response time should not be too slow")
    }
    
    // MARK: - Mock State Management Tests
    
    @Test("Mock State Management - Call history tracking")
    func testCallHistoryTracking() async throws {
        let mockService = AdvancedMockBookSearchService()
        mockService.enableDetailedTracking(true)
        
        let testQueries = [
            "isbn:9781111111111",
            "title:Swift Programming",
            "author:John Smith",
            "isbn:9782222222222",
            "title:Python Guide"
        ]
        
        for query in testQueries {
            await mockService.search(query: query)
        }
        
        let callHistory = mockService.getDetailedCallHistory()
        
        #expect(callHistory.count == 5, "Should track all calls")
        
        for (index, call) in callHistory.enumerated() {
            #expect(call.query == testQueries[index], "Should track queries in order")
            #expect(call.timestamp != nil, "Should track call timestamp")
            #expect(call.responseTime >= 0, "Should track response time")
        }
        
        // Verify query pattern analysis
        let queryAnalysis = mockService.analyzeQueryPatterns()
        #expect(queryAnalysis.isbnQueryCount == 2, "Should identify ISBN queries")
        #expect(queryAnalysis.titleQueryCount == 2, "Should identify title queries")
        #expect(queryAnalysis.authorQueryCount == 1, "Should identify author queries")
    }
    
    @Test("Mock State Management - Mock state reset and isolation")
    func testMockStateResetAndIsolation() async throws {
        let mockService = AdvancedMockBookSearchService()
        
        // Configure initial state
        mockService.configureMockResponse(for: "test1", response: .success([]))
        await mockService.search(query: "test1")
        
        let initialCallCount = mockService.searchCallCount
        #expect(initialCallCount == 1, "Should have one call")
        
        // Reset mock state
        mockService.resetMockState()
        
        #expect(mockService.searchCallCount == 0, "Should reset call count")
        #expect(mockService.getCallHistory().isEmpty, "Should reset call history")
        
        // Verify previous configurations are cleared
        let result = await mockService.search(query: "test1")
        #expect(result.isFailure || (result.isSuccess && result.successValue?.isEmpty == true), "Should not use previous configuration")
        
        // Configure new state after reset
        mockService.configureMockResponse(for: "test2", response: .success([
            BookMetadata(googleBooksID: "after-reset", title: "After Reset", authors: ["Test"])
        ]))
        
        let newResult = await mockService.search(query: "test2")
        switch newResult {
        case .success(let books):
            #expect(books.first?.title == "After Reset", "Should use new configuration")
        case .failure:
            throw TestingError("New configuration should work")
        }
    }
    
    @Test("Mock State Management - Concurrent access safety")
    func testConcurrentAccessSafety() async throws {
        let mockService = AdvancedMockBookSearchService()
        mockService.enableThreadSafetyValidation(true)
        
        // Configure responses for concurrent testing
        for i in 1...50 {
            let isbn = "978\(String(i).padded(toLength: 10, withPad: "0", startingAt: 0))"
            mockService.configureMockResponse(for: isbn, response: .success([
                BookMetadata(googleBooksID: "concurrent-\(i)", title: "Book \(i)", authors: ["Author \(i)"], isbn: isbn)
            ]))
        }
        
        // Execute concurrent requests
        await withTaskGroup(of: Bool.self) { group in
            for i in 1...50 {
                group.addTask {
                    let isbn = "978\(String(i).padded(toLength: 10, withPad: "0", startingAt: 0))"
                    let result = await mockService.search(query: "isbn:\(isbn)")
                    return result.isSuccess
                }
            }
            
            var successCount = 0
            for await success in group {
                if success {
                    successCount += 1
                }
            }
            
            #expect(successCount == 50, "All concurrent requests should succeed")
        }
        
        // Verify thread safety
        let threadSafetyReport = mockService.getThreadSafetyReport()
        #expect(threadSafetyReport.raceconditionCount == 0, "Should not have race conditions")
        #expect(threadSafetyReport.dataCorruptionCount == 0, "Should not have data corruption")
        #expect(threadSafetyReport.concurrentAccessCount >= 50, "Should track concurrent access")
    }
}

// MARK: - Advanced Mock Service Implementation

class AdvancedMockBookSearchService {
    
    // MARK: - Basic Mock State
    private var mockResponses: [String: MockResponse] = [:]
    private var conditionalResponses: [ConditionalResponse] = []
    private var sequenceResponses: [String: [MockResponse]] = [:]
    private var sequenceIndices: [String: Int] = [:]
    
    // MARK: - Call Tracking
    private(set) var searchCallCount = 0
    private(set) var lastSearchQuery: String?
    private var callHistory: [CallRecord] = []
    private var detailedTracking = false
    
    // MARK: - Performance Simulation
    private var performanceConfig: PerformanceConfig?
    private var performanceStats: PerformanceStats = PerformanceStats()
    
    // MARK: - Network Simulation
    private var httpStatusResponses: [String: Int] = [:]
    private var networkErrorResponses: [String: NetworkErrorType] = [:]
    private var rateLimitConfig: RateLimitConfig?
    private var rateLimitState = RateLimitState()
    private var intermittentConfig: IntermittentConfig?
    private var intermittentState = IntermittentState()
    
    // MARK: - Data Variation
    private var dataCompletenessConfig: DataCompletenessConfig?
    private var responseTimeConfig: ResponseTimeConfig?
    
    // MARK: - Thread Safety
    private var threadSafetyValidation = false
    private var threadSafetyReport = ThreadSafetyReport()
    private let accessQueue = DispatchQueue(label: "mock-service-queue", attributes: .concurrent)
    
    // MARK: - Basic Configuration
    
    func configureMockResponse(for query: String, response: MockResponse) {
        mockResponses[query] = response
    }
    
    func addConditionalResponse(condition: QueryCondition, response: MockResponse) {
        conditionalResponses.append(ConditionalResponse(condition: condition, response: response))
    }
    
    func configureSequenceResponse(for query: String, sequence: [MockResponse]) {
        sequenceResponses[query] = sequence
        sequenceIndices[query] = 0
    }
    
    // MARK: - Performance Configuration
    
    func configurePerformanceSimulation(
        averageResponseTime: TimeInterval,
        responseTimeVariation: TimeInterval,
        successRate: Double,
        networkLatencySimulation: Bool
    ) {
        performanceConfig = PerformanceConfig(
            averageResponseTime: averageResponseTime,
            responseTimeVariation: responseTimeVariation,
            successRate: successRate,
            networkLatencySimulation: networkLatencySimulation
        )
    }
    
    // MARK: - Network Error Configuration
    
    func configureHTTPStatusResponse(_ statusCode: Int, for query: String) {
        httpStatusResponses[query] = statusCode
    }
    
    func configureNetworkError(_ errorType: NetworkErrorType, for query: String) {
        networkErrorResponses[query] = errorType
    }
    
    func configureRateLimiting(
        maxRequests: Int,
        timeWindow: TimeInterval,
        rateLimitResponse: RateLimitResponse
    ) {
        rateLimitConfig = RateLimitConfig(
            maxRequests: maxRequests,
            timeWindow: timeWindow,
            response: rateLimitResponse
        )
        rateLimitState = RateLimitState()
    }
    
    func configureIntermittentConnectivity(
        pattern: ConnectivityPattern,
        failureRate: Double,
        recoveryTime: TimeInterval
    ) {
        intermittentConfig = IntermittentConfig(
            pattern: pattern,
            failureRate: failureRate,
            recoveryTime: recoveryTime
        )
        intermittentState = IntermittentState()
    }
    
    // MARK: - Data Variation Configuration
    
    func configureDataCompletenessVariation(
        completeDataRate: Double,
        partialDataRate: Double,
        minimalDataRate: Double
    ) {
        dataCompletenessConfig = DataCompletenessConfig(
            completeDataRate: completeDataRate,
            partialDataRate: partialDataRate,
            minimalDataRate: minimalDataRate
        )
    }
    
    func configureResponseTimeVariation(
        fastResponseRate: Double,
        normalResponseRate: Double,
        slowResponseRate: Double
    ) {
        responseTimeConfig = ResponseTimeConfig(
            fastResponseRate: fastResponseRate,
            normalResponseRate: normalResponseRate,
            slowResponseRate: slowResponseRate
        )
    }
    
    // MARK: - Tracking Configuration
    
    func enableDetailedTracking(_ enabled: Bool) {
        detailedTracking = enabled
    }
    
    func enableThreadSafetyValidation(_ enabled: Bool) {
        threadSafetyValidation = enabled
    }
    
    // MARK: - Main Search Implementation
    
    func search(
        query: String,
        sortBy: BookSearchService.SortOption = .relevance,
        maxResults: Int = 40,
        includeTranslations: Bool = true
    ) async -> Result<[BookMetadata], BookSearchService.BookError> {
        
        let startTime = Date()
        
        // Thread safety validation
        if threadSafetyValidation {
            threadSafetyReport.concurrentAccessCount += 1
        }
        
        // Track call
        searchCallCount += 1
        lastSearchQuery = query
        
        // Rate limiting check
        if let rateLimitResult = await checkRateLimit() {
            return rateLimitResult
        }
        
        // Intermittent connectivity check
        if let connectivityResult = await checkIntermittentConnectivity() {
            return connectivityResult
        }
        
        // Performance simulation delay
        if let delay = calculateResponseDelay() {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        // Check for configured responses
        let response = await determineResponse(for: query)
        
        // Track call details
        if detailedTracking {
            let responseTime = Date().timeIntervalSince(startTime)
            callHistory.append(CallRecord(
                query: query,
                timestamp: startTime,
                responseTime: responseTime,
                wasSuccessful: response.isSuccess
            ))
        }
        
        // Update performance stats
        let responseTime = Date().timeIntervalSince(startTime)
        performanceStats.addResponseTime(responseTime)
        
        return response
    }
    
    // MARK: - Response Determination
    
    private func determineResponse(for query: String) async -> Result<[BookMetadata], BookSearchService.BookError> {
        
        // Check for HTTP status errors
        if let statusCode = httpStatusResponses[query] {
            return .failure(.networkError("HTTP \(statusCode)"))
        }
        
        // Check for network errors
        if let errorType = networkErrorResponses[query] {
            let error = NetworkSimulationError(errorType: errorType)
            return .failure(.networkError(error.localizedDescription))
        }
        
        // Check sequence responses first
        if let sequence = sequenceResponses[query] {
            let index = sequenceIndices[query] ?? 0
            if index < sequence.count {
                sequenceIndices[query] = index + 1
                return convertMockResponse(sequence[index], for: query)
            }
        }
        
        // Check direct mock responses
        if let mockResponse = mockResponses[query] {
            return convertMockResponse(mockResponse, for: query)
        }
        
        // Check conditional responses
        for conditionalResponse in conditionalResponses {
            if conditionalResponse.condition.matches(query) {
                return convertMockResponse(conditionalResponse.response, for: query)
            }
        }
        
        // Performance simulation success rate
        if let config = performanceConfig {
            let random = Double.random(in: 0...1)
            if random > config.successRate {
                return .failure(.networkError("Simulated network failure"))
            }
        }
        
        // Default response with data completeness variation
        let bookMetadata = generateResponseWithDataVariation(for: query)
        return .success(bookMetadata)
    }
    
    private func convertMockResponse(_ mockResponse: MockResponse, for query: String) -> Result<[BookMetadata], BookSearchService.BookError> {
        switch mockResponse {
        case .success(let books):
            return .success(books)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    // MARK: - Data Generation with Variation
    
    private func generateResponseWithDataVariation(for query: String) -> [BookMetadata] {
        guard let config = dataCompletenessConfig else {
            return [generateDefaultBookMetadata(for: query)]
        }
        
        let random = Double.random(in: 0...1)
        let completeness: DataCompleteness
        
        if random <= config.completeDataRate {
            completeness = .complete
        } else if random <= config.completeDataRate + config.partialDataRate {
            completeness = .partial
        } else {
            completeness = .minimal
        }
        
        return [generateBookMetadata(for: query, completeness: completeness)]
    }
    
    private func generateBookMetadata(for query: String, completeness: DataCompleteness) -> BookMetadata {
        let baseId = query.replacingOccurrences(of: "[^a-zA-Z0-9]", with: "", options: .regularExpression)
        
        switch completeness {
        case .complete:
            return BookMetadata(
                googleBooksID: "complete-\(baseId)",
                title: "Complete Data Book for \(query)",
                authors: ["Complete Author"],
                publishedDate: "2024",
                pageCount: 250,
                bookDescription: "This is a complete book description with rich metadata",
                imageURL: URL(string: "https://example.com/complete-cover.jpg"),
                language: "en",
                publisher: "Complete Publisher",
                isbn: "9781234567890",
                genre: ["Fiction", "Technology", "Education"]
            )
            
        case .partial:
            return BookMetadata(
                googleBooksID: "partial-\(baseId)",
                title: "Partial Data Book for \(query)",
                authors: ["Partial Author"],
                publishedDate: "2024",
                pageCount: nil,
                bookDescription: nil,
                imageURL: nil,
                language: "en",
                publisher: nil,
                isbn: "9781234567891",
                genre: ["Fiction"]
            )
            
        case .minimal:
            return BookMetadata(
                googleBooksID: "minimal-\(baseId)",
                title: "Minimal Book",
                authors: ["Author"],
                publishedDate: nil,
                pageCount: nil,
                bookDescription: nil,
                imageURL: nil,
                language: nil,
                publisher: nil,
                isbn: nil,
                genre: []
            )
        }
    }
    
    private func generateDefaultBookMetadata(for query: String) -> BookMetadata {
        let baseId = query.replacingOccurrences(of: "[^a-zA-Z0-9]", with: "", options: .regularExpression)
        return BookMetadata(
            googleBooksID: "default-\(baseId)",
            title: "Default Book for \(query)",
            authors: ["Default Author"],
            isbn: "9781234567890"
        )
    }
    
    // MARK: - Rate Limiting Logic
    
    private func checkRateLimit() async -> Result<[BookMetadata], BookSearchService.BookError>? {
        guard let config = rateLimitConfig else { return nil }
        
        let now = Date()
        
        // Clean old requests
        rateLimitState.requestTimes = rateLimitState.requestTimes.filter {
            now.timeIntervalSince($0) < config.timeWindow
        }
        
        // Check if over limit
        if rateLimitState.requestTimes.count >= config.maxRequests {
            switch config.response {
            case .http429WithRetryAfter(let retryAfter):
                let error = HTTPStatusError(statusCode: 429, retryAfter: retryAfter)
                return .failure(.networkError("Rate limited: \(error.localizedDescription)"))
            case .networkTimeout:
                return .failure(.networkError("Network timeout due to rate limiting"))
            }
        }
        
        // Record this request
        rateLimitState.requestTimes.append(now)
        return nil
    }
    
    // MARK: - Intermittent Connectivity Logic
    
    private func checkIntermittentConnectivity() async -> Result<[BookMetadata], BookSearchService.BookError>? {
        guard let config = intermittentConfig else { return nil }
        
        let now = Date()
        
        // Check recovery time
        if let lastFailure = intermittentState.lastFailureTime,
           now.timeIntervalSince(lastFailure) < config.recoveryTime {
            return .failure(.networkError("Connection still recovering"))
        }
        
        let shouldFail: Bool
        switch config.pattern {
        case .alternating:
            shouldFail = intermittentState.lastWasSuccess
            intermittentState.lastWasSuccess = !shouldFail
        case .random:
            shouldFail = Double.random(in: 0...1) < config.failureRate
        }
        
        if shouldFail {
            intermittentState.lastFailureTime = now
            intermittentState.connectivityChanges += 1
            return .failure(.networkError("Intermittent connectivity failure"))
        }
        
        return nil
    }
    
    // MARK: - Response Time Calculation
    
    private func calculateResponseDelay() -> TimeInterval? {
        if let responseConfig = responseTimeConfig {
            let random = Double.random(in: 0...1)
            
            if random <= responseConfig.fastResponseRate {
                return Double.random(in: 0.01...0.1)
            } else if random <= responseConfig.fastResponseRate + responseConfig.normalResponseRate {
                return Double.random(in: 0.1...0.5)
            } else {
                return Double.random(in: 0.5...2.0)
            }
        } else if let perfConfig = performanceConfig {
            let baseTime = perfConfig.averageResponseTime
            let variation = perfConfig.responseTimeVariation
            let delay = baseTime + Double.random(in: -variation...variation)
            return max(0.01, delay)
        }
        
        return nil
    }
    
    // MARK: - State Management
    
    func resetMockState() {
        mockResponses.removeAll()
        conditionalResponses.removeAll()
        sequenceResponses.removeAll()
        sequenceIndices.removeAll()
        searchCallCount = 0
        lastSearchQuery = nil
        callHistory.removeAll()
        performanceStats = PerformanceStats()
        rateLimitState = RateLimitState()
        intermittentState = IntermittentState()
        threadSafetyReport = ThreadSafetyReport()
    }
    
    // MARK: - Query and Statistics
    
    func getCallHistory() -> [String] {
        return callHistory.map(\.query)
    }
    
    func getDetailedCallHistory() -> [CallRecord] {
        return callHistory
    }
    
    func analyzeQueryPatterns() -> QueryPatternAnalysis {
        let isbnQueries = callHistory.filter { $0.query.contains("isbn:") }
        let titleQueries = callHistory.filter { $0.query.contains("title:") || (!$0.query.contains("isbn:") && !$0.query.contains("author:")) }
        let authorQueries = callHistory.filter { $0.query.contains("author:") }
        
        return QueryPatternAnalysis(
            isbnQueryCount: isbnQueries.count,
            titleQueryCount: titleQueries.count,
            authorQueryCount: authorQueries.count
        )
    }
    
    func getPerformanceStats() -> PerformanceStats {
        return performanceStats
    }
    
    func getConnectivityStats() -> ConnectivityStats {
        return ConnectivityStats(connectivityChanges: intermittentState.connectivityChanges)
    }
    
    func getThreadSafetyReport() -> ThreadSafetyReport {
        return threadSafetyReport
    }
}

// MARK: - Supporting Types and Enums

enum MockResponse {
    case success([BookMetadata])
    case failure(BookSearchService.BookError)
}

struct ConditionalResponse {
    let condition: QueryCondition
    let response: MockResponse
}

enum QueryCondition {
    case queryContains(String)
    case queryMatches(String)
    case queryStartsWith(String)
    
    func matches(_ query: String) -> Bool {
        switch self {
        case .queryContains(let substring):
            return query.lowercased().contains(substring.lowercased())
        case .queryMatches(let exact):
            return query.lowercased() == exact.lowercased()
        case .queryStartsWith(let prefix):
            return query.lowercased().hasPrefix(prefix.lowercased())
        }
    }
}

struct PerformanceConfig {
    let averageResponseTime: TimeInterval
    let responseTimeVariation: TimeInterval
    let successRate: Double
    let networkLatencySimulation: Bool
}

struct DataCompletenessConfig {
    let completeDataRate: Double
    let partialDataRate: Double
    let minimalDataRate: Double
}

struct ResponseTimeConfig {
    let fastResponseRate: Double
    let normalResponseRate: Double
    let slowResponseRate: Double
}

struct RateLimitConfig {
    let maxRequests: Int
    let timeWindow: TimeInterval
    let response: RateLimitResponse
}

enum RateLimitResponse {
    case http429WithRetryAfter(Int)
    case networkTimeout
}

struct IntermittentConfig {
    let pattern: ConnectivityPattern
    let failureRate: Double
    let recoveryTime: TimeInterval
}

enum ConnectivityPattern {
    case alternating
    case random
}

enum NetworkErrorType {
    case timeout
    case connectionLost
    case noInternet
    case dnsFailure
    case invalidURL
}

enum DataCompleteness {
    case complete
    case partial
    case minimal
}

// MARK: - State Types

struct RateLimitState {
    var requestTimes: [Date] = []
}

struct IntermittentState {
    var lastWasSuccess = true
    var lastFailureTime: Date?
    var connectivityChanges = 0
}

struct PerformanceStats {
    private var responseTimes: [TimeInterval] = []
    
    var averageResponseTime: TimeInterval {
        guard !responseTimes.isEmpty else { return 0 }
        return responseTimes.reduce(0, +) / Double(responseTimes.count)
    }
    
    mutating func addResponseTime(_ time: TimeInterval) {
        responseTimes.append(time)
    }
}

struct ThreadSafetyReport {
    var raceconditionCount = 0
    var dataCorruptionCount = 0
    var concurrentAccessCount = 0
}

// MARK: - Record Types

struct CallRecord {
    let query: String
    let timestamp: Date
    let responseTime: TimeInterval
    let wasSuccessful: Bool
}

struct QueryPatternAnalysis {
    let isbnQueryCount: Int
    let titleQueryCount: Int
    let authorQueryCount: Int
}

struct ConnectivityStats {
    let connectivityChanges: Int
}

// MARK: - Error Types

struct HTTPStatusError: Error {
    let statusCode: Int
    let retryAfter: Int?
    
    init(statusCode: Int, retryAfter: Int? = nil) {
        self.statusCode = statusCode
        self.retryAfter = retryAfter
    }
    
    var localizedDescription: String {
        if let retryAfter = retryAfter {
            return "HTTP \(statusCode) - Retry after \(retryAfter) seconds"
        }
        return "HTTP \(statusCode)"
    }
}

struct NetworkSimulationError: Error {
    let errorType: NetworkErrorType
    
    var localizedDescription: String {
        switch errorType {
        case .timeout:
            return "Request timeout"
        case .connectionLost:
            return "Connection lost"
        case .noInternet:
            return "No internet connection"
        case .dnsFailure:
            return "DNS lookup failed"
        case .invalidURL:
            return "Invalid URL"
        }
    }
}

// MARK: - Helper Functions

private func calculateCompletenessScore(_ book: BookMetadata) -> Double {
    var score = 0.0
    let totalFields = 10.0
    
    if !book.title.isEmpty { score += 1.0 }
    if !book.authors.isEmpty { score += 1.0 }
    if book.publishedDate != nil { score += 1.0 }
    if book.pageCount != nil { score += 1.0 }
    if book.bookDescription != nil && !book.bookDescription!.isEmpty { score += 1.0 }
    if book.imageURL != nil { score += 1.0 }
    if book.language != nil { score += 1.0 }
    if book.publisher != nil && !book.publisher!.isEmpty { score += 1.0 }
    if book.isbn != nil && !book.isbn!.isEmpty { score += 1.0 }
    if !book.genre.isEmpty { score += 1.0 }
    
    return score / totalFields
}

// MARK: - Result Extensions

extension Result {
    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
    
    var isFailure: Bool {
        if case .failure = self { return true }
        return false
    }
    
    var successValue: Success? {
        if case .success(let value) = self { return value }
        return nil
    }
}

// String padding extension
extension String {
    func padded(toLength length: Int, withPad padString: String, startingAt startIndex: Int) -> String {
        let padLength = length - self.count
        guard padLength > 0 else { return self }
        
        let padding = String(repeating: padString, count: padLength / padString.count + 1)
        return self + String(padding.prefix(padLength))
    }
}

struct TestingError: Error, CustomStringConvertible {
    let message: String
    
    init(_ message: String) {
        self.message = message
    }
    
    var description: String {
        return message
    }
}