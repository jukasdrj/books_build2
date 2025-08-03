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
                .background(Color.theme.surface)
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
                    if let result = importService.importResult, 
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
                        .foregroundColor(Color.theme.primaryAction)
                    
                    Text("Initializing import service...")
                        .bodyMedium()
                        .foregroundColor(Color.theme.secondaryText)
                        .padding(.top, Theme.Spacing.md)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.theme.surface)
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
    @ObservedObject var importService: CSVImportService
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()
            
            // Progress Animation
            VStack(spacing: Theme.Spacing.lg) {
                ZStack {
                    Circle()
                        .stroke(Color.theme.outline, lineWidth: 8)
                        .frame(width: 120, height: 120)
                    
                    if let progress = importService.importProgress {
                        Circle()
                            .trim(from: 0, to: progress.progress)
                            .stroke(Color.theme.primaryAction, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 120, height: 120)
                            .rotationEffect(.degrees(-90))
                            .animation(Theme.Animation.gentleSpring, value: progress.progress)
                        
                        VStack(spacing: Theme.Spacing.xs) {
                            Text("\(Int(progress.progress * 100))%")
                                .titleLarge()
                                .fontWeight(.bold)
                                .foregroundColor(Color.theme.primaryText)
                            
                            Text("\(progress.processedBooks)/\(progress.totalBooks)")
                                .labelMedium()
                                .foregroundColor(Color.theme.secondaryText)
                        }
                    }
                }
                
                // Status and Progress Details
                VStack(spacing: Theme.Spacing.md) {
                    if let progress = importService.importProgress {
                        Text(progress.currentStep.rawValue)
                            .titleMedium()
                            .foregroundColor(Color.theme.primaryText)
                            .multilineTextAlignment(.center)
                        
                        // Progress Summary
                        if progress.totalBooks > 0 {
                            VStack(spacing: Theme.Spacing.sm) {
                                HStack {
                                    ProgressStat(title: "Imported", value: progress.successfulImports, color: Color.theme.success)
                                    Spacer()
                                    ProgressStat(title: "Duplicates", value: progress.duplicatesSkipped, color: Color.theme.warning)
                                    Spacer()
                                    ProgressStat(title: "Failed", value: progress.failedImports, color: Color.theme.error)
                                }
                            }
                            .padding(.horizontal, Theme.Spacing.lg)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Cancel Button
            Button("Cancel Import") {
                onCancel()
            }
            .materialButton(style: .outlined, size: .large)
            .padding(.horizontal, Theme.Spacing.lg)
        }
        .padding(Theme.Spacing.lg)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Import in progress")
        .accessibilityValue(importService.importProgress?.progress.formatted(.percent) ?? "Unknown progress")
    }
}

struct ProgressStat: View {
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
                .foregroundColor(Color.theme.secondaryText)
        }
    }
}

// MARK: - Import Completed View

struct ImportCompletedView: View {
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
                        .fill(Color.theme.successContainer)
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(Color.theme.success)
                }
                
                // Title and Summary
                VStack(spacing: Theme.Spacing.sm) {
                    Text("Import Complete!")
                        .titleLarge()
                        .fontWeight(.bold)
                        .foregroundColor(Color.theme.primaryText)
                        .multilineTextAlignment(.center)
                    
                    Text(result.summary)
                        .bodyMedium()
                        .foregroundColor(Color.theme.secondaryText)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Detailed Results
            VStack(spacing: Theme.Spacing.md) {
                ResultCard(
                    icon: "checkmark.circle",
                    title: "Successfully Imported",
                    value: "\(result.successfulImports) books",
                    color: Color.theme.success
                )
                
                if result.duplicatesSkipped > 0 {
                    ResultCard(
                        icon: "doc.on.doc",
                        title: "Duplicates Skipped",
                        value: "\(result.duplicatesSkipped) books",
                        color: Color.theme.warning
                    )
                }
                
                if result.failedImports > 0 {
                    ResultCard(
                        icon: "exclamationmark.triangle",
                        title: "Failed to Import",
                        value: "\(result.failedImports) books",
                        color: Color.theme.error
                    )
                }
                
                // Duration
                ResultCard(
                    icon: "clock",
                    title: "Import Duration",
                    value: formatDuration(result.duration),
                    color: Color.theme.primaryAction
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
                    .foregroundColor(Color.theme.secondaryText)
                
                Text(value)
                    .bodyLarge()
                    .fontWeight(.semibold)
                    .foregroundColor(Color.theme.primaryText)
            }
            
            Spacer()
        }
        .padding(Theme.Spacing.md)
        .materialCard()
    }
}

// MARK: - Progress Header

struct ImportProgressHeader: View {
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
                                .fill(isStepCompleted(step.0) ? Color.theme.primaryAction : Color.theme.outline)
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
        .background(Color.theme.surface)
    }
    
    private func stepColor(for step: CSVImportView.ImportStep) -> Color {
        if isStepCompleted(step) || step == currentStep {
            return Color.theme.primaryAction
        } else {
            return Color.theme.outline
        }
    }
    
    private func stepTextColor(for step: CSVImportView.ImportStep) -> Color {
        if isStepCompleted(step) || step == currentStep {
            return Color.theme.primaryText
        } else {
            return Color.theme.secondaryText
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
    let onSelectFile: () -> Void
    let selectedFile: URL?
    
    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            VStack(spacing: Theme.Spacing.lg) {
                // Icon
                Image(systemName: "doc.text.below.ecg")
                    .font(.system(size: 80))
                    .foregroundColor(Color.theme.primaryAction)
                
                // Title and description
                VStack(spacing: Theme.Spacing.sm) {
                    Text("Import Your Goodreads Library")
                        .titleLarge()
                        .foregroundColor(Color.theme.primaryText)
                        .multilineTextAlignment(.center)
                    
                    Text("Select your Goodreads export CSV file to import your books into your personal library.")
                        .bodyMedium()
                        .foregroundColor(Color.theme.secondaryText)
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
                            .foregroundColor(Color.theme.primaryAction)
                        
                        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                            Text(selectedFile.lastPathComponent)
                                .bodyMedium()
                                .foregroundColor(Color.theme.primaryText)
                            
                            Text("Ready to import")
                                .labelSmall()
                                .foregroundColor(Color.theme.success)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color.theme.success)
                    }
                    .padding(Theme.Spacing.md)
                    .materialCard(backgroundColor: Color.theme.successContainer)
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
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "info.circle")
                    .foregroundColor(Color.theme.primaryAction)
                Text("How to export from Goodreads")
                    .titleSmall()
                    .foregroundColor(Color.theme.primaryText)
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
    let number: Int
    let text: String
    
    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Text("\(number)")
                .labelSmall()
                .fontWeight(.bold)
                .foregroundColor(Color.theme.onPrimary)
                .frame(width: 20, height: 20)
                .background(Color.theme.primaryAction)
                .clipShape(Circle())
            
            Text(text)
                .bodyMedium()
                .foregroundColor(Color.theme.primaryText)
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