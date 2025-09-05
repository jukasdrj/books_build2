//
//  SearchDebouncer.swift
//  books
//
//  iOS 26 Enhanced Search Performance Optimization
//  Intelligent debouncing with adaptive timing and query analysis
//

import Foundation
import Combine
import SwiftUI

@MainActor
@Observable
class SearchDebouncer {
    
    // MARK: - Configuration
    
    /// Base debounce delay for search queries
    private let baseDelay: TimeInterval = 0.3
    
    /// Minimum delay for very fast typing
    private let minimumDelay: TimeInterval = 0.1
    
    /// Maximum delay for complex queries
    private let maximumDelay: TimeInterval = 0.8
    
    /// Threshold for "fast typing" detection
    private let fastTypingThreshold: TimeInterval = 0.15
    
    // MARK: - State Management
    
    @ObservationIgnored
    private var cancellables = Set<AnyCancellable>()
    
    @ObservationIgnored
    private var lastQueryTime = Date()
    
    @ObservationIgnored
    private var queryHistory: [String] = []
    
    @ObservationIgnored
    private var currentTask: Task<Void, Never>?
    
    // Performance metrics
    @ObservationIgnored
    private(set) var averageQueryTime: TimeInterval = 0
    
    @ObservationIgnored
    private(set) var queryCount: Int = 0
    
    @ObservationIgnored
    private(set) var cacheHitRate: Double = 0
    
    // MARK: - Debounced Search
    
    /// Performs intelligent debounced search with adaptive timing
    func debouncedSearch(
        query: String,
        searchAction: @escaping (String) async -> Void
    ) {
        // Cancel any existing search task
        currentTask?.cancel()
        
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let queryComplexity = analyzeQueryComplexity(trimmedQuery)
        let adaptiveDelay = calculateAdaptiveDelay(for: trimmedQuery, complexity: queryComplexity)
        
        // Store query timing for adaptive learning
        let now = Date()
        let timeSinceLastQuery = now.timeIntervalSince(lastQueryTime)
        lastQueryTime = now
        
        currentTask = Task {
            // Wait for the adaptive delay
            try? await Task.sleep(nanoseconds: UInt64(adaptiveDelay * 1_000_000_000))
            
            // Check if task was cancelled during delay
            if Task.isCancelled { return }
            
            // Validate query is still relevant
            guard !trimmedQuery.isEmpty else { return }
            
            // Record query metrics
            let searchStartTime = Date()
            queryCount += 1
            queryHistory.append(trimmedQuery)
            
            // Limit history size
            if queryHistory.count > 20 {
                queryHistory.removeFirst()
            }
            
            // Execute search
            await searchAction(trimmedQuery)
            
            // Update performance metrics
            let searchDuration = Date().timeIntervalSince(searchStartTime)
            updatePerformanceMetrics(duration: searchDuration)
            
            #if DEBUG
            print("🔍 SearchDebouncer: Query '\(trimmedQuery)' executed in \(String(format: \"%.3f\", searchDuration))s after \(String(format: \"%.3f\", adaptiveDelay))s delay")
            #endif
        }
    }
    
    /// Cancel any pending search operations
    func cancelPendingSearch() {
        currentTask?.cancel()
        currentTask = nil
    }
    
    // MARK: - Adaptive Intelligence
    
    /// Analyze query complexity to determine optimal debounce timing
    private func analyzeQueryComplexity(_ query: String) -> QueryComplexity {
        let wordCount = query.split(separator: " ").count
        let hasSpecialCharacters = query.rangeOfCharacter(from: CharacterSet.punctuationCharacters) != nil
        let hasNumbers = query.rangeOfCharacter(from: CharacterSet.decimalDigits) != nil
        let isISBN = query.count >= 10 && query.allSatisfy { $0.isNumber || $0 == "-" }
        
        if isISBN {
            return .isbn
        } else if wordCount >= 3 || hasSpecialCharacters {
            return .complex
        } else if wordCount == 2 || hasNumbers {
            return .medium
        } else {
            return .simple
        }
    }
    
    /// Calculate adaptive delay based on query characteristics and user behavior
    private func calculateAdaptiveDelay(for query: String, complexity: QueryComplexity) -> TimeInterval {
        var delay = baseDelay
        
        // Adjust based on query complexity
        switch complexity {
        case .simple:
            delay *= 0.7 // Faster for simple queries
        case .medium:
            delay *= 1.0 // Standard delay
        case .complex:
            delay *= 1.3 // Slower for complex queries
        case .isbn:
            delay *= 0.5 // Very fast for ISBN lookups
        }
        
        // Adjust based on typing speed
        let now = Date()
        let timeSinceLastQuery = now.timeIntervalSince(lastQueryTime)
        
        if timeSinceLastQuery < fastTypingThreshold {
            // User is typing fast, increase delay to reduce API calls
            delay = min(delay * 1.5, maximumDelay)
        } else if timeSinceLastQuery > 1.0 {
            // User paused, reduce delay for immediate feedback
            delay = max(delay * 0.8, minimumDelay)
        }
        
        // Check for similar recent queries (potential backspacing/corrections)
        if let lastQuery = queryHistory.last,
           lastQuery.hasPrefix(query) || query.hasPrefix(lastQuery) {
            // Likely editing previous query, reduce delay
            delay *= 0.6
        }
        
        return max(minimumDelay, min(maximumDelay, delay))
    }
    
    /// Update performance metrics for optimization
    private func updatePerformanceMetrics(duration: TimeInterval) {
        // Update average query time using exponential moving average
        let alpha: Double = 0.1
        averageQueryTime = alpha * duration + (1 - alpha) * averageQueryTime
        
        // Estimate cache hit rate based on query patterns
        let similarQueries = queryHistory.suffix(5).filter { query in
            queryHistory.last?.localizedCaseInsensitiveContains(query) == true ||
            query.localizedCaseInsensitiveContains(queryHistory.last ?? "")
        }
        
        cacheHitRate = Double(similarQueries.count) / Double(min(queryHistory.count, 5))
        
        #if DEBUG
        print("📊 SearchDebouncer: Avg query time: \(String(format: \"%.3f\", averageQueryTime))s, Cache hit rate: \(String(format: \"%.1f\", cacheHitRate * 100))%")
        #endif
    }
    
    // MARK: - Smart Suggestions
    
    /// Get intelligent search suggestions based on typing patterns
    func getSmartSuggestions(for partialQuery: String, limit: Int = 5) -> [SearchSuggestion] {
        let trimmedQuery = partialQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmedQuery.isEmpty else { return [] }
        
        var suggestions: [SearchSuggestion] = []
        
        // 1. Auto-completion from query history
        let historySuggestions = queryHistory
            .filter { $0.lowercased().hasPrefix(trimmedQuery) && $0.lowercased() != trimmedQuery }
            .suffix(3)
            .map { SearchSuggestion(text: $0, type: .autoComplete, metadata: "Recent") }
        
        suggestions.append(contentsOf: historySuggestions)
        
        // 2. Query expansion suggestions
        let expansionSuggestions = generateQueryExpansions(for: trimmedQuery)
        suggestions.append(contentsOf: expansionSuggestions.prefix(2))
        
        // 3. Contextual suggestions based on partial query
        if trimmedQuery.count >= 2 {
            let contextualSuggestions = generateContextualSuggestions(for: trimmedQuery)
            suggestions.append(contentsOf: contextualSuggestions.prefix(2))
        }
        
        return Array(suggestions.prefix(limit))
    }
    
    /// Generate query expansion suggestions
    private func generateQueryExpansions(for query: String) -> [SearchSuggestion] {
        var expansions: [SearchSuggestion] = []
        
        // Common search patterns
        if query.count >= 3 {
            let commonExpansions = [
                "\(query) series",
                "\(query) author",
                "\(query) book"
            ]
            
            expansions.append(contentsOf: commonExpansions.map {
                SearchSuggestion(text: $0, type: .expansion, metadata: "Suggested")
            })
        }
        
        return expansions
    }
    
    /// Generate contextual suggestions based on query analysis
    private func generateContextualSuggestions(for query: String) -> [SearchSuggestion] {
        var suggestions: [SearchSuggestion] = []
        
        // Detect potential author names (contains space and proper capitalization patterns)
        if query.contains(" ") && query.split(separator: " ").allSatisfy({ $0.first?.isUppercase == true }) {
            suggestions.append(SearchSuggestion(
                text: "Books by \(query)",
                type: .contextual,
                metadata: "Author search"
            ))
        }
        
        // Detect potential ISBN patterns
        if query.count >= 8 && query.allSatisfy({ $0.isNumber || $0 == "-" }) {
            suggestions.append(SearchSuggestion(
                text: query,
                type: .contextual,
                metadata: "ISBN lookup"
            ))
        }
        
        // Detect potential series search
        if query.lowercased().contains("book") || query.lowercased().contains("series") {
            suggestions.append(SearchSuggestion(
                text: query.replacingOccurrences(of: "book", with: "").trimmingCharacters(in: .whitespaces),
                type: .contextual,
                metadata: "Series search"
            ))
        }
        
        return suggestions
    }
    
    // MARK: - Performance Monitoring
    
    /// Get current performance statistics
    func getPerformanceStats() -> PerformanceStats {
        return PerformanceStats(
            totalQueries: queryCount,
            averageQueryTime: averageQueryTime,
            cacheHitRate: cacheHitRate,
            currentHistorySize: queryHistory.count
        )
    }
    
    /// Reset performance metrics and history
    func resetMetrics() {
        queryCount = 0
        averageQueryTime = 0
        cacheHitRate = 0
        queryHistory.removeAll()
        
        #if DEBUG
        print("🔄 SearchDebouncer: Performance metrics reset")
        #endif
    }
}

// MARK: - Supporting Types

enum QueryComplexity {
    case simple     // Single word, no special characters
    case medium     // Two words or contains numbers
    case complex    // Multiple words or special characters
    case isbn       // ISBN pattern detected
}

struct SearchSuggestion: Identifiable, Hashable {
    let id = UUID()
    let text: String
    let type: SuggestionType
    let metadata: String?
    
    enum SuggestionType {
        case autoComplete
        case expansion
        case contextual
        case history
        
        var systemImage: String {
            switch self {
            case .autoComplete: return "text.cursor"
            case .expansion: return "plus.magnifyingglass"
            case .contextual: return "lightbulb"
            case .history: return "clock"
            }
        }
        
        var priority: Int {
            switch self {
            case .autoComplete: return 4
            case .contextual: return 3
            case .expansion: return 2
            case .history: return 1
            }
        }
    }
}

struct PerformanceStats {
    let totalQueries: Int
    let averageQueryTime: TimeInterval
    let cacheHitRate: Double
    let currentHistorySize: Int
    
    var formattedAverageQueryTime: String {
        String(format: "%.3f", averageQueryTime)
    }
    
    var formattedCacheHitRate: String {
        String(format: "%.1f%%", cacheHitRate * 100)
    }
}

// MARK: - SwiftUI Environment Integration

struct SearchDebouncerEnvironmentKey: EnvironmentKey {
    static let defaultValue = SearchDebouncer()
}

extension EnvironmentValues {
    var searchDebouncer: SearchDebouncer {
        get { self[SearchDebouncerEnvironmentKey.self] }
        set { self[SearchDebouncerEnvironmentKey.self] = newValue }
    }
}