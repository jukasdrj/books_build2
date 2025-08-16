//
//  ConcurrentImportConfig.swift
//  books
//
//  Configuration settings for concurrent CSV import system
//  Makes it easy to tune performance parameters
//

import Foundation

/// Configuration for concurrent import performance tuning
struct ConcurrentImportConfig {
    
    // MARK: - Concurrency Settings
    
    /// Maximum concurrent ISBN lookups (4 is conservative and reliable)
    let maxConcurrentLookups: Int
    
    /// Batch size for processing books (balances memory vs progress updates)
    let batchSize: Int
    
    /// Size of each batch for concurrent processing
    let concurrentBatchSize: Int
    
    // MARK: - Rate Limiting Settings
    
    /// API requests per second for rate limiting
    let apiRequestsPerSecond: Double
    
    /// Burst capacity for rate limiter (tokens)
    let rateLimiterBurstSize: Int
    
    // MARK: - Memory Management
    
    /// Number of books to save to database in each batch
    let databaseBatchSize: Int
    
    // MARK: - Fallback Settings
    
    /// Whether to use concurrent processing for primary queue (ISBN lookups)
    let useConcurrentPrimaryQueue: Bool
    
    /// Whether to use rate limiting
    let useRateLimiting: Bool
    
    // MARK: - Predefined Configurations
    
    /// Conservative configuration for reliability (default)
    static let conservative = ConcurrentImportConfig(
        maxConcurrentLookups: 2,
        batchSize: 50,
        concurrentBatchSize: 5,
        apiRequestsPerSecond: 0.5,
        rateLimiterBurstSize: 5,
        databaseBatchSize: 50,
        useConcurrentPrimaryQueue: true,
        useRateLimiting: true
    )
    
    /// Aggressive configuration for maximum speed
    static let aggressive = ConcurrentImportConfig(
        maxConcurrentLookups: 3,
        batchSize: 100,
        concurrentBatchSize: 10,
        apiRequestsPerSecond: 1.0,
        rateLimiterBurstSize: 10,
        databaseBatchSize: 100,
        useConcurrentPrimaryQueue: true,
        useRateLimiting: true
    )
    
    /// Sequential configuration (no concurrency for testing/debugging)
    static let sequential = ConcurrentImportConfig(
        maxConcurrentLookups: 1,
        batchSize: 25,
        concurrentBatchSize: 1,
        apiRequestsPerSecond: 5.0,
        rateLimiterBurstSize: 5,
        databaseBatchSize: 25,
        useConcurrentPrimaryQueue: false,
        useRateLimiting: true
    )
    
    /// No rate limiting configuration (for testing or local APIs)
    static let unlimited = ConcurrentImportConfig(
        maxConcurrentLookups: 6,
        batchSize: 75,
        concurrentBatchSize: 15,
        apiRequestsPerSecond: 100.0,
        rateLimiterBurstSize: 100,
        databaseBatchSize: 75,
        useConcurrentPrimaryQueue: true,
        useRateLimiting: false
    )
    
    // MARK: - Performance Estimates
    
    /// Estimated books per minute based on configuration
    var estimatedBooksPerMinute: Int {
        if useConcurrentPrimaryQueue {
            // Concurrent processing estimate
            let effectiveRate = min(apiRequestsPerSecond, Double(maxConcurrentLookups))
            return Int(effectiveRate * 60 * 0.8) // 80% efficiency factor
        } else {
            // Sequential processing estimate  
            return Int(apiRequestsPerSecond * 60 * 0.7) // 70% efficiency factor
        }
    }
    
    /// Expected speed improvement over sequential processing
    var expectedSpeedupFactor: Double {
        if useConcurrentPrimaryQueue && maxConcurrentLookups > 1 {
            // Theoretical maximum is maxConcurrentLookups, but real-world is lower
            return min(Double(maxConcurrentLookups) * 0.7, 5.0) // Cap at 5x
        } else {
            return 1.0
        }
    }
    
    /// Memory usage category based on batch sizes
    var memoryUsageCategory: MemoryUsage {
        let totalBufferSize = batchSize + databaseBatchSize
        if totalBufferSize <= 50 {
            return .low
        } else if totalBufferSize <= 150 {
            return .medium
        } else {
            return .high
        }
    }
    
    enum MemoryUsage: String, CaseIterable {
        case low = "Low"
        case medium = "Medium" 
        case high = "High"
        
        var description: String {
            switch self {
            case .low:
                return "Low memory usage, good for older devices"
            case .medium:
                return "Balanced memory usage, good for most devices"
            case .high:
                return "Higher memory usage, best for newer devices"
            }
        }
    }
    
    // MARK: - Validation
    
    /// Whether this configuration is valid
    var isValid: Bool {
        return maxConcurrentLookups >= 1 &&
               batchSize >= 1 &&
               concurrentBatchSize >= 1 &&
               apiRequestsPerSecond > 0 &&
               rateLimiterBurstSize >= 1 &&
               databaseBatchSize >= 1
    }
    
    /// Validation warnings for this configuration
    var validationWarnings: [String] {
        var warnings: [String] = []
        
        if maxConcurrentLookups > 8 {
            warnings.append("Very high concurrency (\(maxConcurrentLookups)) may overwhelm API")
        }
        
        if apiRequestsPerSecond > 15 {
            warnings.append("High API rate (\(apiRequestsPerSecond)/s) may trigger rate limits")
        }
        
        if batchSize > 200 {
            warnings.append("Large batch size (\(batchSize)) may use significant memory")
        }
        
        if !useRateLimiting && apiRequestsPerSecond > 5 {
            warnings.append("No rate limiting with high request rate may cause API errors")
        }
        
        return warnings
    }
    
    // MARK: - Description
    
    var description: String {
        return """
        Concurrent Import Configuration:
        - Max Concurrency: \(maxConcurrentLookups) requests
        - API Rate: \(apiRequestsPerSecond)/s (\(rateLimiterBurstSize) burst)
        - Batch Size: \(batchSize) books
        - Memory Usage: \(memoryUsageCategory.rawValue)
        - Expected Speed: \(String(format: "%.1f", expectedSpeedupFactor))x faster
        - Est. Throughput: \(estimatedBooksPerMinute) books/min
        - Rate Limiting: \(useRateLimiting ? "Enabled" : "Disabled")
        """
    }
}

// MARK: - Configuration Factory

extension ConcurrentImportConfig {
    
    /// Create configuration based on device capabilities
    static func forDevice() -> ConcurrentImportConfig {
        // In a real app, you might check device memory, CPU cores, etc.
        // For now, we'll use conservative settings
        return .conservative
    }
    
    /// Create configuration optimized for network conditions
    static func forNetworkCondition(_ condition: NetworkCondition) -> ConcurrentImportConfig {
        switch condition {
        case .excellent:
            return .aggressive
        case .good:
            return .conservative
        case .poor:
            return .sequential
        case .offline:
            return .sequential // Will fail anyway, but won't overwhelm when network returns
        }
    }
    
    enum NetworkCondition {
        case excellent  // Fast, stable connection
        case good       // Normal connection
        case poor       // Slow or unstable connection
        case offline    // No connection
    }
}

// MARK: - Global Configuration

extension ConcurrentImportConfig {
    
    /// Thread-safe storage for current configuration
    @MainActor
    private static var _current: ConcurrentImportConfig = .conservative
    
    /// Current global configuration (can be changed for testing/tuning)
    @MainActor
    static var current: ConcurrentImportConfig {
        get {
            return _current
        }
        set {
            _current = newValue
        }
    }
    
    /// Update the current configuration
    @MainActor
    static func setCurrent(_ config: ConcurrentImportConfig) {
        guard config.isValid else {
            print("⚠️ Invalid configuration, keeping current settings")
            return
        }
        
        if !config.validationWarnings.isEmpty {
            print("⚠️ Configuration warnings:")
            for warning in config.validationWarnings {
                print("   - \(warning)")
            }
        }
        
        current = config
        print("✅ Updated concurrent import configuration")
        print(config.description)
    }
}