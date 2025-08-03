import SwiftUI

struct ThemePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTheme: ThemeVariant
    
    private let themeManager = ThemeManager.shared
    
    init() {
        _selectedTheme = State(initialValue: ThemeManager.shared.currentTheme)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    headerSection
                    
                    ForEach(ThemeVariant.allCases) { theme in
                        ThemePreviewCard(
                            theme: theme,
                            isSelected: selectedTheme == theme,
                            onSelect: {
                                selectTheme(theme)
                            }
                        )
                    }
                }
                .padding(Theme.Spacing.lg)
            }
            .background(Color.theme.surface)
            .navigationTitle("Choose Theme")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color.theme.primary)
                }
            }
        }
    }
    
    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text("Personalize Your Experience")
                .font(.title2).bold()
                .foregroundColor(Color.theme.primaryText)
                .multilineTextAlignment(.center)
            
            Text("Choose a theme that matches your reading mood.")
                .font(.subheadline)
                .foregroundColor(Color.theme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, Theme.Spacing.md)
    }
    
    private func selectTheme(_ theme: ThemeVariant) {
        selectedTheme = theme
        themeManager.switchTheme(to: theme, animated: true)
        
        // Haptic feedback for a delightful interaction
        HapticFeedbackManager.shared.lightImpact()
    }
}