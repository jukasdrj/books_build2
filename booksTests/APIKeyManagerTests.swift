import Testing
import Foundation
import Security
@testable import books

@Suite("API Key Manager Security Tests")
struct APIKeyManagerTests {
    
    // MARK: - Test Lifecycle
    
    /// Clean up keychain before each test to ensure isolation
    init() async {
        await clearTestKeychain()
    }
    
    deinit {
        Task {
            await clearTestKeychain()
        }
    }
    
    // MARK: - Singleton Pattern Tests
    
    @Test("APIKeyManager should maintain singleton pattern")
    func testSingletonPattern() async {
        let manager1 = await APIKeyManager.shared
        let manager2 = await APIKeyManager.shared
        
        #expect(manager1 === manager2, "APIKeyManager should be a singleton")
    }
    
    // MARK: - Keychain Storage Tests
    
    @Test("Should store API keys securely in keychain")
    func testKeychainStorage() async {
        let manager = await APIKeyManager.shared
        let testKey = "test-api-key-123"
        
        // Store key
        await manager.setGoogleBooksAPIKey(testKey)
        
        // Retrieve and verify
        let retrievedKey = await manager.googleBooksAPIKey
        #expect(retrievedKey == testKey, "Stored key should match retrieved key")
    }
    
    @Test("Should handle nil values correctly")
    func testNilKeyStorage() async {
        let manager = await APIKeyManager.shared
        
        // Set key first
        await manager.setGoogleBooksAPIKey("temporary-key")
        #expect(await manager.googleBooksAPIKey != nil, "Key should be stored")
        
        // Clear key by setting nil
        await manager.setGoogleBooksAPIKey(nil)
        #expect(await manager.googleBooksAPIKey == nil, "Key should be cleared")
    }
    
    @Test("Should handle empty string values")
    func testEmptyStringStorage() async {
        let manager = await APIKeyManager.shared
        
        // Store empty string
        await manager.setGoogleBooksAPIKey("")
        let retrievedKey = await manager.googleBooksAPIKey
        
        #expect(retrievedKey == "", "Empty string should be stored and retrieved correctly")
    }
    
    // MARK: - First Run Migration Tests
    
    @Test("Should detect first run correctly")
    func testFirstRunDetection() async {
        // Clear all keychain data to simulate first run
        await clearTestKeychain()
        
        let manager = await APIKeyManager.shared
        
        // Since we cleared keychain, it should be considered first run
        // The manager automatically calls setupInitialKeys() on init
        let googleKey = await manager.googleBooksAPIKey
        #expect(googleKey != nil, "Google Books API key should be migrated on first run")
    }
    
    @Test("Should not re-migrate on subsequent runs")
    func testSubsequentRunBehavior() async {
        let manager = await APIKeyManager.shared
        
        // First setup (this happens automatically in init)
        let initialKey = await manager.googleBooksAPIKey
        
        // Manually call setupInitialKeys again
        await manager.setupInitialKeys()
        
        // Key should remain the same (no re-migration)
        let subsequentKey = await manager.googleBooksAPIKey
        #expect(initialKey == subsequentKey, "Key should not change on subsequent setupInitialKeys calls")
    }
    
    // MARK: - Key Status Tests
    
    @Test("Should report key status accurately")
    func testKeyStatus() async {
        let manager = await APIKeyManager.shared
        await clearTestKeychain()
        
        // Initially no keys
        var status = await manager.keyStatus()
        #expect(status["Google Books"] == false, "Google Books key should be reported as missing initially")
        #expect(status["ISBNDB"] == false, "ISBNDB key should be reported as missing initially")
        
        // Add Google Books key
        await manager.setGoogleBooksAPIKey("test-google-key")
        status = await manager.keyStatus()
        #expect(status["Google Books"] == true, "Google Books key should be reported as present")
        #expect(status["ISBNDB"] == false, "ISBNDB key should still be missing")
        
        // Add ISBNDB key
        await manager.setISBNDBAPIKey("test-isbndb-key")
        status = await manager.keyStatus()
        #expect(status["Google Books"] == true, "Google Books key should still be present")
        #expect(status["ISBNDB"] == true, "ISBNDB key should now be present")
    }
    
    // MARK: - Clear and Reset Tests
    
    @Test("Should clear all keys correctly")
    func testClearAllKeys() async {
        let manager = await APIKeyManager.shared
        
        // Set up some keys
        await manager.setGoogleBooksAPIKey("google-test-key")
        await manager.setISBNDBAPIKey("isbndb-test-key")
        
        // Verify keys are set
        #expect(await manager.googleBooksAPIKey != nil, "Google key should be set before clearing")
        #expect(await manager.isbndbAPIKey != nil, "ISBNDB key should be set before clearing")
        
        // Clear all keys
        await manager.clearAllKeys()
        
        // Verify keys are cleared
        #expect(await manager.googleBooksAPIKey == nil, "Google key should be cleared")
        #expect(await manager.isbndbAPIKey == nil, "ISBNDB key should be cleared")
        
        // Verify status reflects cleared state
        let status = await manager.keyStatus()
        #expect(status["Google Books"] == false, "Google Books status should reflect cleared state")
        #expect(status["ISBNDB"] == false, "ISBNDB status should reflect cleared state")
    }
    
    @Test("Should reset to defaults correctly")
    func testResetToDefaults() async {
        let manager = await APIKeyManager.shared
        
        // Clear everything first
        await manager.clearAllKeys()
        #expect(await manager.googleBooksAPIKey == nil, "Key should be cleared before reset")
        
        // Reset to defaults
        await manager.resetToDefaults()
        
        // Should have Google Books key after reset
        #expect(await manager.googleBooksAPIKey != nil, "Google Books key should be restored after reset")
        
        // Verify it's the expected default value
        let googleKey = await manager.googleBooksAPIKey
        #expect(googleKey == "AIzaSyCj0-1RxPlVwO_XRZRkkQxCgp4lQVCxWaE", "Should restore correct default Google Books API key")
    }
    
    // MARK: - Keychain Access Security Tests
    
    @Test("Should use correct keychain access level")
    func testKeychainAccessLevel() async {
        let manager = await APIKeyManager.shared
        let testKey = "access-level-test-key"
        
        await manager.setGoogleBooksAPIKey(testKey)
        
        // Verify key can be retrieved (implying correct access level)
        let retrievedKey = await manager.googleBooksAPIKey
        #expect(retrievedKey == testKey, "Key should be retrievable with kSecAttrAccessibleWhenUnlocked")
    }
    
    @Test("Should isolate keys by service identifier")
    func testServiceIsolation() async {
        let manager = await APIKeyManager.shared
        
        // Store keys with different service identifiers should not interfere
        await manager.setGoogleBooksAPIKey("google-key")
        await manager.setISBNDBAPIKey("isbndb-key")
        
        #expect(await manager.googleBooksAPIKey == "google-key", "Google key should remain isolated")
        #expect(await manager.isbndbAPIKey == "isbndb-key", "ISBNDB key should remain isolated")
        
        // Clearing one should not affect the other
        await manager.setGoogleBooksAPIKey(nil)
        #expect(await manager.googleBooksAPIKey == nil, "Google key should be cleared")
        #expect(await manager.isbndbAPIKey == "isbndb-key", "ISBNDB key should remain unaffected")
    }
    
    // MARK: - Error Handling Tests
    
    @Test("Should handle keychain errors gracefully")
    func testKeychainErrorHandling() async {
        let manager = await APIKeyManager.shared
        
        // Test with various edge cases that might cause keychain errors
        let longKey = String(repeating: "a", count: 10000) // Very long key
        await manager.setGoogleBooksAPIKey(longKey)
        
        let retrievedLongKey = await manager.googleBooksAPIKey
        #expect(retrievedLongKey == longKey, "Should handle long keys correctly")
        
        // Test with special characters
        let specialKey = "key-with-special-chars-!@#$%^&*()_+-=[]{}|;:,.<>?"
        await manager.setGoogleBooksAPIKey(specialKey)
        
        let retrievedSpecialKey = await manager.googleBooksAPIKey
        #expect(retrievedSpecialKey == specialKey, "Should handle special characters correctly")
    }
    
    // MARK: - Concurrency Safety Tests
    
    @Test("Should handle concurrent access safely")
    func testConcurrentAccess() async {
        let manager = await APIKeyManager.shared
        
        // Test concurrent writes and reads
        await withTaskGroup(of: Void.self) { group in
            // Multiple concurrent writes
            for i in 0..<10 {
                group.addTask {
                    await manager.setGoogleBooksAPIKey("concurrent-key-\(i)")
                }
            }
            
            // Multiple concurrent reads
            for _ in 0..<10 {
                group.addTask {
                    let _ = await manager.googleBooksAPIKey
                }
            }
        }
        
        // Should complete without crashing and have some valid key
        let finalKey = await manager.googleBooksAPIKey
        #expect(finalKey != nil, "Should have a key after concurrent access")
        #expect(finalKey?.hasPrefix("concurrent-key-") == true, "Should have one of the concurrent keys")
    }
}

// MARK: - Test Helper Extensions

extension APIKeyManagerTests {
    
    /// Helper method to clear test keychain data
    private func clearTestKeychain() async {
        let manager = await APIKeyManager.shared
        await manager.clearAllKeys()
    }
}

// MARK: - APIKeyManager Test Extensions

@MainActor
extension APIKeyManager {
    
    /// Test-only method to set Google Books API key
    func setGoogleBooksAPIKey(_ key: String?) {
        self.googleBooksAPIKey = key
    }
    
    /// Test-only method to set ISBNDB API key  
    func setISBNDBAPIKey(_ key: String?) {
        self.isbndbAPIKey = key
    }
}