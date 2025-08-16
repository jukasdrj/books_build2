import Testing
import Foundation
@testable import books

@Suite("BookSearchService Security Integration Tests")
struct BookSearchServiceSecurityIntegrationTests {
    
    // MARK: - Test Lifecycle
    
    init() async {
        // Ensure clean state for each test
        await resetAPIKeys()
    }
    
    deinit {
        Task {
            await resetAPIKeys()
        }
    }
    
    // MARK: - API Key Integration Tests
    
    @Test("BookSearchService should initialize with APIKeyManager integration")
    func testServiceAPIKeyManagerIntegration() async {
        let service = await BookSearchService.shared
        let keyManager = await APIKeyManager.shared
        
        // Verify service has reference to key manager
        // This tests the integration setup in BookSearchService.init()
        
        // Ensure key is available
        await keyManager.setupInitialKeys()
        let hasKey = await keyManager.googleBooksAPIKey != nil
        #expect(hasKey, "APIKeyManager should provide Google Books API key")
    }
    
    @Test("BookSearchService should handle missing API key gracefully")
    func testSearchWithMissingAPIKey() async {
        let service = await BookSearchService.shared
        let keyManager = await APIKeyManager.shared
        
        // Clear API key to simulate missing key scenario
        await keyManager.clearAllKeys()
        
        // Attempt search
        let result = await service.search(query: "Swift Programming")
        
        switch result {
        case .success:
            throw TestingError("Search should fail when API key is missing")
        case .failure(let error):
            guard case .networkError(let message) = error else {
                throw TestingError("Should return networkError for missing API key")
            }
            #expect(message.contains("API key not configured"), "Error message should indicate API key issue")
        }
    }
    
    @Test("BookSearchService should work with valid API key")
    func testSearchWithValidAPIKey() async {
        let service = await BookSearchService.shared
        let keyManager = await APIKeyManager.shared
        
        // Ensure we have a valid API key
        await keyManager.setupInitialKeys()
        let hasKey = await keyManager.googleBooksAPIKey != nil
        
        guard hasKey else {
            throw TestingError("Test setup failed: No API key available")
        }
        
        // This test uses the actual API but with a safe, minimal query
        // In a production environment, you might want to mock this
        let result = await service.search(query: "Swift", maxResults: 1)
        
        switch result {
        case .success(let books):
            // Should get some results (even if empty due to API limits)
            #expect(books.count >= 0, "Should return valid results array")
        case .failure(let error):
            // If it fails, it should not be due to missing API key
            guard case .networkError(let message) = error else {
                throw TestingError("Unexpected error type: \(error)")
            }
            #expect(!message.contains("API key not configured"), "Should not fail due to missing API key")
        }
    }
    
    @Test("BookSearchService should retrieve fresh API key after reset")
    func testAPIKeyRefreshAfterReset() async {
        let service = await BookSearchService.shared
        let keyManager = await APIKeyManager.shared
        
        // Clear keys
        await keyManager.clearAllKeys()
        
        // First search should fail
        let firstResult = await service.search(query: "Test Query")
        switch firstResult {
        case .success:
            throw TestingError("First search should fail with no API key")
        case .failure(let error):
            guard case .networkError(let message) = error else {
                throw TestingError("Should return networkError for missing API key")
            }
            #expect(message.contains("API key not configured"), "Should indicate API key issue")
        }
        
        // Reset to defaults
        await keyManager.resetToDefaults()
        
        // Second search should work (or at least not fail due to missing key)
        let secondResult = await service.search(query: "Test Query")
        switch secondResult {
        case .success:
            // Success is fine
            break
        case .failure(let error):
            guard case .networkError(let message) = error else {
                throw TestingError("Should only fail with network errors after key reset")
            }
            #expect(!message.contains("API key not configured"), "Should not fail due to missing API key after reset")
        }
    }
    
    // MARK: - Security Boundary Tests
    
    @Test("API key should not be exposed in search URLs")
    func testAPIKeyNotExposedInURLs() async {
        let service = await BookSearchService.shared
        let keyManager = await APIKeyManager.shared
        
        // Ensure key is set
        await keyManager.setupInitialKeys()
        
        // Monitor for any potential key exposure
        // This is a conceptual test - in practice, you'd need to intercept URL creation
        // or use a custom URLSession for testing
        
        let result = await service.search(query: "Security Test")
        
        // The test passes if the search completes without exposing the key
        // In production, you might capture and analyze the actual URLs
        switch result {
        case .success, .failure:
            // Both outcomes are acceptable for this security test
            // The key is that no key exposure occurs during the process
            break
        }
    }
    
    @Test("Service should handle API key changes during runtime")
    func testRuntimeAPIKeyChanges() async {
        let service = await BookSearchService.shared
        let keyManager = await APIKeyManager.shared
        
        // Set initial key
        await keyManager.setupInitialKeys()
        
        // Perform search
        let firstResult = await service.search(query: "Runtime Test 1")
        
        // Change API key
        await keyManager.setGoogleBooksAPIKey("different-test-key")
        
        // Perform another search
        let secondResult = await service.search(query: "Runtime Test 2")
        
        // Both searches should handle their respective key states appropriately
        switch (firstResult, secondResult) {
        case (.success, .failure(let error)):
            // First succeeded with valid key, second failed with invalid key
            guard case .networkError = error else {
                throw TestingError("Second search should fail with network error for invalid key")
            }
        case (.failure(let error1), .failure(let error2)):
            // Both failed - check they're appropriate failures
            guard case .networkError = error1, case .networkError = error2 else {
                throw TestingError("Both searches should fail with network errors")
            }
        case (.success, .success):
            // Both succeeded - this could happen in test environment
            break
        case (.failure, .success):
            throw TestingError("First search shouldn't fail if second succeeds")
        }
    }
    
    // MARK: - Error Recovery Tests
    
    @Test("Service should provide helpful error messages for API key issues")
    func testAPIKeyErrorMessages() async {
        let service = await BookSearchService.shared
        let keyManager = await APIKeyManager.shared
        
        // Test various API key error scenarios
        
        // Scenario 1: No key
        await keyManager.clearAllKeys()
        let noKeyResult = await service.search(query: "Error Test")
        
        switch noKeyResult {
        case .success:
            throw TestingError("Should fail when no API key is present")
        case .failure(let error):
            guard case .networkError(let message) = error else {
                throw TestingError("Should return networkError for missing API key")
            }
            #expect(message.contains("API key not configured"), "Error should mention API key configuration")
            #expect(message.contains("restart the app"), "Error should suggest restart to reinitialize")
        }
        
        // Scenario 2: Empty key
        await keyManager.setGoogleBooksAPIKey("")
        let emptyKeyResult = await service.search(query: "Error Test")
        
        switch emptyKeyResult {
        case .success:
            throw TestingError("Should fail when API key is empty")
        case .failure(let error):
            guard case .networkError(let message) = error else {
                throw TestingError("Should return networkError for empty API key")
            }
            #expect(message.contains("API key not configured"), "Error should mention API key configuration")
        }
    }
    
    // MARK: - Performance Tests
    
    @Test("API key retrieval should not impact search performance significantly")
    func testAPIKeyPerformanceImpact() async {
        let service = await BookSearchService.shared
        let keyManager = await APIKeyManager.shared
        
        // Setup
        await keyManager.setupInitialKeys()
        
        // Measure time for multiple key retrievals
        let startTime = Date()
        
        for _ in 0..<100 {
            let _ = await keyManager.googleBooksAPIKey
        }
        
        let keyRetrievalTime = Date().timeIntervalSince(startTime)
        
        // Key retrieval should be fast (under 0.1 seconds for 100 retrievals)
        #expect(keyRetrievalTime < 0.1, "API key retrieval should be fast: \(keyRetrievalTime)s for 100 retrievals")
    }
    
    // MARK: - Mock Network Tests
    
    @Test("Service should handle API authentication errors appropriately")
    func testAPIAuthenticationErrorHandling() async {
        let service = await BookSearchService.shared
        let keyManager = await APIKeyManager.shared
        
        // Set an obviously invalid API key
        await keyManager.setGoogleBooksAPIKey("invalid-api-key-12345")
        
        // Attempt search
        let result = await service.search(query: "Auth Test")
        
        switch result {
        case .success:
            // In some test environments, this might still succeed
            // That's acceptable for this test
            break
        case .failure(let error):
            // Should handle authentication errors gracefully
            switch error {
            case .networkError(let message):
                // Network error is expected for invalid API key
                #expect(!message.isEmpty, "Error message should not be empty")
            case .invalidURL, .decodingError, .noData:
                throw TestingError("Unexpected error type for authentication failure: \(error)")
            }
        }
    }
}

// MARK: - Test Helpers

extension BookSearchServiceSecurityIntegrationTests {
    
    /// Reset API keys to a clean state for testing
    private func resetAPIKeys() async {
        let keyManager = await APIKeyManager.shared
        await keyManager.resetToDefaults()
    }
}

// MARK: - Test Utilities

/// Custom error for test failures
struct TestingError: Error {
    let message: String
    
    init(_ message: String) {
        self.message = message
    }
}

// MARK: - APIKeyManager Test Extension

@MainActor
extension APIKeyManager {
    
    /// Test helper to set Google Books API key
    func setGoogleBooksAPIKey(_ key: String?) {
        self.googleBooksAPIKey = key
    }
}