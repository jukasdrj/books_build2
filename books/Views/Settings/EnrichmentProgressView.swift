//
//  EnrichmentProgressView.swift
//  books
//
//  Progress modal for metadata enrichment
//

import SwiftUI
import SwiftData

struct EnrichmentProgressView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var enrichmentService: MetadataEnrichmentService
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    if let progress = enrichmentService.enrichmentProgress {
                        progressHeader(progress)
                        progressDetails(progress)
                        actionButtons
                    } else {
                        completedState
                    }
                }
                .padding(Theme.Spacing.md)
            }
            .navigationTitle("Enhancement Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Progress Header
    
    private func progressHeader(_ progress: EnrichmentProgress) -> some View {
        VStack(spacing: Theme.Spacing.md) {
            // Animated progress ring
            ZStack {
                Circle()
                    .stroke(theme.surfaceVariant, lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: progressPercentage(progress))
                    .stroke(theme.primary, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: progressPercentage(progress))
                
                VStack {
                    Text("\(Int(progressPercentage(progress) * 100))%")
                        .titleLarge()
                        .fontWeight(.bold)
                        .foregroundColor(theme.primary)
                    
                    Text("Complete")
                        .labelMedium()
                        .foregroundColor(theme.secondaryText)
                }
            }
            
            VStack(spacing: Theme.Spacing.xs) {
                Text("Enhancing Your Library")
                    .headlineMedium()
                    .foregroundColor(theme.primaryText)
                
                Text("Adding missing covers, descriptions, and metadata")
                    .bodyMedium()
                    .foregroundColor(theme.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Progress Details
    
    private func progressDetails(_ progress: EnrichmentProgress) -> some View {
        VStack(spacing: Theme.Spacing.md) {
            // Progress stats
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Theme.Spacing.sm) {
                ProgressStatCard(
                    title: "Total",
                    value: "\(progress.totalBooks)",
                    icon: "books.vertical.fill",
                    color: theme.primary
                )
                
                ProgressStatCard(
                    title: "Enhanced",
                    value: "\(progress.successfulEnrichments)",
                    icon: "checkmark.circle.fill",
                    color: theme.success
                )
                
                ProgressStatCard(
                    title: "Failed",
                    value: "\(progress.failedEnrichments)",
                    icon: "xmark.circle.fill",
                    color: progress.failedEnrichments > 0 ? theme.error : theme.secondaryText
                )
            }
            
            // Time remaining
            if progress.estimatedTimeRemaining > 0 {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(theme.primary)
                    
                    Text("About \(formatTimeRemaining(progress.estimatedTimeRemaining)) remaining")
                        .bodyMedium()
                        .foregroundColor(theme.primaryText)
                    
                    Spacer()
                }
                .padding(Theme.Spacing.md)
                .background(theme.primary.opacity(0.1))
                .cornerRadius(Theme.CornerRadius.medium)
            }
            
            // Current book (if available)
            if !progress.currentBookTitle.isEmpty {
                HStack {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("Currently enhancing")
                            .labelMedium()
                            .foregroundColor(theme.secondaryText)
                        
                        Text(progress.currentBookTitle)
                            .bodyMedium()
                            .fontWeight(.medium)
                            .foregroundColor(theme.primaryText)
                    }
                    
                    Spacer()
                    
                    ProgressView()
                        .scaleEffect(0.8)
                }
                .padding(Theme.Spacing.md)
                .materialCard()
            }
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Button("Run in Background") {
                dismiss()
            }
            .materialButton(style: .tonal)
            
            Button("Stop Enhancement") {
                enrichmentService.stopEnrichment()
                dismiss()
            }
            .materialButton(style: .outlined)
        }
    }
    
    // MARK: - Completed State
    
    private var completedState: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(theme.success)
            
            VStack(spacing: Theme.Spacing.sm) {
                Text("Enhancement Complete!")
                    .headlineLarge()
                    .foregroundColor(theme.primaryText)
                
                Text("Your library has been successfully enhanced with additional metadata.")
                    .bodyLarge()
                    .foregroundColor(theme.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            Button("Done") {
                dismiss()
            }
            .materialButton(style: .filled)
        }
        .padding(Theme.Spacing.xl)
    }
    
    // MARK: - Helper Methods
    
    private func progressPercentage(_ progress: EnrichmentProgress) -> Double {
        guard progress.totalBooks > 0 else { return 0 }
        return Double(progress.processedBooks) / Double(progress.totalBooks)
    }
    
    private func formatTimeRemaining(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds / 60)
        let remainingSeconds = Int(seconds.truncatingRemainder(dividingBy: 60))
        
        if minutes > 0 {
            return "\(minutes)m \(remainingSeconds)s"
        } else {
            return "\(remainingSeconds)s"
        }
    }
}

// MARK: - Progress Stat Card

struct ProgressStatCard: View {
    @Environment(\.appTheme) private var theme
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            
            Text(value)
                .titleMedium()
                .fontWeight(.bold)
                .foregroundColor(theme.primaryText)
            
            Text(title)
                .labelSmall()
                .foregroundColor(theme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.sm)
        .materialCard()
    }
}

// MARK: - Preview

#Preview {
    EnrichmentProgressView(
        enrichmentService: {
            let service = MetadataEnrichmentService(modelContext: ModelContext(try! ModelContainer(for: UserBook.self, BookMetadata.self)))
            service.enrichmentProgress = EnrichmentProgress(
                totalBooks: 50,
                processedBooks: 23,
                successfulEnrichments: 20,
                failedEnrichments: 3,
                currentBookTitle: "The Great Gatsby",
                estimatedTimeRemaining: 120
            )
            return service
        }()
    )
    .environment(\.appTheme, AppColorTheme(variant: .purpleBoho))
}