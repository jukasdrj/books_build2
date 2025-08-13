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
    
    // MARK: - Singleton
    
    static var shared: BackgroundImportCoordinator?
    
    static func initialize(with modelContext: ModelContext) -> BackgroundImportCoordinator {
        if let existing = shared {
            return existing
        }
        
        let coordinator = BackgroundImportCoordinator(modelContext: modelContext)
        shared = coordinator
        return coordinator
    }
    
    // MARK: - Import State
    
    private(set) var currentImport: BackgroundImportSession?
    private(set) var needsUserReview: [ReviewItem] = []
    private(set) var currentProgress: ImportProgress?
    
    // MARK: - Services
    
    private let csvImportService: CSVImportService
    private let modelContext: ModelContext
//    private let liveActivityManager = UnifiedLiveActivityManager.shared
    
    // MARK: - Monitoring State
    
    private var isMonitoring: Bool = false
    
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
        checkForExistingImport()
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
        
        currentImport = backgroundSession
        
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
                currentImport = nil
                currentProgress = nil
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
        
        // Stop monitoring and clear current import
        isMonitoring = false
        currentImport = nil
        currentProgress = nil
        
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
        
        csvImportService.cancelImport()
        
        // End the Live Activity
//        await liveActivityManager.endCurrentActivity()
        
        // Stop monitoring
        isMonitoring = false
        currentImport = nil
        currentProgress = nil
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
    
    // MARK: - Private Implementation
    
    private func checkForExistingImport() {
        // Check ImportStateManager for existing import
        if let resumableInfo = ImportStateManager.shared.getResumableImportInfo(),
           ImportStateManager.shared.canResumeImport() {
            
            print("[BackgroundImportCoordinator] Found existing import: \(resumableInfo.fileName)")
            
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
            
            currentImport = backgroundSession
            monitorImportProgress()
        }
    }
    
    private func monitorImportProgress() {
        // Prevent multiple monitoring tasks from running
        guard !isMonitoring else {
            print("[BackgroundImportCoordinator] Monitoring already in progress, skipping")
            return
        }
        
        // Only start monitoring if there's actually an import session
        guard currentImport != nil else {
            print("[BackgroundImportCoordinator] No active import session, skipping monitoring")
            return
        }
        
        isMonitoring = true
        print("[BackgroundImportCoordinator] Starting import progress monitoring")
        
        // Monitor the CSVImportService progress
        Task {
            while isImporting && isMonitoring {
                // Wait for import to actually start
                if let progress = csvImportService.importProgress {
                    print("[BackgroundImportCoordinator] Progress update: \(progress.processedBooks)/\(progress.totalBooks), step: \(progress.currentStep)")
                    currentProgress = progress
                    currentImport?.progress = progress
                    
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
                
                // Check every 2 seconds
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }
            
            isMonitoring = false
            print("[BackgroundImportCoordinator] Stopped import progress monitoring")
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