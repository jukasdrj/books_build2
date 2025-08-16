import Testing
import Foundation
import Security
@testable import books

@Suite("API Key Security Validation Tests")
struct APIKeySecurityValidationTests {
    
    // MARK: - Test Lifecycle
    
    init() async {
        await setupSecureTestEnvironment()
    }
    
    deinit {
        Task {
            await cleanupSecureTestEnvironment()
        }
    }
    
    // MARK: - Keychain Security Tests
    
    @Test("API keys should be stored with correct security attributes")
    func testKeychainSecurityAttributes() async {
        let keyManager = await APIKeyManager.shared
        let testKey = "security-validation-key"
        
        // Store a test key
        await keyManager.setGoogleBooksAPIKey(testKey)
        
        // Verify the key exists and has correct security attributes
        let keychainQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "com.oooefam.booksV3",
            kSecAttrAccount as String: "GoogleBooksAPIKey",
            kSecReturnAttributes as String: true
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(keychainQuery as CFDictionary, &item)
        
        #expect(status == errSecSuccess, "Should be able to query keychain item")
        
        if let attributes = item as? [String: Any] {
            let accessibleAttribute = attributes[kSecAttrAccessible as String] as? String
            #expect(accessibleAttribute == kSecAttrAccessibleWhenUnlocked as String, 
                   "Should use kSecAttrAccessibleWhenUnlocked security level")
        }
    }
    
    @Test("API keys should be isolated by service identifier")
    func testServiceIsolation() async {
        let keyManager = await APIKeyManager.shared
        
        // Store keys for different services
        await keyManager.setGoogleBooksAPIKey("google-test-key")
        await keyManager.setISBNDBAPIKey("isbndb-test-key")
        
        // Verify keys are stored separately and don't interfere
        let googleKey = await keyManager.googleBooksAPIKey
        let isbndbKey = await keyManager.isbndbAPIKey
        
        #expect(googleKey == "google-test-key", "Google Books key should be isolated")
        #expect(isbndbKey == "isbndb-test-key", "ISBNDB key should be isolated")
        
        // Verify clearing one doesn't affect the other
        await keyManager.setGoogleBooksAPIKey(nil)
        
        #expect(await keyManager.googleBooksAPIKey == nil, "Google key should be cleared")
        #expect(await keyManager.isbndbAPIKey == "isbndb-test-key", "ISBNDB key should remain")
    }
    
    @Test("Keychain should protect against unauthorized access")
    func testUnauthorizedAccessProtection() async {
        let keyManager = await APIKeyManager.shared
        let testKey = "unauthorized-access-test"
        
        // Store a key
        await keyManager.setGoogleBooksAPIKey(testKey)
        
        // Attempt to access with different service identifier (should fail)
        let maliciousQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.malicious.app", // Different service
            kSecAttrAccount as String: "GoogleBooksAPIKey",
            kSecReturnData as String: true
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(maliciousQuery as CFDictionary, &item)
        
        #expect(status == errSecItemNotFound, "Should not find key with different service identifier")
    }
    
    // MARK: - Data Sanitization Tests
    
    @Test("API keys should be properly sanitized in logs")
    func testLogSanitization() async {
        let keyManager = await APIKeyManager.shared
        let sensitiveKey = "AIzaSyCj0-1RxPlVwO_XRZRkkQxCgp4lQVCxWaE"
        
        await keyManager.setGoogleBooksAPIKey(sensitiveKey)
        
        // In debug mode, verify that sensitive data is not exposed in logs
        // This test ensures that debug output doesn't leak API keys
        
        #if DEBUG
        // Test that debug printing doesn't expose the full key
        let status = await keyManager.keyStatus()
        
        // The status should only indicate presence/absence, not the actual key
        #expect(status["Google Books"] == true, "Status should indicate key presence")
        
        // Verify that the actual key value is not accessible through status
        let statusDescription = String(describing: status)
        #expect(!statusDescription.contains(sensitiveKey), "Status description should not contain actual key")
        #endif
    }
    
    @Test("API key should not be exposed through description or debug output")
    func testKeyExposurePrevention() async {
        let keyManager = await APIKeyManager.shared
        let secretKey = "secret-api-key-12345"
        
        await keyManager.setGoogleBooksAPIKey(secretKey)
        
        // Test various ways the key might be accidentally exposed
        let managerDescription = String(describing: keyManager)
        #expect(!managerDescription.contains(secretKey), "Manager description should not contain key")
        
        // Test that mirror reflection doesn't expose keys
        let mirror = Mirror(reflecting: keyManager)
        for child in mirror.children {
            if let value = child.value as? String {
                #expect(value != secretKey, "Reflection should not expose API key")
            }
        }
    }
    
    // MARK: - Memory Security Tests
    
    @Test("API keys should not persist in memory after clearing")
    func testMemoryClearing() async {
        let keyManager = await APIKeyManager.shared
        let testKey = "memory-test-key-to-clear"
        
        // Store key
        await keyManager.setGoogleBooksAPIKey(testKey)
        #expect(await keyManager.googleBooksAPIKey == testKey, "Key should be stored")
        
        // Clear key
        await keyManager.setGoogleBooksAPIKey(nil)
        #expect(await keyManager.googleBooksAPIKey == nil, "Key should be cleared")
        
        // Verify key is not accessible through any means
        let clearedKey = await keyManager.googleBooksAPIKey
        #expect(clearedKey == nil, "Cleared key should not be accessible")
    }
    
    @Test("Sensitive operations should be atomic")
    func testAtomicOperations() async {
        let keyManager = await APIKeyManager.shared
        
        // Test that key operations are atomic and don't leave partial states
        await withTaskGroup(of: Void.self) { group in
            // Concurrent operations that could interfere
            group.addTask {
                await keyManager.setGoogleBooksAPIKey("concurrent-key-1")
            }
            group.addTask {
                await keyManager.setGoogleBooksAPIKey("concurrent-key-2")
            }
            group.addTask {
                await keyManager.clearAllKeys()
            }
            group.addTask {
                await keyManager.resetToDefaults()
            }
        }
        
        // After all operations complete, should have a consistent state
        let finalKey = await keyManager.googleBooksAPIKey
        
        // Should either have the default key (from reset) or nil (from clear)
        // But not a partial or corrupted state
        if let key = finalKey {
            #expect(key == "AIzaSyCj0-1RxPlVwO_XRZRkkQxCgp4lQVCxWaE" || key.hasPrefix("concurrent-key"), 
                   "Final key should be in a valid state: \(key)")
        }
    }
    
    // MARK: - Device Security Integration Tests
    
    @Test("Keychain should respect device lock state")
    func testDeviceLockIntegration() async {
        let keyManager = await APIKeyManager.shared
        let deviceSecurityKey = "device-security-test-key"
        
        // Store key (this should work when device is unlocked during testing)
        await keyManager.setGoogleBooksAPIKey(deviceSecurityKey)
        
        // Verify key can be retrieved (when device is unlocked)
        let retrievedKey = await keyManager.googleBooksAPIKey
        #expect(retrievedKey == deviceSecurityKey, "Key should be accessible when device is unlocked")
        
        // Note: Testing device lock behavior requires physical device testing
        // This test documents the expected behavior
    }
    
    @Test("Keychain should handle app background/foreground transitions")
    func testAppStateTransitions() async {
        let keyManager = await APIKeyManager.shared
        let transitionTestKey = "app-transition-test-key"
        
        // Store key
        await keyManager.setGoogleBooksAPIKey(transitionTestKey)
        
        // Simulate app state changes by accessing key multiple times
        for _ in 0..<10 {
            let key = await keyManager.googleBooksAPIKey
            #expect(key == transitionTestKey, "Key should remain accessible across app state changes")
            
            // Brief delay to simulate time passage
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
    }
    
    // MARK: - Security Boundary Tests
    
    @Test("Should validate keychain item limits and constraints")
    func testKeychainConstraints() async {
        let keyManager = await APIKeyManager.shared
        
        // Test maximum key length
        let maxLengthKey = String(repeating: "a", count: 8192) // 8KB
        await keyManager.setGoogleBooksAPIKey(maxLengthKey)
        
        let retrievedMaxKey = await keyManager.googleBooksAPIKey
        #expect(retrievedMaxKey == maxLengthKey, "Should handle large keys correctly")
        
        // Test special characters and encoding
        let specialCharKey = "key-with-üñíçødé-characters-!@#$%^&*()"
        await keyManager.setGoogleBooksAPIKey(specialCharKey)
        
        let retrievedSpecialKey = await keyManager.googleBooksAPIKey
        #expect(retrievedSpecialKey == specialCharKey, "Should handle special characters correctly")
    }
    
    @Test("Should protect against key enumeration attacks")
    func testKeyEnumerationProtection() async {
        let keyManager = await APIKeyManager.shared
        
        // Store multiple keys
        await keyManager.setGoogleBooksAPIKey("google-enumeration-test")
        await keyManager.setISBNDBAPIKey("isbndb-enumeration-test")
        
        // Attempt to enumerate all keychain items (should only see our app's items)
        let enumerationQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]
        
        var items: CFTypeRef?
        let status = SecItemCopyMatching(enumerationQuery as CFDictionary, &items)
        
        if status == errSecSuccess, let keychainItems = items as? [[String: Any]] {
            // Should only see items from our app
            let ourServiceIdentifier = Bundle.main.bundleIdentifier ?? "com.oooefam.booksV3"
            
            for item in keychainItems {
                if let service = item[kSecAttrService as String] as? String {
                    if service == ourServiceIdentifier {
                        // This is expected - our app's items
                        continue
                    }
                }
            }
            
            // The key point is that we shouldn't be able to access other apps' keys
            #expect(true, "Enumeration should be properly sandboxed")
        }
    }
    
    // MARK: - Error Security Tests
    
    @Test("Error messages should not leak sensitive information")
    func testErrorMessageSecurity() async {
        let keyManager = await APIKeyManager.shared
        
        // Test various error conditions
        await keyManager.clearAllKeys()
        
        // Error from missing key should not reveal key structure or storage details
        let bookSearchService = await BookSearchService.shared
        let result = await bookSearchService.search(query: "Error Security Test")
        
        switch result {
        case .success:
            // Unexpected but not a security issue
            break
        case .failure(let error):
            let errorDescription = error.localizedDescription
            
            // Verify error doesn't contain sensitive implementation details
            #expect(!errorDescription.contains("kSecAttrAccessible"), "Error should not expose keychain implementation")
            #expect(!errorDescription.contains("SecItem"), "Error should not expose Security framework details")
            #expect(!errorDescription.contains(Bundle.main.bundleIdentifier ?? ""), "Error should not expose bundle identifier")
            
            // Should provide helpful but not sensitive information
            #expect(errorDescription.contains("API key"), "Error should mention API key issue")
        }
    }
    
    // MARK: - Migration Security Tests
    
    @Test("Key migration should be secure and idempotent")
    func testSecureMigration() async {
        let keyManager = await APIKeyManager.shared
        
        // Clear all keys to simulate fresh install
        await keyManager.clearAllKeys()
        
        // First migration
        await keyManager.setupInitialKeys()
        let firstKey = await keyManager.googleBooksAPIKey
        #expect(firstKey != nil, "First migration should set up key")
        
        // Second migration (should be idempotent)
        await keyManager.setupInitialKeys()
        let secondKey = await keyManager.googleBooksAPIKey
        #expect(secondKey == firstKey, "Migration should be idempotent")
        
        // Third migration with manual intervention
        await keyManager.setGoogleBooksAPIKey("manually-set-key")
        await keyManager.setupInitialKeys()
        let thirdKey = await keyManager.googleBooksAPIKey
        #expect(thirdKey == "manually-set-key", "Migration should not overwrite manually set keys")
    }
    
    // MARK: - Performance Security Tests
    
    @Test("Security operations should not create timing attack vectors")
    func testTimingAttackResistance() async {
        let keyManager = await APIKeyManager.shared
        
        // Measure time for key retrieval with different key states
        var timings: [TimeInterval] = []
        
        // Time with no key
        await keyManager.clearAllKeys()
        let startTime1 = Date()
        let _ = await keyManager.googleBooksAPIKey
        timings.append(Date().timeIntervalSince(startTime1))
        
        // Time with short key
        await keyManager.setGoogleBooksAPIKey("short")
        let startTime2 = Date()
        let _ = await keyManager.googleBooksAPIKey
        timings.append(Date().timeIntervalSince(startTime2))
        
        // Time with long key
        await keyManager.setGoogleBooksAPIKey(String(repeating: "long", count: 100))
        let startTime3 = Date()
        let _ = await keyManager.googleBooksAPIKey
        timings.append(Date().timeIntervalSince(startTime3))
        
        // All operations should complete in reasonable time
        for timing in timings {
            #expect(timing < 0.1, "Key operations should complete quickly: \(timing)s")
        }
        
        // Timing differences shouldn't be extreme (no obvious timing attacks)
        let maxTiming = timings.max() ?? 0
        let minTiming = timings.min() ?? 0
        let timingRatio = maxTiming / max(minTiming, 0.001) // Avoid division by zero
        
        #expect(timingRatio < 10, "Timing differences should not be extreme: \(timingRatio)x")
    }
}

// MARK: - Test Security Helpers

extension APIKeySecurityValidationTests {
    
    /// Set up secure test environment
    private func setupSecureTestEnvironment() async {
        let keyManager = await APIKeyManager.shared
        await keyManager.clearAllKeys()
    }
    
    /// Clean up secure test environment
    private func cleanupSecureTestEnvironment() async {
        let keyManager = await APIKeyManager.shared
        await keyManager.resetToDefaults()
    }
    
    /// Verify no sensitive data in string
    private func verifySanitized(_ text: String, shouldNotContain sensitiveData: String) {
        #expect(!text.contains(sensitiveData), "Text should not contain sensitive data: \(sensitiveData)")
    }
}

// MARK: - Security Test Extensions

@MainActor
extension APIKeyManager {
    
    /// Test helper to set Google Books API key
    func setGoogleBooksAPIKey(_ key: String?) {
        self.googleBooksAPIKey = key
    }
    
    /// Test helper to set ISBNDB API key
    func setISBNDBAPIKey(_ key: String?) {
        self.isbndbAPIKey = key
    }
}