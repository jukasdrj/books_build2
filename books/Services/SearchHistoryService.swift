//
//  SearchHistoryService.swift
//  books
//
//  iOS 26 Enhanced Search History and Contextual Suggestions
//  Provides intelligent search history, favorites, and contextual recommendations
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
class SearchHistoryService {
    static let shared = SearchHistoryService()
    
    // MARK: - Configuration
    
    private let maxHistoryItems = 50
    private let maxSuggestions = 8
    private let searchHistoryKey = "SearchHistory"
    private let favoriteSearchesKey = "FavoriteSearches"
    
    // MARK: - Published Properties
    
    @ObservationIgnored
    private(set) var recentSearches: [SearchHistoryItem] = []
    
    @ObservationIgnored
    private(set) var favoriteSearches: [SearchHistoryItem] = []
    
    @ObservationIgnored
    private(set) var contextualSuggestions: [String] = []
    
    private init() {
        loadSearchHistory()
        loadFavoriteSearches()
    }
    
    // MARK: - Search History Management
    
    /// Add a search query to history with intelligent deduplication
    func addToHistory(_ query: String, resultCount: Int = 0) {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty && trimmedQuery.count >= 2 else { return }
        
        let newItem = SearchHistoryItem(
            query: trimmedQuery,
            timestamp: Date(),
            resultCount: resultCount,
            searchCount: 1
        )
        
        // Remove existing item with same query and update search count
        if let existingIndex = recentSearches.firstIndex(where: { $0.query.lowercased() == trimmedQuery.lowercased() }) {
            let existingItem = recentSearches[existingIndex]
            recentSearches.remove(at: existingIndex)
            
            // Create updated item with incremented count
            let updatedItem = SearchHistoryItem(
                id: existingItem.id,
                query: trimmedQuery,
                timestamp: Date(),
                resultCount: resultCount > 0 ? resultCount : existingItem.resultCount,
                searchCount: existingItem.searchCount + 1
            )
            recentSearches.insert(updatedItem, at: 0)
        } else {
            // Add new item at the beginning
            recentSearches.insert(newItem, at: 0)
        }
        
        // Trim to max items
        if recentSearches.count > maxHistoryItems {
            recentSearches = Array(recentSearches.prefix(maxHistoryItems))
        }
        
        saveSearchHistory()
        
        // Add haptic feedback for successful search
        HapticFeedbackManager.shared.lightImpact()
        
        #if DEBUG
        print("📚 SearchHistory: Added '\(trimmedQuery)' (results: \(resultCount))")
        #endif
    }
    
    /// Remove a specific search from history
    func removeFromHistory(_ item: SearchHistoryItem) {
        withAnimation(.easeInOut(duration: 0.3)) {
            recentSearches.removeAll { $0.id == item.id }
        }
        saveSearchHistory()
        HapticFeedbackManager.shared.lightImpact()
    }
    
    /// Clear all search history
    func clearHistory() {
        withAnimation(.easeInOut(duration: 0.3)) {
            recentSearches.removeAll()
        }
        saveSearchHistory()
        HapticFeedbackManager.shared.mediumImpact()
    }
    
    // MARK: - Favorite Searches
    
    /// Add a search to favorites
    func addToFavorites(_ query: String) {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return }
        
        // Check if already favorited
        if favoriteSearches.contains(where: { $0.query.lowercased() == trimmedQuery.lowercased() }) {
            return
        }
        
        let favoriteItem = SearchHistoryItem(
            query: trimmedQuery,
            timestamp: Date(),
            resultCount: 0,
            searchCount: 1,
            isFavorite: true
        )
        
        favoriteSearches.append(favoriteItem)
        saveFavoriteSearches()
        HapticFeedbackManager.shared.success()
        
        #if DEBUG
        print("⭐ SearchHistory: Added '\(trimmedQuery)' to favorites")
        #endif
    }
    
    /// Remove a search from favorites
    func removeFromFavorites(_ item: SearchHistoryItem) {
        withAnimation(.easeInOut(duration: 0.3)) {
            favoriteSearches.removeAll { $0.id == item.id }
        }
        saveFavoriteSearches()
        HapticFeedbackManager.shared.lightImpact()
    }
    
    /// Toggle favorite status
    func toggleFavorite(_ query: String) {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if favoriteSearches.contains(where: { $0.query.lowercased() == trimmedQuery.lowercased() }) {
            favoriteSearches.removeAll { $0.query.lowercased() == trimmedQuery.lowercased() }
            HapticFeedbackManager.shared.lightImpact()
        } else {
            addToFavorites(trimmedQuery)
        }
    }
    
    /// Check if a query is favorited
    func isFavorite(_ query: String) -> Bool {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return favoriteSearches.contains { $0.query.lowercased() == trimmedQuery.lowercased() }
    }
    
    // MARK: - Intelligent Suggestions
    
    /// Get search suggestions based on query and context
    func getSearchSuggestions(for query: String, userLibrary: [UserBook] = []) -> [SearchSuggestion] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmedQuery.isEmpty else {
            return getEmptyStateSuggestions(userLibrary: userLibrary)
        }
        
        var suggestions: [SearchSuggestion] = []
        
        // 1. History-based suggestions
        let historySuggestions = recentSearches
            .filter { $0.query.lowercased().contains(trimmedQuery) }
            .prefix(3)
            .map { SearchSuggestion(text: $0.query, type: .history, metadata: "\($0.searchCount) time\($0.searchCount > 1 ? "s" : "")") }
        suggestions.append(contentsOf: historySuggestions)
        
        // 2. Favorite-based suggestions
        let favoriteSuggestions = favoriteSearches
            .filter { $0.query.lowercased().contains(trimmedQuery) }
            .prefix(2)
            .map { SearchSuggestion(text: $0.query, type: .favorite, metadata: "Favorite") }
        suggestions.append(contentsOf: favoriteSuggestions)
        
        // 3. Library-based suggestions (authors, titles)
        if !userLibrary.isEmpty {
            let librarySuggestions = generateLibrarySuggestions(for: trimmedQuery, from: userLibrary)
            suggestions.append(contentsOf: librarySuggestions.prefix(3))
        }
        
        // 4. Genre and category suggestions
        let genreSuggestions = generateGenreSuggestions(for: trimmedQuery)
        suggestions.append(contentsOf: genreSuggestions.prefix(2))
        
        return Array(suggestions.prefix(maxSuggestions))
    }
    
    /// Get suggestions for empty search state
    private func getEmptyStateSuggestions(userLibrary: [UserBook]) -> [SearchSuggestion] {
        var suggestions: [SearchSuggestion] = []
        
        // Recent searches (top 3)
        suggestions.append(contentsOf: recentSearches.prefix(3).map {
            SearchSuggestion(text: $0.query, type: .history, metadata: "Recent")
        })
        
        // Favorite searches
        suggestions.append(contentsOf: favoriteSearches.prefix(2).map {
            SearchSuggestion(text: $0.query, type: .favorite, metadata: "Favorite")
        })
        
        // Popular genres if no history
        if suggestions.count < 3 {
            let popularGenres = ["Fiction", "Non-fiction", "Mystery", "Romance", "Science Fiction"]
            suggestions.append(contentsOf: popularGenres.prefix(3).map {
                SearchSuggestion(text: $0, type: .genre, metadata: "Popular genre")
            })
        }
        
        return Array(suggestions.prefix(maxSuggestions))
    }
    
    /// Generate library-based suggestions
    private func generateLibrarySuggestions(for query: String, from library: [UserBook]) -> [SearchSuggestion] {
        var suggestions: [SearchSuggestion] = []
        
        // Author suggestions
        let authors = library.compactMap { $0.metadata?.authors.first }
            .filter { $0.lowercased().contains(query) }
            .reduce(into: [String: Int]()) { counts, author in
                counts[author, default: 0] += 1
            }
            .sorted { $0.value > $1.value }
            .prefix(2)
        
        suggestions.append(contentsOf: authors.map { author, count in
            SearchSuggestion(text: author, type: .author, metadata: "\(count) book\(count > 1 ? "s" : "") in library")
        })
        
        // Title suggestions
        let titles = library.compactMap { $0.metadata?.title }
            .filter { $0.lowercased().contains(query) }
            .prefix(2)
        
        suggestions.append(contentsOf: titles.map {
            SearchSuggestion(text: $0, type: .title, metadata: "In your library")
        })
        
        return suggestions
    }
    
    /// Generate genre-based suggestions
    private func generateGenreSuggestions(for query: String) -> [SearchSuggestion] {
        let genres = [
            "Fiction", "Non-fiction", "Mystery", "Romance", "Science Fiction",
            "Fantasy", "Biography", "History", "Self-help", "Poetry",
            "Thriller", "Young Adult", "Children", "Business", "Health"
        ]
        
        return genres
            .filter { $0.lowercased().contains(query) }
            .prefix(2)
            .map { SearchSuggestion(text: $0, type: .genre, metadata: "Genre") }
    }
    
    // MARK: - Contextual Intelligence
    
    /// Update contextual suggestions based on user behavior
    func updateContextualSuggestions(userLibrary: [UserBook] = []) {
        var newSuggestions: [String] = []
        
        // Based on reading patterns
        if !userLibrary.isEmpty {
            let recentReads = userLibrary
                .filter { $0.readingStatus == .read }
                .sorted { $0.dateCompleted ?? Date.distantPast > $1.dateCompleted ?? Date.distantPast }
                .prefix(5)
            
            if !recentReads.isEmpty {
                newSuggestions.append("More from recent authors")
            }
            
            let currentlyReading = userLibrary.filter { $0.readingStatus == .reading }
            if !currentlyReading.isEmpty {
                newSuggestions.append("Similar to current reads")
            }
        }
        
        // Based on search patterns
        let popularSearches = recentSearches
            .filter { $0.searchCount > 1 }
            .sorted { $0.searchCount > $1.searchCount }
            .prefix(2)
            .map { $0.query }
        
        newSuggestions.append(contentsOf: popularSearches)
        
        // Time-based suggestions
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        
        switch hour {
        case 6..<12:
            newSuggestions.append("Morning reads")
        case 18..<22:
            newSuggestions.append("Evening favorites")
        default:
            break
        }
        
        contextualSuggestions = Array(newSuggestions.prefix(maxSuggestions))
    }
    
    // MARK: - Persistence
    
    private func saveSearchHistory() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(recentSearches)
            UserDefaults.standard.set(data, forKey: searchHistoryKey)
        } catch {
            #if DEBUG
            print("❌ SearchHistory: Failed to save history: \(error)")
            #endif
        }
    }
    
    private func loadSearchHistory() {
        guard let data = UserDefaults.standard.data(forKey: searchHistoryKey) else {
            recentSearches = []
            return
        }
        
        do {
            let decoder = JSONDecoder()
            recentSearches = try decoder.decode([SearchHistoryItem].self, from: data)
        } catch {
            #if DEBUG
            print("⚠️ SearchHistory: Failed to load history, starting fresh: \(error)")
            #endif
            recentSearches = []
        }
    }
    
    private func saveFavoriteSearches() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(favoriteSearches)
            UserDefaults.standard.set(data, forKey: favoriteSearchesKey)
        } catch {
            #if DEBUG
            print("❌ SearchHistory: Failed to save favorites: \(error)")
            #endif
        }
    }
    
    private func loadFavoriteSearches() {
        guard let data = UserDefaults.standard.data(forKey: favoriteSearchesKey) else {
            favoriteSearches = []
            return
        }
        
        do {
            let decoder = JSONDecoder()
            favoriteSearches = try decoder.decode([SearchHistoryItem].self, from: data)
        } catch {
            #if DEBUG
            print("⚠️ SearchHistory: Failed to load favorites, starting fresh: \(error)")
            #endif
            favoriteSearches = []
        }
    }
}

// MARK: - Supporting Models

struct SearchHistoryItem: Codable, Identifiable, Hashable {
    let id: UUID
    let query: String
    let timestamp: Date
    let resultCount: Int
    let searchCount: Int
    let isFavorite: Bool
    
    init(id: UUID = UUID(), query: String, timestamp: Date, resultCount: Int, searchCount: Int, isFavorite: Bool = false) {
        self.id = id
        self.query = query
        self.timestamp = timestamp
        self.resultCount = resultCount
        self.searchCount = searchCount
        self.isFavorite = isFavorite
    }
    
    /// Relative time description
    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
    
    /// Search quality score based on results and usage
    var qualityScore: Double {
        let baseScore = resultCount > 0 ? min(Double(resultCount) / 10.0, 1.0) : 0.1
        let usageBonus = min(Double(searchCount) / 5.0, 0.5)
        return baseScore + usageBonus
    }
}

struct SearchSuggestion: Identifiable, Hashable {
    let id = UUID()
    let text: String
    let type: SuggestionType
    let metadata: String?
    
    enum SuggestionType {
        case history
        case favorite  
        case author
        case title
        case genre
        case contextual
        case autoComplete
        case expansion
        
        var systemImage: String {
            switch self {
            case .history: return "clock"
            case .favorite: return "star.fill"
            case .author: return "person.fill"
            case .title: return "book.fill"
            case .genre: return "tag.fill"
            case .contextual: return "lightbulb.fill"
            case .autoComplete: return "text.cursor"
            case .expansion: return "plus.magnifyingglass"
            }
        }
        
        var color: Color {
            switch self {
            case .history: return .secondary
            case .favorite: return .yellow
            case .author: return .blue
            case .title: return .green
            case .genre: return .purple
            case .contextual: return .orange
            case .autoComplete: return .primary
            case .expansion: return .secondary
            }
        }
    }
}

// MARK: - SwiftUI Environment Integration

struct SearchHistoryEnvironmentKey: EnvironmentKey {
    static let defaultValue: SearchHistoryService = {
        @MainActor func create() -> SearchHistoryService {
            return SearchHistoryService.shared
        }
        return MainActor.assumeIsolated(create)
    }()
}

extension EnvironmentValues {
    var searchHistory: SearchHistoryService {
        get { self[SearchHistoryEnvironmentKey.self] }
        set { self[SearchHistoryEnvironmentKey.self] = newValue }
    }
}