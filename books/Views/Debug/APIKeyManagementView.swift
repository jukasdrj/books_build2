#if DEBUG
import SwiftUI

struct APIKeyManagementView: View {
    @StateObject private var keychainService = KeychainService.shared
    @State private var showingClearAlert = false
    @State private var showingResetAlert = false
    @State private var lastRefresh = Date()
    @State private var newAPIKey = ""
    @State private var showingAPIKeyInput = false
    
    private var keyStatusEntries: [(String, Bool)] {
        let status = keychainService.keyStatus()
        let entries = status.map { ($0.key, $0.value) }
        return entries.sorted { $0.0 < $1.0 }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // API Key Status Section
                Section("API Key Status") {
                    ForEach(keyStatusEntries, id: \.0) { service, isConfigured in
                        HStack {
                            Text(service)
                                .bodyLarge()
                            
                            Spacer()
                            
                            HStack(spacing: Theme.Spacing.xs) {
                                if isConfigured {
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
                
                // API Key Configuration Section
                Section("Configure API Key") {
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        if keychainService.keyStatus()["Google Books"] == false {
                            Text("No API key configured. Add your Google Books API key to enable book search.")
                                .bodyMedium()
                                .foregroundColor(.orange)
                        }
                        
                        Button(action: {
                            showingAPIKeyInput = true
                        }) {
                            HStack {
                                Image(systemName: "key.fill")
                                Text(keychainService.keyStatus()["Google Books"] == true ? "Update API Key" : "Add API Key")
                                    .bodyLarge()
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                        }
                        .materialButton(style: .outlined, size: .medium)
                        
                        if keychainService.keyStatus()["Google Books"] == true {
                            Text("API key is securely stored in iOS Keychain")
                                .bodySmall()
                                .foregroundColor(.green)
                        }
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
                    keychainService.clearAllKeys()
                    refreshStatus()
                }
            } message: {
                Text("This will remove all stored API keys. You'll need to restart the app to reload them from defaults.")
            }
            .alert("Reset to Defaults", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    keychainService.resetToDefaults()
                    refreshStatus()
                }
            } message: {
                Text("This will reset all API keys to their default values, overwriting any custom configurations.")
            }
            .sheet(isPresented: $showingAPIKeyInput) {
                APIKeyInputView(
                    apiKey: $newAPIKey,
                    onSave: { key in
                        keychainService.googleBooksAPIKey = key
                        refreshStatus()
                        showingAPIKeyInput = false
                        newAPIKey = ""
                    },
                    onCancel: {
                        showingAPIKeyInput = false
                        newAPIKey = ""
                    }
                )
            }
        }
    }
    
    private func refreshStatus() {
        lastRefresh = Date()
        // Force UI refresh by updating the keychainService
        keychainService.objectWillChange.send()
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

// MARK: - API Key Input View

private struct APIKeyInputView: View {
    @Binding var apiKey: String
    let onSave: (String) -> Void
    let onCancel: () -> Void
    @FocusState private var isKeyFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.lg) {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    Text("Google Books API Key")
                        .titleMedium()
                    
                    Text("Enter your Google Books API key. This will be securely stored in the iOS Keychain.")
                        .bodyMedium()
                        .foregroundColor(.secondary)
                    
                    SecureField("API Key", text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                        .focused($isKeyFieldFocused)
                        .onAppear {
                            isKeyFieldFocused = true
                        }
                }
                .padding()
                
                VStack(spacing: Theme.Spacing.sm) {
                    Text("How to get your API key:")
                        .titleSmall()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("1. Visit Google Cloud Console")
                        Text("2. Enable Books API")
                        Text("3. Create credentials → API Key")
                        Text("4. Restrict to Books API")
                    }
                    .bodySmall()
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)
                .padding(.horizontal)
                
                Spacer()
                
                HStack(spacing: Theme.Spacing.md) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .materialButton(style: .outlined, size: .medium)
                    
                    Button("Save") {
                        onSave(apiKey)
                    }
                    .materialButton(style: .filled, size: .medium)
                    .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
            }
            .navigationTitle("API Key")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Preview

#Preview {
    APIKeyManagementView()
        .environment(\.appTheme, AppColorTheme(variant: .purpleBoho))
}

#endif