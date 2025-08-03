//
// NEW: booksTests/HapticFeedbackTests.swift
//
import Testing
import UIKit
@testable import books

@Suite("Haptic Feedback Tests")
struct HapticFeedbackTests {
    
    @Test("HapticFeedbackManager Singleton - Should provide shared instance")
    func testHapticFeedbackManagerSingleton() async {
        let manager1 = await HapticFeedbackManager.shared
        let manager2 = await HapticFeedbackManager.shared
        
        #expect(manager1 === manager2, "Should be the same singleton instance")
    }
    
    @Test("HapticFeedbackManager Methods - Should not crash when called")
    func testHapticFeedbackManagerMethods() async {
        let manager = await HapticFeedbackManager.shared
        
        // These methods should not crash when called
        // (We can't easily test the actual haptic feedback in unit tests)
        await manager.ratingChanged()
        await manager.ratingCompleted()
        await manager.bookMarkedAsRead()
        await manager.swipeToRate()
        await manager.longPressStarted()
        await manager.lightImpact()
        await manager.mediumImpact()
        await manager.heavyImpact()
        await manager.success()
        await manager.warning()
        await manager.error()
        
        // Test passes if no crashes occur
        #expect(true)
    }
}