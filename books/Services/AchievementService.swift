import Foundation
import SwiftUI
import SwiftData

// MARK: - Achievement Service for Dynamic Achievement Calculation

@MainActor
class AchievementService: ObservableObject {
    
    static let shared = AchievementService()
    
    private init() {}
    
    // MARK: - Calculate All Achievements
    
    func calculateAchievements(from books: [UserBook]) -> [UnifiedAchievement] {
        var achievements: [UnifiedAchievement] = []
        
        // Reading Achievements
        achievements.append(contentsOf: calculateReadingAchievements(from: books))
        
        // Cultural Achievements
        achievements.append(contentsOf: calculateCulturalAchievements(from: books))
        
        // Combined Achievements
        achievements.append(contentsOf: calculateCombinedAchievements(from: books))
        
        return achievements.sorted { achievement1, achievement2 in
            // Sort unlocked achievements first, then by rarity
            if achievement1.isUnlocked != achievement2.isUnlocked {
                return achievement1.isUnlocked
            }
            return achievement1.rarity.rawValue < achievement2.rarity.rawValue
        }
    }
    
    // MARK: - Reading Achievements
    
    private func calculateReadingAchievements(from books: [UserBook]) -> [UnifiedAchievement] {
        let completedBooks = books.filter { $0.readingStatus == .read }
        let bookCount = completedBooks.count
        
        return [
            // First Book
            UnifiedAchievement(
                id: "first_book",
                title: "First Steps",
                description: "Complete your first book",
                icon: "book.fill",
                category: .reading,
                isUnlocked: bookCount >= 1,
                unlockedDate: completedBooks.first?.dateCompleted,
                color: .blue,
                rarity: .common,
                progress: Double(min(bookCount, 1)),
                maxProgress: 1.0
            ),
            
            // 10 Books
            UnifiedAchievement(
                id: "bookworm",
                title: "Bookworm",
                description: "Read 10 books",
                icon: "books.vertical.fill",
                category: .reading,
                isUnlocked: bookCount >= 10,
                unlockedDate: bookCount >= 10 ? completedBooks.dropFirst(9).first?.dateCompleted : nil,
                color: .blue,
                rarity: .uncommon,
                progress: Double(min(bookCount, 10)),
                maxProgress: 10.0
            ),
            
            // 25 Books
            UnifiedAchievement(
                id: "avid_reader",
                title: "Avid Reader",
                description: "Read 25 books",
                icon: "graduationcap.fill",
                category: .reading,
                isUnlocked: bookCount >= 25,
                unlockedDate: bookCount >= 25 ? completedBooks.dropFirst(24).first?.dateCompleted : nil,
                color: .blue,
                rarity: .rare,
                progress: Double(min(bookCount, 25)),
                maxProgress: 25.0
            ),
            
            // 50 Books
            UnifiedAchievement(
                id: "library_master",
                title: "Library Master",
                description: "Read 50 books",
                icon: "building.columns.fill",
                category: .reading,
                isUnlocked: bookCount >= 50,
                unlockedDate: bookCount >= 50 ? completedBooks.dropFirst(49).first?.dateCompleted : nil,
                color: .blue,
                rarity: .epic,
                progress: Double(min(bookCount, 50)),
                maxProgress: 50.0
            ),
            
            // 100 Books
            UnifiedAchievement(
                id: "reading_legend",
                title: "Reading Legend",
                description: "Read 100 books - exceptional dedication",
                icon: "crown.fill",
                category: .reading,
                isUnlocked: bookCount >= 100,
                unlockedDate: bookCount >= 100 ? completedBooks.dropFirst(99).first?.dateCompleted : nil,
                color: .blue,
                rarity: .legendary,
                progress: Double(min(bookCount, 100)),
                maxProgress: 100.0
            ),
            
            // High Rating Achievement
            UnifiedAchievement(
                id: "quality_reader",
                title: "Quality Reader",
                description: "Maintain average rating above 4.0 stars",
                icon: "star.fill",
                category: .reading,
                isUnlocked: calculateAverageRating(from: completedBooks) >= 4.0 && bookCount >= 5,
                unlockedDate: calculateAverageRating(from: completedBooks) >= 4.0 && bookCount >= 5 ? completedBooks.last?.dateCompleted : nil,
                color: .orange,
                rarity: .uncommon,
                progress: calculateAverageRating(from: completedBooks),
                maxProgress: 5.0
            )
        ]
    }
    
    // MARK: - Cultural Achievements
    
    private func calculateCulturalAchievements(from books: [UserBook]) -> [UnifiedAchievement] {
        let completedBooks = books.filter { $0.readingStatus == .read }
        let cultures = Set(completedBooks.compactMap { $0.metadata?.culturalRegion })
        let cultureCount = cultures.count
        
        return [
            // First International Book
            UnifiedAchievement(
                id: "global_perspective",
                title: "Global Perspective",
                description: "Read your first international book",
                icon: "globe.americas.fill",
                category: .cultural,
                isUnlocked: cultureCount >= 1,
                unlockedDate: completedBooks.first(where: { $0.metadata?.culturalRegion != nil })?.dateCompleted,
                color: .green,
                rarity: .common,
                progress: Double(min(cultureCount, 1)),
                maxProgress: 1.0
            ),
            
            // 3 Cultures
            UnifiedAchievement(
                id: "culture_explorer",
                title: "Culture Explorer",
                description: "Read books from 3 different cultures",
                icon: "map.fill",
                category: .cultural,
                isUnlocked: cultureCount >= 3,
                unlockedDate: cultureCount >= 3 ? completedBooks.compactMap({ $0.metadata?.culturalRegion != nil ? $0.dateCompleted : nil }).sorted().dropFirst(2).first : nil,
                color: .green,
                rarity: .uncommon,
                progress: Double(min(cultureCount, 3)),
                maxProgress: 3.0
            ),
            
            // 5 Cultures
            UnifiedAchievement(
                id: "world_traveler",
                title: "World Traveler",
                description: "Read books from 5 different cultures",
                icon: "airplane",
                category: .cultural,
                isUnlocked: cultureCount >= 5,
                unlockedDate: cultureCount >= 5 ? completedBooks.compactMap({ $0.metadata?.culturalRegion != nil ? $0.dateCompleted : nil }).sorted().dropFirst(4).first : nil,
                color: .green,
                rarity: .rare,
                progress: Double(min(cultureCount, 5)),
                maxProgress: 5.0
            ),
            
            // 10 Cultures
            UnifiedAchievement(
                id: "diversity_champion",
                title: "Diversity Champion",
                description: "Read books from 10 different cultures",
                icon: "person.3.fill",
                category: .cultural,
                isUnlocked: cultureCount >= 10,
                unlockedDate: cultureCount >= 10 ? completedBooks.compactMap({ $0.metadata?.culturalRegion != nil ? $0.dateCompleted : nil }).sorted().dropFirst(9).first : nil,
                color: .green,
                rarity: .epic,
                progress: Double(min(cultureCount, 10)),
                maxProgress: 10.0
            ),
            
            // Language Diversity
            UnifiedAchievement(
                id: "polyglot",
                title: "Polyglot",
                description: "Read books in multiple languages",
                icon: "textformat.abc",
                category: .cultural,
                isUnlocked: hasMultipleLanguages(in: completedBooks),
                unlockedDate: hasMultipleLanguages(in: completedBooks) ? completedBooks.last?.dateCompleted : nil,
                color: .green,
                rarity: .rare,
                progress: Double(getLanguageCount(from: completedBooks)),
                maxProgress: 3.0
            )
        ]
    }
    
    // MARK: - Combined Achievements
    
    private func calculateCombinedAchievements(from books: [UserBook]) -> [UnifiedAchievement] {
        let completedBooks = books.filter { $0.readingStatus == .read }
        let bookCount = completedBooks.count
        let cultureCount = Set(completedBooks.compactMap { $0.metadata?.culturalRegion }).count
        let averageRating = calculateAverageRating(from: completedBooks)
        
        return [
            // Balanced Reader
            UnifiedAchievement(
                id: "balanced_reader",
                title: "Balanced Reader",
                description: "Read 20 books from at least 5 cultures",
                icon: "scale.3d",
                category: .combined,
                isUnlocked: bookCount >= 20 && cultureCount >= 5,
                unlockedDate: (bookCount >= 20 && cultureCount >= 5) ? completedBooks.last?.dateCompleted : nil,
                color: .purple,
                rarity: .rare,
                progress: Double(min(bookCount, 20)) * 0.5 + Double(min(cultureCount, 5)) * 0.1,
                maxProgress: 10.5 // (20 * 0.5) + (5 * 0.1)
            ),
            
            // Master Explorer
            UnifiedAchievement(
                id: "master_explorer",
                title: "Master Explorer",
                description: "50 books, 8 cultures, 4+ stars average",
                icon: "sparkles",
                category: .combined,
                isUnlocked: bookCount >= 50 && cultureCount >= 8 && averageRating >= 4.0,
                unlockedDate: (bookCount >= 50 && cultureCount >= 8 && averageRating >= 4.0) ? completedBooks.last?.dateCompleted : nil,
                color: .purple,
                rarity: .legendary,
                progress: (Double(min(bookCount, 50)) / 50.0) * 0.6 + 
                         (Double(min(cultureCount, 8)) / 8.0) * 0.3 + 
                         (min(averageRating, 5.0) / 5.0) * 0.1,
                maxProgress: 1.0
            ),
            
            // Reading Streak
            UnifiedAchievement(
                id: "consistent_reader",
                title: "Consistent Reader",
                description: "Maintain a 7-day reading streak",
                icon: "flame.fill",
                category: .combined,
                isUnlocked: calculateReadingStreak(from: completedBooks) >= 7,
                unlockedDate: calculateReadingStreak(from: completedBooks) >= 7 ? completedBooks.last?.dateCompleted : nil,
                color: .orange,
                rarity: .uncommon,
                progress: Double(min(calculateReadingStreak(from: completedBooks), 7)),
                maxProgress: 7.0
            )
        ]
    }
    
    // MARK: - Helper Methods
    
    private func calculateAverageRating(from books: [UserBook]) -> Double {
        let ratings = books.compactMap { $0.rating }
        guard !ratings.isEmpty else { return 0.0 }
        return Double(ratings.reduce(0, +)) / Double(ratings.count)
    }
    
    private func hasMultipleLanguages(in books: [UserBook]) -> Bool {
        let languages = Set(books.compactMap { $0.metadata?.originalLanguage })
        return languages.count >= 2
    }
    
    private func getLanguageCount(from books: [UserBook]) -> Int {
        let languages = Set(books.compactMap { $0.metadata?.originalLanguage })
        return languages.count
    }
    
    private func calculateReadingStreak(from books: [UserBook]) -> Int {
        let sortedBooks = books.compactMap { $0.dateCompleted }.sorted(by: >)
        guard !sortedBooks.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        var streak = 0
        var currentDate = Date()
        
        for completionDate in sortedBooks {
            let daysDifference = calendar.dateComponents([.day], from: completionDate, to: currentDate).day ?? 0
            
            if daysDifference <= 1 {
                streak += 1
                currentDate = completionDate
            } else {
                break
            }
        }
        
        return min(streak, 30) // Cap at 30 days for display
    }
}