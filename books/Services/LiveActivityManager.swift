//
//  LiveActivityManager.swift
//  books
//
//  Prepares architecture for Phase 2 Live Activities support
//

import Foundation
//import ActivityKit
import SwiftUI

// Import the shared ActivityAttributes
// Note: In the actual Xcode project, this would be included in both targets

/// Manager for Live Activities during CSV import (Phase 2 preparation)
/*
@available(iOS 16.1, *)
@MainActor
class LiveActivityManager: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = LiveActivityManager()
    
    // MARK: - State
    
    @Published private(set) var currentActivity: Activity<CSVImportActivityAttributes>?
    @Published private(set) var isLiveActivitySupported: Bool
    
    // MARK: - Initialization
    
    private init() {
        // Check both authorization and device support
        isLiveActivitySupported = ActivityAuthorizationInfo().areActivitiesEnabled
        
        print("[LiveActivityManager] Live Activities supported: \(isLiveActivitySupported)")
        
        // Additional debug info for troubleshooting
        #if targetEnvironment(simulator)
        print("[LiveActivityManager] Running on simulator - Live Activities may not work properly")
        isLiveActivitySupported = false // Force disable on simulator
        #endif
    }
    
    // MARK: - Public Interface
    
    /// Start a Live Activity for CSV import
    func startImportActivity(
        fileName: String,
        totalBooks: Int,
        sessionId: UUID
    ) async -> Bool {
        guard isLiveActivitySupported else {
            print("[LiveActivityManager] Live Activities not supported or not enabled")
            return false
        }
        
        // End any existing activity
        await endCurrentActivity()
        
        let attributes = CSVImportActivityAttributes(
            fileName: fileName,
            sessionId: sessionId,
            fileSize: nil,
            estimatedDuration: nil
        )
        
        let contentState = CSVImportActivityAttributes.ContentState(
            progress: 0.0,
            currentStep: "Preparing import...",
            booksProcessed: 0,
            totalBooks: totalBooks,
            successCount: 0,
            duplicateCount: 0,
            failureCount: 0,
            currentBookTitle: nil,
            currentBookAuthor: nil
        )
        
        do {
            let activity = try Activity<CSVImportActivityAttributes>.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: nil),
                pushType: nil
            )
            
            currentActivity = activity
            print("[LiveActivityManager] Started Live Activity for import: \(sessionId)")
            return true
        } catch {
            print("[LiveActivityManager] Failed to start Live Activity: \(error)")
            return false
        }
    }
    
    /// Update the current Live Activity
    func updateActivity(with progress: ImportProgress) async {
        guard let activity = currentActivity else { return }
        
        let contentState = CSVImportActivityAttributes.ContentState(
            progress: progress.progress,
            currentStep: progress.message,
            booksProcessed: progress.processedBooks,
            totalBooks: progress.totalBooks,
            successCount: progress.successfulImports,
            duplicatesSkipped: progress.duplicatesSkipped,
            failedImports: progress.failedImports,
            currentBookTitle: progress.currentBookTitle,
            currentBookAuthor: progress.currentBookAuthor
        )
        
        await activity.update(.init(state: contentState, staleDate: nil))
    }
    
    /// End the current Live Activity
    func endCurrentActivity(reason: ActivityUIDismissalPolicy = .default) async {
        guard let activity = currentActivity else { return }
        
        await activity.end(nil, dismissalPolicy: reason)
        currentActivity = nil
        
        print("[LiveActivityManager] Ended Live Activity")
    }
    
    /// Complete the import activity with final results
    func completeImportActivity(with result: ImportResult) async {
        guard let activity = currentActivity else { return }
        
        let finalState = CSVImportActivityAttributes.ContentState(
            progress: 1.0,
            currentStep: "Import completed",
            booksProcessed: result.totalBooks,
            totalBooks: result.totalBooks,
            successCount: result.successfulImports,
            duplicatesSkipped: result.duplicatesSkipped,
            failedImports: result.failedImports,
            currentBookTitle: nil,
            currentBookAuthor: nil
        )
        
        // Update with final state
        await activity.update(.init(state: finalState, staleDate: nil))
        
        // End activity after a delay to show completion
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            await endCurrentActivity(reason: .after(.now.addingTimeInterval(5)))
        }
        
        print("[LiveActivityManager] Completed import activity with final results")
    }
    
    // MARK: - Utility
    
    /// Check if Live Activities are available and enabled
    func checkLiveActivityAvailability() {
        let authInfo = ActivityAuthorizationInfo()
        isLiveActivitySupported = authInfo.areActivitiesEnabled
        
        print("[LiveActivityManager] Live Activities enabled: \(isLiveActivitySupported)")
    }
}
*/

// MARK: - Activity Attributes (Phase 2 Implementation)

/// Activity attributes for CSV import Live Activities
/*
@available(iOS 16.1, *)
struct CSVImportActivityAttributes: ActivityAttributes {
    
    public struct ContentState: Codable, Hashable {
        var progress: Double
        var currentStep: String
        var booksProcessed: Int
        var totalBooks: Int
        var successCount: Int
        var duplicateCount: Int
        var failureCount: Int
        var currentBookTitle: String?
        var currentBookAuthor: String?
        
        var formattedProgress: String {
            return "\(Int(progress * 100))%"
        }
        
        var statusSummary: String {
            if totalBooks == 0 { return "Preparing..." }
            return "\(booksProcessed)/\(totalBooks) books"
        }
        
        var isComplete: Bool {
            return progress >= 1.0
        }
        
        var hasErrors: Bool {
            return failureCount > 0
        }
        
        var hasDuplicates: Bool {
            return duplicateCount > 0
        }
        
        var completionSummary: String {
            var parts: [String] = []
            
            if successCount > 0 {
                parts.append("\(successCount) imported")
            }
            
            if duplicateCount > 0 {
                parts.append("\(duplicateCount) duplicates")
            }
            
            if failureCount > 0 {
                parts.append("\(failureCount) failed")
            }
            
            return parts.isEmpty ? "No books processed" : parts.joined(separator: ", ")
        }
    }
    
    var fileName: String
    var sessionId: UUID
    var fileSize: Int64?
    var estimatedDuration: TimeInterval?
    
    var displayName: String {
        return "Importing \(fileName)"
    }
    
    var shortDisplayName: String {
        let name = fileName.replacingOccurrences(of: ".csv", with: "")
        return name.count > 20 ? String(name.prefix(17)) + "..." : name
    }
}
*/

// MARK: - Fallback for iOS < 16.1

/// Fallback manager for devices that don't support Live Activities
@MainActor
class FallbackLiveActivityManager: ObservableObject, @unchecked Sendable {
    static let shared = FallbackLiveActivityManager()
    
    @Published private(set) var isLiveActivitySupported = false
    
    private init() {}
    
    func startImportActivity(fileName: String, totalBooks: Int, sessionId: UUID) async -> Bool {
        print("[FallbackLiveActivityManager] Live Activities not supported on this iOS version")
        return false
    }
    
    func updateActivity(with progress: ImportProgress) async {
        // No-op for unsupported versions
    }
    
    func endCurrentActivity(reason: String = "default") async {
        // No-op for unsupported versions
    }
    
    func completeImportActivity(with result: ImportResult) async {
        // No-op for unsupported versions
    }
    
    func checkLiveActivityAvailability() {
        // Always false for unsupported versions
    }
}

// MARK: - Unified Interface

/// Unified interface that works across iOS versions
/*
@MainActor
class UnifiedLiveActivityManager: ObservableObject {
    
    static let shared = UnifiedLiveActivityManager()
    
    @Published var isLiveActivitySupported: Bool
    
    private init() {
        if #available(iOS 16.1, *) {
            self.isLiveActivitySupported = LiveActivityManager.shared.isLiveActivitySupported
        } else {
            self.isLiveActivitySupported = false
        }
    }
    
    func startImportActivity(fileName: String, totalBooks: Int, sessionId: UUID) async -> Bool {
        if #available(iOS 16.1, *) {
            return await LiveActivityManager.shared.startImportActivity(
                fileName: fileName,
                totalBooks: totalBooks,
                sessionId: sessionId
            )
        } else {
            return await FallbackLiveActivityManager.shared.startImportActivity(
                fileName: fileName,
                totalBooks: totalBooks,
                sessionId: sessionId
            )
        }
    }
    
    func updateActivity(with progress: ImportProgress) async {
        if #available(iOS 16.1, *) {
            await LiveActivityManager.shared.updateActivity(with: progress)
        } else {
            await FallbackLiveActivityManager.shared.updateActivity(with: progress)
        }
    }
    
    func endCurrentActivity() async {
        if #available(iOS 16.1, *) {
            await LiveActivityManager.shared.endCurrentActivity()
        } else {
            await FallbackLiveActivityManager.shared.endCurrentActivity()
        }
    }
    
    func completeImportActivity(with result: ImportResult) async {
        if #available(iOS 16.1, *) {
            await LiveActivityManager.shared.completeImportActivity(with: result)
        } else {
            await FallbackLiveActivityManager.shared.completeImportActivity(with: result)
        }
    }
    
    func checkLiveActivityAvailability() {
        if #available(iOS 16.1, *) {
            LiveActivityManager.shared.checkLiveActivityAvailability()
            isLiveActivitySupported = LiveActivityManager.shared.isLiveActivitySupported
        } else {
            FallbackLiveActivityManager.shared.checkLiveActivityAvailability()
            isLiveActivitySupported = false
        }
    }
}
*/

// MARK: - Phase 2 TODO Implementation Notes

/*
 Phase 2 Implementation Checklist:
 
 1. Enable Live Activity capability in Xcode project:
    - Add "Push Notifications" capability
    - Add NSSupportsLiveActivities = YES to Info.plist
 
 2. Create Widget Extension:
    - Add new Widget Extension target
    - Implement ActivityConfiguration
    - Design compact and expanded Live Activity views
    - Handle different activity states (running, completed, error)
 
 3. Integrate with import service:
    - Call startImportActivity() when import begins
    - Call updateActivity() during progress updates
    - Call completeImportActivity() when done
    - Handle activity lifecycle with app state changes
 
 4. Add user permissions:
    - Request Live Activity permissions
    - Handle permission denied gracefully
    - Provide settings link for users to enable
 
 5. Testing:
    - Test on physical device (Live Activities don't work in simulator)
    - Test background scenarios
    - Test activity updates and completion
    - Test with different file sizes and import durations
 
 Current State: Architecture prepared, ready for Phase 2 implementation
 */