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
    
    var body: some View {
        Group {
            if let coordinator = backgroundCoordinator, coordinator.isImporting {
                Button(action: { showingDetails = true }) {
                    HStack(spacing: Theme.Spacing.xs) {
                        // Animated progress indicator
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: theme.primary))
                            .scaleEffect(0.7)
                        
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
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }
        }
        .onAppear {
            if backgroundCoordinator == nil {
                backgroundCoordinator = BackgroundImportCoordinator(modelContext: modelContext)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: backgroundCoordinator?.isImporting)
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
                        coordinator.cancelImport()
                        dismiss()
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

/// Small stat card for the detail view
struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .titleMedium()
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .labelSmall()
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    BackgroundImportProgressIndicator()
        .modelContainer(ModelContainer.preview)
        .preferredColorScheme(.dark)
}