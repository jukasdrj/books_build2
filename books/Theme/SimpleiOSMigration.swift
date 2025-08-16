//
//  SimpleiOSMigration.swift
//  books
//
//  Simplified iOS Native Migration 
//  Direct replacements for Material Design components following iOS agent feedback
//

import SwiftUI

// MARK: - iOS Native Component Extensions

extension View {
    
    // MARK: - Cards
    
    /// Native iOS card (replaces .materialCard())
    func nativeCard() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
            )
    }
    
    /// Native iOS grouped card for settings-style lists
    func nativeGroupedCard() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(.regularMaterial)
            )
    }
    
    /// Native iOS prominent card for hero sections
    func nativeProminentCard() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.thickMaterial)
                    .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
            )
    }
    
    // MARK: - Buttons (44pt minimum touch targets)
    
    /// Native iOS filled button
    func nativeFilledButton() -> some View {
        self
            .font(.system(.body, design: .default, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .frame(minHeight: 44) // iOS minimum touch target
            .background(
                Capsule()
                    .fill(Color.accentColor)
            )
            .contentShape(Capsule()) // Ensure entire area is tappable
    }
    
    /// Native iOS tonal button  
    func nativeTonalButton() -> some View {
        self
            .font(.system(.body, design: .default, weight: .semibold))
            .foregroundColor(.accentColor)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .frame(minHeight: 44)
            .background(
                Capsule()
                    .fill(.regularMaterial)
            )
            .contentShape(Capsule())
    }
    
    /// Native iOS outlined button
    func nativeOutlinedButton() -> some View {
        self
            .font(.system(.body, design: .default, weight: .semibold))
            .foregroundColor(.accentColor)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .frame(minHeight: 44)
            .overlay(
                Capsule()
                    .stroke(.quaternary, lineWidth: 1)
            )
            .contentShape(Capsule())
    }
    
    /// Native iOS text button
    func nativeTextButton() -> some View {
        self
            .font(.system(.body, design: .default, weight: .semibold))
            .foregroundColor(.accentColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
    }
    
    /// Native iOS destructive button
    func nativeDestructiveButton() -> some View {
        self
            .font(.system(.body, design: .default, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .frame(minHeight: 44)
            .background(
                Capsule()
                    .fill(.red)
            )
            .contentShape(Capsule())
    }
    
    // MARK: - Interactive
    
    /// Native iOS interactive feedback
    func nativeInteractive() -> some View {
        self
            .scaleEffect(1.0)
            .animation(.easeInOut(duration: 0.1), value: false)
    }
}

// MARK: - iOS Semantic Typography

extension View {
    
    /// iOS Large Title (was displayLarge)
    func nativeLargeTitle() -> some View {
        self.font(.largeTitle.weight(.bold))
    }
    
    /// iOS Title 1 (was headlineLarge)  
    func nativeTitle1() -> some View {
        self.font(.title.weight(.semibold))
    }
    
    /// iOS Title 2 (was headlineMedium)
    func nativeTitle2() -> some View {
        self.font(.title2.weight(.semibold))
    }
    
    /// iOS Title 3 (was headlineSmall)
    func nativeTitle3() -> some View {
        self.font(.title3.weight(.semibold))
    }
    
    /// iOS Headline (was titleLarge)
    func nativeHeadline() -> some View {
        self.font(.headline)
    }
    
    /// iOS Body (was bodyLarge)
    func nativeBody() -> some View {
        self.font(.body)
    }
    
    /// iOS Callout (was bodyMedium)
    func nativeCallout() -> some View {
        self.font(.callout)
    }
    
    /// iOS Subheadline (was bodySmall)
    func nativeSubheadline() -> some View {
        self.font(.subheadline)
    }
    
    /// iOS Footnote (was labelLarge)
    func nativeFootnote() -> some View {
        self.font(.footnote)
    }
    
    /// iOS Caption (was labelMedium/labelSmall)
    func nativeCaption() -> some View {
        self.font(.caption)
    }
}

// MARK: - Migration Helper

struct NativeMigrationHelper {
    
    /// Migration roadmap by week
    static let weeklyMigrationPlan: [Int: [String]] = [
        1: ["BookCardView", "SharedComponents list items", "Simple action buttons"],
        2: ["Import flow buttons", "Filter components", "Settings toggles"],
        3: ["Hero section cards", "Stats cards", "Navigation elements"],
        4: ["Complex interactive cards", "Form controls", "Modal dialogs"]
    ]
    
    /// Components to migrate in Phase 1 (Week 1)
    static let phase1Components = [
        "BookCardView",
        "QuickFilterChip", 
        "ReadingStatusFilterChip",
        "Simple toolbar buttons"
    ]
    
    /// Check if component should be migrated in current week
    static func shouldMigrate(component: String, week: Int) -> Bool {
        guard let componentsForWeek = weeklyMigrationPlan[week] else { return false }
        return componentsForWeek.contains(component)
    }
}