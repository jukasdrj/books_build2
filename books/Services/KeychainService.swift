import Foundation
import KeychainAccess

final class KeychainService: ObservableObject, @unchecked Sendable {
    static let shared = KeychainService()
    private let keychain = Keychain(service: "com.oooefam.booksV3.keychain")

    private let apiKeyKey = "googleBooksAPIKey"
    private let firstRunKey = "AppFirstRun_v1"
    
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
