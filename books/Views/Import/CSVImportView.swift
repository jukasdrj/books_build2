//
//  CSVImportView.swift
//  books
//
//  Main CSV import interface
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct CSVImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appTheme) private var currentTheme
    @AppStorage("selectedTab") private var selectedTab = 0  // Add this to control tab selection
    
    @State private var importService: CSVImportService?
    @State private var showingFilePicker = false
    @State private var selectedFileURL: URL?
    @State private var importSession: CSVImportSession?
    @State private var currentStep: ImportStep = .selectFile
    @State private var columnMappings: [String: BookField] = [:]
    @State private var showingError = false
    @State private var errorMessage = ""
    
    enum ImportStep {
        case selectFile
        case preview
        case mapping
        case importing
        case completed
    }
    
    var body: some View {
        NavigationStack {
            if let importService = importService {
                VStack(spacing: 0) {
                    // Progress indicator
                    ImportProgressHeader(currentStep: currentStep)
                    
                    // Main content
                    Group {
                        switch currentStep {
                        case .selectFile:
                            FileSelectionView(
                                onSelectFile: { showingFilePicker = true },
                                selectedFile: selectedFileURL
                            )
                        case .preview:
                            if let session = importSession {
                                ImportPreviewView(
                                    session: session,
                                    onNext: proceedToMapping,
                                    onBack: { currentStep = .selectFile }
                                )
                            }
                        case .mapping:
                            if let session = importSession {
                                ColumnMappingView(
                                    session: session,
                                    columnMappings: $columnMappings,
                                    onNext: startImport,
                                    onBack: { currentStep = .preview }
                                )
                            }
                        case .importing:
                            ImportProgressView(
                                importService: importService,
                                onCancel: {
                                    importService.cancelImport()
                                    currentStep = .selectFile
                                }
                            )
                        case .completed:
                            if let result = importService.importResult {
                                ImportCompletedView(
                                    result: result,
                                    onViewLibrary: {
                                        // Navigate to Library tab then dismiss
                                        selectedTab = 0
                                        dismiss()
                                    },
                                    onImportAnother: {
                                        resetImport()
                                    }
                                )
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .background(currentTheme.surface)
                .navigationTitle("Import from Goodreads")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            if importService.isImporting {
                                importService.cancelImport()
                            }
                            dismiss()
                        }
                        .bodyMedium()
                    }
                }
                .fileImporter(
                    isPresented: $showingFilePicker,
                    allowedContentTypes: [.commaSeparatedText, .text],
                    allowsMultipleSelection: false
                ) { result in
                    handleFileSelection(result)
                }
                .onReceive(importService.objectWillChange) { _ in
                    if importService.importResult != nil, 
                       importService.importProgress?.isComplete == true {
                        currentStep = .completed
                    }
                }
                .alert("Import Error", isPresented: $showingError) {
                    Button("OK") { }
                } message: {
                    Text(errorMessage)
                }
            } else {
                // Loading state while service initializes
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                        .foregroundColor(currentTheme.primaryAction)
                    
                    Text("Initializing import service...")
                        .bodyMedium()
                        .foregroundColor(currentTheme.secondaryText)
                        .padding(.top, Theme.Spacing.md)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(currentTheme.surface)
                .navigationTitle("Import from Goodreads")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .bodyMedium()
                    }
                }
            }
        }
        .onAppear {
            if importService == nil {
                importService = CSVImportService(modelContext: modelContext)
            }
        }
    }
    
    // MARK: - File Handling
    
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            selectedFileURL = url
            parseSelectedFile(url)
            
        case .failure(let error):
            showError("File selection failed: \(error.localizedDescription)")
        }
    }
    
    private func parseSelectedFile(_ url: URL) {
        guard let importService = importService else { return }
        
        Task {
            do {
                let session = try await importService.parseCSVFile(from: url)
                await MainActor.run {
                    self.importSession = session
                    self.currentStep = .preview
                    
                    // Auto-populate column mappings
                    self.columnMappings = session.detectedColumns.reduce(into: [:]) { mappings, column in
                        if let field = column.mappedField {
                            mappings[column.originalName] = field
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    showError("Failed to parse CSV file: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Navigation
    
    private func proceedToMapping() {
        guard let session = importSession, let service = importService else { return }
        
        // Check if we have essential columns for automated import
        if canProceedDirectlyToImport() {
            // Skip mapping and go straight to import
            currentStep = .importing
            
            // Use detected mappings
            let detectedMappings = session.detectedColumns.reduce(into: [String: BookField]()) { mappings, column in
                if let field = column.mappedField {
                    mappings[column.originalName] = field
                }
            }
            
            service.importBooks(from: session, columnMappings: detectedMappings)
        } else {
            // Fall back to manual mapping
            currentStep = .mapping
        }
    }
    
    /// Check if we can proceed directly to import without manual mapping
    private func canProceedDirectlyToImport() -> Bool {
        guard let session = importSession else { return false }
        
        let detectedFields = Set(session.detectedColumns.compactMap { $0.mappedField })
        
        // We need either:
        // 1. ISBN column (for API lookup) OR
        // 2. Both title and author (for fallback)
        let hasISBN = detectedFields.contains(.isbn)
        let hasTitleAndAuthor = detectedFields.contains(.title) && detectedFields.contains(.author)
        
        return hasISBN || hasTitleAndAuthor
    }
    
    private func startImport() {
        guard let session = importSession, let service = importService else { return }
        
        currentStep = .importing
        service.importBooks(from: session, columnMappings: columnMappings)
    }
    
    private func resetImport() {
        importService?.resetImport()
        importSession = nil
        selectedFileURL = nil
        columnMappings = [:]
        currentStep = .selectFile
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}

// MARK: - Import Progress View

struct ImportProgressView: View {
    @Environment(\.appTheme) private var currentTheme
    @ObservedObject var importService: CSVImportService
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()
            
            // Progress Animation and Details
            progressContent
            
            Spacer()
            
            // Cancel Button
            cancelButton
        }
        .padding(Theme.Spacing.lg)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Import in progress")
        .accessibilityValue(importService.importProgress?.progress.formatted(.percent) ?? "Unknown progress")
    }
    
    // MARK: - Sub-views
    
    @ViewBuilder
    private var progressContent: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Progress Circle
            progressCircle
            
            // Status and Details
            if let progress = importService.importProgress {
                progressDetails(progress)
            }
        }
    }
    
    @ViewBuilder
    private var progressCircle: some View {
        ZStack {
            Circle()
                .stroke(currentTheme.outline, lineWidth: 8)
                .frame(width: 120, height: 120)
            
            if let progress = importService.importProgress {
                Circle()
                    .trim(from: 0, to: progress.progress)
                    .stroke(currentTheme.primaryAction, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(Theme.Animation.gentleSpring, value: progress.progress)
                
                VStack(spacing: Theme.Spacing.xs) {
                    percentageText(progress)
                    progressCountText(progress)
                }
            }
        }
    }
    
    @ViewBuilder
    private func percentageText(_ progress: ImportProgress) -> some View {
        Text("\(Int(progress.progress * 100))%")
            .titleLarge()
            .fontWeight(.bold)
            .foregroundColor(currentTheme.primaryText)
    }
    
    @ViewBuilder
    private func progressCountText(_ progress: ImportProgress) -> some View {
        Text("\(progress.processedBooks)/\(progress.totalBooks)")
            .labelMedium()
            .foregroundColor(currentTheme.secondaryText)
    }
    
    @ViewBuilder
    private func progressDetails(_ progress: ImportProgress) -> some View {
        VStack(spacing: Theme.Spacing.md) {
            // Current step
            Text(progress.currentStep.rawValue)
                .titleMedium()
                .foregroundColor(currentTheme.primaryText)
                .multilineTextAlignment(.center)
            
            // Progress message
            if !progress.message.isEmpty {
                Text(progress.message)
                    .labelMedium()
                    .foregroundColor(currentTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.md)
            }
            
            // Time remaining
            if progress.estimatedTimeRemaining > 0 {
                timeRemainingText(progress.estimatedTimeRemaining)
            }
            
            // Stats summary
            if progress.totalBooks > 0 {
                progressStats(progress)
            }
        }
    }
    
    @ViewBuilder
    private func timeRemainingText(_ timeRemaining: TimeInterval) -> some View {
        Text("Est. time remaining: \(formatTime(timeRemaining))")
            .labelSmall()
            .foregroundColor(currentTheme.secondaryText.opacity(0.8))
    }
    
    @ViewBuilder
    private func progressStats(_ progress: ImportProgress) -> some View {
        VStack(spacing: Theme.Spacing.sm) {
            HStack {
                ProgressStat(title: "Imported", value: progress.successfulImports, color: currentTheme.success)
                Spacer()
                ProgressStat(title: "Duplicates", value: progress.duplicatesSkipped, color: currentTheme.warning)
                Spacer()
                ProgressStat(title: "Failed", value: progress.failedImports, color: currentTheme.error)
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
    }
    
    @ViewBuilder
    private var cancelButton: some View {
        Button("Cancel Import") {
            onCancel()
        }
        .materialButton(style: .outlined, size: .large)
        .padding(.horizontal, Theme.Spacing.lg)
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        
        if minutes > 0 {
            return "\(minutes)m \(remainingSeconds)s"
        } else {
            return "\(remainingSeconds)s"
        }
    }
}

struct ProgressStat: View {
    @Environment(\.appTheme) private var currentTheme
    let title: String
    let value: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text("\(value)")
                .titleLarge()
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .labelSmall()
                .foregroundColor(currentTheme.secondaryText)
        }
    }
}

// MARK: - Import Completed View

struct ImportCompletedView: View {
    @Environment(\.appTheme) private var currentTheme
    let result: ImportResult
    let onViewLibrary: () -> Void
    let onImportAnother: () -> Void
    
    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()
            
            // Success Icon and Summary
            VStack(spacing: Theme.Spacing.lg) {
                // Success icon
                ZStack {
                    Circle()
                        .fill(currentTheme.successContainer)
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(currentTheme.success)
                }
                
                // Title and Summary
                VStack(spacing: Theme.Spacing.sm) {
                    Text("Import Complete!")
                        .titleLarge()
                        .fontWeight(.bold)
                        .foregroundColor(currentTheme.primaryText)
                        .multilineTextAlignment(.center)
                    
                    Text(result.summary)
                        .bodyMedium()
                        .foregroundColor(currentTheme.secondaryText)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Detailed Results
            VStack(spacing: Theme.Spacing.md) {
                ResultCard(
                    icon: "checkmark.circle",
                    title: "Successfully Imported",
                    value: "\(result.successfulImports) books",
                    color: currentTheme.success
                )
                
                if result.duplicatesSkipped > 0 {
                    VStack(spacing: Theme.Spacing.xs) {
                        ResultCard(
                            icon: "doc.on.doc",
                            title: "Duplicates Skipped",
                            value: "\(result.duplicatesSkipped) books",
                            color: currentTheme.warning
                        )
                        
                        // Show duplicate detection method breakdown
                        if result.duplicatesISBN > 0 || result.duplicatesGoogleID > 0 || result.duplicatesTitleAuthor > 0 {
                            HStack(spacing: Theme.Spacing.sm) {
                                Spacer()
                                    .frame(width: 46) // Align with card content
                                
                                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                    if result.duplicatesISBN > 0 {
                                        HStack(spacing: Theme.Spacing.xs) {
                                            Image(systemName: "barcode")
                                                .font(.caption)
                                                .foregroundColor(currentTheme.secondaryText)
                                            Text("\(result.duplicatesISBN) matched by ISBN")
                                                .labelSmall()
                                                .foregroundColor(currentTheme.secondaryText)
                                        }
                                    }
                                    
                                    if result.duplicatesGoogleID > 0 {
                                        HStack(spacing: Theme.Spacing.xs) {
                                            Image(systemName: "globe")
                                                .font(.caption)
                                                .foregroundColor(currentTheme.secondaryText)
                                            Text("\(result.duplicatesGoogleID) matched by Google Books ID")
                                                .labelSmall()
                                                .foregroundColor(currentTheme.secondaryText)
                                        }
                                    }
                                    
                                    if result.duplicatesTitleAuthor > 0 {
                                        HStack(spacing: Theme.Spacing.xs) {
                                            Image(systemName: "textformat")
                                                .font(.caption)
                                                .foregroundColor(currentTheme.secondaryText)
                                            Text("\(result.duplicatesTitleAuthor) matched by title/author")
                                                .labelSmall()
                                                .foregroundColor(currentTheme.secondaryText)
                                        }
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, Theme.Spacing.md)
                            .padding(.bottom, Theme.Spacing.sm)
                        }
                    }
                }
                
                if result.failedImports > 0 {
                    ResultCard(
                        icon: "exclamationmark.triangle",
                        title: "Failed to Import",
                        value: "\(result.failedImports) books",
                        color: currentTheme.error
                    )
                }
                
                // Duration
                ResultCard(
                    icon: "clock",
                    title: "Import Duration",
                    value: formatDuration(result.duration),
                    color: currentTheme.primaryAction
                )
            }
            .padding(.horizontal, Theme.Spacing.lg)
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: Theme.Spacing.md) {
                Button("View My Library") {
                    onViewLibrary()
                }
                .materialButton(style: .filled, size: .large)
                
                Button("Import Another File") {
                    onImportAnother()
                }
                .materialButton(style: .outlined, size: .large)
            }
            .padding(.horizontal, Theme.Spacing.lg)
        }
        .padding(Theme.Spacing.lg)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "\(Int(duration))s"
    }
}

struct ResultCard: View {
    @Environment(\.appTheme) private var currentTheme
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(title)
                    .labelMedium()
                    .foregroundColor(currentTheme.secondaryText)
                
                Text(value)
                    .bodyLarge()
                    .fontWeight(.semibold)
                    .foregroundColor(currentTheme.primaryText)
            }
            
            Spacer()
        }
        .padding(Theme.Spacing.md)
        .materialCard()
    }
}

// MARK: - Progress Header

struct ImportProgressHeader: View {
    @Environment(\.appTheme) private var currentTheme
    let currentStep: CSVImportView.ImportStep
    
    private let steps: [(CSVImportView.ImportStep, String)] = [
        (.selectFile, "Select"),
        (.preview, "Preview"),
        (.mapping, "Map"),
        (.importing, "Import"),
        (.completed, "Done")
    ]
    
    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            HStack {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(spacing: Theme.Spacing.xs) {
                        // Step circle
                        Circle()
                            .fill(stepColor(for: step.0))
                            .frame(width: 24, height: 24)
                            .overlay(
                                Text("\(index + 1)")
                                    .labelSmall()
                                    .fontWeight(.semibold)
                                    .foregroundColor(stepTextColor(for: step.0))
                            )
                        
                        // Step label
                        Text(step.1)
                            .labelMedium()
                            .foregroundColor(stepTextColor(for: step.0))
                        
                        // Connector line
                        if index < steps.count - 1 {
                            Rectangle()
                                .fill(isStepCompleted(step.0) ? currentTheme.primaryAction : currentTheme.outline)
                                .frame(height: 2)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            
            Divider()
        }
        .padding(.top, Theme.Spacing.md)
        .background(currentTheme.surface)
    }
    
    private func stepColor(for step: CSVImportView.ImportStep) -> Color {
        if isStepCompleted(step) || step == currentStep {
            return currentTheme.primaryAction
        } else {
            return currentTheme.outline
        }
    }
    
    private func stepTextColor(for step: CSVImportView.ImportStep) -> Color {
        if isStepCompleted(step) || step == currentStep {
            return currentTheme.primaryText
        } else {
            return currentTheme.secondaryText
        }
    }
    
    private func isStepCompleted(_ step: CSVImportView.ImportStep) -> Bool {
        let stepIndex = steps.firstIndex { $0.0 == step } ?? 0
        let currentIndex = steps.firstIndex { $0.0 == currentStep } ?? 0
        return stepIndex < currentIndex
    }
}

// MARK: - File Selection View

struct FileSelectionView: View {
    @Environment(\.appTheme) private var currentTheme
    let onSelectFile: () -> Void
    let selectedFile: URL?
    
    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            VStack(spacing: Theme.Spacing.lg) {
                // Icon
                Image(systemName: "doc.text.below.ecg")
                    .font(.system(size: 80))
                    .foregroundColor(currentTheme.primaryAction)
                
                // Title and description
                VStack(spacing: Theme.Spacing.sm) {
                    Text("Import Your Goodreads Library")
                        .titleLarge()
                        .foregroundColor(currentTheme.primaryText)
                        .multilineTextAlignment(.center)
                    
                    Text("Select your Goodreads export CSV file to import your books into your personal library.")
                        .bodyMedium()
                        .foregroundColor(currentTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Theme.Spacing.lg)
                }
            }
            
            // File selection area
            VStack(spacing: Theme.Spacing.md) {
                if let selectedFile = selectedFile {
                    // Show selected file
                    HStack(spacing: Theme.Spacing.md) {
                        Image(systemName: "doc.text")
                            .foregroundColor(currentTheme.primaryAction)
                        
                        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                            Text(selectedFile.lastPathComponent)
                                .bodyMedium()
                                .foregroundColor(currentTheme.primaryText)
                            
                            Text("Ready to import")
                                .labelSmall()
                                .foregroundColor(currentTheme.success)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(currentTheme.success)
                    }
                    .padding(Theme.Spacing.md)
                    .background(currentTheme.successContainer)
                    .materialCard()
                }
                
                // Select file button
                Button(action: onSelectFile) {
                    HStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: "folder")
                        Text(selectedFile == nil ? "Select CSV File" : "Choose Different File")
                            .labelLarge()
                    }
                    .frame(maxWidth: .infinity)
                }
                .materialButton(style: .filled, size: .large)
                .padding(.horizontal, Theme.Spacing.lg)
            }
            
            // Instructions
            InstructionsCard()
            
            Spacer()
        }
        .padding(Theme.Spacing.lg)
    }
}

// MARK: - Instructions Card

struct InstructionsCard: View {
    @Environment(\.appTheme) private var currentTheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "info.circle")
                    .foregroundColor(currentTheme.primaryAction)
                Text("How to export from Goodreads")
                    .titleSmall()
                    .foregroundColor(currentTheme.primaryText)
            }
            
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                InstructionStep(number: 1, text: "Go to goodreads.com and sign in")
                InstructionStep(number: 2, text: "Visit 'My Books' → 'Import and export'")
                InstructionStep(number: 3, text: "Click 'Export Library' and download CSV")
                InstructionStep(number: 4, text: "Select the downloaded file here")
            }
        }
        .padding(Theme.Spacing.md)
        .materialCard()
    }
}

struct InstructionStep: View {
    @Environment(\.appTheme) private var currentTheme
    let number: Int
    let text: String
    
    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Text("\(number)")
                .labelSmall()
                .fontWeight(.bold)
                .foregroundColor(currentTheme.onPrimary)
                .frame(width: 20, height: 20)
                .background(currentTheme.primaryAction)
                .clipShape(Circle())
            
            Text(text)
                .bodyMedium()
                .foregroundColor(currentTheme.primaryText)
        }
    }
}

// MARK: - Model Container Extension for Previews

extension ModelContainer {
    static var preview: ModelContainer {
        do {
            let container = try ModelContainer(
                for: UserBook.self, BookMetadata.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            return container
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }
}

#Preview {
    CSVImportView()
        .modelContainer(ModelContainer.preview)
        .preferredColorScheme(.dark)
}