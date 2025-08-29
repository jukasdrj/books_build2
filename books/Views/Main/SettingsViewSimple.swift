import SwiftUI

// Simple SettingsView for testing the liquid glass migration
struct SettingsViewSimple: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.unifiedThemeStore) private var unifiedThemeStore
    
    var body: some View {
        NavigationStack {
            if unifiedThemeStore.currentTheme.isLiquidGlass {
                liquidGlassContent
            } else {
                materialDesignContent
            }
        }
        .liquidGlassNavigation(material: .thin, vibrancy: .medium)
    }
    
    @ViewBuilder
    private var liquidGlassContent: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                VStack(spacing: 12) {
                    LiquidGlassButton("Choose Your Theme", style: .glass) {
                        // Theme picker action
                    }
                    
                    LiquidGlassSegmentedControl(
                        selection: Binding(
                            get: { unifiedThemeStore.appearancePreference },
                            set: { unifiedThemeStore.setAppearance($0) }
                        ),
                        options: AppearancePreference.allCases,
                        displayName: { $0.displayName }
                    )
                }
                .liquidGlassSection {
                    Label("Personalization", systemImage: "paintbrush.fill")
                }
            }
            .padding(.horizontal, 16)
        }
        .liquidGlassBackground(material: .ultraThin, vibrancy: .subtle)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                LiquidGlassButton("Done", style: .secondary) {
                    dismiss()
                }
            }
        }
    }
    
    @ViewBuilder
    private var materialDesignContent: some View {
        List {
            Section("Personalization") {
                Text("Material Design 3 Fallback")
            }
        }
        .navigationTitle("Settings")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}