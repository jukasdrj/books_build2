//
//  BackgroundTaskManager.swift
//  books
//
//  Background task management for CSV imports
//

import Foundation
import UIKit
import BackgroundTasks

/// Manages iOS background tasks for long-running CSV import operations
@MainActor
class BackgroundTaskManager: NSObject, ObservableObject {
    
    // MARK: - Configuration
    
    /// Background task identifier for CSV imports
    static let csvImportTaskIdentifier = "com.books.readingtracker.csv-import"
    
    // MARK: - State
    
    @Published private(set) var isBackgroundTaskActive = false
    @Published private(set) var backgroundTimeRemaining: TimeInterval = 0
    
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var backgroundTaskExpirationTimer: Timer?
    
    // MARK: - Singleton
    
    static let shared = BackgroundTaskManager()
    
    private override init() {
        super.init()
    }
    
    // MARK: - Background Task Registration
    
    /// Register background task handlers with the system
    func registerBackgroundTasks() {
        // Register background processing task
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.csvImportTaskIdentifier,
            using: nil
        ) { [weak self] task in
            self?.handleCSVImportBackgroundTask(task as! BGProcessingTask)
        }
        
        print("[BackgroundTaskManager] Registered background task: \(Self.csvImportTaskIdentifier)")
    }
    
    // MARK: - Background Task Execution
    
    /// Start a background task for CSV import
    func beginBackgroundTask(for importId: UUID) -> Bool {
        guard backgroundTask == .invalid else {
            print("[BackgroundTaskManager] Background task already active")
            return false
        }
        
        backgroundTask = UIApplication.shared.beginBackgroundTask(
            withName: "CSV Import \(importId.uuidString)"
        ) { [weak self] in
            // Task expiration handler
            self?.handleBackgroundTaskExpiration()
        }
        
        guard backgroundTask != .invalid else {
            print("[BackgroundTaskManager] Failed to start background task")
            return false
        }
        
        isBackgroundTaskActive = true
        startBackgroundTimeMonitoring()
        
        print("[BackgroundTaskManager] Started background task for import: \(importId)")
        return true
    }
    
    /// End the current background task
    func endBackgroundTask() {
        guard backgroundTask != .invalid else { return }
        
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
        isBackgroundTaskActive = false
        
        stopBackgroundTimeMonitoring()
        
        print("[BackgroundTaskManager] Ended background task")
    }
    
    /// Request extended background processing time
    func requestExtendedBackgroundTime() {
        let request = BGProcessingTaskRequest(identifier: Self.csvImportTaskIdentifier)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("[BackgroundTaskManager] Submitted extended background processing request")
        } catch {
            print("[BackgroundTaskManager] Failed to submit background task request: \(error)")
        }
    }
    
    // MARK: - Background Task Handlers
    
    private func handleCSVImportBackgroundTask(_ task: BGProcessingTask) {
        print("[BackgroundTaskManager] Handling background CSV import task")
        
        // Set up task completion
        task.expirationHandler = { [weak self] in
            print("[BackgroundTaskManager] Background task expired")
            task.setTaskCompleted(success: false)
            self?.handleBackgroundTaskExpiration()
        }
        
        // Resume any pending imports
        Task {
            await resumePendingImports()
            task.setTaskCompleted(success: true)
        }
    }
    
    private func handleBackgroundTaskExpiration() {
        print("[BackgroundTaskManager] Background task expiring - saving state")
        
        // Notify import service to save state
        NotificationCenter.default.post(
            name: .backgroundTaskWillExpire,
            object: nil
        )
        
        endBackgroundTask()
    }
    
    // MARK: - Background Time Monitoring
    
    private func startBackgroundTimeMonitoring() {
        backgroundTaskExpirationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateBackgroundTimeRemaining()
        }
    }
    
    private func stopBackgroundTimeMonitoring() {
        backgroundTaskExpirationTimer?.invalidate()
        backgroundTaskExpirationTimer = nil
        backgroundTimeRemaining = 0
    }
    
    private func updateBackgroundTimeRemaining() {
        backgroundTimeRemaining = UIApplication.shared.backgroundTimeRemaining
        
        // Warn when running low on time
        if backgroundTimeRemaining < 30 && backgroundTimeRemaining > 0 {
            print("[BackgroundTaskManager] Background time low: \(Int(backgroundTimeRemaining))s remaining")
            
            // Request extended time if available
            if backgroundTimeRemaining < 10 {
                requestExtendedBackgroundTime()
            }
        }
    }
    
    // MARK: - Import Management
    
    /// Resume any pending imports from persistent storage
    private func resumePendingImports() async {
        // This will be implemented with the ImportStateManager
        print("[BackgroundTaskManager] Checking for pending imports to resume")
        
        // Notify the import service to check for resumable imports
        NotificationCenter.default.post(
            name: .shouldResumePendingImports,
            object: nil
        )
    }
    
    // MARK: - App Lifecycle Management
    
    /// Handle app entering background
    func handleAppDidEnterBackground() {
        print("[BackgroundTaskManager] App entered background")
        
        // Check if we have an active import that needs background time
        if ImportStateManager.shared.hasActiveImport {
            let importId = ImportStateManager.shared.currentImportId
            if importId != nil && !beginBackgroundTask(for: importId!) {
                print("[BackgroundTaskManager] Failed to start background task for active import")
            }
        }
    }
    
    /// Handle app becoming active
    func handleAppDidBecomeActive() {
        print("[BackgroundTaskManager] App became active")
        endBackgroundTask()
    }
    
    /// Handle app termination
    func handleAppWillTerminate() {
        print("[BackgroundTaskManager] App will terminate - saving critical state")
        
        // Ensure import state is persisted
        NotificationCenter.default.post(
            name: .appWillTerminate,
            object: nil
        )
        
        endBackgroundTask()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let backgroundTaskWillExpire = Notification.Name("backgroundTaskWillExpire")
    static let shouldResumePendingImports = Notification.Name("shouldResumePendingImports")
    static let appWillTerminate = Notification.Name("appWillTerminate")
}

// MARK: - Background Task Status

enum BackgroundTaskStatus {
    case inactive
    case active(timeRemaining: TimeInterval)
    case expiring
    case expired
    
    var isActive: Bool {
        switch self {
        case .active:
            return true
        default:
            return false
        }
    }
    
    var timeRemaining: TimeInterval {
        switch self {
        case .active(let time):
            return time
        default:
            return 0
        }
    }
}