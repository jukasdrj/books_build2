import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.unifiedThemeStore) private var unifiedThemeStore
    @Environment(\.modelContext) private var modelContext
    @State private var showingThemePicker = false
    @State private var showingCSVImport = false
    @State private var showingGoalSettings = false
    @State private var showingLibraryReset = false
    @State private var showingAbout = false
    
    
    var body: some View {
        NavigationStack {
            if unifiedThemeStore.currentTheme.isLiquidGlass {
                liquidGlassContent
            } else {
                materialDesignContent
            }
        }
        .sheet(isPresented: $showingThemePicker) {
            ThemePickerView()
        }
        .sheet(isPresented: $showingCSVImport) {
            CSVImportView()
        }
        .sheet(isPresented: $showingGoalSettings) {
            GoalSettingsView()
        }
        .sheet(isPresented: $showingLibraryReset) {
            LibraryResetConfirmationView(modelContext: modelContext)
        }
        .sheet(isPresented: $showingAbout) {
            AboutThisAppView()
        }
    }
    
    @ViewBuilder
    private var liquidGlassContent: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                VStack(spacing: 12) {
                    LiquidGlassButton("Choose Your Theme", style: .glass) {
                        showingThemePicker = true
                        Task { @MainActor in
                            HapticFeedbackManager.shared.lightImpact()
                        }
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
                
                VStack(spacing: 12) {
                    LiquidGlassButton("Reading Goals", style: .primary) {
                        showingGoalSettings = true
                        Task { @MainActor in
                            HapticFeedbackManager.shared.lightImpact()
                        }
                    }
                }
                .liquidGlassSection {
                    Label("Reading Goals", systemImage: "target")
                }
                
                VStack(spacing: 12) {
                    LiquidGlassButton("Import Your Books", style: .secondary) {
                        showingCSVImport = true
                        Task { @MainActor in
                            HapticFeedbackManager.shared.lightImpact()
                        }
                    }
                    
                    LiquidGlassButton("Reset Library", style: .glass) {
                        showingLibraryReset = true
                        Task { @MainActor in
                            HapticFeedbackManager.shared.warning()
                        }
                    }
                }
                .liquidGlassSection {
                    Label("Your Library", systemImage: "books.vertical")
                }
                
                VStack(spacing: 12) {
                    LiquidGlassButton("About Books Tracker", style: .glass) {
                        showingAbout = true
                        Task { @MainActor in
                            HapticFeedbackManager.shared.lightImpact()
                        }
                    }
                }
                .liquidGlassSection {
                    Label("Information", systemImage: "info.circle")
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
                    Task { @MainActor in
                        HapticFeedbackManager.shared.lightImpact()
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var materialDesignContent: some View {
        List {
            // Theme Section
            Section("Personalization") {
                Button {
                    showingThemePicker = true
                    Task { @MainActor in
                        HapticFeedbackManager.shared.lightImpact()
                    }
                } label: {
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            unifiedThemeStore.appTheme.primary,
                                            unifiedThemeStore.appTheme.secondary
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "paintbrush.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 18, weight: .medium))
                        }
                        .shadow(color: unifiedThemeStore.appTheme.primary.opacity(0.3), radius: 4, x: 0, y: 2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Choose Your Theme")
                                .font(.headline)
                                .foregroundColor(unifiedThemeStore.appTheme.primaryText)
                            
                            HStack(spacing: 8) {
                                Text(unifiedThemeStore.currentTheme.emoji)
                                    .font(.title3)
                                
                                Text(unifiedThemeStore.currentTheme.displayName)
                                    .font(.subheadline)
                                    .foregroundColor(unifiedThemeStore.appTheme.secondaryText)
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(unifiedThemeStore.appTheme.outline)
                            .font(.footnote)
                            .fontWeight(.semibold)
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Appearance Preference Selection
                Button {
                    cycleAppearancePreference()
                    Task { @MainActor in
                        HapticFeedbackManager.shared.lightImpact()
                    }
                } label: {
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: unifiedThemeStore.appearancePreference.icon)
                                .foregroundColor(.white)
                                .font(.system(size: 18, weight: .medium))
                        }
                        .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("App Appearance")
                                .font(.headline)
                                .foregroundColor(unifiedThemeStore.appTheme.primaryText)
                            
                            HStack(spacing: 8) {
                                Image(systemName: unifiedThemeStore.appearancePreference.icon)
                                    .font(.title3)
                                    .foregroundColor(unifiedThemeStore.appTheme.primary)
                                
                                Text(unifiedThemeStore.appearancePreference.displayName)
                                    .font(.subheadline)
                                    .foregroundColor(unifiedThemeStore.appTheme.secondaryText)
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(unifiedThemeStore.appTheme.outline)
                            .font(.footnote)
                            .fontWeight(.semibold)
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Reading Goals Section
            Section("Reading Goals") {
                settingsRow(
                    icon: "target",
                    title: "Reading Goals",
                    subtitle: "Set daily & weekly targets",
                    action: {
                        showingGoalSettings = true
                        Task { @MainActor in
                            HapticFeedbackManager.shared.lightImpact()
                        }
                    }
                )
            }
            
            // Your Library Section
            Section("Your Library") {
                settingsRow(
                    icon: "square.and.arrow.down.fill",
                    title: "Import Your Books",
                    subtitle: "From Goodreads CSV",
                    action: {
                        showingCSVImport = true
                        Task { @MainActor in
                            HapticFeedbackManager.shared.lightImpact()
                        }
                    }
                )
                
                Button {
                    showingLibraryReset = true
                    Task { @MainActor in
                        HapticFeedbackManager.shared.warning()
                    }
                } label: {
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.red.opacity(0.15))
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "trash.fill")
                                .foregroundColor(.red)
                                .font(.system(size: 18, weight: .medium))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Reset Library")
                                .font(.body)
                                .foregroundColor(.red)
                            
                            Text("Delete all books and data")
                                .font(.caption)
                                .foregroundColor(unifiedThemeStore.appTheme.secondaryText)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.red.opacity(0.6))
                            .font(.footnote)
                            .fontWeight(.semibold)
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Information Section
            Section("Information") {
                settingsRow(
                    icon: "info.circle",
                    title: "About Books Tracker",
                    subtitle: "Version 1.0.0 • Made with 💜",
                    action: {
                        showingAbout = true
                        Task { @MainActor in
                            HapticFeedbackManager.shared.lightImpact()
                        }
                    }
                )
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                    Task { @MainActor in
                        HapticFeedbackManager.shared.lightImpact()
                    }
                }
                .foregroundColor(unifiedThemeStore.appTheme.primary)
                .fontWeight(.semibold)
            }
        }
    }
    
    @ViewBuilder
    private func settingsRow(
        icon: String,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(unifiedThemeStore.appTheme.primary.opacity(0.1))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .foregroundColor(unifiedThemeStore.appTheme.primary)
                        .font(.system(size: 18, weight: .medium))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.body)
                        .foregroundColor(unifiedThemeStore.appTheme.primaryText)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(unifiedThemeStore.appTheme.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(unifiedThemeStore.appTheme.outline)
                    .font(.footnote)
                    .fontWeight(.semibold)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    /// Cycles through appearance preferences (system -> light -> dark -> system)
    private func cycleAppearancePreference() {
        let allPreferences = AppearancePreference.allCases
        let currentIndex = allPreferences.firstIndex(of: unifiedThemeStore.appearancePreference) ?? 0
        let nextIndex = (currentIndex + 1) % allPreferences.count
        let nextPreference = allPreferences[nextIndex]
        
        unifiedThemeStore.setAppearance(nextPreference)
    }
}