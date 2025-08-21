import Foundation
import KeychainAccess

final class KeychainService: ObservableObject, @unchecked Sendable {
    static let shared = KeychainService()
    private let keychain = Keychain(service: "com.oooefam.booksV3.keychain")

    private let apiKeyKey = "googleBooksAPIKey"
    private let firstRunKey = "AppFirstRun_v1"
    
    // Enhanced configuration keys for different environments
    private let configEnvironmentKey = "appEnvironment"
    private let rateLimit_requestsPerMinute = "rateLimitRequests"
    private let rateLimit_burstSize = "rateLimitBurst"
    
    private init() {
        setupInitialKeys()
    }

    // MARK: - API Key Management
    
    var googleBooksAPIKey: String? {
        get { loadAPIKey() }
        set { 
            if let key = newValue {
                try? saveAPIKey(key)
            } else {
                try? deleteAPIKey()
            }
        }
    }

    nonisolated func saveAPIKey(_ apiKey: String) throws {
        try keychain.set(apiKey, key: apiKeyKey)
    }

    nonisolated func loadAPIKey() -> String? {
        return try? keychain.get(apiKeyKey)
    }

    nonisolated func deleteAPIKey() throws {
        try keychain.remove(apiKeyKey)
    }
    
    // MARK: - Environment Configuration Management
    
    enum AppEnvironment: String, CaseIterable {
        case development = "dev"
        case staging = "staging"
        case production = "prod"
        
        var displayName: String {
            switch self {
            case .development: return "Development"
            case .staging: return "Staging"
            case .production: return "Production"
            }
        }
    }
    
    var currentEnvironment: AppEnvironment {
        get {
            guard let envString = try? keychain.get(configEnvironmentKey),
                  let env = AppEnvironment(rawValue: envString) else {
                return .production // Default to production for security
            }
            return env
        }
        set {
            try? keychain.set(newValue.rawValue, key: configEnvironmentKey)
        }
    }
    
    // MARK: - Rate Limiting Configuration
    
    var rateLimitRequestsPerMinute: Int {
        get {
            guard let valueString = try? keychain.get(rateLimit_requestsPerMinute),
                  let value = Int(valueString) else {
                return 30 // Default: 30 requests per minute (conservative)
            }
            return value
        }
        set {
            try? keychain.set(String(newValue), key: rateLimit_requestsPerMinute)
        }
    }
    
    var rateLimitBurstSize: Int {
        get {
            guard let valueString = try? keychain.get(rateLimit_burstSize),
                  let value = Int(valueString) else {
                return 5 // Default: 5 burst requests
            }
            return value
        }
        set {
            try? keychain.set(String(newValue), key: rateLimit_burstSize)
        }
    }
    
    // MARK: - Device-Adaptive Configuration
    
    /// Get optimal concurrent request limit based on device capabilities
    var deviceAdaptiveConcurrentLimit: Int {
        let physicalMemory = ProcessInfo.processInfo.physicalMemory / (1024 * 1024) // MB
        let processorCount = ProcessInfo.processInfo.processorCount
        
        // Adaptive limits based on device performance
        if physicalMemory >= 6144 && processorCount >= 6 { // High-end devices (Pro models)
            return 8
        } else if physicalMemory >= 4096 && processorCount >= 4 { // Mid-range devices
            return 6
        } else if physicalMemory >= 3072 { // Standard devices
            return 4
        } else { // Lower-end devices
            return 2
        }
    }
    
    /// Get optimal rate limit based on environment and device
    var adaptiveRateLimit: (requestsPerMinute: Int, burstSize: Int) {
        let baseRate = rateLimitRequestsPerMinute
        let baseBurst = rateLimitBurstSize
        
        switch currentEnvironment {
        case .development:
            return (requestsPerMinute: baseRate * 2, burstSize: baseBurst * 2) // More lenient for dev
        case .staging:
            return (requestsPerMinute: Int(Double(baseRate) * 1.5), burstSize: Int(Double(baseBurst) * 1.5))
        case .production:
            return (requestsPerMinute: baseRate, burstSize: baseBurst) // Conservative for production
        }
    }
    
    // MARK: - Setup Methods
    
    /// Sets up initial API keys on first app launch
    /// User must manually configure API key through debug interface
    func setupInitialKeys() {
        guard isFirstRun else { return }
        
        // No default API key - user must configure manually through debug interface
        // This ensures no hardcoded keys in the codebase
        
        // Mark setup as complete
        isFirstRun = false
        
        #if DEBUG
        print("⚠️ KeychainService: First run detected - API key must be configured manually")
        printKeyStatus()
        #endif
    }
    
    // MARK: - Utility Methods
    
    /// Returns status of configured API keys
    func keyStatus() -> [String: Bool] {
        return [
            "Google Books": googleBooksAPIKey != nil
        ]
    }
    
    /// Clears all stored API keys (for testing/reset)
    func clearAllKeys() {
        try? deleteAPIKey()
        try? keychain.remove(firstRunKey)
        
        #if DEBUG
        print("🗑️ KeychainService: All keys cleared from Keychain")
        #endif
    }
    
    /// Resets keys to default values
    func resetToDefaults() {
        clearAllKeys()
        setupInitialKeys()
    }
    
    // MARK: - First Run Management
    
    private var isFirstRun: Bool {
        get { (try? keychain.get(firstRunKey)) == nil }
        set {
            if newValue {
                try? keychain.remove(firstRunKey)
            } else {
                try? keychain.set("completed", key: firstRunKey)
            }
        }
    }

    #if DEBUG
    func loadAPIKeyForDebug() -> String {
        if let key = try? keychain.get(apiKeyKey) {
            return "Keychain Key: \(key)"
        } else {
            return "Keychain Key: Not Found"
        }
    }
    
    /// Prints current key status for debugging
    func printKeyStatus() {
        print("📊 KeychainService Status:")
        for (service, hasKey) in keyStatus() {
            print("  \(service): \(hasKey ? "✅ Configured" : "❌ Missing")")
        }
    }
    #endif
}
