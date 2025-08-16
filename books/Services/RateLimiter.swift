//
//  RateLimiter.swift
//  books
//
//  Smart rate limiting for API calls using token bucket algorithm
//  Designed for Google Books API with graceful backoff
//

import Foundation

/// Smart rate limiter using token bucket algorithm
/// 
/// This service provides intelligent rate limiting for API calls to prevent
/// exceeding API quotas while maximizing throughput. Uses token bucket algorithm
/// with exponential backoff for failed requests.
///
/// Key Features:
/// - Token bucket algorithm for smooth rate limiting
/// - Configurable rate limits per service
/// - Exponential backoff on rate limit errors
/// - Thread-safe concurrent access
/// - Real-time rate monitoring
actor RateLimiter {
    
    // MARK: - Configuration
    
    /// Configuration for different API services
    enum ServiceType {
        case googleBooks
        case openLibrary
        case custom(tokensPerSecond: Double, burstSize: Int)
        
        var configuration: Configuration {
            switch self {
            case .googleBooks:
                // Google Books API: With API key - 1000 requests/day limit
                // Conservative: ~1 request every 2 seconds (1800 requests/hour max)
                return Configuration(
                    tokensPerSecond: 0.5,
                    bucketSize: 5,
                    initialTokens: 2
                )
            case .openLibrary:
                // OpenLibrary: More generous limits
                return Configuration(
                    tokensPerSecond: 10.0,
                    bucketSize: 20,
                    initialTokens: 10
                )
            case .custom(let tokensPerSecond, let burstSize):
                return Configuration(
                    tokensPerSecond: tokensPerSecond,
                    bucketSize: burstSize,
                    initialTokens: min(burstSize, Int(tokensPerSecond))
                )
            }
        }
    }
    
    struct Configuration {
        let tokensPerSecond: Double
        let bucketSize: Int
        let initialTokens: Int
    }
    
    // MARK: - State
    
    private let configuration: Configuration
    private var tokens: Double
    private var lastRefillTime: Date
    private var consecutiveRateLimitErrors: Int = 0
    private let maxConsecutiveErrors: Int = 3
    
    // MARK: - Statistics
    
    private(set) var totalRequests: Int = 0
    private(set) var rateLimitedRequests: Int = 0
    private(set) var backoffEvents: Int = 0
    
    // MARK: - Initialization
    
    init(serviceType: ServiceType = .googleBooks) {
        self.configuration = serviceType.configuration
        self.tokens = Double(configuration.initialTokens)
        self.lastRefillTime = Date()
    }
    
    // MARK: - Public Interface
    
    /// Wait for permission to make an API call
    /// - Returns: True if permission granted immediately, false if had to wait
    @discardableResult
    func waitForPermission() async -> Bool {
        totalRequests += 1
        
        // Refill tokens based on elapsed time
        refillTokens()
        
        // Check if we need exponential backoff due to consecutive errors
        if consecutiveRateLimitErrors > 0 {
            let backoffDelay = calculateBackoffDelay()
            if backoffDelay > 0 {
                backoffEvents += 1
                try? await Task.sleep(nanoseconds: UInt64(backoffDelay * 1_000_000_000))
                refillTokens() // Refill again after backoff
            }
        }
        
        // If we have tokens, consume one and proceed
        if tokens >= 1.0 {
            tokens -= 1.0
            consecutiveRateLimitErrors = 0 // Reset on successful permission
            return true
        }
        
        // Need to wait for tokens
        rateLimitedRequests += 1
        let waitTime = calculateWaitTime()
        try? await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
        
        // Refill after waiting and consume token
        refillTokens()
        if tokens >= 1.0 {
            tokens -= 1.0
            consecutiveRateLimitErrors = 0
            return false // Had to wait
        }
        
        // Fallback: just consume available tokens
        tokens = max(0, tokens - 1.0)
        return false
    }
    
    /// Report a rate limit error to trigger backoff
    func reportRateLimitError() {
        consecutiveRateLimitErrors += 1
        rateLimitedRequests += 1
    }
    
    /// Report successful API call (resets error count)
    func reportSuccess() {
        consecutiveRateLimitErrors = 0
    }
    
    /// Get current rate limiter status
    func getStatus() -> RateLimiterStatus {
        refillTokens()
        return RateLimiterStatus(
            currentTokens: tokens,
            maxTokens: Double(configuration.bucketSize),
            tokensPerSecond: configuration.tokensPerSecond,
            totalRequests: totalRequests,
            rateLimitedRequests: rateLimitedRequests,
            backoffEvents: backoffEvents,
            consecutiveErrors: consecutiveRateLimitErrors,
            isBackoffActive: consecutiveRateLimitErrors > 0
        )
    }
    
    /// Reset all statistics
    func resetStatistics() {
        totalRequests = 0
        rateLimitedRequests = 0
        backoffEvents = 0
        consecutiveRateLimitErrors = 0
    }
    
    // MARK: - Private Implementation
    
    /// Refill tokens based on elapsed time
    private func refillTokens() {
        let now = Date()
        let timePassed = now.timeIntervalSince(lastRefillTime)
        let tokensToAdd = timePassed * configuration.tokensPerSecond
        
        tokens = min(Double(configuration.bucketSize), tokens + tokensToAdd)
        lastRefillTime = now
    }
    
    /// Calculate how long to wait for a token
    private func calculateWaitTime() -> Double {
        let tokensNeeded = 1.0 - tokens
        return tokensNeeded / configuration.tokensPerSecond
    }
    
    /// Calculate exponential backoff delay
    private func calculateBackoffDelay() -> Double {
        guard consecutiveRateLimitErrors > 0 else { return 0 }
        
        // Exponential backoff: 1s, 2s, 4s, then cap at 8s
        let backoffSeconds = min(8.0, pow(2.0, Double(consecutiveRateLimitErrors - 1)))
        
        // Add some jitter (±25%) to avoid thundering herd
        let jitter = Double.random(in: 0.75...1.25)
        return backoffSeconds * jitter
    }
}

// MARK: - Status Information

/// Current status of the rate limiter
struct RateLimiterStatus {
    let currentTokens: Double
    let maxTokens: Double
    let tokensPerSecond: Double
    let totalRequests: Int
    let rateLimitedRequests: Int
    let backoffEvents: Int
    let consecutiveErrors: Int
    let isBackoffActive: Bool
    
    var utilizationRate: Double {
        guard totalRequests > 0 else { return 0 }
        return Double(rateLimitedRequests) / Double(totalRequests)
    }
    
    var tokensRemainingPercent: Double {
        guard maxTokens > 0 else { return 0 }
        return (currentTokens / maxTokens) * 100
    }
    
    var description: String {
        return "Tokens: \(Int(currentTokens))/\(Int(maxTokens)) " +
               "(\(Int(tokensRemainingPercent))%), " +
               "Rate: \(tokensPerSecond)/s, " +
               "Utilization: \(Int(utilizationRate * 100))%, " +
               "Backoff: \(isBackoffActive ? "Active" : "Inactive")"
    }
}

// MARK: - Convenience Extensions

extension RateLimiter {
    
    /// Execute an async operation with rate limiting
    /// - Parameter operation: The async operation to execute
    /// - Returns: Result of the operation
    func execute<T: Sendable>(_ operation: @escaping @Sendable () async throws -> T) async throws -> T {
        await waitForPermission()
        
        do {
            let result = try await operation()
            reportSuccess()
            return result
        } catch {
            // Check if this is a rate limit error
            if isRateLimitError(error) {
                reportRateLimitError()
            }
            throw error
        }
    }
    
    /// Check if an error is a rate limit error
    /// - Parameter error: The error to check
    /// - Returns: True if this is a rate limiting error
    private func isRateLimitError(_ error: Error) -> Bool {
        // Common HTTP status codes for rate limiting
        if let urlError = error as? URLError {
            return urlError.code == .cannotConnectToHost ||
                   urlError.code == .timedOut
        }
        
        // Check error description for rate limit indicators
        let errorDescription = error.localizedDescription.lowercased()
        return errorDescription.contains("rate limit") ||
               errorDescription.contains("too many requests") ||
               errorDescription.contains("quota exceeded") ||
               errorDescription.contains("429")
    }
}

// MARK: - Global Rate Limiter Instance

extension RateLimiter {
    
    /// Shared instance for Google Books API
    static let googleBooks = RateLimiter(serviceType: .googleBooks)
    
    /// Shared instance for OpenLibrary API
    static let openLibrary = RateLimiter(serviceType: .openLibrary)
}