/*
//
//  EnhancedLiveActivityViews.swift
//  BooksWidgets
//
//  Enhanced Live Activity views with improved visual design
//  Optimized for iOS 16.1+ with Dynamic Island support
//

import ActivityKit
import WidgetKit
import SwiftUI

@available(iOS 16.1, *)
@MainActor
extension CSVImportLiveActivity {
    
    // MARK: - Enhanced Lock Screen View
    
    struct EnhancedLockScreenView: View {
        let context: ActivityViewContext<CSVImportActivityAttributes>
        
        var body: some View {
            VStack(spacing: Theme.Spacing.md) {
                // Header Section
                headerSection
                
                // Progress Section
                progressSection
                
                // Statistics Section
                if context.state.totalBooks > 0 {
                    statisticsSection
                }
                
                // Current Book Section
                if let currentTitle = context.state.currentBookTitle {
                    currentBookSection(title: currentTitle, author: context.state.currentBookAuthor)
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("CSV Import Progress")
            .accessibilityHint("Shows import progress, statistics, and current book being processed")
            .padding(Theme.Spacing.lg)
            .background(backgroundGradient)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
            .shadow(
                color: Theme.Elevation.card.color,
                radius: Theme.Elevation.card.radius,
                x: Theme.Elevation.card.x,
                y: Theme.Elevation.card.y
            )
        }
        
        private var headerSection: some View {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "doc.text.fill")
                    .font(Theme.Typography.titleMedium)
                    .foregroundColor(.accentColor)
                    .frame(width: 32, height: 32)
                    .background(Color.accentColor.opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.attributes.shortDisplayName)
                        .font(Theme.Typography.titleMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text("CSV Import in Progress")
                        .font(Theme.Typography.labelMedium)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(context.state.formattedProgress)
                        .font(Theme.Typography.titleLarge)
                        .fontWeight(.bold)
                        .foregroundColor(.accentColor)
                    
                    Text(context.state.statusSummary)
                        .font(Theme.Typography.labelMedium)
                        .foregroundColor(.secondary)
                }
            }
        }
        
        private var progressSection: some View {
            VStack(spacing: 8) {
                ProgressView(value: context.state.progress)
                    .progressViewStyle(CustomLinearProgressStyle())
                    .frame(height: 12)
                
                HStack {
                    Text(context.state.currentStep)
                        .font(Theme.Typography.bodyMedium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    
                    Spacer()
                    
                    if context.state.totalBooks > 0 {
                        Text("\(context.state.booksProcessed) of \(context.state.totalBooks)")
                            .font(Theme.Typography.labelMedium)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        
        private var statisticsSection: some View {
            HStack(spacing: 20) {
                if context.state.successCount > 0 {
                    StatBadge(
                        icon: "checkmark.circle.fill",
                        count: context.state.successCount,
                        label: "Imported",
                        color: .green
                    )
                }
                
                if context.state.duplicateCount > 0 {
                    StatBadge(
                        icon: "doc.on.doc.fill",
                        count: context.state.duplicateCount,
                        label: "Duplicates",
                        color: .orange
                    )
                }
                
                if context.state.failureCount > 0 {
                    StatBadge(
                        icon: "exclamationmark.triangle.fill",
                        count: context.state.failureCount,
                        label: "Failed",
                        color: .red
                    )
                }
                
                Spacer()
            }
        }
        
        private func currentBookSection(title: String, author: String?) -> some View {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "book.fill")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                    Text("Currently Processing")
                        .font(Theme.Typography.labelMedium)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Theme.Typography.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    
                    if let author = author, !author.isEmpty {
                        Text("by \(author)")
                            .font(Theme.Typography.labelMedium)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
            }
            .padding(Theme.Spacing.sm)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.small))
        }
        
        private var backgroundGradient: some View {
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.systemGray6).opacity(0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    // MARK: - Enhanced Dynamic Island Views
    
    struct EnhancedDynamicIslandViews {
        
        static func compactLeading(context: ActivityViewContext<CSVImportActivityAttributes>) -> some View {
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 2)
                    .frame(width: 24, height: 24)
                
                Circle()
                    .trim(from: 0, to: context.state.progress)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 24, height: 24)
                    .rotationEffect(.degrees(-90))
                    .animation(Theme.Animation.accessible, value: context.state.progress)
            }
        }
        
        static func compactTrailing(context: ActivityViewContext<CSVImportActivityAttributes>) -> some View {
            VStack(spacing: 1) {
                Text("\(context.state.booksProcessed)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("\(context.state.totalBooks)")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
        
        static func minimal(context: ActivityViewContext<CSVImportActivityAttributes>) -> some View {
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1.5)
                    .frame(width: 18, height: 18)
                
                Circle()
                    .trim(from: 0, to: context.state.progress)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                    .frame(width: 18, height: 18)
                    .rotationEffect(.degrees(-90))
                    .animation(Theme.Animation.accessible, value: context.state.progress)
            }
        }
        
        static func expandedLeading(context: ActivityViewContext<CSVImportActivityAttributes>) -> some View {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 3)
                        .frame(width: 44, height: 44)
                    
                    Circle()
                        .trim(from: 0, to: context.state.progress)
                        .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 44, height: 44)
                        .rotationEffect(.degrees(-90))
                        .animation(Theme.Animation.accessible, value: context.state.progress)
                    
                    Text(context.state.formattedProgress)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.accentColor)
                }
                
                Image(systemName: "doc.text.fill")
                    .font(.caption)
                    .foregroundColor(.accentColor)
            }
        }
        
        static func expandedTrailing(context: ActivityViewContext<CSVImportActivityAttributes>) -> some View {
            VStack(alignment: .trailing, spacing: Theme.Spacing.xs) {
                HStack(spacing: Theme.Spacing.xs) {
                    if context.state.successCount > 0 {
                        Text("✓\(context.state.successCount)")
                            .font(Theme.Typography.labelSmall)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                            .accessibilityLabel("\(context.state.successCount) successful")
                    }
                    
                    if context.state.failureCount > 0 {
                        Text("✗\(context.state.failureCount)")
                            .font(Theme.Typography.labelSmall)
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                            .accessibilityLabel("\(context.state.failureCount) failed")
                    }
                }
                
                Text(context.state.statusSummary)
                    .font(Theme.Typography.labelMedium)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.trailing)
                    .accessibilityLabel("Status: \(context.state.statusSummary)")
            }
            .accessibilityElement(children: .contain)
        }
        
        static func expandedBottom(context: ActivityViewContext<CSVImportActivityAttributes>) -> some View {
            VStack(spacing: Theme.Spacing.xs) {
                // Current step
                Text(context.state.currentStep)
                    .font(Theme.Typography.bodySmall)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .accessibilityLabel("Current step: \(context.state.currentStep)")
                
                // Current book if available
                if let currentTitle = context.state.currentBookTitle {
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "book.fill")
                            .font(Theme.Typography.labelSmall)
                            .foregroundColor(.accentColor)
                            .accessibilityHidden(true)
                        
                        Text(currentTitle)
                            .font(Theme.Typography.labelMedium)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .accessibilityLabel("Currently processing: \(currentTitle)")
                        
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .accessibilityElement(children: .contain)
        }
    }
}

// MARK: - Supporting Views

@available(iOS 16.1, *)
@MainActor
struct StatBadge: View {
    let icon: String
    let count: Int
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: icon)
                .font(Theme.Typography.labelSmall)
                .foregroundColor(color)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 1) {
                Text("\(count)")
                    .font(Theme.Typography.labelMedium)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(label)
                    .font(Theme.Typography.labelSmall)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xs)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.small))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(count) \(label.lowercased())")
        .accessibilityAddTraits(.isStaticText)
    }
}

@available(iOS 16.1, *)
@MainActor
struct CustomLinearProgressStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(.systemGray5))
                .frame(height: 12)
            
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: (configuration.fractionCompleted ?? 0) * 100, height: 12)
                .animation(Theme.Animation.accessible, value: configuration.fractionCompleted)
        }
    }
}
*/
