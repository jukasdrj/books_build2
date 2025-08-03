import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingThemePicker = false
    @State private var showingCSVImport = false
    
    private let themeManager = ThemeManager.shared
    
    var body: some View {
        NavigationStack {
            List {
                // Theme Section
                Section("Appearance") {
                    Button {
                        showingThemePicker = true
                        HapticFeedbackManager.shared.lightImpact()
                    } label: {
                        HStack {
                            Image(systemName: "paintbrush.fill")
                                .foregroundColor(Color.theme.primary)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Theme")
                                    .font(.body)
                                
                                Text(themeManager.currentTheme.displayName)
                                    .font(.caption)
                                    .foregroundColor(Color.theme.secondaryText)
                            }
                            
                            Spacer()
                            
                            Text(themeManager.currentTheme.emoji)
                                .font(.title2)
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(Color.theme.outline)
                                .font(.caption)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Reading Goals Section
                Section("Reading Goals") {
                    settingsRow(
                        icon: "target",
                        title: "Daily Page Goal",
                        subtitle: "Not set",
                        action: {
                            // TODO: Implement daily page goal settings
                            print("Daily page goal tapped")
                            HapticFeedbackManager.shared.lightImpact()
                        }
                    )
                    
                    settingsRow(
                        icon: "calendar",
                        title: "Monthly Book Goal",
                        subtitle: "Not set",
                        action: {
                            // TODO: Implement monthly book goal settings
                            print("Monthly book goal tapped")
                            HapticFeedbackManager.shared.lightImpact()
                        }
                    )
                }
                
                // Data Section
                Section("Data") {
                    settingsRow(
                        icon: "square.and.arrow.down",
                        title: "Import Books",
                        subtitle: "From Goodreads CSV",
                        action: {
                            showingCSVImport = true
                            HapticFeedbackManager.shared.lightImpact()
                        }
                    )
                    
                    settingsRow(
                        icon: "square.and.arrow.up",
                        title: "Export Data",
                        subtitle: "Backup your library",
                        action: {
                            // TODO: Implement export functionality
                            print("Export data tapped")
                            HapticFeedbackManager.shared.lightImpact()
                        }
                    )
                }
                
                // About Section
                Section("About") {
                    settingsRow(
                        icon: "info.circle",
                        title: "App Version",
                        subtitle: "1.0.0",
                        action: {
                            // TODO: Show more detailed about info
                            print("App version tapped")
                            HapticFeedbackManager.shared.lightImpact()
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
                        HapticFeedbackManager.shared.lightImpact()
                    }
                    .foregroundColor(Color.theme.primary)
                }
            }
        }
        .sheet(isPresented: $showingThemePicker) {
            ThemePickerView()
        }
        .sheet(isPresented: $showingCSVImport) {
            CSVImportView()
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
                Image(systemName: icon)
                    .foregroundColor(Color.theme.primary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(Color.theme.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(Color.theme.outline)
                    .font(.caption)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}