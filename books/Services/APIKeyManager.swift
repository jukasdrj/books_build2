import Foundation
import Security

/// Secure API key management using iOS Keychain
/// Follows app's established @MainActor singleton pattern with Swift 6 compliance
@MainActor
final class APIKeyManager: ObservableObject, @unchecked Sendable {
    static let shared = APIKeyManager()
    
    private init() {
        setupInitialKeys()
    }
    
    // MARK: - Keychain Configuration
    
    private enum KeychainKeys {
        static let googleBooksAPI = "GoogleBooksAPIKey"
        static let isbndbAPI = "ISBNDBAPIKey"
        static let appFirstRun = "AppFirstRun_v1"
    }
    
    private enum KeychainAccess {
        static let accessibleWhenUnlocked = kSecAttrAccessibleWhenUnlocked
        static let service = Bundle.main.bundleIdentifier ?? "com.oooefam.booksV3"
    }
    
    // MARK: - API Key Properties
    
    /// Google Books API key (securely stored in Keychain)
    var googleBooksAPIKey: String? {
        get { getKeychainValue(for: KeychainKeys.googleBooksAPI) }
        set { setKeychainValue(newValue, for: KeychainKeys.googleBooksAPI) }
    }
    
    /// ISBNDB API key (for future integration)
    var isbndbAPIKey: String? {
        get { getKeychainValue(for: KeychainKeys.isbndbAPI) }
        set { setKeychainValue(newValue, for: KeychainKeys.isbndbAPI) }
    }
    
    // MARK: - First Run Management
    
    private var isFirstRun: Bool {
        get { getKeychainValue(for: KeychainKeys.appFirstRun) == nil }
        set {
            if newValue {
                deleteKeychainValue(for: KeychainKeys.appFirstRun)
            } else {
                setKeychainValue("completed", for: KeychainKeys.appFirstRun)
            }
        }
    }
    
    // MARK: - Setup Methods
    
    /// Sets up initial API keys on first app launch
    /// Migrates hardcoded keys to secure Keychain storage
    func setupInitialKeys() {
        guard isFirstRun else { return }
        
        // Migrate existing Google Books API key to Keychain
        googleBooksAPIKey = "AIzaSyCj0-1RxPlVwO_XRZRkkQxCgp4lQVCxWaE"
        
        // Mark setup as complete
        isFirstRun = false
        
        #if DEBUG
        print("✅ APIKeyManager: Keys migrated to Keychain securely")
        printKeyStatus()
        #endif
    }
    
    // MARK: - Utility Methods
    
    /// Returns status of all configured API keys
    func keyStatus() -> [String: Bool] {
        return [
            "Google Books": googleBooksAPIKey != nil,
            "ISBNDB": isbndbAPIKey != nil
        ]
    }
    
    /// Clears all stored API keys (for testing/reset)
    func clearAllKeys() {
        deleteKeychainValue(for: KeychainKeys.googleBooksAPI)
        deleteKeychainValue(for: KeychainKeys.isbndbAPI)
        deleteKeychainValue(for: KeychainKeys.appFirstRun)
        
        #if DEBUG
        print("🗑️ APIKeyManager: All keys cleared from Keychain")
        #endif
    }
    
    /// Resets keys to default values
    func resetToDefaults() {
        clearAllKeys()
        setupInitialKeys()
    }
    
    #if DEBUG
    /// Prints current key status for debugging
    func printKeyStatus() {
        print("📊 APIKeyManager Status:")
        for (service, hasKey) in keyStatus() {
            print("  \(service): \(hasKey ? "✅ Configured" : "❌ Missing")")
        }
    }
    #endif
}

// MARK: - Keychain Operations

private extension APIKeyManager {
    
    /// Retrieves a value from the Keychain
    func getKeychainValue(for key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: KeychainAccess.service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess,
              let data = item as? Data,
              let value = String(data: data, encoding: .utf8) else {
            #if DEBUG
            if status != errSecItemNotFound {
                print("⚠️ APIKeyManager: Keychain read error for \(key): \(status)")
            }
            #endif
            return nil
        }
        
        return value
    }
    
    /// Stores a value in the Keychain
    func setKeychainValue(_ value: String?, for key: String) {
        guard let value = value else {
            deleteKeychainValue(for: key)
            return
        }
        
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: KeychainAccess.service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: KeychainAccess.accessibleWhenUnlocked
        ]
        
        // Try to update existing item first
        let updateQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: KeychainAccess.service,
            kSecAttrAccount as String: key
        ]
        
        let updateAttributes: [String: Any] = [
            kSecValueData as String: data
        ]
        
        let updateStatus = SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary)
        
        if updateStatus == errSecItemNotFound {
            // Item doesn't exist, add it
            let addStatus = SecItemAdd(query as CFDictionary, nil)
            
            #if DEBUG
            if addStatus != errSecSuccess {
                print("⚠️ APIKeyManager: Keychain add error for \(key): \(addStatus)")
            }
            #endif
        } else if updateStatus != errSecSuccess {
            #if DEBUG
            print("⚠️ APIKeyManager: Keychain update error for \(key): \(updateStatus)")
            #endif
        }
    }
    
    /// Deletes a value from the Keychain
    func deleteKeychainValue(for key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: KeychainAccess.service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        #if DEBUG
        if status != errSecSuccess && status != errSecItemNotFound {
            print("⚠️ APIKeyManager: Keychain delete error for \(key): \(status)")
        }
        #endif
    }
}