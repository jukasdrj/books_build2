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
    
    // MARK: - Import State
    
    private(set) var currentImport: BackgroundImportSession?
    private(set) var needsUserReview: [ReviewItem] = []
    
    // MARK: - Services
    
    private let csvImportService: CSVImportService
    private let modelContext: ModelContext
    
    // MARK: - Computed Properties
    
    var isImporting: Bool { 
        currentImport != nil 
    }
    
    var progress: ImportProgress? { 
        currentImport?.progress 
    }
    
    var shouldShowReviewModal: Bool {
        !needsUserReview.isEmpty
    }
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
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
        
        // Start the import in background using existing service
        // The CSVImportService will insert books into modelContext as they're processed
        // This automatically triggers @Query updates in LibraryView for seamless integration
        await csvImportService.importBooks(from: session, columnMappings: mappings)
        
        // Monitor for completion
        monitorImportProgress()
    }
    
    /// Handle completion - check for review needs
    func handleImportCompletion() async {
        guard let session = currentImport else { return }
        
        print("[BackgroundImportCoordinator] Import completed for session: \(session.csvSession.id)")
        
        // Check if any books need user review (ambiguous matches, no matches, etc.)
        await checkForReviewNeeds()
        
        // Clear current import
        currentImport = nil
        
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
    func cancelImport() {
        guard currentImport != nil else { return }
        
        csvImportService.cancelImport()
        currentImport = nil
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
        // Monitor the CSVImportService progress
        Task {
            while isImporting {
                if let progress = csvImportService.importProgress {
                    currentImport?.progress = progress
                    
                    // Check for completion
                    if progress.isComplete {
                        await handleImportCompletion()
                        break
                    }
                }
                
                // Check every 2 seconds
                try? await Task.sleep(nanoseconds: 2_000_000_000)
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