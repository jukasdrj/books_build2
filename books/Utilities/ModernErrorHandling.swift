//
//  ModernErrorHandling.swift
//  books
//
//  iOS 26 modernization - Enhanced error handling with call stack tracking
//

import Foundation
import SwiftUI

// MARK: - Enhanced Error Handling

@available(iOS 26.0, *)
struct EnhancedError: Error, CustomStringConvertible {
    let originalError: Error
    let context: String
    let callStack: [String] // Simplified call stack representation
    let timestamp: Date
    let userInfo: [String: String] // Made Sendable-compatible
    
    init(_ error: Error, context: String, userInfo: [String: Any] = [:]) {
        self.originalError = error
        self.context = context
        // Simplified stack trace using Thread.callStackSymbols
        self.callStack = Thread.callStackSymbols
        self.timestamp = Date()
        // Convert userInfo to Sendable format
        self.userInfo = userInfo.compactMapValues { "\($0)" }
    }
    
    var description: String {
        return """
        ⚠️ Enhanced Error Report
        Context: \(context)
        Original Error: \(originalError.localizedDescription)
        Timestamp: \(timestamp.ISO8601Format())
        Stack Trace Available: \(callStack.count) frames
        """
    }
    
    /// Get call stack for debugging
    var symbolicatedBacktrace: String {
        return callStack.enumerated().map { index, symbol in
            "  \(index): \(symbol)"
        }.joined(separator: "\n")
    }
}

// MARK: - Modern Error Handler

@available(iOS 26.0, *)
@MainActor
class ModernErrorHandler: ObservableObject {
    static let shared = ModernErrorHandler()
    
    @Published var recentErrors: [EnhancedError] = []
    private let maxStoredErrors = 50
    
    private init() {}
    
    /// Handle errors with enhanced context and backtrace capture
    func handle(_ error: Error, context: String, userInfo: [String: Any] = [:]) {
        let enhancedError = EnhancedError(error, context: context, userInfo: userInfo)
        
        // Store for debugging
        recentErrors.append(enhancedError)
        if recentErrors.count > maxStoredErrors {
            recentErrors.removeFirst()
        }
        
        // Log with backtrace in debug builds
        #if DEBUG
        print("🔴 \(enhancedError.description)")
        print("📍 Backtrace:")
        print(enhancedError.symbolicatedBacktrace)
        #endif
        
        // Send to analytics or crash reporting service
        logToAnalytics(enhancedError)
    }
    
    /// Handle critical errors that should terminate the app
    func handleCritical(_ error: Error, context: String, userInfo: [String: Any] = [:]) -> Never {
        let enhancedError = EnhancedError(error, context: context, userInfo: userInfo)
        
        #if DEBUG
        print("💀 CRITICAL ERROR: \(enhancedError.description)")
        print("📍 Critical Backtrace:")
        print(enhancedError.symbolicatedBacktrace)
        #endif
        
        // Log critical error before terminating
        logToAnalytics(enhancedError, isCritical: true)
        
        fatalError("Critical error in \(context): \(error.localizedDescription)")
    }
    
    private func logToAnalytics(_ error: EnhancedError, isCritical: Bool = false) {
        // Placeholder for analytics integration (Firebase, etc.)
        // In production, you would send this to your analytics service
        let eventData: [String: Any] = [
            "error_type": String(describing: type(of: error.originalError)),
            "context": error.context,
            "is_critical": isCritical,
            "stack_frame_count": error.backtrace.addresses.count,
            "timestamp": error.timestamp.timeIntervalSince1970
        ]
        
        #if DEBUG
        print("📊 Analytics Event: \(eventData)")
        #endif
    }
}

// MARK: - Fallback for iOS < 26

struct LegacyError: Error, CustomStringConvertible {
    let originalError: Error
    let context: String
    let timestamp: Date
    let userInfo: [String: String] // Made Sendable-compatible
    
    init(_ error: Error, context: String, userInfo: [String: Any] = [:]) {
        self.originalError = error
        self.context = context
        self.timestamp = Date()
        // Convert userInfo to Sendable format
        self.userInfo = userInfo.compactMapValues { "\($0)" }
    }
    
    var description: String {
        return """
        ⚠️ Error Report (Legacy)
        Context: \(context)
        Original Error: \(originalError.localizedDescription)
        Timestamp: \(timestamp.ISO8601Format())
        """
    }
}

@MainActor
class LegacyErrorHandler: ObservableObject {
    static let shared = LegacyErrorHandler()
    
    @Published var recentErrors: [LegacyError] = []
    private let maxStoredErrors = 50
    
    private init() {}
    
    func handle(_ error: Error, context: String, userInfo: [String: Any] = [:]) {
        let legacyError = LegacyError(error, context: context, userInfo: userInfo)
        
        recentErrors.append(legacyError)
        if recentErrors.count > maxStoredErrors {
            recentErrors.removeFirst()
        }
        
        #if DEBUG
        print("🔴 \(legacyError.description)")
        #endif
    }
    
    func handleCritical(_ error: Error, context: String, userInfo: [String: Any] = [:]) -> Never {
        let legacyError = LegacyError(error, context: context, userInfo: userInfo)
        
        #if DEBUG
        print("💀 CRITICAL ERROR: \(legacyError.description)")
        #endif
        
        fatalError("Critical error in \(context): \(error.localizedDescription)")
    }
}

// MARK: - Unified Error Handler

@MainActor
class ErrorHandler: ObservableObject {
    static let shared = ErrorHandler()
    
    private init() {}
    
    /// Handle errors with modern backtrace on iOS 26+ or legacy handling on older iOS
    func handle(_ error: Error, context: String, userInfo: [String: Any] = [:]) {
        if #available(iOS 26.0, *) {
            ModernErrorHandler.shared.handle(error, context: context, userInfo: userInfo)
        } else {
            LegacyErrorHandler.shared.handle(error, context: context, userInfo: userInfo)
        }
    }
    
    /// Handle critical errors that should terminate the app
    func handleCritical(_ error: Error, context: String, userInfo: [String: Any] = [:]) -> Never {
        if #available(iOS 26.0, *) {
            ModernErrorHandler.shared.handleCritical(error, context: context, userInfo: userInfo)
        } else {
            LegacyErrorHandler.shared.handleCritical(error, context: context, userInfo: userInfo)
        }
    }
}

// MARK: - Swift 6.2 Result Extensions

extension Result {
    /// Handle errors with enhanced context using modern error handling
    @MainActor
    func handleError(context: String, userInfo: [String: Any] = [:]) -> Success? {
        switch self {
        case .success(let value):
            return value
        case .failure(let error):
            ErrorHandler.shared.handle(error, context: context, userInfo: userInfo)
            return nil
        }
    }
    
    /// Get value or handle error with modern error handling
    @MainActor
    func getOrHandleError(context: String, userInfo: [String: Any] = [:]) throws -> Success {
        switch self {
        case .success(let value):
            return value
        case .failure(let error):
            ErrorHandler.shared.handle(error, context: context, userInfo: userInfo)
            throw error
        }
    }
}

// MARK: - Async Extensions for Modern Swift

extension Task where Success == Void, Failure == Never {
    /// Create a task with enhanced error handling
    @MainActor
    static func withErrorHandling(
        context: String,
        userInfo: [String: Any] = [:],
        operation: @escaping @Sendable () async throws -> Void
    ) -> Task<Void, Never> {
        Task {
            do {
                try await operation()
            } catch {
                ErrorHandler.shared.handle(error, context: context, userInfo: userInfo)
            }
        }
    }
}

// MARK: - SwiftUI Integration

struct ErrorHandlingModifier: ViewModifier {
    let context: String
    
    func body(content: Content) -> some View {
        content
            .task {
                // Example of how to use in views
                // This modifier can be extended for view-specific error handling
            }
    }
}

extension View {
    /// Add enhanced error handling to a view
    func withErrorHandling(context: String) -> some View {
        modifier(ErrorHandlingModifier(context: context))
    }
}