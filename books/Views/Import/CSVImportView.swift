//
//  CSVImportView.swift
//  books
//
//  Main CSV import interface
//

import SwiftUI
import UniformTypeIdentifiers

struct CSVImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @StateObject private var importService: CSVImportService
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
    
    init() {
        // We'll initialize this properly when we have access to modelContext
        self._importService = StateObject(wrappedValue: CSVImportService(modelContext: ModelContext(.init(for: UserBook.self))))
    }
    
    var body: some View {
        NavigationStack {
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
                }
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.commaSeparatedText, .text],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
        .onReceive(importService.$importResult) { result in
            if result != nil && importService.importProgress?.isComplete == true {
                currentStep = .completed
            }
        }
        .onAppear {
            // Reinitialize service with proper context
            let newService = CSVImportService(modelContext: modelContext)
            // Transfer any existing state if needed
            self.importService.resetImport()
        }
        .alert("Import Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
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
        currentStep = .mapping
    }
    
    private func startImport() {
        currentStep = .importing
        
        guard let session = importSession else { return }
        importService.importBooks(from: session, columnMappings: columnMappings)
    }
    
    private func resetImport() {
        importService.resetImport()
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

#Preview {
    CSVImportView()
        .modelContainer(for: [UserBook.self, BookMetadata.self], inMemory: true)
}