import SwiftUI

// MARK: - iOS 26 Migration Status: ✅ FULLY MIGRATED
// Uses UnifiedThemeStore bridge pattern with dual-theme category display

struct ThemePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    @Environment(\.unifiedThemeStore) private var unifiedThemeStore
    @State private var selectedTheme: UnifiedThemeVariant
    
    init() {
        // Will be updated in onAppear to sync with store
        _selectedTheme = State(initialValue: .purpleBoho)
    }
    
    var body: some View {
        VStack(spacing: 0) {
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
                            
                            Text("Experience both iOS 26 Liquid Glass and Material Design 3 themes, each creating a unique reading sanctuary tailored to your style.")
                                .font(.body)
                                .foregroundColor(theme.secondaryText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, Theme.Spacing.md)
                        }
                    }
                    
                    // Theme sections with enhanced presentation
                    VStack(spacing: Theme.Spacing.xl) {
                        
                        // iOS 26 Liquid Glass Themes Section
                        if !UnifiedThemeStore.liquidGlassThemes.isEmpty {
                            VStack(spacing: Theme.Spacing.md) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "sparkles")
                                                .font(.title2)
                                                .foregroundStyle(
                                                    LinearGradient(
                                                        colors: [Color.blue, Color.purple],
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                )
                                            
                                            Text("iOS 26 Liquid Glass")
                                                .font(.title2)
                                                .fontWeight(.bold)
                                                .foregroundColor(theme.primaryText)
                                        }
                                        
                                        Text("Modern glass materials with depth and translucency")
                                            .font(.caption)
                                            .foregroundColor(theme.secondaryText)
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 4)
                                
                                VStack(spacing: Theme.Spacing.lg) {
                                    ForEach(UnifiedThemeStore.liquidGlassThemes) { themeVariant in
                                        UnifiedThemePreviewCard(
                                            theme: themeVariant,
                                            isSelected: selectedTheme == themeVariant,
                                            onSelect: {
                                                selectTheme(themeVariant)
                                            }
                                        )
                                        .shadow(
                                            color: selectedTheme == themeVariant ? 
                                                Color.blue.opacity(0.3) : 
                                                Color.black.opacity(0.05),
                                            radius: selectedTheme == themeVariant ? 12 : 4,
                                            x: 0,
                                            y: selectedTheme == themeVariant ? 8 : 2
                                        )
                                    }
                                }
                            }
                        }
                        
                        // Material Design 3 Themes Section
                        if !UnifiedThemeStore.legacyThemes.isEmpty {
                            VStack(spacing: Theme.Spacing.md) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "rectangle.3.group.fill")
                                                .font(.title2)
                                                .foregroundStyle(
                                                    LinearGradient(
                                                        colors: [Color.green, Color.teal],
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                )
                                            
                                            Text("Material Design 3")
                                                .font(.title2)
                                                .fontWeight(.bold)
                                                .foregroundColor(theme.primaryText)
                                        }
                                        
                                        Text("Classic material design with rich colors and shadows")
                                            .font(.caption)
                                            .foregroundColor(theme.secondaryText)
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 4)
                                
                                VStack(spacing: Theme.Spacing.lg) {
                                    ForEach(UnifiedThemeStore.legacyThemes) { themeVariant in
                                        UnifiedThemePreviewCard(
                                            theme: themeVariant,
                                            isSelected: selectedTheme == themeVariant,
                                            onSelect: {
                                                selectTheme(themeVariant)
                                            }
                                        )
                                        .shadow(
                                            color: selectedTheme == themeVariant ? 
                                                Color.blue.opacity(0.3) : 
                                                Color.black.opacity(0.05),
                                            radius: selectedTheme == themeVariant ? 12 : 4,
                                            x: 0,
                                            y: selectedTheme == themeVariant ? 8 : 2
                                        )
                                    }
                                }
                            }
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
                selectedTheme = unifiedThemeStore.currentTheme
            }
        }
    }
    
    private func selectTheme(_ theme: UnifiedThemeVariant) {
        selectedTheme = theme
        
        // Update the unified theme store with the new selection
        unifiedThemeStore.setTheme(theme)
        
        // Automatically dismiss after a shorter delay to show the selection
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            dismiss()
        }
    }
}