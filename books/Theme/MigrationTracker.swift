import SwiftUI

// MARK: - Migration Tracker
/// Simple migration tracking for iOS 26 Liquid Glass migration
@MainActor
final class MigrationTracker: ObservableObject, @unchecked Sendable {
    static let shared = MigrationTracker()
    
    @Published private(set) var accessedViews: Set<String> = []
    @Published private(set) var migratedViews: Set<String> = []
    
    private init() {}
    
    func markViewAsAccessed(_ viewName: String) {
        accessedViews.insert(viewName)
    }
    
    func markViewAsMigrated(_ viewName: String) {
        migratedViews.insert(viewName)
        print("✅ View migrated: \(viewName)")
    }
    
    var migrationProgress: Double {
        guard !accessedViews.isEmpty else { return 0.0 }
        return Double(migratedViews.count) / Double(accessedViews.count)
    }
}