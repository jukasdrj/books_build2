import Testing
import Foundation
import Security
@testable import books

// MARK: - Mock Keychain Protocol

/// Protocol for keychain operations to enable mocking
protocol KeychainOperationsProtocol {
    func getKeychainValue(for key: String) async -> String?
    func setKeychainValue(_ value: String?, for key: String) async
    func deleteKeychainValue(for key: String) async
}

// MARK: - Mock Keychain Implementation

/// Mock keychain implementation for testing
@MainActor
final class MockKeychain: KeychainOperationsProtocol, @unchecked Sendable {
    
    private var storage: [String: String] = [:]
    private var failureConditions: [String: MockKeychainError] = [:]
    private var accessCounts: [String: Int] = [:]
    
    // MARK: - Mock Configuration
    
    enum MockKeychainError: Error {
        case accessDenied
        case itemNotFound
        case duplicateItem
        case invalidParameter
        case memoryError
        case authenticationRequired
    }
    
    /// Configure mock to fail for specific keys
    func setFailureCondition(for key: String, error: MockKeychainError) {
        failureConditions[key] = error
    }
    
    /// Clear all failure conditions
    func clearFailureConditions() {
        failureConditions.removeAll()
    }
    
    /// Get access count for a key
    func getAccessCount(for key: String) -> Int {
        return accessCounts[key] ?? 0
    }
    
    /// Clear all data and reset state
    func reset() {
        storage.removeAll()
        failureConditions.removeAll()
        accessCounts.removeAll()
    }
    
    // MARK: - KeychainOperationsProtocol Implementation
    
    func getKeychainValue(for key: String) async -> String? {
        incrementAccessCount(for: key)
        
        // Check for failure conditions
        if let error = failureConditions[key] {
            switch error {
            case .itemNotFound:
                return nil
            case .accessDenied, .authenticationRequired:
                return nil // Simulate access failure
            default:
                return nil
            }
        }
        
        return storage[key]
    }
    
    func setKeychainValue(_ value: String?, for key: String) async {
        incrementAccessCount(for: key)
        
        // Check for failure conditions
        if let error = failureConditions[key] {
            switch error {
            case .accessDenied, .authenticationRequired:
                return // Simulate write failure
            case .duplicateItem where storage[key] != nil:
                return // Simulate duplicate error
            case .invalidParameter where value?.isEmpty == true:
                return // Simulate parameter validation
            default:
                break
            }
        }
        
        if let value = value {
            storage[key] = value
        } else {
            storage.removeValue(forKey: key)
        }
    }
    
    func deleteKeychainValue(for key: String) async {
        incrementAccessCount(for: key)
        
        // Check for failure conditions
        if let error = failureConditions[key] {
            switch error {
            case .accessDenied:
                return // Simulate delete failure
            default:
                break
            }
        }
        
        storage.removeValue(forKey: key)
    }
    
    // MARK: - Private Helpers
    
    private func incrementAccessCount(for key: String) {
        accessCounts[key] = (accessCounts[key] ?? 0) + 1
    }
}

// MARK: - Mockable APIKeyManager

/// Extended APIKeyManager that supports mock keychain for testing
@MainActor
final class MockableAPIKeyManager: ObservableObject, @unchecked Sendable {
    
    private let keychain: KeychainOperationsProtocol
    
    // Use the same keychain keys as the real implementation
    private enum KeychainKeys {
        static let googleBooksAPI = "GoogleBooksAPIKey"
        static let isbndbAPI = "ISBNDBAPIKey"
        static let appFirstRun = "AppFirstRun_v1"
    }
    
    init(keychain: KeychainOperationsProtocol) {
        self.keychain = keychain
    }
    
    // MARK: - API Key Properties
    
    var googleBooksAPIKey: String? {
        get {
            // This is a synchronous property in the real implementation
            // For testing, we'll use a blocking approach
            var result: String?
            let semaphore = DispatchSemaphore(value: 0)
            
            Task {
                result = await keychain.getKeychainValue(for: KeychainKeys.googleBooksAPI)
                semaphore.signal()
            }
            
            semaphore.wait()
            return result
        }
        set {
            Task {
                await keychain.setKeychainValue(newValue, for: KeychainKeys.googleBooksAPI)
            }
        }
    }
    
    var isbndbAPIKey: String? {
        get {
            var result: String?
            let semaphore = DispatchSemaphore(value: 0)
            
            Task {
                result = await keychain.getKeychainValue(for: KeychainKeys.isbndbAPI)
                semaphore.signal()
            }
            
            semaphore.wait()
            return result
        }
        set {
            Task {
                await keychain.setKeychainValue(newValue, for: KeychainKeys.isbndbAPI)
            }
        }
    }
    
    private var isFirstRun: Bool {
        get {
            var result: String?
            let semaphore = DispatchSemaphore(value: 0)
            
            Task {
                result = await keychain.getKeychainValue(for: KeychainKeys.appFirstRun)
                semaphore.signal()
            }
            
            semaphore.wait()
            return result == nil
        }
        set {
            Task {
                if newValue {
                    await keychain.deleteKeychainValue(for: KeychainKeys.appFirstRun)
                } else {
                    await keychain.setKeychainValue("completed", for: KeychainKeys.appFirstRun)
                }
            }
        }
    }
    
    // MARK: - Setup Methods
    
    func setupInitialKeys() async {
        guard isFirstRun else { return }
        
        // Migrate existing Google Books API key to Keychain
        await keychain.setKeychainValue("AIzaSyCj0-1RxPlVwO_XRZRkkQxCgp4lQVCxWaE", for: KeychainKeys.googleBooksAPI)
        
        // Mark setup as complete
        isFirstRun = false
    }
    
    // MARK: - Utility Methods
    
    func keyStatus() async -> [String: Bool] {
        let googleKey = await keychain.getKeychainValue(for: KeychainKeys.googleBooksAPI)
        let isbndbKey = await keychain.getKeychainValue(for: KeychainKeys.isbndbAPI)
        
        return [
            "Google Books": googleKey != nil,
            "ISBNDB": isbndbKey != nil
        ]
    }
    
    func clearAllKeys() async {
        await keychain.deleteKeychainValue(for: KeychainKeys.googleBooksAPI)
        await keychain.deleteKeychainValue(for: KeychainKeys.isbndbAPI)
        await keychain.deleteKeychainValue(for: KeychainKeys.appFirstRun)
    }
    
    func resetToDefaults() async {
        await clearAllKeys()
        await setupInitialKeys()
    }
}

// MARK: - Mock Test Suite

@Suite("Mock Keychain Strategy Tests")
struct MockKeychainTests {
    
    // MARK: - Basic Mock Functionality Tests
    
    @Test("Mock keychain should store and retrieve values")
    func testBasicMockOperation() async {
        let mockKeychain = MockKeychain()
        let testKey = "test-key"
        let testValue = "test-value"
        
        // Store value
        await mockKeychain.setKeychainValue(testValue, for: testKey)
        
        // Retrieve value
        let retrievedValue = await mockKeychain.getKeychainValue(for: testKey)
        #expect(retrievedValue == testValue, "Mock keychain should store and retrieve values correctly")
    }
    
    @Test("Mock keychain should handle nil values")
    func testMockNilHandling() async {
        let mockKeychain = MockKeychain()
        let testKey = "nil-test-key"
        
        // Store value first
        await mockKeychain.setKeychainValue("initial-value", for: testKey)
        #expect(await mockKeychain.getKeychainValue(for: testKey) != nil, "Value should be stored")
        
        // Clear value by setting nil
        await mockKeychain.setKeychainValue(nil, for: testKey)
        #expect(await mockKeychain.getKeychainValue(for: testKey) == nil, "Value should be cleared")
    }
    
    @Test("Mock keychain should track access counts")
    func testAccessCountTracking() async {
        let mockKeychain = MockKeychain()
        let testKey = "access-count-key"
        
        #expect(mockKeychain.getAccessCount(for: testKey) == 0, "Initial access count should be 0")
        
        // Perform several operations
        await mockKeychain.getKeychainValue(for: testKey) // +1
        await mockKeychain.setKeychainValue("test", for: testKey) // +1
        await mockKeychain.getKeychainValue(for: testKey) // +1
        await mockKeychain.deleteKeychainValue(for: testKey) // +1
        
        #expect(mockKeychain.getAccessCount(for: testKey) == 4, "Access count should track all operations")
    }
    
    // MARK: - Failure Simulation Tests
    
    @Test("Mock keychain should simulate access denied errors")
    func testAccessDeniedSimulation() async {
        let mockKeychain = MockKeychain()
        let testKey = "access-denied-key"
        
        // Configure failure condition
        mockKeychain.setFailureCondition(for: testKey, error: .accessDenied)
        
        // Attempt to store value (should fail silently)
        await mockKeychain.setKeychainValue("test-value", for: testKey)
        
        // Attempt to retrieve value (should return nil)
        let result = await mockKeychain.getKeychainValue(for: testKey)
        #expect(result == nil, "Should return nil when access is denied")
    }
    
    @Test("Mock keychain should simulate item not found errors")
    func testItemNotFoundSimulation() async {
        let mockKeychain = MockKeychain()
        let testKey = "not-found-key"
        
        // Configure failure condition
        mockKeychain.setFailureCondition(for: testKey, error: .itemNotFound)
        
        // Attempt to retrieve value (should return nil)
        let result = await mockKeychain.getKeychainValue(for: testKey)
        #expect(result == nil, "Should return nil for item not found")
    }
    
    @Test("Mock keychain should simulate authentication required errors")
    func testAuthenticationRequiredSimulation() async {
        let mockKeychain = MockKeychain()
        let testKey = "auth-required-key"
        
        // Store value first
        await mockKeychain.setKeychainValue("stored-value", for: testKey)
        #expect(await mockKeychain.getKeychainValue(for: testKey) == "stored-value", "Value should be stored initially")
        
        // Configure failure condition
        mockKeychain.setFailureCondition(for: testKey, error: .authenticationRequired)
        
        // Attempt to retrieve value (should return nil due to auth requirement)
        let result = await mockKeychain.getKeychainValue(for: testKey)
        #expect(result == nil, "Should return nil when authentication is required")
    }
    
    // MARK: - MockableAPIKeyManager Tests
    
    @Test("Mockable API key manager should work with mock keychain")
    func testMockableAPIKeyManager() async {
        let mockKeychain = MockKeychain()
        let manager = MockableAPIKeyManager(keychain: mockKeychain)
        
        // Test basic functionality
        let testKey = "mock-api-key"
        manager.googleBooksAPIKey = testKey
        
        #expect(manager.googleBooksAPIKey == testKey, "Mockable manager should store and retrieve keys")
    }
    
    @Test("Mockable manager should handle first run setup")
    func testMockableFirstRunSetup() async {
        let mockKeychain = MockKeychain()
        let manager = MockableAPIKeyManager(keychain: mockKeychain)
        
        // Should be first run initially
        await manager.setupInitialKeys()
        
        // Should have Google Books key after setup
        #expect(manager.googleBooksAPIKey != nil, "Should set up Google Books key on first run")
        
        // Should not re-setup on subsequent calls
        let initialKey = manager.googleBooksAPIKey
        await manager.setupInitialKeys()
        #expect(manager.googleBooksAPIKey == initialKey, "Should not change key on subsequent setup")
    }
    
    @Test("Mockable manager should handle failure conditions")
    func testMockableManagerWithFailures() async {
        let mockKeychain = MockKeychain()
        let manager = MockableAPIKeyManager(keychain: mockKeychain)
        
        // Configure keychain to fail for Google Books key
        mockKeychain.setFailureCondition(for: "GoogleBooksAPIKey", error: .accessDenied)
        
        // Attempt to set key (should fail silently)
        manager.googleBooksAPIKey = "test-key"
        
        // Key should not be set due to failure
        #expect(manager.googleBooksAPIKey == nil, "Key should not be set when keychain access is denied")
    }
    
    @Test("Mockable manager should report correct key status")
    func testMockableKeyStatus() async {
        let mockKeychain = MockKeychain()
        let manager = MockableAPIKeyManager(keychain: mockKeychain)
        
        // Initially no keys
        var status = await manager.keyStatus()
        #expect(status["Google Books"] == false, "Google Books key should be missing initially")
        #expect(status["ISBNDB"] == false, "ISBNDB key should be missing initially")
        
        // Set Google Books key
        manager.googleBooksAPIKey = "google-key"
        status = await manager.keyStatus()
        #expect(status["Google Books"] == true, "Google Books key should be present")
        #expect(status["ISBNDB"] == false, "ISBNDB key should still be missing")
        
        // Set ISBNDB key
        manager.isbndbAPIKey = "isbndb-key"
        status = await manager.keyStatus()
        #expect(status["Google Books"] == true, "Google Books key should still be present")
        #expect(status["ISBNDB"] == true, "ISBNDB key should now be present")
    }
    
    // MARK: - Performance Testing with Mocks
    
    @Test("Mock keychain should handle high-frequency operations")
    func testMockPerformance() async {
        let mockKeychain = MockKeychain()
        let testKey = "performance-test-key"
        
        let startTime = Date()
        
        // Perform many operations
        for i in 0..<1000 {
            await mockKeychain.setKeychainValue("value-\(i)", for: testKey)
            let _ = await mockKeychain.getKeychainValue(for: testKey)
        }
        
        let elapsedTime = Date().timeIntervalSince(startTime)
        #expect(elapsedTime < 1.0, "Mock keychain should handle 2000 operations quickly: \(elapsedTime)s")
        
        // Verify access count
        #expect(mockKeychain.getAccessCount(for: testKey) == 2000, "Should track all operations")
    }
    
    @Test("Mock keychain should handle concurrent access safely")
    func testMockConcurrency() async {
        let mockKeychain = MockKeychain()
        
        await withTaskGroup(of: Void.self) { group in
            // Multiple concurrent writers
            for i in 0..<50 {
                group.addTask {
                    await mockKeychain.setKeychainValue("concurrent-\(i)", for: "concurrent-key")
                }
            }
            
            // Multiple concurrent readers
            for _ in 0..<50 {
                group.addTask {
                    let _ = await mockKeychain.getKeychainValue(for: "concurrent-key")
                }
            }
        }
        
        // Should complete without crashing
        let finalValue = await mockKeychain.getKeychainValue(for: "concurrent-key")
        #expect(finalValue?.hasPrefix("concurrent-") == true, "Should have a valid value after concurrent access")
        
        // Should have tracked all operations
        #expect(mockKeychain.getAccessCount(for: "concurrent-key") == 100, "Should track all concurrent operations")
    }
    
    // MARK: - Integration Testing with Mocks
    
    @Test("Mock strategy should enable comprehensive integration testing")
    func testMockIntegrationTesting() async {
        let mockKeychain = MockKeychain()
        let manager = MockableAPIKeyManager(keychain: mockKeychain)
        
        // Test complete workflow with mocks
        
        // 1. First run setup
        await manager.setupInitialKeys()
        var status = await manager.keyStatus()
        #expect(status["Google Books"] == true, "Should set up Google Books key")
        
        // 2. Clear all keys
        await manager.clearAllKeys()
        status = await manager.keyStatus()
        #expect(status["Google Books"] == false, "Should clear all keys")
        #expect(status["ISBNDB"] == false, "Should clear all keys")
        
        // 3. Reset to defaults
        await manager.resetToDefaults()
        status = await manager.keyStatus()
        #expect(status["Google Books"] == true, "Should restore default keys")
        
        // 4. Verify access patterns
        #expect(mockKeychain.getAccessCount(for: "GoogleBooksAPIKey") > 0, "Should have accessed Google Books key")
        #expect(mockKeychain.getAccessCount(for: "AppFirstRun_v1") > 0, "Should have accessed first run flag")
    }
}

// MARK: - Mock Usage Examples

@Suite("Mock Usage Examples")
struct MockUsageExamples {
    
    @Test("Example: Testing app launch with corrupted keychain")
    func testCorruptedKeychainScenario() async {
        let mockKeychain = MockKeychain()
        
        // Simulate corrupted keychain where reads fail
        mockKeychain.setFailureCondition(for: "GoogleBooksAPIKey", error: .memoryError)
        
        let manager = MockableAPIKeyManager(keychain: mockKeychain)
        
        // App launch should handle corrupted keychain gracefully
        await manager.setupInitialKeys()
        
        // Should not crash and provide fallback behavior
        let status = await manager.keyStatus()
        #expect(status["Google Books"] == false, "Should handle corrupted keychain gracefully")
    }
    
    @Test("Example: Testing device lock/unlock simulation")
    func testDeviceLockSimulation() async {
        let mockKeychain = MockKeychain()
        let manager = MockableAPIKeyManager(keychain: mockKeychain)
        
        // Set up keys when "unlocked"
        await manager.setupInitialKeys()
        #expect(manager.googleBooksAPIKey != nil, "Keys should be accessible when unlocked")
        
        // Simulate device lock (access denied)
        mockKeychain.setFailureCondition(for: "GoogleBooksAPIKey", error: .authenticationRequired)
        
        // Keys should not be accessible when "locked"
        #expect(manager.googleBooksAPIKey == nil, "Keys should not be accessible when locked")
        
        // Simulate device unlock (clear failure condition)
        mockKeychain.clearFailureConditions()
        
        // Keys should be accessible again when "unlocked"
        #expect(manager.googleBooksAPIKey != nil, "Keys should be accessible when unlocked again")
    }
    
    @Test("Example: Testing keychain migration scenarios")
    func testKeychainMigrationScenario() async {
        let mockKeychain = MockKeychain()
        
        // Simulate old keychain with different key structure
        await mockKeychain.setKeychainValue("old-api-key", for: "OldGoogleBooksAPIKey")
        
        let manager = MockableAPIKeyManager(keychain: mockKeychain)
        
        // Migration logic would check for old keys and migrate them
        // This is a simplified example of how migration testing would work
        
        await manager.setupInitialKeys()
        
        // Verify new key structure is used
        #expect(manager.googleBooksAPIKey != nil, "Migration should set up new key structure")
    }
}

// MARK: - Performance Comparison Tests

@Suite("Mock vs Real Performance Comparison")
struct MockPerformanceTests {
    
    @Test("Mock operations should be faster than real keychain operations")
    func testMockVsRealPerformance() async {
        let mockKeychain = MockKeychain()
        let realManager = APIKeyManager.shared
        
        // Test mock performance
        let mockStartTime = Date()
        for i in 0..<100 {
            await mockKeychain.setKeychainValue("mock-\(i)", for: "performance-test")
            let _ = await mockKeychain.getKeychainValue(for: "performance-test")
        }
        let mockTime = Date().timeIntervalSince(mockStartTime)
        
        // Test real keychain performance
        let realStartTime = Date()
        for i in 0..<100 {
            await realManager.setGoogleBooksAPIKey("real-\(i)")
            let _ = await realManager.googleBooksAPIKey
        }
        let realTime = Date().timeIntervalSince(realStartTime)
        
        // Mock should be significantly faster
        #expect(mockTime < realTime, "Mock operations should be faster than real keychain: mock=\(mockTime)s, real=\(realTime)s")
        
        // Both should complete in reasonable time
        #expect(mockTime < 0.5, "Mock operations should be very fast")
        #expect(realTime < 5.0, "Real operations should complete in reasonable time")
    }
}

// MARK: - Test Extensions

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