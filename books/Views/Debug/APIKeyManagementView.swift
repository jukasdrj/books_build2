#if DEBUG
import SwiftUI

struct APIKeyManagementView: View {
    @StateObject private var apiKeyManager = APIKeyManager.shared
    @State private var showingClearAlert = false
    @State private var showingResetAlert = false
    @State private var lastRefresh = Date()
    
    var body: some View {
        NavigationView {
            List {
                // API Key Status Section
                Section("API Key Status") {
                    ForEach(Array(apiKeyManager.keyStatus().keys.sorted()), id: \.self) { service in
                        HStack {
                            Text(service)
                                .bodyLarge()
                            
                            Spacer()
                            
                            HStack(spacing: Theme.Spacing.xs) {
                                if apiKeyManager.keyStatus()[service] == true {
                                    Image(systemName: "checkmark.shield.fill")
                                        .foregroundColor(.green)
                                    Text("Configured")
                                        .labelMedium()
                                        .foregroundColor(.green)
                                } else {
                                    Image(systemName: "exclamationmark.shield.fill")
                                        .foregroundColor(.red)
                                    Text("Missing")
                                        .labelMedium()
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        .padding(.vertical, Theme.Spacing.xs)
                    }
                }
                
                // Security Information Section
                Section("Security Information") {
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        HStack(spacing: Theme.Spacing.sm) {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(.green)
                            Text("Keychain Protected")
                                .titleMedium()
                        }
                        
                        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                            SecurityFeatureRow(
                                icon: "key.fill",
                                title: "Encrypted Storage",
                                description: "Keys stored in iOS Keychain with hardware encryption"
                            )
                            
                            SecurityFeatureRow(
                                icon: "faceid",
                                title: "Access Control",
                                description: "Requires device unlock for key access"
                            )
                            
                            SecurityFeatureRow(
                                icon: "app.badge.fill",
                                title: "App Isolation",
                                description: "Keys are sandboxed to this app only"
                            )
                        }
                        
                        Text("For maximum security, consider migrating to a server-side proxy solution.")
                            .labelSmall()
                            .foregroundColor(.secondary)
                            .padding(.top, Theme.Spacing.xs)
                    }
                    .padding(.vertical, Theme.Spacing.sm)
                }
                
                // Actions Section
                Section("Management Actions") {
                    VStack(spacing: Theme.Spacing.md) {
                        Button(action: refreshStatus) {
                            Label("Refresh Status", systemImage: "arrow.clockwise")
                                .frame(maxWidth: .infinity)
                        }
                        .materialButton(style: .tonal)
                        
                        Button(action: { showingResetAlert = true }) {
                            Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
                                .frame(maxWidth: .infinity)
                        }
                        .materialButton(style: .outlined)
                        
                        Button(action: { showingClearAlert = true }) {
                            Label("Clear All Keys", systemImage: "trash.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .materialButton(style: .destructive)
                    }
                    .padding(.vertical, Theme.Spacing.sm)
                }
                
                // Debug Information Section
                Section("Debug Information") {
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        HStack {
                            Text("Last Refresh:")
                                .labelMedium()
                            Spacer()
                            Text(lastRefresh.formatted(date: .omitted, time: .shortened))
                                .labelMedium()
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Keychain Service:")
                                .labelMedium()
                            Spacer()
                            Text(Bundle.main.bundleIdentifier ?? "Unknown")
                                .labelMedium()
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Security Level:")
                                .labelMedium()
                            Spacer()
                            Text("kSecAttrAccessibleWhenUnlocked")
                                .labelMedium()
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("API Security")
            .titleLarge()
            .onAppear {
                refreshStatus()
            }
            .alert("Clear All Keys", isPresented: $showingClearAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    apiKeyManager.clearAllKeys()
                    refreshStatus()
                }
            } message: {
                Text("This will remove all stored API keys. You'll need to restart the app to reload them from defaults.")
            }
            .alert("Reset to Defaults", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    apiKeyManager.resetToDefaults()
                    refreshStatus()
                }
            } message: {
                Text("This will reset all API keys to their default values, overwriting any custom configurations.")
            }
        }
    }
    
    private func refreshStatus() {
        lastRefresh = Date()
        // Force UI refresh by updating the apiKeyManager
        apiKeyManager.objectWillChange.send()
    }
}

// MARK: - Security Feature Row Component

private struct SecurityFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .labelMedium()
                    .fontWeight(.medium)
                
                Text(description)
                    .labelSmall()
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    APIKeyManagementView()
        .environment(\.appTheme, AppColorTheme(variant: .purpleBoho))
}

#endif