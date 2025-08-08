import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingThemePicker = false
    @State private var showingCSVImport = false
    @State private var showingGoalSettings = false
    
    private let themeManager = ThemeManager.shared
    
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
                                                Color.theme.primary,
                                                Color.theme.secondary
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
                            .shadow(color: Color.theme.primary.opacity(0.3), radius: 4, x: 0, y: 2)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Choose Your Theme")
                                    .font(.headline)
                                    .foregroundColor(Color.theme.primaryText)
                                
                                HStack(spacing: Theme.Spacing.xs) {
                                    Text(themeManager.currentTheme.emoji)
                                        .font(.title3)
                                    
                                    Text(themeManager.currentTheme.displayName)
                                        .font(.subheadline)
                                        .foregroundColor(Color.theme.secondaryText)
                                    
                                    Text("•")
                                        .foregroundColor(Color.theme.outline)
                                        .font(.caption)
                                    
                                    Text("5 Beautiful Options")
                                        .font(.caption)
                                        .foregroundColor(Color.theme.primary)
                                        .fontWeight(.medium)
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(Color.theme.outline)
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
                        .foregroundColor(Color.theme.primaryText)
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
                                    .foregroundColor(Color.theme.primaryText)
                                
                                HStack(spacing: Theme.Spacing.xs) {
                                    Text("📊")
                                        .font(.title3)
                                    
                                    Text("Set daily & weekly targets")
                                        .font(.subheadline)
                                        .foregroundColor(Color.theme.secondaryText)
                                    
                                    Text("•")
                                        .foregroundColor(Color.theme.outline)
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
                                .foregroundColor(Color.theme.outline)
                        }
                    }
                    .buttonStyle(.plain)
                } header: {
                    Text("Reading Goals")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.theme.primaryText)
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
                                    .fill(Color.theme.tertiary.opacity(0.15))
                                    .frame(width: 36, height: 36)
                                
                                Image(systemName: "square.and.arrow.down.fill")
                                    .foregroundColor(Color.theme.tertiary)
                                    .font(.system(size: 18, weight: .medium))
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Import Your Books")
                                    .font(.headline)
                                    .foregroundColor(Color.theme.primaryText)
                                
                                HStack(spacing: Theme.Spacing.xs) {
                                    Text("From Goodreads CSV")
                                        .font(.subheadline)
                                        .foregroundColor(Color.theme.secondaryText)
                                    
                                    Text("•")
                                        .foregroundColor(Color.theme.outline)
                                        .font(.caption)
                                    
                                    Text("Quick Setup")
                                        .font(.caption)
                                        .foregroundColor(Color.theme.tertiary)
                                        .fontWeight(.medium)
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(Color.theme.outline)
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
                            print("Export data tapped")
                            HapticFeedbackManager.shared.lightImpact()
                        }
                    )
                } header: {
                    Text("Your Library")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.theme.primaryText)
                }
                
                // About Section
                Section {
                    settingsRow(
                        icon: "info.circle",
                        title: "About Books Tracker",
                        subtitle: "Version 1.0.0 • Made with 💜",
                        action: {
                            // TODO: Show more detailed about info
                            print("About tapped")
                            HapticFeedbackManager.shared.lightImpact()
                        }
                    )
                } header: {
                    Text("Information")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.theme.primaryText)
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
                        .fill(Color.theme.primary.opacity(0.1))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .foregroundColor(Color.theme.primary)
                        .font(.system(size: 18, weight: .medium))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.body)
                        .foregroundColor(Color.theme.primaryText)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(Color.theme.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(Color.theme.outline)
                    .font(.footnote)
                    .fontWeight(.semibold)
            }
            .padding(.vertical, Theme.Spacing.xs)
        }
        .buttonStyle(PlainButtonStyle())
    }
}