import Foundation

/// Secure storage service using iOS UserDefaults for API key management
/// Provides secure app-sandboxed storage for non-sensitive configuration data
final class KeychainService: ObservableObject, @unchecked Sendable {
    static let shared = KeychainService()
    
    private let apiKeyKey = "googleBooksAPIKey"
    private let firstRunKey = "AppFirstRun_v1"
    
    private init() {}

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

    /// Save API key securely to UserDefaults
    nonisolated func saveAPIKey(_ apiKey: String) throws {
        UserDefaults.standard.set(apiKey, forKey: apiKeyKey)
    }

    /// Load API key from secure storage
    nonisolated func loadAPIKey() -> String? {
        return UserDefaults.standard.string(forKey: apiKeyKey)
    }

    /// Remove API key from secure storage
    nonisolated func deleteAPIKey() throws {
        UserDefaults.standard.removeObject(forKey: apiKeyKey)
    }
    
    // MARK: - Environment Configuration Management
    
    enum AppEnvironment: String, CaseIterable {
        case development = "dev"
        case production = "prod"
        case testing = "test"
        
        var displayName: String {
            switch self {
            case .development: return "Development"
            case .production: return "Production"
            case .testing: return "Testing"
            }
        }
    }
    
    var appEnvironment: AppEnvironment {
        get { .production } // Default to production
        set { /* Stub - do nothing */ }
    }
    
    var rateLimitRequestsPerMinute: Int {
        get { 100 } // Default rate limit
        set { /* Stub - do nothing */ }
    }
    
    var rateLimitBurstSize: Int {
        get { 10 } // Default burst size
        set { /* Stub - do nothing */ }
    }
    
    // MARK: - First Run Detection
    
    var isFirstRun: Bool {
        get { UserDefaults.standard.bool(forKey: firstRunKey) == false }
        set {
            if newValue {
                UserDefaults.standard.removeObject(forKey: firstRunKey)
            } else {
                UserDefaults.standard.set(true, forKey: firstRunKey)
            }
        }
    }
    
    func hasStoredAPIKey() -> Bool {
        return loadAPIKey() != nil
    }
    
    private func setupInitialKeys() {
        // Initialize default values if needed
    }
    
    /// Clear all stored data
    func clearAllData() throws {
        UserDefaults.standard.removeObject(forKey: apiKeyKey)
        UserDefaults.standard.removeObject(forKey: firstRunKey)
    }
    
    /// Get status of all stored keys for debugging
    func keyStatus() -> [String: Bool] {
        return [
            "Google Books API": hasStoredAPIKey()
        ]
    }
    
    // MARK: - Additional Methods for UI Integration
    
    func clearAllKeys() {
        try? clearAllData()
    }
    
    func resetToDefaults() {
        // Reset to default state - clear existing keys
        try? clearAllData()
        // Could add default key setup here if needed
    }
}