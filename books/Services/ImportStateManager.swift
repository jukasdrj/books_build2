//
//  ImportStateManager.swift
//  books
//
//  Manages persistent state for CSV import operations
//

import Foundation
import SwiftData

/// Manages persistence and recovery of CSV import state across app lifecycle
@MainActor
class ImportStateManager: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = ImportStateManager()
    
    // MARK: - Configuration
    
    private let userDefaults = UserDefaults.standard
    private let stateKey = "csvImportState"
    private let sessionKey = "csvImportSession"
    
    // MARK: - Published Properties
    
    @Published private(set) var hasActiveImport: Bool = false
    @Published private(set) var currentImportId: UUID?
    @Published private(set) var persistedProgress: ImportProgress?
    
    // MARK: - Private Properties
    
    private var modelContext: ModelContext?
    
    // MARK: - Initialization
    
    private init() {
        checkForActiveImport()
        setupNotificationObservers()
    }
    
    // MARK: - Public Interface
    
    /// Set the model context for database operations
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    /// Save current import state
    func saveImportState(
        progress: ImportProgress,
        session: CSVImportSession,
        columnMappings: [String: BookField]
    ) {
        let state = PersistedImportState(
            id: progress.sessionId,
            progress: progress,
            session: session,
            columnMappings: columnMappings,
            lastUpdated: Date()
        )
        
        do {
            let encoded = try JSONEncoder().encode(state)
            userDefaults.set(encoded, forKey: stateKey)
            
            hasActiveImport = true
            currentImportId = progress.sessionId
            persistedProgress = progress
            
            print("[ImportStateManager] Saved import state for session: \(progress.sessionId)")
        } catch {
            print("[ImportStateManager] Failed to save import state: \(error)")
        }
    }
    
    /// Load persisted import state
    func loadImportState() -> PersistedImportState? {
        guard let data = userDefaults.data(forKey: stateKey) else { return nil }
        
        do {
            let state = try JSONDecoder().decode(PersistedImportState.self, from: data)
            
            // Check if state is not too old (prevent resuming very old imports)
            let maxAge: TimeInterval = 24 * 60 * 60 // 24 hours
            if Date().timeIntervalSince(state.lastUpdated) > maxAge {
                print("[ImportStateManager] Import state too old, clearing")
                clearImportState()
                return nil
            }
            
            hasActiveImport = true
            currentImportId = state.id
            persistedProgress = state.progress
            
            print("[ImportStateManager] Loaded import state for session: \(state.id)")
            return state
        } catch {
            print("[ImportStateManager] Failed to load import state: \(error)")
            clearImportState()
            return nil
        }
    }
    
    /// Clear persisted import state
    func clearImportState() {
        userDefaults.removeObject(forKey: stateKey)
        userDefaults.removeObject(forKey: sessionKey)
        
        hasActiveImport = false
        currentImportId = nil
        persistedProgress = nil
        
        print("[ImportStateManager] Cleared import state")
    }
    
    /// Update progress for current import
    func updateProgress(_ progress: ImportProgress) {
        persistedProgress = progress
        
        // Update the stored state with new progress
        if let state = loadImportState() {
            saveImportState(
                progress: progress,
                session: state.session,
                columnMappings: state.columnMappings
            )
        }
    }
    
    /// Mark import as completed
    func markImportCompleted() {
        hasActiveImport = false
        currentImportId = nil
        persistedProgress = nil
        clearImportState()
        
        print("[ImportStateManager] Marked import as completed")
    }
    
    /// Check if there's a resumable import
    func canResumeImport() -> Bool {
        guard let state = loadImportState() else { return false }
        
        // Can resume if import is not completed and not cancelled
        return !state.progress.isComplete && !state.progress.isCancelled
    }
    
    // MARK: - Background State Management
    
    /// Save critical import state before app termination
    func saveStateForTermination() {
        guard let progress = persistedProgress,
              let state = loadImportState() else { return }
        
        // Update progress to indicate graceful shutdown
        var updatedProgress = progress
        updatedProgress.message = "Import paused - will resume when app reopens"
        
        saveImportState(
            progress: updatedProgress,
            session: state.session,
            columnMappings: state.columnMappings
        )
        
        print("[ImportStateManager] Saved state for app termination")
    }
    
    /// Handle background task expiration
    func handleBackgroundExpiration() {
        guard let progress = persistedProgress,
              let state = loadImportState() else { return }
        
        // Mark as paused due to background limits
        var updatedProgress = progress
        updatedProgress.message = "Import paused - background time expired"
        
        saveImportState(
            progress: updatedProgress,
            session: state.session,
            columnMappings: state.columnMappings
        )
        
        print("[ImportStateManager] Handled background task expiration")
    }
    
    // MARK: - Recovery
    
    /// Get resumable import information for UI
    func getResumableImportInfo() -> ResumableImportInfo? {
        guard let state = loadImportState(), canResumeImport() else { return nil }
        
        return ResumableImportInfo(
            sessionId: state.id,
            fileName: state.session.fileName,
            progress: state.progress,
            lastUpdated: state.lastUpdated,
            estimatedBooksRemaining: state.progress.totalBooks - state.progress.processedBooks
        )
    }
    
    // MARK: - Private Implementation
    
    private func checkForActiveImport() {
        if let state = loadImportState() {
            hasActiveImport = !state.progress.isComplete && !state.progress.isCancelled
            currentImportId = hasActiveImport ? state.id : nil
            persistedProgress = hasActiveImport ? state.progress : nil
        }
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleBackgroundTaskWillExpire),
            name: .backgroundTaskWillExpire,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppWillTerminate),
            name: .appWillTerminate,
            object: nil
        )
    }
    
    @objc private func handleBackgroundTaskWillExpire() {
        handleBackgroundExpiration()
    }
    
    @objc private func handleAppWillTerminate() {
        saveStateForTermination()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Data Models

/// Persistent import state that survives app lifecycle
struct PersistedImportState: Codable {
    let id: UUID
    let progress: ImportProgress
    let session: CSVImportSession
    let columnMappings: [String: BookField]
    let lastUpdated: Date
}

/// Information about a resumable import for UI display
struct ResumableImportInfo {
    let sessionId: UUID
    let fileName: String
    let progress: ImportProgress
    let lastUpdated: Date
    let estimatedBooksRemaining: Int
    
    var formattedLastUpdated: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastUpdated, relativeTo: Date())
    }
    
    var progressPercentage: Double {
        guard progress.totalBooks > 0 else { return 0 }
        return Double(progress.processedBooks) / Double(progress.totalBooks)
    }
}

// MARK: - Extended ImportProgress for Codable

extension ImportProgress: Codable {
    enum CodingKeys: String, CodingKey {
        case sessionId, currentStep, message, processedBooks, totalBooks
        case successfulImports, duplicatesSkipped, duplicatesISBN
        case duplicatesGoogleID, duplicatesTitleAuthor, failedImports
        case errors, estimatedTimeRemaining, startTime, endTime
        case isCancelled, retryAttempts, successfulRetries, failedRetries
        case maxRetryAttempts, circuitBreakerTriggered, finalFailureReasons
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(sessionId, forKey: .sessionId)
        try container.encode(currentStep.rawValue, forKey: .currentStep)
        try container.encode(message, forKey: .message)
        try container.encode(processedBooks, forKey: .processedBooks)
        try container.encode(totalBooks, forKey: .totalBooks)
        try container.encode(successfulImports, forKey: .successfulImports)
        try container.encode(duplicatesSkipped, forKey: .duplicatesSkipped)
        try container.encode(duplicatesISBN, forKey: .duplicatesISBN)
        try container.encode(duplicatesGoogleID, forKey: .duplicatesGoogleID)
        try container.encode(duplicatesTitleAuthor, forKey: .duplicatesTitleAuthor)
        try container.encode(failedImports, forKey: .failedImports)
        try container.encode(estimatedTimeRemaining, forKey: .estimatedTimeRemaining)
        try container.encode(startTime, forKey: .startTime)
        try container.encode(endTime, forKey: .endTime)
        try container.encode(isCancelled, forKey: .isCancelled)
        try container.encode(retryAttempts, forKey: .retryAttempts)
        try container.encode(successfulRetries, forKey: .successfulRetries)
        try container.encode(failedRetries, forKey: .failedRetries)
        try container.encode(maxRetryAttempts, forKey: .maxRetryAttempts)
        try container.encode(circuitBreakerTriggered, forKey: .circuitBreakerTriggered)
        try container.encode(finalFailureReasons, forKey: .finalFailureReasons)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.sessionId = try container.decode(UUID.self, forKey: .sessionId)
        
        let stepRawValue = try container.decode(String.self, forKey: .currentStep)
        self.currentStep = ImportStep(rawValue: stepRawValue) ?? .preparing
        
        self.message = try container.decode(String.self, forKey: .message)
        self.processedBooks = try container.decode(Int.self, forKey: .processedBooks)
        self.totalBooks = try container.decode(Int.self, forKey: .totalBooks)
        self.successfulImports = try container.decode(Int.self, forKey: .successfulImports)
        self.duplicatesSkipped = try container.decode(Int.self, forKey: .duplicatesSkipped)
        self.duplicatesISBN = try container.decode(Int.self, forKey: .duplicatesISBN)
        self.duplicatesGoogleID = try container.decode(Int.self, forKey: .duplicatesGoogleID)
        self.duplicatesTitleAuthor = try container.decode(Int.self, forKey: .duplicatesTitleAuthor)
        self.failedImports = try container.decode(Int.self, forKey: .failedImports)
        self.errors = [] // Errors don't need to persist
        self.estimatedTimeRemaining = try container.decode(TimeInterval.self, forKey: .estimatedTimeRemaining)
        self.startTime = try container.decode(Date?.self, forKey: .startTime)
        self.endTime = try container.decode(Date?.self, forKey: .endTime)
        self.isCancelled = try container.decode(Bool.self, forKey: .isCancelled)
        self.retryAttempts = try container.decode(Int.self, forKey: .retryAttempts)
        self.successfulRetries = try container.decode(Int.self, forKey: .successfulRetries)
        self.failedRetries = try container.decode(Int.self, forKey: .failedRetries)
        self.maxRetryAttempts = try container.decode(Int.self, forKey: .maxRetryAttempts)
        self.circuitBreakerTriggered = try container.decode(Bool.self, forKey: .circuitBreakerTriggered)
        self.finalFailureReasons = try container.decode([String: Int].self, forKey: .finalFailureReasons)
    }
}