import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var currentTheme
    @Environment(\.themeStore) private var themeStore
    @State private var showingThemePicker = false
    @State private var showingCSVImport = false
    @State private var showingGoalSettings = false
    
    
    var body: some View {
        NavigationStack {
            List {
                // Theme Section - Enhanced for App Store appeal
                Section {
                    Button {
                        showingThemePicker = true
                        HapticFeedbackManager.shared.lightImpact()
                    } label: {
                        HStack(spacing: Theme.Spacing.md) {
                            // Beautiful gradient icon background
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                currentTheme.primary,
                                                currentTheme.secondary
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
                            .shadow(color: currentTheme.primary.opacity(0.3), radius: 4, x: 0, y: 2)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Choose Your Theme")
                                    .font(.headline)
                                    .foregroundColor(currentTheme.primaryText)
                                
                                HStack(spacing: Theme.Spacing.xs) {
                                    Text(themeStore.currentTheme.emoji)
                                        .font(.title3)
                                    
                                    Text(themeStore.currentTheme.displayName)
                                        .font(.subheadline)
                                        .foregroundColor(currentTheme.secondaryText)
                                    
                                    Text("•")
                                        .foregroundColor(currentTheme.outline)
                                        .font(.caption)
                                    
                                    Text("5 Beautiful Options")
                                        .font(.caption)
                                        .foregroundColor(currentTheme.primary)
                                        .fontWeight(.medium)
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(currentTheme.outline)
                                .font(.footnote)
                                .fontWeight(.semibold)
                        }
                        .padding(.vertical, Theme.Spacing.xs)
                    }
                    .buttonStyle(PlainButtonStyle())
                } header: {
                    Text("Personalization")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(currentTheme.primaryText)
                }
                
                // Reading Goals Section - Enhanced
                Section {
                    Button {
                        showingGoalSettings = true
                        HapticFeedbackManager.shared.lightImpact()
                    } label: {
                        HStack(spacing: Theme.Spacing.md) {
                            // Beautiful gradient icon background
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                .orange,
                                                .red
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 36, height: 36)
                                
                                Image(systemName: "target")
                                    .foregroundColor(.white)
                                    .font(.system(size: 18, weight: .medium))
                            }
                            .shadow(color: Color.orange.opacity(0.3), radius: 4, x: 0, y: 2)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Reading Goals")
                                    .font(.headline)
                                    .foregroundColor(currentTheme.primaryText)
                                
                                HStack(spacing: Theme.Spacing.xs) {
                                    Text("📊")
                                        .font(.title3)
                                    
                                    Text("Set daily & weekly targets")
                                        .font(.subheadline)
                                        .foregroundColor(currentTheme.secondaryText)
                                    
                                    Text("•")
                                        .foregroundColor(currentTheme.outline)
                                        .font(.caption)
                                    
                                    Text("Track Your Progress")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                            }
                            
                            Spacer()
                            
                            // Subtle iOS-style disclosure indicator
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(currentTheme.outline)
                        }
                    }
                    .buttonStyle(.plain)
                } header: {
                    Text("Reading Goals")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(currentTheme.primaryText)
                }
                
                // Data Section - Enhanced for CSV import prominence
                Section {
                    Button {
                        showingCSVImport = true
                        HapticFeedbackManager.shared.lightImpact()
                    } label: {
                        HStack(spacing: Theme.Spacing.md) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(currentTheme.tertiary.opacity(0.15))
                                    .frame(width: 36, height: 36)
                                
                                Image(systemName: "square.and.arrow.down.fill")
                                    .foregroundColor(currentTheme.tertiary)
                                    .font(.system(size: 18, weight: .medium))
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Import Your Books")
                                    .font(.headline)
                                    .foregroundColor(currentTheme.primaryText)
                                
                                HStack(spacing: Theme.Spacing.xs) {
                                    Text("From Goodreads CSV")
                                        .font(.subheadline)
                                        .foregroundColor(currentTheme.secondaryText)
                                    
                                    Text("•")
                                        .foregroundColor(currentTheme.outline)
                                        .font(.caption)
                                    
                                    Text("Quick Setup")
                                        .font(.caption)
                                        .foregroundColor(currentTheme.tertiary)
                                        .fontWeight(.medium)
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(currentTheme.outline)
                                .font(.footnote)
                                .fontWeight(.semibold)
                        }
                        .padding(.vertical, Theme.Spacing.xs)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    settingsRow(
                        icon: "square.and.arrow.up",
                        title: "Export Your Data",
                        subtitle: "Backup your reading library",
                        action: {
                            // TODO: Implement export functionality
// print("Export data tapped")
                            HapticFeedbackManager.shared.lightImpact()
                        }
                    )
                } header: {
                    Text("Your Library")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(currentTheme.primaryText)
                }
                
                // About Section
                Section {
                    settingsRow(
                        icon: "info.circle",
                        title: "About Books Tracker",
                        subtitle: "Version 1.0.0 • Made with 💜",
                        action: {
                            // TODO: Show more detailed about info
// print("About tapped")
                            HapticFeedbackManager.shared.lightImpact()
                        }
                    )
                } header: {
                    Text("Information")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(currentTheme.primaryText)
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
                    .foregroundColor(currentTheme.primary)
                    .fontWeight(.semibold)
                }
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
    }
    
    @ViewBuilder
    private func settingsRow(
        icon: String,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(currentTheme.primary.opacity(0.1))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .foregroundColor(currentTheme.primary)
                        .font(.system(size: 18, weight: .medium))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.body)
                        .foregroundColor(currentTheme.primaryText)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(currentTheme.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(currentTheme.outline)
                    .font(.footnote)
                    .fontWeight(.semibold)
            }
            .padding(.vertical, Theme.Spacing.xs)
        }
        .buttonStyle(PlainButtonStyle())
    }
}