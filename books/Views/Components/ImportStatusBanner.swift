//
//  ImportStatusBanner.swift
//  books
//
//  A prominent banner that shows CSV import progress at the top of the library
//

import SwiftUI
import SwiftData

struct ImportStatusBanner: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.modelContext) private var modelContext
    @State private var importService: CSVImportService?
    @State private var isExpanded = false
    @State private var showCancelAlert = false
    @State private var updateTimer: Timer?
    @State private var refreshTrigger = 0  // Used to force UI updates
    
    var body: some View {
        Group {
            if let service = importService, 
               service.isImporting,
               let progress = service.importProgress {
                
                VStack(spacing: 0) {
                    // Main banner
                    Button(action: { withAnimation { isExpanded.toggle() } }) {
                        HStack(spacing: Theme.Spacing.md) {
                            // Progress indicator
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                            
                            // Status text
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Importing Books...")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Text("\(progress.processedBooks) of \(progress.totalBooks) books")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            
                            Spacer()
                            
                            // Progress percentage
                            Text("\(Int(progress.progress * 100))%")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                            
                            // Expand/collapse chevron
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .foregroundColor(.white.opacity(0.8))
                                .font(.system(size: 12))
                        }
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.vertical, Theme.Spacing.sm)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .background(
                        LinearGradient(
                            colors: [theme.primary, theme.primary.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    
                    // Expanded details
                    if isExpanded {
                        VStack(spacing: Theme.Spacing.sm) {
                            // Progress bar
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color.white.opacity(0.2))
                                        .frame(height: 4)
                                        .cornerRadius(2)
                                    
                                    Rectangle()
                                        .fill(Color.white)
                                        .frame(width: geometry.size.width * progress.progress, height: 4)
                                        .cornerRadius(2)
                                        .animation(.linear(duration: 0.3), value: progress.progress)
                                }
                            }
                            .frame(height: 4)
                            .padding(.horizontal, Theme.Spacing.md)
                            
                            // Statistics
                            HStack(spacing: Theme.Spacing.lg) {
                                ImportStat(
                                    icon: "checkmark.circle.fill",
                                    value: "\(progress.successfulImports)",
                                    label: "Imported"
                                )
                                
                                ImportStat(
                                    icon: "arrow.2.circlepath",
                                    value: "\(progress.duplicatesSkipped)",
                                    label: "Duplicates"
                                )
                                
                                if progress.failedImports > 0 {
                                    ImportStat(
                                        icon: "exclamationmark.triangle.fill",
                                        value: "\(progress.failedImports)",
                                        label: "Failed"
                                    )
                                }
                                
                                Spacer()
                                
                                // Cancel button
                                Button(action: { showCancelAlert = true }) {
                                    Text("Cancel")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, Theme.Spacing.sm)
                                        .padding(.vertical, 4)
                                        .background(Color.white.opacity(0.2))
                                        .cornerRadius(4)
                                }
                            }
                            .padding(.horizontal, Theme.Spacing.md)
                            
                            // Current status message
                            if !progress.message.isEmpty {
                                Text(progress.message)
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.8))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, Theme.Spacing.md)
                            }
                        }
                        .padding(.vertical, Theme.Spacing.sm)
                        .background(theme.primary.opacity(0.95))
                    }
                }
                .id(refreshTrigger)  // Force refresh when timer updates
                .transition(.move(edge: .top).combined(with: .opacity))
                .shadow(radius: 4)
                .alert("Cancel Import?", isPresented: $showCancelAlert) {
                    Button("Continue Import", role: .cancel) { }
                    Button("Cancel", role: .destructive) {
                        importService?.cancelImport()
                    }
                } message: {
                    Text("This will stop the import process. Books already imported will remain in your library.")
                }
            }
        }
        .onAppear {
            setupImportService()
            startUpdateTimer()
        }
        .onDisappear {
            stopUpdateTimer()
        }
        .onReceive(NotificationCenter.default.publisher(for: .importServiceCreated)) { notification in
            if let service = notification.object as? CSVImportService {
                self.importService = service
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .csvImportDidStart)) { notification in
            if let service = notification.object as? CSVImportService {
                self.importService = service
                print("[ImportStatusBanner] Received csvImportDidStart notification")
                print("[ImportStatusBanner] Service is importing: \(service.isImporting)")
                print("[ImportStatusBanner] Progress exists: \(service.importProgress != nil)")
            }
        }
        .animation(.easeInOut(duration: 0.3), value: importService?.isImporting ?? false)
    }
    
    private func setupImportService() {
        // Get the shared import service from BackgroundImportCoordinator
        if let coordinator = BackgroundImportCoordinator.shared {
            self.importService = coordinator.csvImportService
            print("[ImportStatusBanner] Service connected: \(importService != nil)")
            print("[ImportStatusBanner] Is importing: \(importService?.isImporting ?? false)")
            print("[ImportStatusBanner] Progress exists: \(importService?.importProgress != nil)")
        } else {
            print("[ImportStatusBanner] No coordinator found")
        }
    }
    
    private func startUpdateTimer() {
        stopUpdateTimer()  // Stop any existing timer
        
        // Check every 0.5 seconds for import state
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            Task { @MainActor in
                // Re-check for the coordinator and service
                if self.importService == nil {
                    self.setupImportService()
                }
                
                // Force UI update by incrementing the refresh trigger
                self.refreshTrigger += 1
            }
        }
    }
    
    private func stopUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
}

struct ImportStat: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.8))
            
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                
                Text(label)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
}

// Notification extension for service communication
extension Notification.Name {
    static let importServiceCreated = Notification.Name("importServiceCreated")
    static let csvImportDidStart = Notification.Name("csvImportDidStart")
    static let csvImportDidComplete = Notification.Name("csvImportDidComplete")
}
