//
//  DataQualityOnboardingView.swift
//  books
//
//  Onboarding experience for data quality features
//  Using iOS 26 Liquid Glass design system
//

import SwiftUI

struct DataQualityOnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    
    let onComplete: () -> Void
    
    @State private var currentStep = 0
    private let steps = OnboardingStep.allSteps
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress indicator
                HStack {
                    ForEach(0..<steps.count, id: \.self) { index in
                        Capsule()
                            .fill(index <= currentStep ? theme.primary : theme.outline.opacity(0.3))
                            .frame(height: 4)
                            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: currentStep)
                        
                        if index < steps.count - 1 {
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.top, Theme.Spacing.md)
                
                // Content
                ScrollView {
                    VStack(spacing: Theme.Spacing.xl) {
                        // Hero illustration area
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(theme.surfaceVariant)
                                .frame(height: 200)
                            
                            Image(systemName: steps[currentStep].icon)
                                .font(.system(size: 60, weight: .light))
                                .foregroundColor(theme.primary)
                        }
                        .padding(.top, Theme.Spacing.xl)
                        
                        // Step content
                        VStack(spacing: Theme.Spacing.lg) {
                            Text(steps[currentStep].title)
                                .font(Theme.Typography.headlineMedium)
                                .foregroundColor(theme.primaryText)
                                .multilineTextAlignment(.center)
                            
                            Text(steps[currentStep].description)
                                .font(Theme.Typography.bodyLarge)
                                .foregroundColor(theme.secondaryText)
                                .multilineTextAlignment(.center)
                                .lineLimit(nil)
                        }
                        .padding(.horizontal, Theme.Spacing.lg)
                        
                        Spacer(minLength: Theme.Spacing.xxl)
                    }
                }
                
                // Action buttons
                VStack(spacing: Theme.Spacing.md) {
                    if currentStep < steps.count - 1 {
                        Button("Next") {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                currentStep += 1
                            }
                            HapticFeedbackManager.shared.lightImpact()
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Skip") {
                            completeOnboarding()
                        }
                        .buttonStyle(.bordered)
                    } else {
                        Button("Get Started") {
                            completeOnboarding()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                    if currentStep > 0 {
                        Button("Previous") {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                currentStep -= 1
                            }
                            HapticFeedbackManager.shared.lightImpact()
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(Theme.Spacing.lg)
            }
            .navigationTitle("Library Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip") {
                        completeOnboarding()
                    }
                    .foregroundColor(theme.secondaryText)
                }
            }
        }
        .interactiveDismissDisabled()
    }
    
    private func completeOnboarding() {
        HapticFeedbackManager.shared.success()
        onComplete()
        dismiss()
    }
}

// MARK: - Onboarding Steps

struct OnboardingStep {
    let title: String
    let description: String
    let icon: String
    
    static let allSteps = [
        OnboardingStep(
            title: "Track Your Data Quality",
            description: "See how complete your book information is at a glance. Get smart suggestions to improve your library data.",
            icon: "chart.bar.doc.horizontal"
        ),
        OnboardingStep(
            title: "Get Personalized Suggestions",
            description: "Receive tailored prompts to add ratings, notes, and cultural information based on your reading patterns.",
            icon: "lightbulb.fill"
        ),
        OnboardingStep(
            title: "Organize with Smart Sorting",
            description: "Sort your library by data completeness to quickly find books that need attention or are fully detailed.",
            icon: "arrow.up.arrow.down"
        ),
        OnboardingStep(
            title: "Build a Rich Library",
            description: "Track cultural diversity, personal insights, and detailed metadata to create a comprehensive reading record.",
            icon: "books.vertical.fill"
        )
    ]
}

// MARK: - Onboarding State Management

extension UserDefaults {
    private enum Keys {
        static let hasSeenDataQualityOnboarding = "hasSeenDataQualityOnboarding"
    }
    
    var hasSeenDataQualityOnboarding: Bool {
        get { bool(forKey: Keys.hasSeenDataQualityOnboarding) }
        set { set(newValue, forKey: Keys.hasSeenDataQualityOnboarding) }
    }
}

// MARK: - Preview

#Preview {
    DataQualityOnboardingView {
        print("Onboarding completed")
    }
}