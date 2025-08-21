//
//  BackgroundImportCoordinator.swift
//  books
//
//  Coordinates background CSV import UX with library integration
//  Swift 6 compliant with @Observable for seamless UI updates
//

import Foundation
import SwiftUI
import SwiftData

/// Coordinates background import UX and library integration
@MainActor
@Observable
class BackgroundImportCoordinator {
    
    // MARK: - Singleton with Thread-Safe Initialization
    
    private static var _shared: BackgroundImportCoordinator?
    private static let lockQueue = DispatchQueue(label: "backgroundImportCoordinator.lock")
    
    static func initialize(with modelContext: ModelContext) -> BackgroundImportCoordinator {
        return lockQueue.sync {
            if let existing = _shared {
                // Ensure the existing coordinator has the same model context
                if existing.modelContext === modelContext {
                    print("[BackgroundImportCoordinator] Using existing coordinator with same context")
                    return existing
                } else {
                    print("[BackgroundImportCoordinator] Model context changed, creating new coordinator")
                    existing.cleanupResources()
                    _shared = nil
                }
            }
            
            let coordinator = BackgroundImportCoordinator(modelContext: modelContext)
            _shared = coordinator
            print("[BackgroundImportCoordinator] Initialized new coordinator")
            return coordinator
        }
    }
    
    static var shared: BackgroundImportCoordinator? {
        return lockQueue.sync {
            return _shared
        }
    }
    
    /// Call this to properly clean up the singleton when no longer needed
    static func cleanup() {
        lockQueue.sync {
            _shared?.cleanupResources()
            _shared = nil
        }
    }
    
    // MARK: - Import State
    
    private(set) var currentImport: BackgroundImportSession?
    private(set) var needsUserReview: [ReviewItem] = []
    private(set) var currentProgress: ImportProgress?
    
    // MARK: - Services
    
    let csvImportService: CSVImportService  // Made public for UI access
    private let modelContext: ModelContext
//    private let liveActivityManager = UnifiedLiveActivityManager.shared
    
    // MARK: - Monitoring State & Task Management
    
    private var isMonitoring: Bool = false
    private var monitoringTask: Task<Void, Never>?
    
    // MARK: - Computed Properties
    
    var isImporting: Bool { 
        currentImport != nil 
    }
    
    var progress: ImportProgress? { 
        currentProgress
    }
    
    var shouldShowReviewModal: Bool {
        !needsUserReview.isEmpty
    }
    
    // MARK: - Initialization
    
    private init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.csvImportService = CSVImportService(modelContext: modelContext)
        
        // Check for existing import on startup
        Task {
            await checkForExistingImport()
        }
    }
    
    // MARK: - Public Interface
    
    /// Start background import immediately (Phase 1: no user choice)
    func startBackgroundImport(session: CSVImportSession, mappings: [String: BookField]) async {
        print("[BackgroundImportCoordinator] Starting background import for \(session.totalRows) books")
        
        let backgroundSession = BackgroundImportSession(
            csvSession: session,
            mappings: mappings,
            startTime: Date()
        )
        
        await MainActor.run {
            currentImport = backgroundSession
        }
        
        // Start Live Activity for this import
/*
        let activityStarted = await liveActivityManager.startImportActivity(
            fileName: session.fileName,
            totalBooks: session.totalRows,
            sessionId: sessionId
        )
        
        if activityStarted {
            print("[BackgroundImportCoordinator] Live Activity started for import session: \(sessionId)")
        } else {
            print("[BackgroundImportCoordinator] Live Activity failed to start, continuing without Live Activity support")
        }
*/
        
        // Start the import in background using existing service
        // The CSVImportService will insert books into modelContext as they're processed
        // This automatically triggers @Query updates in LibraryView for seamless integration
        
        // Begin import process and wait for it to initialize
        csvImportService.importBooks(from: session, columnMappings: mappings)
        
        // Wait for import service to actually create progress before monitoring
        Task {
            // Wait up to 5 seconds for import to initialize
            let maxWaitTime = 5.0
            let checkInterval = 0.1
            var elapsed = 0.0
            
            while elapsed < maxWaitTime && csvImportService.importProgress == nil {
                try? await Task.sleep(nanoseconds: UInt64(checkInterval * 1_000_000_000))
                elapsed += checkInterval
            }
            
            if csvImportService.importProgress != nil {
                print("[BackgroundImportCoordinator] Import initialized, starting monitoring")
                monitorImportProgress()
            } else {
                print("[BackgroundImportCoordinator] Warning: Import failed to initialize within \(maxWaitTime) seconds")
                // Reset state on initialization failure
                await MainActor.run {
                    currentImport = nil
                    currentProgress = nil
                }
            }
        }
    }
    
    /// Handle completion - check for review needs
    func handleImportCompletion() async {
        guard let session = currentImport else { return }
        
        print("[BackgroundImportCoordinator] Import completed for session: \(session.csvSession.fileName)")
        
        // Check if any books need user review (ambiguous matches, no matches, etc.)
        await checkForReviewNeeds()
        
        // Complete the Live Activity with final results
/*
        if let progress = session.progress {
            let result = ImportResult(
                sessionId: UUID(), // Generate unique ID for this import session
                totalBooks: progress.totalBooks,
                successfulImports: progress.successfulImports,
                failedImports: progress.failedImports,
                duplicatesSkipped: progress.duplicatesSkipped,
                duplicatesISBN: 0, // TODO: Track these separately in future
                duplicatesGoogleID: 0,
                duplicatesTitleAuthor: 0,
                duration: Date().timeIntervalSince(session.startTime),
                errors: [], // TODO: Collect errors from import process
                importedBookIds: [], // TODO: Track imported book IDs
                retryAttempts: 0,
                successfulRetries: 0
            )
            await liveActivityManager.completeImportActivity(with: result)
        } else {
            await liveActivityManager.endCurrentActivity()
        }
*/
        
        // Stop monitoring task and clear current import
        monitoringTask?.cancel()
        monitoringTask = nil
        isMonitoring = false
        await MainActor.run {
            currentImport = nil
            currentProgress = nil
        }
        
        // Show completion notification
        await showCompletionNotification()
    }
    
    /// Present review modal for ambiguous matches
    func presentReviewModal() async -> ReviewResult {
        // This will be called when shouldShowReviewModal is true
        // The UI will present a sheet with review options
        
        // For now, return a placeholder - the UI will handle actual review
        return ReviewResult.completed
    }
    
    /// Cancel current background import
    func cancelImport() async {
        guard currentImport != nil else { return }
        
        // Cancel monitoring task first
        monitoringTask?.cancel()
        
        csvImportService.cancelImport()
        
        // End the Live Activity
//        await liveActivityManager.endCurrentActivity()
        
        // Stop monitoring
        isMonitoring = false
        await MainActor.run {
            currentImport = nil
            currentProgress = nil
        }
        needsUserReview.removeAll()
        
        print("[BackgroundImportCoordinator] Background import cancelled")
    }
    
    /// Pause/Resume import
    func pauseImport() {
        csvImportService.cancelImport()
    }
    
    func resumeImport() {
        if csvImportService.canResumeImport() {
            _ = csvImportService.resumeImportIfAvailable()
        }
    }
    
    /// Clear user review items
    func clearReviewItems() {
        needsUserReview.removeAll()
    }
    
    /// Clean up resources and cancel any ongoing operations
    func cleanupResources() {
        print("[BackgroundImportCoordinator] Cleaning up resources")
        
        // Cancel monitoring task first to prevent memory leaks
        monitoringTask?.cancel()
        monitoringTask = nil
        
        // Cancel any ongoing imports
        csvImportService.cancelImport()
        
        // Stop monitoring
        isMonitoring = false
        
        // Clear state
        currentImport = nil
        currentProgress = nil
        needsUserReview.removeAll()
        
        // Note: We don't clean up modelContext as it's owned by the caller
        print("[BackgroundImportCoordinator] Resource cleanup completed")
    }
    
    // MARK: - Private Implementation
    
    private func checkForExistingImport() async {
        // Check ImportStateManager for existing import AND that CSVImportService is actually importing
        if let resumableInfo = ImportStateManager.shared.getResumableImportInfo(),
           ImportStateManager.shared.canResumeImport(),
           csvImportService.isImporting {
            
            print("[BackgroundImportCoordinator] Found existing active import: \(resumableInfo.fileName)")
            
            // Recreate background session from persisted state
            let backgroundSession = BackgroundImportSession(
                csvSession: CSVImportSession(
                    fileName: resumableInfo.fileName,
                    fileSize: 0, // Will be restored from state
                    totalRows: resumableInfo.estimatedBooksRemaining + resumableInfo.progress.processedBooks,
                    detectedColumns: [], // Will be restored from state
                    sampleData: [], // Will be restored from state
                    allData: [] // Will be restored from state
                ),
                mappings: [:], // Will be restored from state
                startTime: resumableInfo.lastUpdated
            )
            
            await MainActor.run {
                currentImport = backgroundSession
            }
            monitorImportProgress()
        } else {
            // Clear any stale import state if there's no active import
            if ImportStateManager.shared.getResumableImportInfo() != nil {
                print("[BackgroundImportCoordinator] Found stale import state with no active import, cleaning up")
                ImportStateManager.shared.clearImportState()
            }
        }
    }
    
    private func monitorImportProgress() {
        // Cancel any existing monitoring task
        monitoringTask?.cancel()
        
        // Prevent multiple monitoring tasks from running
        guard !isMonitoring else {
            print("[BackgroundImportCoordinator] Monitoring already in progress, skipping")
            return
        }
        
        // Only start monitoring if there's actually an import session AND it's actively importing
        guard currentImport != nil, csvImportService.isImporting else {
            print("[BackgroundImportCoordinator] No active import session or not importing, skipping monitoring")
            return
        }
        
        isMonitoring = true
        print("[BackgroundImportCoordinator] Starting import progress monitoring")
        
        // Create and track the monitoring task
        monitoringTask = Task { @MainActor in
            defer {
                isMonitoring = false
                monitoringTask = nil
                print("[BackgroundImportCoordinator] Stopped import progress monitoring")
            }
            
            while isImporting && isMonitoring && !Task.isCancelled {
                // Check for task cancellation
                guard !Task.isCancelled else {
                    print("[BackgroundImportCoordinator] Monitoring task cancelled")
                    break
                }
                
                // Wait for import to actually start
                if let progress = csvImportService.importProgress {
                    // Only update if progress has actually changed to reduce UI bouncing
                    let hasProgressChanged = currentProgress?.processedBooks != progress.processedBooks ||
                                           currentProgress?.currentStep != progress.currentStep
                    
                    if hasProgressChanged {
                        print("[BackgroundImportCoordinator] Progress update: \(progress.processedBooks)/\(progress.totalBooks), step: \(progress.currentStep)")
                        
                        // Update state directly on MainActor
                        currentProgress = progress
                        currentImport?.progress = progress
                        print("[BackgroundImportCoordinator] UI state updated - isImporting: \(isImporting), progress: \(String(describing: progress))")
                    }
                    
                    // Update Live Activity with current progress
//                    await liveActivityManager.updateActivity(with: progress)
                    
                    // Check for completion
                    if progress.isComplete {
                        await handleImportCompletion()
                        break
                    }
                } else {
                    print("[BackgroundImportCoordinator] Waiting for import to start... (isImporting: \(csvImportService.isImporting))")
                }
                
                // Check every 2 seconds with cancellation support
                do {
                    try await Task.sleep(nanoseconds: 2_000_000_000)
                } catch {
                    print("[BackgroundImportCoordinator] Monitoring sleep interrupted")
                    break
                }
            }
        }
    }
    
    private func checkForReviewNeeds() async {
        // Check for books that need user review
        // This would integrate with the fallback queue results
        
        guard let progress = currentImport?.progress else { return }
        
        var reviewItems: [ReviewItem] = []
        
        // Add items that failed and might need manual review
        for error in progress.errors {
            if error.errorType == .networkError || error.errorType == .validationError {
                let reviewItem = ReviewItem(
                    bookTitle: error.bookTitle ?? "Unknown Book",
                    author: error.suggestions.first ?? "Unknown Author",
                    issue: error.message,
                    suggestions: error.suggestions
                )
                reviewItems.append(reviewItem)
            }
        }
        
        needsUserReview = reviewItems
        
        if !reviewItems.isEmpty {
            print("[BackgroundImportCoordinator] \(reviewItems.count) books need user review")
        }
    }
    
    private func showCompletionNotification() async {
        // Trigger UI notification - the ImportCompletionBanner observes shouldShowReviewModal
        let successCount = currentImport?.progress?.successfulImports ?? 0
        let reviewCount = needsUserReview.count
        
        if reviewCount > 0 {
            print("[BackgroundImportCoordinator] Import complete: \(successCount) books added, \(reviewCount) need review")
            // The banner will show automatically due to shouldShowReviewModal being true
        } else {
            print("[BackgroundImportCoordinator] Import complete: \(successCount) books added successfully")
            // Even without review items, we could show a simple success notification
            // For Phase 1, we'll keep it minimal and just log
        }
    }
}

// MARK: - Data Models

/// Represents a background import session
struct BackgroundImportSession {
    let csvSession: CSVImportSession
    let mappings: [String: BookField]
    let startTime: Date
    var progress: ImportProgress?
    
    var duration: TimeInterval {
        Date().timeIntervalSince(startTime)
    }
    
    var estimatedCompletion: Date? {
        guard let progress = progress,
              progress.estimatedTimeRemaining > 0 else { return nil }
        
        return Date().addingTimeInterval(progress.estimatedTimeRemaining)
    }
}

/// Item that needs user review
struct ReviewItem: Identifiable {
    let id = UUID()
    let bookTitle: String
    let author: String
    let issue: String
    let suggestions: [String]
}

/// Result of user review session
enum ReviewResult {
    case completed
    case cancelled
    case deferred
}