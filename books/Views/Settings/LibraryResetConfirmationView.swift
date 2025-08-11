import SwiftUI
import SwiftData

/// Multi-step confirmation view for library reset following iOS 18 HIG
struct LibraryResetConfirmationView: View {
    @StateObject private var viewModel: LibraryResetViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.themeStore) private var themeStore
    
    init(modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: LibraryResetViewModel(modelContext: modelContext))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress indicator
                ProgressIndicatorView(step: viewModel.currentStep)
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                
                // Content based on current step
                ScrollView {
                    VStack(spacing: Theme.Spacing.xxl) {
                        switch viewModel.currentStep {
                        case .initial:
                            InitialWarningView(itemsDescription: viewModel.itemsToDeleteDescription)
                        case .warning:
                            DetailedWarningView()
                        case .typeToConfirm:
                            TypeToConfirmView(
                                confirmationText: $viewModel.confirmationText,
                                requiredText: viewModel.requiredConfirmationText
                            )
                        case .holdToConfirm:
                            HoldToConfirmView(
                                isHolding: $viewModel.isHoldingButton,
                                holdProgress: viewModel.holdProgress,
                                onStart: viewModel.startHoldToConfirm,
                                onStop: viewModel.stopHoldToConfirm
                            )
                        case .exporting:
                            ExportOptionsView(
                                onExportCSV: { await viewModel.exportLibraryData(format: .csv) },
                                onExportJSON: { await viewModel.exportLibraryData(format: .json) },
                                onSkip: { await viewModel.skipExport() },
                                exportCompleted: viewModel.exportCompleted
                            )
                        case .finalConfirmation:
                            FinalConfirmationView(
                                didExport: viewModel.exportCompleted,
                                isResetting: viewModel.isResetting
                            )
                        }
                    }
                    .padding()
                }
                
                // Action buttons
                actionButtons
            }
            .navigationTitle("Reset Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.cancel()
                        dismiss()
                    }
                    .foregroundColor(themeStore.appTheme.primary)
                }
            }
            .sheet(isPresented: $viewModel.showingShareSheet) {
                if let fileURL = viewModel.exportedFileURL {
                    ShareSheet(items: [fileURL])
                }
            }
            .alert("Reset Complete", isPresented: .constant(viewModel.resetCompleted)) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your library has been reset. The app will return to the home screen.")
            }
            .alert("Reset Failed", isPresented: .constant(viewModel.resetError != nil)) {
                Button("OK") {
                    viewModel.cancel()
                    dismiss()
                }
            } message: {
                if let error = viewModel.resetError {
                    Text(error.localizedDescription)
                }
            }
        }
    }
    
    @ViewBuilder
    private var actionButtons: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Back button (except on initial step)
            if viewModel.currentStep != .initial {
                Button(action: {
                    Task {
                        await viewModel.goBackToPreviousStep()
                    }
                }) {
                    Label("Back", systemImage: "chevron.left")
                        .frame(maxWidth: .infinity)
                }
                .materialButton(style: .tonal)
            }
            
            // Next/Action button
            if viewModel.currentStep == .holdToConfirm {
                // Special handling for hold-to-confirm step
                Label(actionButtonTitle, systemImage: actionButtonIcon)
                    .frame(maxWidth: .infinity)
                    .materialButton(style: actionButtonStyle)
                    .onLongPressGesture(
                        minimumDuration: .infinity,
                        maximumDistance: .infinity,
                        pressing: { isPressing in
                            if isPressing {
                                viewModel.startHoldToConfirm()
                            } else {
                                viewModel.stopHoldToConfirm()
                            }
                        },
                        perform: {}
                    )
            } else {
                Button(action: {
                    Task {
                        await viewModel.proceedToNextStep()
                    }
                }) {
                    Label(actionButtonTitle, systemImage: actionButtonIcon)
                        .frame(maxWidth: .infinity)
                }
                .materialButton(style: actionButtonStyle)
                .disabled(!canProceed)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    private var actionButtonTitle: String {
        switch viewModel.currentStep {
        case .initial:
            return "Continue"
        case .warning:
            return "I Understand"
        case .typeToConfirm:
            return "Proceed"
        case .holdToConfirm:
            return "Hold to Confirm"
        case .exporting:
            return viewModel.exportCompleted ? "Continue" : "Skip Export"
        case .finalConfirmation:
            return viewModel.isResetting ? "Resetting..." : "Reset Library"
        }
    }
    
    private var actionButtonIcon: String {
        switch viewModel.currentStep {
        case .initial:
            return "exclamationmark.triangle"
        case .warning:
            return "checkmark.circle"
        case .typeToConfirm:
            return "arrow.right"
        case .holdToConfirm:
            return "hand.raised"
        case .exporting:
            return viewModel.exportCompleted ? "checkmark" : "arrow.right"
        case .finalConfirmation:
            return viewModel.isResetting ? "arrow.triangle.2.circlepath" : "trash"
        }
    }
    
    private var actionButtonStyle: MaterialButtonStyle {
        switch viewModel.currentStep {
        case .finalConfirmation:
            return .destructive
        case .exporting where !viewModel.exportCompleted:
            return .tonal
        default:
            return .filled
        }
    }
    
    private var canProceed: Bool {
        switch viewModel.currentStep {
        case .typeToConfirm:
            return viewModel.canProceedFromTypeConfirm
        case .holdToConfirm:
            return false // Handled by hold gesture
        case .finalConfirmation:
            return !viewModel.isResetting
        default:
            return true
        }
    }
}

// MARK: - Step Views

struct ProgressIndicatorView: View {
    let step: LibraryResetViewModel.ConfirmationStep
    @Environment(\.themeStore) private var themeStore
    
    private var stepNumber: Int {
        switch step {
        case .initial: return 1
        case .warning: return 2
        case .typeToConfirm: return 3
        case .holdToConfirm: return 4
        case .exporting: return 5
        case .finalConfirmation: return 6
        }
    }
    
    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ForEach(1...6, id: \.self) { num in
                Circle()
                    .fill(num <= stepNumber ? themeStore.appTheme.primary : Color(.systemGray4))
                    .frame(width: 8, height: 8)
                
                if num < 6 {
                    Rectangle()
                        .fill(num < stepNumber ? themeStore.appTheme.primary : Color(.systemGray4))
                        .frame(height: 2)
                }
            }
        }
        .animation(.easeInOut, value: stepNumber)
    }
}

struct InitialWarningView: View {
    let itemsDescription: String
    @Environment(\.themeStore) private var themeStore
    
    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 64))
                .foregroundColor(Color(.systemOrange))
            
            Text("Reset Library")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(itemsDescription)
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(Color(.secondaryLabel))
            
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Label("All your books will be deleted", systemImage: "book.closed")
                Label("Reading progress will be lost", systemImage: "chart.line.downtrend.xyaxis")
                Label("Notes and ratings will be removed", systemImage: "note.text")
                Label("This action cannot be undone", systemImage: "arrow.uturn.backward.circle.badge.ellipsis")
            }
            .font(.callout)
            .padding()
            .materialCard()
        }
    }
}

struct DetailedWarningView: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Image(systemName: "trash.fill")
                .font(.system(size: 64))
                .foregroundColor(Color(.systemRed))
            
            Text("This Will Delete Everything")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                DetailRow(
                    icon: "books.vertical.fill",
                    title: "Library Data",
                    description: "All books, including covers and metadata"
                )
                
                DetailRow(
                    icon: "star.fill",
                    title: "Personal Data",
                    description: "Ratings, reviews, notes, and tags"
                )
                
                DetailRow(
                    icon: "chart.xyaxis.line",
                    title: "Reading History",
                    description: "Progress tracking and reading statistics"
                )
                
                DetailRow(
                    icon: "globe",
                    title: "Cultural Data",
                    description: "Author nationalities and language information"
                )
            }
            .padding()
            .materialCard()
            
            Text("Consider exporting your library before proceeding")
                .font(.footnote)
                .foregroundColor(Color(.secondaryLabel))
                .multilineTextAlignment(.center)
        }
    }
}

struct DetailRow: View {
    let icon: String
    let title: String
    let description: String
    @Environment(\.themeStore) private var themeStore
    
    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(themeStore.appTheme.primary)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(Color(.secondaryLabel))
            }
            
            Spacer()
        }
    }
}

struct TypeToConfirmView: View {
    @Binding var confirmationText: String
    let requiredText: String
    @FocusState private var isFocused: Bool
    @Environment(\.themeStore) private var themeStore
    
    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Image(systemName: "keyboard")
                .font(.system(size: 64))
                .foregroundColor(themeStore.appTheme.primary)
            
            Text("Type to Confirm")
                .font(.title)
                .fontWeight(.bold)
            
            Text("To confirm you want to reset your library, type **\(requiredText)** below")
                .font(.body)
                .multilineTextAlignment(.center)
            
            VStack(spacing: Theme.Spacing.sm) {
                TextField("Type \(requiredText)", text: $confirmationText)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.allCharacters)
                    .autocorrectionDisabled()
                    .focused($isFocused)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                
                if !confirmationText.isEmpty && confirmationText.uppercased() != requiredText {
                    Label("Type \(requiredText) to continue", systemImage: "exclamationmark.circle")
                        .font(.caption)
                        .foregroundColor(Color(.systemRed))
                }
            }
            .padding()
            .materialCard()
        }
        .onAppear {
            isFocused = true
        }
    }
}

struct HoldToConfirmView: View {
    @Binding var isHolding: Bool
    let holdProgress: Double
    let onStart: () -> Void
    let onStop: () -> Void
    @Environment(\.themeStore) private var themeStore
    
    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 64))
                .foregroundColor(isHolding ? Color(.systemRed) : themeStore.appTheme.primary)
                .scaleEffect(isHolding ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isHolding)
            
            Text("Hold to Confirm")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Press and hold the button below for 3 seconds to confirm")
                .font(.body)
                .multilineTextAlignment(.center)
            
            ZStack {
                Circle()
                    .stroke(Color(.systemGray4), lineWidth: 8)
                    .frame(width: 150, height: 150)
                
                Circle()
                    .trim(from: 0, to: holdProgress)
                    .stroke(
                        LinearGradient(
                            colors: [Color(.systemOrange), Color(.systemRed)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 150, height: 150)
                    .rotationEffect(.degrees(-90))
                
                VStack {
                    Image(systemName: isHolding ? "hand.raised.fill" : "hand.raised")
                        .font(.largeTitle)
                        .foregroundColor(isHolding ? Color(.systemRed) : Color(.secondaryLabel))
                    
                    if holdProgress > 0 {
                        Text("\(Int(holdProgress * 100))%")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                }
            }
            .scaleEffect(isHolding ? 0.95 : 1.0)
            .onLongPressGesture(
                minimumDuration: .infinity,
                maximumDistance: .infinity,
                pressing: { isPressing in
                    if isPressing {
                        onStart()
                    } else {
                        onStop()
                    }
                },
                perform: {}
            )
            
            Text("Release to cancel")
                .font(.caption)
                .foregroundColor(Color(.secondaryLabel))
                .opacity(isHolding ? 1 : 0)
        }
    }
}

struct ExportOptionsView: View {
    let onExportCSV: () async -> Void
    let onExportJSON: () async -> Void
    let onSkip: () async -> Void
    let exportCompleted: Bool
    @Environment(\.themeStore) private var themeStore
    
    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Image(systemName: exportCompleted ? "checkmark.circle.fill" : "square.and.arrow.up")
                .font(.system(size: 64))
                .foregroundColor(exportCompleted ? Color(.systemGreen) : themeStore.appTheme.primary)
            
            Text(exportCompleted ? "Export Complete" : "Export Your Library")
                .font(.title)
                .fontWeight(.bold)
            
            if exportCompleted {
                Text("Your library has been exported successfully")
                    .font(.body)
                    .multilineTextAlignment(.center)
            } else {
                Text("Save a backup of your library before resetting")
                    .font(.body)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: Theme.Spacing.md) {
                    Button(action: {
                        Task { await onExportCSV() }
                    }) {
                        HStack {
                            Image(systemName: "doc.text")
                            Text("Export as CSV")
                            Spacer()
                            Text("Goodreads compatible")
                                .font(.caption)
                                .foregroundColor(Color(.secondaryLabel))
                        }
                        .padding()
                    }
                    .materialCard()
                    
                    Button(action: {
                        Task { await onExportJSON() }
                    }) {
                        HStack {
                            Image(systemName: "doc.badge.gearshape")
                            Text("Export as JSON")
                            Spacer()
                            Text("Complete data")
                                .font(.caption)
                                .foregroundColor(Color(.secondaryLabel))
                        }
                        .padding()
                    }
                    .materialCard()
                }
            }
        }
    }
}

struct FinalConfirmationView: View {
    let didExport: Bool
    let isResetting: Bool
    
    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Image(systemName: isResetting ? "arrow.triangle.2.circlepath" : "trash.fill")
                .font(.system(size: 64))
                .foregroundColor(Color(.systemRed))
                .rotationEffect(.degrees(isResetting ? 360 : 0))
                .animation(isResetting ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isResetting)
            
            Text(isResetting ? "Resetting Library..." : "Final Confirmation")
                .font(.title)
                .fontWeight(.bold)
            
            if isResetting {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(1.5)
                    .padding()
                
                Text("Please wait while your library is being reset")
                    .font(.body)
                    .multilineTextAlignment(.center)
            } else {
                VStack(spacing: Theme.Spacing.md) {
                    if didExport {
                        Label("Backup created", systemImage: "checkmark.circle.fill")
                            .foregroundColor(Color(.systemGreen))
                    } else {
                        Label("No backup created", systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(Color(.systemOrange))
                    }
                    
                    Text("This is your last chance to cancel")
                        .font(.headline)
                        .foregroundColor(Color(.systemRed))
                    
                    Text("Pressing 'Reset Library' will immediately delete all your data")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color(.secondaryLabel))
                }
                .padding()
                .materialCard()
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}