import SwiftUI

struct ThemePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    @Environment(\.themeStore) private var themeStore
    @State private var selectedTheme: ThemeVariant
    
    init() {
        // Will be updated in onAppear to sync with store
        _selectedTheme = State(initialValue: .purpleBoho)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // ScreenshotMode visual banner (purple gradient, visible only in ScreenshotMode)
            if ScreenshotMode.isEnabled {
                ZStack {
                    LinearGradient(
                        colors: [Color.purple.opacity(0.85), Color.purple.opacity(0.65)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    HStack {
                        Image(systemName: "camera.aperture")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Screenshot Mode")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal)
                }
                .frame(height: 32)
                .cornerRadius(0)
                .shadow(color: Color.purple.opacity(0.15), radius: 7, x: 0, y: 4)
            }
        }
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.xl) {
                    // Enhanced header section for App Store appeal
                    VStack(spacing: Theme.Spacing.lg) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            theme.primary.opacity(0.2),
                                            theme.secondary.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "paintbrush.pointed.fill")
                                .font(.system(size: 40, weight: .medium))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [theme.primary, theme.secondary],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        .shadow(color: theme.primary.opacity(0.2), radius: 16, x: 0, y: 8)
                        
                        VStack(spacing: Theme.Spacing.sm) {
                            Text("Choose Your Perfect Theme")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(theme.primaryText)
                                .multilineTextAlignment(.center)
                            
                            Text("Each theme creates a unique reading sanctuary tailored to your mood and style.")
                                .font(.body)
                                .foregroundColor(theme.secondaryText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, Theme.Spacing.md)
                        }
                    }
                    
                    // Theme cards with enhanced presentation
                    VStack(spacing: Theme.Spacing.lg) {
                        ForEach(ThemeStore.availableThemes) { theme in
                            ThemePreviewCard(
                                theme: theme,
                                isSelected: selectedTheme == theme,
                                onSelect: {
                                    selectTheme(theme)
                                }
                            )
                            .shadow(
                                color: selectedTheme == theme ? 
                                    theme.colorDefinition.primary.light.toColor().opacity(0.3) : 
                                    Color.black.opacity(0.05),
                                radius: selectedTheme == theme ? 12 : 4,
                                x: 0,
                                y: selectedTheme == theme ? 8 : 2
                            )
                        }
                    }
                }
                .padding(Theme.Spacing.lg)
            }
            .background(
                LinearGradient(
                    colors: [
                        theme.background,
                        theme.surface.opacity(0.8)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("Themes")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                        HapticFeedbackManager.shared.lightImpact()
                    }
                    .foregroundColor(theme.primary)
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            // Sync selected theme with store on appear
            selectedTheme = themeStore.currentTheme
        }
    }
    
    private func selectTheme(_ theme: ThemeVariant) {
        selectedTheme = theme
        
        // Update the theme store with the new selection
        themeStore.setTheme(theme)
        
        // Automatically dismiss after a shorter delay to show the selection
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            dismiss()
        }
    }
}