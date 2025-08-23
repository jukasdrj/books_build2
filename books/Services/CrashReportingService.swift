//
//  CrashReportingService.swift
//  books
//
//  Created by Claude on production stability fix
//

import Foundation
import UIKit
import os.log

/// Crash reporting and error tracking service
/// Designed to be easily integrated with Crashlytics, Sentry, or similar services
@MainActor
class CrashReportingService {
    static let shared = CrashReportingService()
    
    private let logger = Logger(subsystem: "com.papertracks.books", category: "CrashReporting")
    private var isEnabled: Bool = true
    
    // Key areas to monitor for this app
    private let criticalAreas = [
        "SwiftData",
        "CSVImport", 
        "BookSearch",
        "BackgroundTasks",
        "Navigation",
        "ImageCache"
    ]
    
    private init() {
        setupGlobalErrorHandling()
    }
    
    // MARK: - Error Reporting
    
    /// Report non-fatal errors that don't crash the app
    func reportError(_ error: Error, context: String, metadata: [String: Any] = [:]) {
        guard isEnabled else { return }
        
        let errorInfo = ErrorReport(
            error: error,
            context: context,
            metadata: metadata,
            timestamp: Date(),
            appVersion: Bundle.main.appVersion,
            osVersion: UIDevice.current.systemVersion
        )
        
        // Log locally
        logger.error("🚨 Error in \(context): \(error.localizedDescription)")
        
        // TODO: Integrate with crash reporting service
        // Crashlytics.crashlytics().record(error: error)
        // or Sentry.capture(error: error)
        
        // For now, store locally for debugging
        storeErrorLocally(errorInfo)
    }
    
    /// Report critical issues that could lead to crashes
    func reportCriticalIssue(_ message: String, area: String, metadata: [String: Any] = [:]) {
        guard isEnabled else { return }
        
        logger.fault("💥 Critical issue in \(area): \(message)")
        
        let criticalReport = CriticalIssueReport(
            message: message,
            area: area,
            metadata: metadata,
            timestamp: Date(),
            appVersion: Bundle.main.appVersion,
            osVersion: UIDevice.current.systemVersion
        )
        
        // TODO: Send to crash reporting service immediately
        // Crashlytics.crashlytics().log(message)
        // or Sentry.addBreadcrumb(message: message)
        
        storeErrorLocally(criticalReport)
    }
    
    /// Track SwiftData initialization specifically
    func reportSwiftDataError(_ error: Error, failureType: SwiftDataFailureType) {
        let metadata: [String: Any] = [
            "failureType": failureType.rawValue,
            "errorType": String(describing: type(of: error)),
            "localizedDescription": error.localizedDescription
        ]
        
        reportCriticalIssue(
            "SwiftData initialization failed: \(error.localizedDescription)",
            area: "SwiftData",
            metadata: metadata
        )
    }
    
    /// Track network-related errors
    func reportNetworkError(_ error: Error, endpoint: String, retryCount: Int = 0) {
        let metadata: [String: Any] = [
            "endpoint": endpoint,
            "retryCount": retryCount,
            "errorCode": (error as NSError).code,
            "errorDomain": (error as NSError).domain
        ]
        
        // Only report as critical if it's a recurring issue
        if retryCount > 0 {
            reportCriticalIssue(
                "Network error after retries: \(error.localizedDescription)",
                area: "BookSearch",
                metadata: metadata
            )
        } else {
            reportError(error, context: "Network Request", metadata: metadata)
        }
    }
    
    // MARK: - App State Monitoring
    
    /// Set up global error handling and crash detection
    private func setupGlobalErrorHandling() {
        // Monitor for memory warnings
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.reportCriticalIssue(
                    "Memory warning received",
                    area: "Memory",
                    metadata: ["availableMemory": ProcessInfo.processInfo.physicalMemory]
                )
            }
        }
        
        // Monitor for app state changes
        NotificationCenter.default.addObserver(
            forName: UIApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.flushPendingReports()
            }
        }
    }
    
    // MARK: - Local Storage (for debugging and fallback)
    
    private func storeErrorLocally(_ report: ErrorReportProtocol) {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, 
                                                                in: .userDomainMask).first else {
            return
        }
        
        let errorLogURL = documentsDirectory.appendingPathComponent("error_reports.json")
        
        do {
            var existingReports: [Any] = []
            
            // Load existing reports if file exists
            if FileManager.default.fileExists(atPath: errorLogURL.path) {
                let data = try Data(contentsOf: errorLogURL)
                if let json = try JSONSerialization.jsonObject(with: data) as? [Any] {
                    existingReports = json
                }
            }
            
            // Add new report
            let reportDict = report.toDictionary()
            existingReports.append(reportDict)
            
            // Keep only recent reports (last 100)
            if existingReports.count > 100 {
                existingReports = Array(existingReports.suffix(100))
            }
            
            // Save back to file
            let jsonData = try JSONSerialization.data(withJSONObject: existingReports, options: .prettyPrinted)
            try jsonData.write(to: errorLogURL)
            
        } catch {
            logger.error("Failed to store error report locally: \(error.localizedDescription)")
        }
    }
    
    private func flushPendingReports() {
        // TODO: Send any pending reports to crash service
        logger.info("Flushing pending crash reports...")
    }
    
    // MARK: - Configuration
    
    func configure(enabled: Bool) {
        isEnabled = enabled
        logger.info("Crash reporting \(enabled ? "enabled" : "disabled")")
    }
}

// MARK: - Supporting Types

enum SwiftDataFailureType: String {
    case initialization = "initialization"
    case migration = "migration"
    case corruption = "corruption" 
    case unknown = "unknown"
}

protocol ErrorReportProtocol {
    func toDictionary() -> [String: Any]
}

struct ErrorReport: ErrorReportProtocol {
    let error: Error
    let context: String
    let metadata: [String: Any]
    let timestamp: Date
    let appVersion: String
    let osVersion: String
    
    func toDictionary() -> [String: Any] {
        return [
            "type": "error",
            "error": error.localizedDescription,
            "context": context,
            "metadata": metadata,
            "timestamp": timestamp.ISO8601Format(),
            "appVersion": appVersion,
            "osVersion": osVersion
        ]
    }
}

struct CriticalIssueReport: ErrorReportProtocol {
    let message: String
    let area: String
    let metadata: [String: Any]
    let timestamp: Date
    let appVersion: String
    let osVersion: String
    
    func toDictionary() -> [String: Any] {
        return [
            "type": "critical",
            "message": message,
            "area": area,
            "metadata": metadata,
            "timestamp": timestamp.ISO8601Format(),
            "appVersion": appVersion,
            "osVersion": osVersion
        ]
    }
}

extension Bundle {
    var appVersion: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
}