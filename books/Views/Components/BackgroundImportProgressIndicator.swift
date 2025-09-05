//
//  BackgroundImportProgressIndicator.swift
//  books
//
//  Subtle progress indicator for background CSV imports
//  Shows minimal UI impact while providing import status
//

import SwiftUI
import SwiftData

struct BackgroundImportProgressIndicator: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.modelContext) private var modelContext
    @State private var backgroundCoordinator: BackgroundImportCoordinator?
    @State private var showingDetails = false
    @State private var hasError = false
    @State private var errorMessage = ""
    @State private var isConnecting = true
    
    var body: some View {
        Group {
            if isConnecting && backgroundCoordinator == nil {
                // Skeleton state while connecting to coordinator
                SkeletonProgressIndicator()
                    .progressiveGlassEffect(material: .regular, level: .subtle)
            } else if hasError {
                // Error state with retry
                ErrorProgressIndicator(
                    message: errorMessage,
                    onRetry: { setupImportService() }
                )
                .progressiveGlassEffect(material: .regular, level: .subtle)
            } else if let coordinator = backgroundCoordinator, 
               coordinator.isImporting, 
               coordinator.progress != nil {
                Button(action: { 
                    // Haptic feedback for interaction
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    showingDetails = true 
                }) {
                    HStack(spacing: Theme.Spacing.xs) {
                        // Enhanced animated progress indicator with iOS 26 styling
                        ZStack {
                            Circle()
                                .stroke(theme.primary.opacity(0.2), lineWidth: 2)
                                .frame(width: 20, height: 20)
                            
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: theme.primary))
                                .scaleEffect(0.6)
                                .progressiveGlassEffect(material: .regular, level: .subtle)
                        }
                        
                        // Progress text (minimal)
                        if let progress = coordinator.progress {
                            Text("\(progress.processedBooks)")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(theme.primary)
                        }
                    }
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $showingDetails) {
                    BackgroundImportDetailView(coordinator: coordinator)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .progressiveGlassEffect(material: .regular, level: .elevated)
                .accessibilityLabel("Import progress: \(coordinator.progress?.processedBooks ?? 0) of \(coordinator.progress?.totalBooks ?? 0) books")
                .accessibilityHint("Double tap to view detailed progress")
            }
        }
        .onAppear {
            setupImportService()
            // Auto-hide connecting state after 3 seconds
            Task {
                try await Task.sleep(nanoseconds: 3_000_000_000)
                await MainActor.run {
                    if backgroundCoordinator == nil {
                        isConnecting = false
                        hasError = true
                        errorMessage = "Unable to connect to import service"
                    }
                }
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: (backgroundCoordinator?.isImporting ?? false) && (backgroundCoordinator?.progress != nil))
        .animation(.easeInOut(duration: 0.3), value: isConnecting)
        .animation(.easeInOut(duration: 0.3), value: hasError)
    }
    
    private func setupImportService() {
        isConnecting = true
        hasError = false
        errorMessage = ""
        
        // Use existing shared instance or create if needed
        if let shared = BackgroundImportCoordinator.shared {
            backgroundCoordinator = shared
            isConnecting = false
        } else {
            // Try to initialize
            do {
                backgroundCoordinator = BackgroundImportCoordinator.initialize(with: modelContext)
                isConnecting = false
            } catch {
                hasError = true
                errorMessage = "Failed to initialize import service"
                isConnecting = false
            }
        }
    }
}

/// Detailed view shown when user taps the progress indicator
struct BackgroundImportDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    let coordinator: BackgroundImportCoordinator
    
    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.lg) {
                // Header
                VStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 40))
                        .foregroundColor(theme.primary)
                    
                    Text("Importing Books")
                        .titleLarge()
                        .fontWeight(.bold)
                        .foregroundColor(theme.primaryText)
                    
                    Text("Your books are being imported in the background")
                        .bodyMedium()
                        .foregroundColor(theme.secondaryText)
                        .multilineTextAlignment(.center)
                }
                
                // Progress details
                if let progress = coordinator.progress {
                    VStack(spacing: Theme.Spacing.md) {
                        // Progress bar
                        ProgressView(value: progress.progress)
                            .progressViewStyle(LinearProgressViewStyle(tint: theme.primary))
                            .frame(height: 8)
                            .cornerRadius(4)
                        
                        // Statistics
                        HStack {
                            StatCard(
                                icon: "checkmark.circle.fill",
                                title: "Imported",
                                value: "\(progress.successfulImports)",
                                color: theme.success
                            )
                            
                            Spacer()
                            
                            StatCard(
                                icon: "clock.fill",
                                title: "Remaining",
                                value: "\(progress.totalBooks - progress.processedBooks)",
                                color: theme.primary
                            )
                            
                            Spacer()
                            
                            StatCard(
                                icon: "exclamationmark.triangle.fill",
                                title: "Failed",
                                value: "\(progress.failedImports)",
                                color: theme.error
                            )
                        }
                        
                        // Time estimate
                        if progress.estimatedTimeRemaining > 0 {
                            HStack(spacing: Theme.Spacing.xs) {
                                Image(systemName: "timer")
                                    .foregroundColor(theme.secondaryText)
                                
                                Text("About \(formatTimeRemaining(progress.estimatedTimeRemaining)) remaining")
                                    .bodyMedium()
                                    .foregroundColor(theme.secondaryText)
                            }
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                }
                
                // Action buttons
                VStack(spacing: Theme.Spacing.sm) {
                    Button("Browse Library") {
                        dismiss()
                    }
                    .materialButton(style: .filled, size: .large)
                    
                    Button("Cancel Import") {
                        Task {
                            await coordinator.cancelImport()
                            await MainActor.run {
                                dismiss()
                            }
                        }
                    }
                    .materialButton(style: .outlined, size: .medium)
                }
                .padding(.horizontal, Theme.Spacing.lg)
                
                Spacer()
            }
            .padding(Theme.Spacing.lg)
            .navigationTitle("Import Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDragIndicator(.visible)
    }
    
    private func formatTimeRemaining(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        if minutes > 0 {
            return "\(minutes) minute\(minutes == 1 ? "" : "s")"
        } else {
            return "less than a minute"
        }
    }
}


#Preview {
    BackgroundImportProgressIndicator()
        .modelContainer(ModelContainer.preview)
        .preferredColorScheme(.dark)
}