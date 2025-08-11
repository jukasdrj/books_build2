import Foundation
import SwiftUI
import SwiftData

/// View model for managing library reset with iOS-compliant confirmation flow
@MainActor
class LibraryResetViewModel: ObservableObject {
    
    // MARK: - Confirmation States
    
    enum ConfirmationStep {
        case initial
        case warning
        case typeToConfirm
        case holdToConfirm
        case exporting
        case finalConfirmation
    }
    
    // MARK: - Properties
    
    @Published var currentStep: ConfirmationStep = .initial
    @Published var showingResetSheet = false
    @Published var confirmationText = ""
    @Published var isHoldingButton = false
    @Published var holdProgress: Double = 0.0
    @Published var showingExportOptions = false
    @Published var showingShareSheet = false
    @Published var exportCompleted = false
    
    // Required confirmation text
    let requiredConfirmationText = "RESET"
    let requiredHoldDuration: TimeInterval = 3.0
    
    // Service
    private let resetService: LibraryResetService
    private let hapticManager = HapticFeedbackManager.shared
    
    // Hold timer
    private var holdTimer: Timer?
    private var holdStartTime: Date?
    
    // MARK: - Computed Properties
    
    var canProceedFromTypeConfirm: Bool {
        confirmationText.uppercased() == requiredConfirmationText
    }
    
    var itemsToDeleteDescription: String {
        let books = resetService.booksToDelete
        let metadata = resetService.metadataToDelete
        
        if books == 0 {
            return "Your library is already empty"
        }
        
        let bookText = books == 1 ? "1 book" : "\(books) books"
        let metadataText = metadata == 1 ? "1 metadata entry" : "\(metadata) metadata entries"
        
        return "This will permanently delete \(bookText) and \(metadataText)"
    }
    
    var exportedFileURL: URL? {
        resetService.exportedFileURL
    }
    
    var isResetting: Bool {
        if case .resetting = resetService.resetState {
            return true
        }
        return false
    }
    
    var resetCompleted: Bool {
        if case .completed = resetService.resetState {
            return true
        }
        return false
    }
    
    var resetError: Error? {
        if case .failed(let error) = resetService.resetState {
            return error
        }
        return nil
    }
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.resetService = LibraryResetService(modelContext: modelContext)
    }
    
    // MARK: - Public Methods
    
    /// Start the reset flow
    func startResetFlow() async {
        await resetService.countItemsToDelete()
        
        // Don't show reset flow if library is empty
        if resetService.booksToDelete == 0 {
            return
        }
        
        currentStep = .initial
        showingResetSheet = true
        await hapticManager.warning()
    }
    
    /// Proceed to next step
    func proceedToNextStep() async {
        await hapticManager.impact()
        
        switch currentStep {
        case .initial:
            currentStep = .warning
        case .warning:
            currentStep = .typeToConfirm
        case .typeToConfirm:
            if canProceedFromTypeConfirm {
                currentStep = .holdToConfirm
            }
        case .holdToConfirm:
            // Handled by hold completion
            break
        case .exporting:
            currentStep = .finalConfirmation
        case .finalConfirmation:
            await performReset()
        }
    }
    
    /// Go back to previous step
    func goBackToPreviousStep() async {
        await hapticManager.impact()
        
        switch currentStep {
        case .initial:
            cancel()
        case .warning:
            currentStep = .initial
        case .typeToConfirm:
            currentStep = .warning
            confirmationText = ""
        case .holdToConfirm:
            currentStep = .typeToConfirm
        case .exporting:
            currentStep = .holdToConfirm
        case .finalConfirmation:
            currentStep = exportCompleted ? .exporting : .holdToConfirm
        }
    }
    
    /// Cancel the reset flow
    func cancel() {
        showingResetSheet = false
        currentStep = .initial
        confirmationText = ""
        holdProgress = 0.0
        exportCompleted = false
        resetService.cancelReset()
        Task {
            await hapticManager.impact()
        }
    }
    
    /// Start hold-to-confirm
    func startHoldToConfirm() {
        isHoldingButton = true
        holdStartTime = Date()
        holdProgress = 0.0
        
        Task {
            await hapticManager.impactHeavy()
        }
        
        // Start timer to update progress
        holdTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateHoldProgress()
            }
        }
    }
    
    /// Stop hold-to-confirm
    func stopHoldToConfirm() {
        isHoldingButton = false
        holdTimer?.invalidate()
        holdTimer = nil
        
        // Reset progress if not completed
        if holdProgress < 1.0 {
            withAnimation(.easeOut(duration: 0.2)) {
                holdProgress = 0.0
            }
            Task {
                await hapticManager.impact()
            }
        }
    }
    
    /// Export library data
    func exportLibraryData(format: LibraryResetService.ExportFormat = .csv) async {
        currentStep = .exporting
        
        do {
            let fileURL = try await resetService.exportLibraryData(format: format)
            exportCompleted = true
            showingShareSheet = true
            await hapticManager.success()
            
            print("[LibraryResetViewModel] Export completed: \(fileURL)")
        } catch {
            print("[LibraryResetViewModel] Export failed: \(error)")
            await hapticManager.error()
            // Show error but allow proceeding without export
            exportCompleted = false
        }
    }
    
    /// Skip export and proceed
    func skipExport() async {
        exportCompleted = false
        currentStep = .finalConfirmation
        await hapticManager.warning()
    }
    
    /// Perform the actual reset
    private func performReset() async {
        do {
            try await resetService.resetLibrary()
            
            // Wait a moment for animation
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            // Close sheet and reset state
            showingResetSheet = false
            resetService.resetToIdle()
            currentStep = .initial
            confirmationText = ""
            holdProgress = 0.0
            exportCompleted = false
            
        } catch {
            print("[LibraryResetViewModel] Reset failed: \(error)")
            await hapticManager.error()
        }
    }
    
    // MARK: - Private Methods
    
    private func updateHoldProgress() {
        guard let startTime = holdStartTime, isHoldingButton else { return }
        
        let elapsed = Date().timeIntervalSince(startTime)
        let progress = min(elapsed / requiredHoldDuration, 1.0)
        
        withAnimation(.linear(duration: 0.05)) {
            holdProgress = progress
        }
        
        // Haptic feedback at intervals
        if progress > 0.25 && progress < 0.3 {
            Task { await hapticManager.impact() }
        } else if progress > 0.5 && progress < 0.55 {
            Task { await hapticManager.impact() }
        } else if progress > 0.75 && progress < 0.8 {
            Task { await hapticManager.impactHeavy() }
        }
        
        // Complete if held long enough
        if progress >= 1.0 {
            holdTimer?.invalidate()
            holdTimer = nil
            isHoldingButton = false
            
            Task { @MainActor in
                await hapticManager.success()
                // Show export options
                showingExportOptions = true
                // Move to the exporting step
                currentStep = .exporting
            }
        }
    }
}