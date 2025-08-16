import Testing
import Foundation
import KeychainAccess
@testable import books

@Suite("Keychain Service Security Tests")
struct KeychainServiceTests {
    
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
    
    @Test("KeychainService should maintain singleton pattern")
    func testSingletonPattern() async {
        let service1 = await KeychainService.shared
        let service2 = await KeychainService.shared
        
        #expect(service1 === service2, "KeychainService should be a singleton")
    }
    
    // MARK: - Keychain Storage Tests
    
    @Test("Should store API keys securely in keychain")
    func testKeychainStorage() async {
        let service = await KeychainService.shared
        let testKey = "test-api-key-123"
        
        // Store key
        await service.setGoogleBooksAPIKey(testKey)
        
        // Retrieve and verify
        let retrievedKey = service.loadAPIKey()
        #expect(retrievedKey == testKey, "Stored key should match retrieved key")
    }
    
    @Test("Should handle nil values correctly")
    func testNilKeyStorage() async {
        let service = await KeychainService.shared
        
        // Set key first
        await service.setGoogleBooksAPIKey("temporary-key")
        #expect(service.loadAPIKey() != nil, "Key should be stored")
        
        // Clear key by setting nil
        await service.setGoogleBooksAPIKey(nil)
        #expect(service.loadAPIKey() == nil, "Key should be cleared")
    }
    
    @Test("Should handle empty string values")
    func testEmptyStringStorage() async {
        let service = await KeychainService.shared
        
        // Store empty string
        await service.setGoogleBooksAPIKey("")
        let retrievedKey = service.loadAPIKey()
        
        #expect(retrievedKey == "", "Empty string should be stored and retrieved correctly")
    }
    
    // MARK: - First Run Migration Tests
    
    @Test("Should detect first run correctly")
    func testFirstRunDetection() async {
        // Clear all keychain data to simulate first run
        await clearTestKeychain()
        
        let service = await KeychainService.shared
        
        // Since we cleared keychain, it should be considered first run
        // The service automatically calls setupInitialKeys() on init, but no longer sets default keys
        let googleKey = await service.googleBooksAPIKey
        #expect(googleKey == nil, "No default API key should be set for security - user must configure manually")
    }
    
    @Test("Should not re-migrate on subsequent runs")
    func testSubsequentRunBehavior() async {
        let service = await KeychainService.shared
        
        // First setup (this happens automatically in init)
        let initialKey = await service.googleBooksAPIKey
        
        // Manually call setupInitialKeys again
        await service.setupInitialKeys()
        
        // Key should remain the same (no re-migration)
        let subsequentKey = await service.googleBooksAPIKey
        #expect(initialKey == subsequentKey, "Key should not change on subsequent setupInitialKeys calls")
    }
    
    // MARK: - Key Status Tests
    
    @Test("Should report key status accurately")
    func testKeyStatus() async {
        let service = await KeychainService.shared
        await clearTestKeychain()
        
        // Initially no keys
        var status = await service.keyStatus()
        #expect(status["Google Books"] == false, "Google Books key should be reported as missing initially")
        
        // Add Google Books key
        await service.setGoogleBooksAPIKey("test-google-key")
        status = await service.keyStatus()
        #expect(status["Google Books"] == true, "Google Books key should be reported as present")
    }
    
    // MARK: - Clear and Reset Tests
    
    @Test("Should clear all keys correctly")
    func testClearAllKeys() async {
        let service = await KeychainService.shared
        
        // Set up key
        await service.setGoogleBooksAPIKey("google-test-key")
        
        // Verify key is set
        #expect(await service.googleBooksAPIKey != nil, "Google key should be set before clearing")
        
        // Clear all keys
        await service.clearAllKeys()
        
        // Verify key is cleared
        #expect(await service.googleBooksAPIKey == nil, "Google key should be cleared")
        
        // Verify status reflects cleared state
        let status = await service.keyStatus()
        #expect(status["Google Books"] == false, "Google Books status should reflect cleared state")
    }
    
    @Test("Should reset to defaults correctly")
    func testResetToDefaults() async {
        let service = await KeychainService.shared
        
        // Clear everything first
        await service.clearAllKeys()
        #expect(await service.googleBooksAPIKey == nil, "Key should be cleared before reset")
        
        // Reset to defaults
        await service.resetToDefaults()
        
        // Since we no longer set default keys, reset should clear everything
        let googleKey = await service.googleBooksAPIKey
        #expect(googleKey == nil, "Reset should clear all keys - no default API key set for security")
    }
    
    // MARK: - Keychain Access Security Tests
    
    @Test("Should use correct keychain access level")
    func testKeychainAccessLevel() async {
        let service = await KeychainService.shared
        let testKey = "access-level-test-key"
        
        await service.setGoogleBooksAPIKey(testKey)
        
        // Verify key can be retrieved (implying correct access level)
        let retrievedKey = await service.googleBooksAPIKey
        #expect(retrievedKey == testKey, "Key should be retrievable with proper keychain access")
    }
    
    @Test("Should handle direct API access")
    func testDirectAPIAccess() async {
        let service = await KeychainService.shared
        
        // Test both high-level and low-level APIs
        await service.setGoogleBooksAPIKey("direct-test-key")
        
        // Test property access
        #expect(await service.googleBooksAPIKey == "direct-test-key", "Property access should work")
        
        // Test method access
        #expect(service.loadAPIKey() == "direct-test-key", "Method access should work")
    }
    
    // MARK: - Error Handling Tests
    
    @Test("Should handle keychain errors gracefully")
    func testKeychainErrorHandling() async {
        let service = await KeychainService.shared
        
        // Test with various edge cases that might cause keychain errors
        let longKey = String(repeating: "a", count: 10000) // Very long key
        await service.setGoogleBooksAPIKey(longKey)
        
        let retrievedLongKey = await service.googleBooksAPIKey
        #expect(retrievedLongKey == longKey, "Should handle long keys correctly")
        
        // Test with special characters
        let specialKey = "key-with-special-chars-!@#$%^&*()_+-=[]{}|;:,.<>?"
        await service.setGoogleBooksAPIKey(specialKey)
        
        let retrievedSpecialKey = await service.googleBooksAPIKey
        #expect(retrievedSpecialKey == specialKey, "Should handle special characters correctly")
    }
    
    // MARK: - Concurrency Safety Tests
    
    @Test("Should handle concurrent access safely")
    func testConcurrentAccess() async {
        let service = await KeychainService.shared
        
        // Test concurrent writes and reads
        await withTaskGroup(of: Void.self) { group in
            // Multiple concurrent writes
            for i in 0..<10 {
                group.addTask {
                    await service.setGoogleBooksAPIKey("concurrent-key-\(i)")
                }
            }
            
            // Multiple concurrent reads
            for _ in 0..<10 {
                group.addTask {
                    let _ = service.loadAPIKey()
                }
            }
        }
        
        // Should complete without crashing and have some valid key
        let finalKey = await service.googleBooksAPIKey
        #expect(finalKey != nil, "Should have a key after concurrent access")
        #expect(finalKey?.hasPrefix("concurrent-key-") == true, "Should have one of the concurrent keys")
    }
    
    // MARK: - KeychainAccess Library Integration Tests
    
    @Test("Should properly integrate with KeychainAccess library")
    func testKeychainAccessIntegration() async {
        let service = await KeychainService.shared
        let testKey = "keychain-access-test"
        
        // Store via our service
        await service.setGoogleBooksAPIKey(testKey)
        
        // Verify we can retrieve it
        let retrieved = service.loadAPIKey()
        #expect(retrieved == testKey, "KeychainAccess integration should work correctly")
        
        // Test deletion
        do {
            try service.deleteAPIKey()
            let afterDelete = service.loadAPIKey()
            #expect(afterDelete == nil, "Key should be deleted")
        } catch {
            #expect(Bool(false), "Delete operation should not throw: \(error)")
        }
    }
}

// MARK: - Test Helper Extensions

extension KeychainServiceTests {
    
    /// Helper method to clear test keychain data
    private func clearTestKeychain() async {
        let service = await KeychainService.shared
        await service.clearAllKeys()
    }
}

// MARK: - KeychainService Test Extensions

@MainActor
extension KeychainService {
    
    /// Test-only method to set Google Books API key
    func setGoogleBooksAPIKey(_ key: String?) {
        self.googleBooksAPIKey = key
    }
}