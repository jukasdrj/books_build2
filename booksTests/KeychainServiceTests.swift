import Testing
import Foundation
@testable import books

@Suite("KeychainService UserDefaults Storage Tests")
struct KeychainServiceTests {
    
    // MARK: - Test Lifecycle
    
    /// Clean up UserDefaults before each test to ensure isolation
    init() {
        clearTestUserDefaults()
    }
    
    // MARK: - Singleton Pattern Tests
    
    @Test("KeychainService should maintain singleton pattern")
    func testSingletonPattern() {
        let service1 = KeychainService.shared
        let service2 = KeychainService.shared
        
        #expect(service1 === service2, "KeychainService should be a singleton")
    }
    
    // MARK: - UserDefaults Storage Tests
    
    @Test("Should store API keys securely in UserDefaults")
    func testUserDefaultsStorage() {
        let service = KeychainService.shared
        let testKey = "test-api-key-123"
        
        // Store key
        service.googleBooksAPIKey = testKey
        
        // Retrieve and verify
        let retrievedKey = service.loadAPIKey()
        #expect(retrievedKey == testKey, "Stored key should match retrieved key")
    }
    
    @Test("Should handle nil values correctly")
    func testNilKeyStorage() {
        let service = KeychainService.shared
        
        // Set key first
        service.googleBooksAPIKey = "temporary-key"
        #expect(service.loadAPIKey() != nil, "Key should be stored")
        
        // Clear key by setting nil
        service.googleBooksAPIKey = nil
        #expect(service.loadAPIKey() == nil, "Key should be cleared")
    }
    
    @Test("Should handle empty string values")
    func testEmptyStringStorage() {
        let service = KeychainService.shared
        
        // Store empty string
        service.googleBooksAPIKey = ""
        let retrievedKey = service.loadAPIKey()
        
        #expect(retrievedKey == "", "Empty string should be stored and retrieved correctly")
    }
    
    // MARK: - First Run Migration Tests
    
    @Test("Should detect first run correctly")
    func testFirstRunDetection() {
        // Clear all keychain data to simulate first run
        clearTestUserDefaults()
        
        let service = KeychainService.shared
        
        // Since we cleared keychain, it should be considered first run
        let googleKey = service.googleBooksAPIKey
        #expect(googleKey == nil, "No default API key should be set for security - user must configure manually")
    }
    
    // MARK: - Key Status Tests
    
    @Test("Should report key status accurately")
    func testKeyStatus() {
        let service = KeychainService.shared
        clearTestUserDefaults()
        
        // Initially no keys
        var status = service.keyStatus()
        #expect(status["Google Books API"] == false, "Google Books key should be reported as missing initially")
        
        // Add Google Books key
        service.googleBooksAPIKey = "test-google-key"
        status = service.keyStatus()
        #expect(status["Google Books API"] == true, "Google Books key should be reported as present")
    }
    
    // MARK: - Clear and Reset Tests
    
    @Test("Should clear all keys correctly")
    func testClearAllKeys() {
        let service = KeychainService.shared
        
        // Set up key
        service.googleBooksAPIKey = "google-test-key"
        
        // Verify key is set
        #expect(service.googleBooksAPIKey != nil, "Google key should be set before clearing")
        
        // Clear all keys
        service.clearAllKeys()
        
        // Verify key is cleared
        #expect(service.googleBooksAPIKey == nil, "Google key should be cleared")
        
        // Verify status reflects cleared state
        let status = service.keyStatus()
        #expect(status["Google Books API"] == false, "Google Books status should reflect cleared state")
    }
    
    @Test("Should reset to defaults correctly")
    func testResetToDefaults() {
        let service = KeychainService.shared
        
        // Clear everything first
        service.clearAllKeys()
        #expect(service.googleBooksAPIKey == nil, "Key should be cleared before reset")
        
        // Reset to defaults
        service.resetToDefaults()
        
        // Since we no longer set default keys, reset should clear everything
        let googleKey = service.googleBooksAPIKey
        #expect(googleKey == nil, "Reset should clear all keys - no default API key set for security")
    }
    
    // MARK: - Error Handling Tests
    
    @Test("Should handle keychain errors gracefully")
    func testKeychainErrorHandling() {
        let service = KeychainService.shared
        
        // Test with various edge cases that might cause keychain errors
        let longKey = String(repeating: "a", count: 1000) // Long key
        service.googleBooksAPIKey = longKey
        
        let retrievedLongKey = service.googleBooksAPIKey
        #expect(retrievedLongKey == longKey, "Should handle long keys correctly")
        
        // Test with special characters
        let specialKey = "key-with-special-chars-!@#$%^&*()_+-=[]{}|;:,.<>?"
        service.googleBooksAPIKey = specialKey
        
        let retrievedSpecialKey = service.googleBooksAPIKey
        #expect(retrievedSpecialKey == specialKey, "Should handle special characters correctly")
    }
    
    // MARK: - Direct API Access Tests
    
    @Test("Should handle direct API access")
    func testDirectAPIAccess() {
        let service = KeychainService.shared
        
        // Test both high-level and low-level APIs
        service.googleBooksAPIKey = "direct-test-key"
        
        // Test property access
        #expect(service.googleBooksAPIKey == "direct-test-key", "Property access should work")
        
        // Test method access
        #expect(service.loadAPIKey() == "direct-test-key", "Method access should work")
    }
    
    @Test("Should handle deletion correctly")
    func testDeletion() {
        let service = KeychainService.shared
        let testKey = "deletion-test"
        
        // Store via our service
        service.googleBooksAPIKey = testKey
        
        // Verify we can retrieve it
        let retrieved = service.loadAPIKey()
        #expect(retrieved == testKey, "Key should be stored correctly")
        
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
    
    /// Helper method to clear test UserDefaults data
    private func clearTestUserDefaults() {
        let service = KeychainService.shared
        service.clearAllKeys()
    }
}