//
//  DataErrorRecoveryView.swift
//  books
//
//  Created by Claude on critical production fix
//

import SwiftUI

/// Emergency error recovery view displayed when SwiftData initialization fails
/// Prevents app crashes by providing graceful error handling and recovery options
struct DataErrorRecoveryView: View {
    let error: Error?
    @ObservedObject var themeStore: ThemeStore
    let onRetry: () -> Void
    
    @State private var showingTechnicalDetails = false
    @State private var isRetrying = false
    
    init(error: Error?, themeStore: ThemeStore, onRetry: @escaping () -> Void) {
        self.error = error
        self.themeStore = themeStore
        self.onRetry = onRetry
        
        // Report critical SwiftData error
        if let error = error {
            CrashReportingService.shared.reportSwiftDataError(error, failureType: .initialization)
        }
    }
    
    var body: some View {
        ZStack {
            // Use theme background
            themeStore.appTheme.background
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // Error Icon
                ZStack {
                    Circle()
                        .fill(themeStore.appTheme.error.opacity(0.1))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(themeStore.appTheme.error)
                }
                
                VStack(spacing: 12) {
                    Text("Data Initialization Failed")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(themeStore.appTheme.primaryText)
                        .multilineTextAlignment(.center)
                    
                    Text("We're unable to start the app with your data. This might be a temporary issue.")
                        .font(.body)
                        .foregroundColor(themeStore.appTheme.primaryText.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                VStack(spacing: 16) {
                    // Retry Button
                    Button(action: handleRetry) {
                        HStack {
                            if isRetrying {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(themeStore.appTheme.onPrimary)
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                            Text(isRetrying ? "Retrying..." : "Try Again")
                                .fontWeight(.medium)
                        }
                        .foregroundColor(themeStore.appTheme.onPrimary)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(themeStore.appTheme.primary)
                        .cornerRadius(12)
                    }
                    .disabled(isRetrying)
                    .padding(.horizontal, 48)
                    
                    // Emergency Contact Button
                    Button("Contact Support") {
                        if let url = URL(string: "mailto:support@papertracks.app?subject=Data%20Initialization%20Error") {
                            UIApplication.shared.open(url)
                        }
                    }
                    .foregroundColor(themeStore.appTheme.primary)
                    .font(.body)
                    
                    // Technical Details Toggle
                    Button(showingTechnicalDetails ? "Hide Details" : "Show Technical Details") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingTechnicalDetails.toggle()
                        }
                    }
                    .foregroundColor(themeStore.appTheme.primaryText.opacity(0.6))
                    .font(.caption)
                }
                
                if showingTechnicalDetails {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Technical Information:")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(themeStore.appTheme.primaryText.opacity(0.8))
                        
                        ScrollView {
                            Text(errorDescription)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(themeStore.appTheme.primaryText.opacity(0.6))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(themeStore.appTheme.surface.opacity(0.5))
                                .cornerRadius(8)
                        }
                        .frame(maxHeight: 120)
                    }
                    .padding(.horizontal, 32)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
                
                Spacer()
                
                // App Info
                VStack(spacing: 4) {
                    Text("PaperTracks")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(themeStore.appTheme.primaryText.opacity(0.6))
                    
                    Text("Version \(appVersion)")
                        .font(.caption2)
                        .foregroundColor(themeStore.appTheme.primaryText.opacity(0.4))
                }
            }
            .padding(.vertical, 32)
        }
        .preferredColorScheme(nil)
    }
    
    private var errorDescription: String {
        guard let error = error else { return "Unknown error occurred during initialization" }
        return String(describing: error)
    }
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    private func handleRetry() {
        guard !isRetrying else { return }
        
        isRetrying = true
        HapticFeedbackManager.shared.lightImpact()
        
        // Add a slight delay to show the retry state
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            onRetry()
            isRetrying = false
        }
    }
}

#Preview {
    DataErrorRecoveryView(
        error: NSError(domain: "SwiftData", code: 100, userInfo: [
            NSLocalizedDescriptionKey: "Unable to create ModelContainer"
        ]),
        themeStore: ThemeStore(),
        onRetry: {}
    )
}