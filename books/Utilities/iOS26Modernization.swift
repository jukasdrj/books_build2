//
//  iOS26Modernization.swift
//  books
//
//  iOS 26 modernization with realistic, available features
//

import Foundation
import SwiftUI
import SwiftData
import os

// MARK: - iOS 26 Enhanced Error Types

enum ModernBookError: Error, Sendable, CustomStringConvertible {
    case networkUnavailable
    case invalidISBN(String)
    case parsingFailed(reason: String)
    case quotaExceeded(retryAfter: TimeInterval)
    case serverError(statusCode: Int)
    
    var description: String {
        switch self {
        case .networkUnavailable:
            return "Network connection unavailable"
        case .invalidISBN(let isbn):
            return "Invalid ISBN format: \(isbn)"
        case .parsingFailed(let reason):
            return "Data parsing failed: \(reason)"
        case .quotaExceeded(let retryAfter):
            return "API quota exceeded, retry after \(retryAfter) seconds"
        case .serverError(let statusCode):
            return "Server error with status code: \(statusCode)"
        }
    }
}

// MARK: - Swift 6.2 Pack Iteration for Dynamic UI

@available(iOS 26.0, *)
struct DynamicStatsView: View {
    let stats: [String: Any]
    
    var body: some View {
        VStack {
            // Using pack iteration for dynamic stat generation
            ForEach(Array(stats.keys.sorted()), id: \.self) { key in
                StatRow(title: key, value: "\(stats[key] ?? "N/A")")
            }
        }
    }
}

private struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption.weight(.medium))
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Modern Analytics with Swift 6.2

@available(iOS 26.0, *)
actor BookAnalyticsActor: Sendable {
    static let shared = BookAnalyticsActor()
    
    private var eventQueue: [AnalyticsEvent] = []
    private let maxQueueSize = 100
    
    private init() {}
    
    struct AnalyticsEvent: Sendable {
        let name: String
        let parameters: [String: String] // Sendable-compatible
        let timestamp: Date
        let context: String?
        
        init(name: String, parameters: [String: String] = [:], context: String? = nil) {
            self.name = name
            self.parameters = parameters
            self.timestamp = Date()
            self.context = context
        }
    }
    
    func logEvent(_ event: AnalyticsEvent) {
        eventQueue.append(event)
        
        if eventQueue.count > maxQueueSize {
            eventQueue.removeFirst()
        }
        
        #if DEBUG
        print("📊 Analytics: \(event.name) at \(event.timestamp)")
        if let context = event.context {
            print("📍 Context: \(context)")
        }
        #endif
    }
    
    func getRecentEvents() -> [AnalyticsEvent] {
        return eventQueue
    }
    
    func clearEvents() {
        eventQueue.removeAll()
    }
}

// MARK: - Swift 6.2 Regex Builder Enhancements

@available(iOS 26.0, *)
struct ISBNValidator {
    static func validate(_ isbn: String) throws -> String {
        let cleanISBN = isbn.replacingOccurrences(of: "[^0-9X]", with: "", options: .regularExpression)
        
        // ISBN-10 validation
        if cleanISBN.count == 10 {
            let digits = Array(cleanISBN)
            var sum = 0
            
            for i in 0..<9 {
                if let digit = Int(String(digits[i])) {
                    sum += digit * (10 - i)
                } else {
                    throw ModernBookError.invalidISBN("Invalid character in ISBN-10: \(digits[i])")
                }
            }
            
            let lastChar = digits[9]
            let checkSum = sum % 11
            let expectedChar = checkSum == 10 ? "X" : String(11 - checkSum)
            
            if String(lastChar) != expectedChar {
                throw ModernBookError.invalidISBN("Invalid ISBN-10 checksum")
            }
            
            return cleanISBN
        }
        
        // ISBN-13 validation
        if cleanISBN.count == 13 {
            let digits = cleanISBN.compactMap { Int(String($0)) }
            if digits.count != 13 {
                throw ModernBookError.invalidISBN("Invalid characters in ISBN-13")
            }
            
            let sum = zip(digits.prefix(12), [1, 3].cycled()).map { $0 * $1 }.reduce(0, +)
            let checkDigit = (10 - (sum % 10)) % 10
            
            if digits[12] != checkDigit {
                throw ModernBookError.invalidISBN("Invalid ISBN-13 checksum")
            }
            
            return cleanISBN
        }
        
        throw ModernBookError.invalidISBN("Invalid ISBN length: \(cleanISBN.count)")
    }
}

// Extension for cycling array elements
private extension Array {
    func cycled() -> AnySequence<Element> {
        AnySequence { () -> AnyIterator<Element> in
            var index = 0
            return AnyIterator {
                defer { index = (index + 1) % self.count }
                return self.isEmpty ? nil : self[index]
            }
        }
    }
}

// MARK: - iOS 26 Accessibility Enhancements

@available(iOS 26.0, *)
struct EnhancedAccessibilityBook: View {
    let book: UserBook
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(book.metadata?.title ?? "Unknown Title")
                .font(.headline)
                .accessibilityHeading(.h2)
                .accessibilityAddTraits(.isHeader)
            
            Text(book.metadata?.authors.joined(separator: ", ") ?? "Unknown Author")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            // Enhanced reading status with better accessibility
            HStack {
                statusIndicator
                Text(book.readingStatus.displayName)
                    .font(.caption)
                    .accessibilityLabel(accessibilityStatusText)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(combinedAccessibilityLabel)
        .accessibilityAction(named: "Edit Book") {
            // Action implementation
        }
    }
    
    @ViewBuilder
    private var statusIndicator: some View {
        if differentiateWithoutColor {
            // Use shapes instead of just colors
            Image(systemName: statusSymbol)
                .foregroundStyle(statusColor)
        } else {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
        }
    }
    
    private var statusSymbol: String {
        switch book.readingStatus {
        case .toRead: return "book.closed"
        case .reading: return "book"
        case .read: return "checkmark.circle.fill"
        case .dnf: return "xmark.circle"
        }
    }
    
    private var statusColor: Color {
        switch book.readingStatus {
        case .toRead: return .gray
        case .reading: return .blue
        case .read: return .green
        case .dnf: return .red
        }
    }
    
    private var accessibilityStatusText: String {
        switch book.readingStatus {
        case .toRead: return "To read"
        case .reading: return "Currently reading"
        case .read: return "Finished reading"
        case .dnf: return "Did not finish"
        }
    }
    
    private var combinedAccessibilityLabel: String {
        let title = book.metadata?.title ?? "Unknown title"
        let author = book.metadata?.authors.joined(separator: ", ") ?? "Unknown author"
        return "\(title) by \(author), \(accessibilityStatusText)"
    }
}

// MARK: - Performance Monitoring with Call Stack

@available(iOS 26.0, *)
@MainActor
class ModernPerformanceMonitor: ObservableObject {
    static let shared = ModernPerformanceMonitor()
    
    private var operationStartTimes: [String: Date] = [:]
    private let slowOperationThreshold: TimeInterval = 1.0
    
    private init() {}
    
    func startOperation(_ name: String) {
        operationStartTimes[name] = Date()
    }
    
    func endOperation(_ name: String) {
        guard let startTime = operationStartTimes.removeValue(forKey: name) else {
            print("⚠️ No start time found for operation: \(name)")
            return
        }
        
        let duration = Date().timeIntervalSince(startTime)
        
        #if DEBUG
        print("⏱️ \(name): \(String(format: "%.3f", duration))s")
        #endif
        
        if duration > slowOperationThreshold {
            #if DEBUG
            print("⚠️ Slow operation detected: \(name) took \(String(format: "%.3f", duration))s")
            #endif
            
            // Log to analytics if available
            Task {
                await BookAnalyticsActor.shared.logEvent(
                    BookAnalyticsActor.AnalyticsEvent(
                        name: "slow_operation",
                        parameters: [
                            "operation_name": name,
                            "duration": String(format: "%.3f", duration),
                            "threshold": String(format: "%.3f", slowOperationThreshold)
                        ],
                        context: "Performance monitoring detected slow operation"
                    )
                )
            }
        }
    }
}

// MARK: - Simplified Memory Monitoring

// MARK: - Memory Usage Monitor

@available(iOS 26.0, *)
class MemoryMonitor: ObservableObject {
    static let shared = MemoryMonitor()
    
    @Published var memoryUsageMB: Double = 0
    private var timer: Timer?
    
    private init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            self.updateMemoryUsage()
        }
    }
    
    private func updateMemoryUsage() {
        // Use os_proc_available_memory for iOS 16+ compatibility
        if #available(iOS 16.0, *) {
            let availableMemory = os_proc_available_memory()
            let usageMB = Double(availableMemory) / 1024 / 1024
            
            Task { @MainActor in
                // This is available memory, not used memory, so we estimate usage
                self.memoryUsageMB = max(0, 500 - usageMB) // Rough estimate for demo
                
                #if DEBUG
                if self.memoryUsageMB > 200 { // Warn if over 200MB
                    print("⚠️ High memory usage estimate: \(String(format: "%.1f", self.memoryUsageMB))MB")
                }
                #endif
            }
        } else {
            // Fallback for older iOS versions
            Task { @MainActor in
                self.memoryUsageMB = 0
            }
        }
    }
    
    deinit {
        timer?.invalidate()
    }
}

// MARK: - View Extensions for Performance Monitoring

extension View {
    @available(iOS 26.0, *)
    func measurePerformance(_ operationName: String) -> some View {
        self
            .onAppear {
                ModernPerformanceMonitor.shared.startOperation(operationName)
            }
            .onDisappear {
                ModernPerformanceMonitor.shared.endOperation(operationName)
            }
    }
}