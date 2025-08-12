//
//  ImportCompletionBanner.swift
//  books
//
//  Notification banner for background import completion
//  Shows success message and review needs
//

import SwiftUI
import SwiftData

struct ImportCompletionBanner: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.modelContext) private var modelContext
    @State private var backgroundCoordinator: BackgroundImportCoordinator?
    @State private var showingReviewModal = false
    @State private var bannerOffset: CGFloat = -200
    @State private var isVisible = false
    
    var body: some View {
        VStack {
            if let coordinator = backgroundCoordinator,
               !coordinator.isImporting,
               coordinator.shouldShowReviewModal,
               isVisible {
                
                HStack(spacing: Theme.Spacing.md) {
                    // Success icon
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(theme.success)
                    
                    // Message content
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("Import Complete!")
                            .labelLarge()
                            .fontWeight(.semibold)
                            .foregroundColor(theme.primaryText)
                        
                        if !coordinator.needsUserReview.isEmpty {
                            Text("\(coordinator.needsUserReview.count) books need review")
                                .labelMedium()
                                .foregroundColor(theme.secondaryText)
                        }
                    }
                    
                    Spacer()
                    
                    // Review button
                    Button("Review") {
                        showingReviewModal = true
                        dismissBanner()
                    }
                    .materialButton(style: .tonal, size: .small)
                    
                    // Dismiss button
                    Button {
                        dismissBanner()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundColor(theme.secondaryText)
                    }
                }
                .padding(Theme.Spacing.md)
                .background(theme.successContainer)
                .materialCard()
                .padding(.horizontal, Theme.Spacing.md)
                .offset(y: bannerOffset)
                .transition(.move(edge: .top).combined(with: .opacity))
                .onAppear {
                    // Auto-dismiss after 10 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                        if isVisible {
                            dismissBanner()
                        }
                    }
                }
            }
            
            Spacer()
        }
        .onAppear {
            if backgroundCoordinator == nil {
                backgroundCoordinator = BackgroundImportCoordinator.initialize(with: modelContext)
            }
        }
        .onChange(of: backgroundCoordinator?.shouldShowReviewModal) { _, shouldShow in
            if shouldShow == true {
                showBanner()
            }
        }
        .sheet(isPresented: $showingReviewModal) {
            if let coordinator = backgroundCoordinator {
                ImportReviewModal(coordinator: coordinator)
            }
        }
    }
    
    private func showBanner() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            bannerOffset = 0
            isVisible = true
        }
    }
    
    private func dismissBanner() {
        withAnimation(.easeInOut(duration: 0.3)) {
            bannerOffset = -200
            isVisible = false
        }
        
        // Clear review items after dismissing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            backgroundCoordinator?.clearReviewItems()
        }
    }
}

/// Modal for reviewing ambiguous matches and failed imports
struct ImportReviewModal: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    let coordinator: BackgroundImportCoordinator
    
    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.lg) {
                // Header
                VStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 40))
                        .foregroundColor(theme.warning)
                    
                    Text("Books Need Review")
                        .titleLarge()
                        .fontWeight(.bold)
                        .foregroundColor(theme.primaryText)
                    
                    Text("These books couldn't be imported automatically and need your attention")
                        .bodyMedium()
                        .foregroundColor(theme.secondaryText)
                        .multilineTextAlignment(.center)
                }
                
                // Review items list
                List(coordinator.needsUserReview) { item in
                    ReviewItemRow(item: item)
                }
                .listStyle(.plain)
                
                // Action buttons
                VStack(spacing: Theme.Spacing.sm) {
                    Button("Review Later") {
                        dismiss()
                    }
                    .materialButton(style: .filled, size: .large)
                    
                    Button("Skip These Books") {
                        // Clear review items
                        coordinator.clearReviewItems()
                        dismiss()
                    }
                    .materialButton(style: .outlined, size: .medium)
                }
                .padding(.horizontal, Theme.Spacing.lg)
            }
            .padding(Theme.Spacing.lg)
            .navigationTitle("Review Needed")
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
}

/// Row displaying a single review item
struct ReviewItemRow: View {
    @Environment(\.appTheme) private var theme
    let item: ReviewItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Book info
            HStack {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(item.bookTitle)
                        .bodyMedium()
                        .fontWeight(.semibold)
                        .foregroundColor(theme.primaryText)
                    
                    Text("by \(item.author)")
                        .labelMedium()
                        .foregroundColor(theme.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(theme.warning)
            }
            
            // Issue description
            Text(item.issue)
                .labelMedium()
                .foregroundColor(theme.error)
                .padding(.vertical, Theme.Spacing.xs)
                .padding(.horizontal, Theme.Spacing.sm)
                .background(theme.error.opacity(0.1))
                .cornerRadius(8)
            
            // Suggestions if available
            if !item.suggestions.isEmpty {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Suggestions:")
                        .labelSmall()
                        .fontWeight(.medium)
                        .foregroundColor(theme.secondaryText)
                    
                    ForEach(item.suggestions.prefix(3), id: \.self) { suggestion in
                        Text("• \(suggestion)")
                            .labelSmall()
                            .foregroundColor(theme.secondaryText)
                    }
                }
            }
        }
        .padding(.vertical, Theme.Spacing.sm)
    }
}

#Preview {
    ImportCompletionBanner()
        .modelContainer(ModelContainer.preview)
        .preferredColorScheme(.dark)
}