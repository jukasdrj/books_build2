import Foundation
import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

// MARK: - Haptic Feedback Support

/// Cross-platform haptic intensity levels
enum HapticIntensity {
    case light
    case medium  
    case heavy
    
    #if canImport(UIKit)
    var uiKitStyle: UIImpactFeedbackGenerator.FeedbackStyle {
        switch self {
        case .light: return .light
        case .medium: return .medium
        case .heavy: return .heavy
        }
    }
    #endif
}

// MARK: - Reading Insights Data Models

/// Monthly aggregated reading data for timeline visualization
struct MonthlyReadingData: Identifiable, Equatable {
    let id = UUID()
    let month: String
    let year: Int
    let booksRead: Int
    let diversityScore: Double
    let averageRating: Double
    let culturesExplored: Int
    let languagesRead: Set<String>
    let primaryGenre: String
    let totalPagesRead: Int
    let averagePageCount: Int
    let readingTime: Int // minutes
    
    init(
        month: String,
        year: Int,
        booksRead: Int,
        diversityScore: Double,
        averageRating: Double,
        culturesExplored: Int,
        languagesRead: Set<String>,
        primaryGenre: String,
        totalPagesRead: Int,
        averagePageCount: Int,
        readingTime: Int
    ) {
        self.month = month
        self.year = year
        self.booksRead = booksRead
        self.diversityScore = diversityScore
        self.averageRating = averageRating
        self.culturesExplored = culturesExplored
        self.languagesRead = languagesRead
        self.primaryGenre = primaryGenre
        self.totalPagesRead = totalPagesRead
        self.averagePageCount = averagePageCount
        self.readingTime = readingTime
    }
    
    /// Short month identifier (e.g., "Jan", "Feb")
    var shortMonth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        
        if let monthIndex = Calendar.current.monthSymbols.firstIndex(of: month) {
            formatter.locale = Locale.current
            let calendar = Calendar.current
            let date = calendar.date(from: DateComponents(year: year, month: monthIndex + 1)) ?? Date()
            return formatter.string(from: date)
        }
        
        return String(month.prefix(3))
    }
    
    /// Formatted date for accessibility
    var accessibilityDate: String {
        "\(month) \(year)"
    }
}

/// Achievement system for gamified reading progress
struct UnifiedAchievement: Identifiable, Equatable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let category: AchievementCategory
    let isUnlocked: Bool
    let unlockedDate: Date?
    let color: Color
    let rarity: AchievementRarity
    let progress: Double // 0.0 to 1.0 for partial achievements
    let maxProgress: Double // Maximum value for this achievement
    
    init(
        id: String,
        title: String,
        description: String,
        icon: String,
        category: AchievementCategory,
        isUnlocked: Bool,
        unlockedDate: Date? = nil,
        color: Color,
        rarity: AchievementRarity,
        progress: Double = 0.0,
        maxProgress: Double = 1.0
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.icon = icon
        self.category = category
        self.isUnlocked = isUnlocked
        self.unlockedDate = unlockedDate
        self.color = color
        self.rarity = rarity
        self.progress = min(progress, maxProgress)
        self.maxProgress = maxProgress
    }
    
    /// Progress percentage for display (0-100)
    var progressPercentage: Double {
        guard maxProgress > 0 else { return 0 }
        return (progress / maxProgress) * 100
    }
    
    /// Human-readable progress description
    var progressDescription: String {
        if isUnlocked {
            return "Unlocked"
        } else if progress > 0 {
            return "\(Int(progress))/\(Int(maxProgress))"
        } else {
            return "Not started"
        }
    }
    
    /// Accessibility label for achievement
    var accessibilityLabel: String {
        let status = isUnlocked ? "unlocked" : "locked"
        let progressText = isUnlocked ? "" : ", progress: \(progressDescription)"
        return "\(title) achievement, \(category.displayName), \(rarity.displayName) rarity, \(status)\(progressText). \(description)"
    }
}

/// Achievement categories for organization
enum AchievementCategory: String, CaseIterable, Identifiable {
    case reading = "reading"
    case cultural = "cultural"
    case combined = "combined"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .reading: return "Reading"
        case .cultural: return "Cultural"
        case .combined: return "Combined"
        }
    }
    
    var icon: String {
        switch self {
        case .reading: return "book.fill"
        case .cultural: return "globe"
        case .combined: return "star.fill"
        }
    }
    
    var systemColor: Color {
        switch self {
        case .reading: return .blue
        case .cultural: return .green  
        case .combined: return .purple
        }
    }
}

/// Achievement rarity system with visual differentiation
enum AchievementRarity: String, CaseIterable, Identifiable {
    case common = "common"
    case uncommon = "uncommon"
    case rare = "rare"
    case epic = "epic"
    case legendary = "legendary"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .common: return "Common"
        case .uncommon: return "Uncommon"
        case .rare: return "Rare"
        case .epic: return "Epic"
        case .legendary: return "Legendary"
        }
    }
    
    /// Haptic feedback intensity based on rarity
    var hapticIntensity: HapticIntensity {
        switch self {
        case .common, .uncommon: return .light
        case .rare: return .medium
        case .epic, .legendary: return .heavy
        }
    }
    
    /// Visual weight for different rarities
    var visualWeight: Font.Weight {
        switch self {
        case .common: return .regular
        case .uncommon: return .medium
        case .rare: return .semibold
        case .epic: return .bold
        case .legendary: return .heavy
        }
    }
    
    /// Glow effect radius for rare achievements
    var glowRadius: CGFloat {
        switch self {
        case .common, .uncommon: return 0
        case .rare: return 2
        case .epic: return 4
        case .legendary: return 6
        }
    }
    
    /// Color modifier for rarity indication
    func colorModifier(baseColor: Color) -> Color {
        switch self {
        case .common: return baseColor.opacity(0.8)
        case .uncommon: return baseColor.opacity(0.9)
        case .rare: return baseColor
        case .epic: return baseColor.opacity(1.0) // Full opacity
        case .legendary: return baseColor.opacity(1.0) // Full opacity with potential glow effect
        }
    }
}

/// Trend direction indicator for metrics
enum TrendDirection: String, CaseIterable {
    case up = "up"
    case down = "down"
    case stable = "stable"
    
    var icon: String {
        switch self {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .stable: return "minus"
        }
    }
    
    var systemColor: Color {
        switch self {
        case .up: return .green
        case .down: return .red
        case .stable: return .gray
        }
    }
    
    var accessibilityDescription: String {
        switch self {
        case .up: return "trending up"
        case .down: return "trending down"
        case .stable: return "stable"
        }
    }
}

/// Time period filter for insights
enum InsightsTimeFrame: String, CaseIterable, Identifiable {
    case week = "week"
    case month = "month"
    case year = "year"
    case allTime = "all_time"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        case .year: return "Year"
        case .allTime: return "All Time"
        }
    }
    
    /// Calculate the start date for this time frame
    func startDate(from referenceDate: Date = Date()) -> Date {
        let calendar = Calendar.current
        switch self {
        case .week:
            return calendar.date(byAdding: .day, value: -7, to: referenceDate) ?? referenceDate
        case .month:
            return calendar.date(byAdding: .month, value: -1, to: referenceDate) ?? referenceDate
        case .year:
            return calendar.date(byAdding: .year, value: -1, to: referenceDate) ?? referenceDate
        case .allTime:
            return Date.distantPast
        }
    }
}

/// Insight metric type for filtering
enum InsightMetricType: String, CaseIterable, Identifiable {
    case readingVelocity = "reading_velocity"
    case culturalExploration = "cultural_exploration"
    case readingStreak = "reading_streak"
    case genreDiversity = "genre_diversity"
    case readingGoals = "reading_goals"
    case timeSpent = "time_spent"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .readingVelocity: return "Reading Velocity"
        case .culturalExploration: return "Cultural Exploration"
        case .readingStreak: return "Reading Streak"
        case .genreDiversity: return "Genre Diversity"
        case .readingGoals: return "Reading Goals"
        case .timeSpent: return "Time Spent"
        }
    }
    
    var icon: String {
        switch self {
        case .readingVelocity: return "gauge.high"
        case .culturalExploration: return "globe.americas"
        case .readingStreak: return "flame"
        case .genreDiversity: return "books.vertical"
        case .readingGoals: return "target"
        case .timeSpent: return "clock"
        }
    }
    
    var unit: String {
        switch self {
        case .readingVelocity: return "books/month"
        case .culturalExploration: return "cultures"
        case .readingStreak: return "days"
        case .genreDiversity: return "genres"
        case .readingGoals: return "books"
        case .timeSpent: return "hours"
        }
    }
}

/// Smart goal tracking
struct SmartGoal: Identifiable, Equatable {
    let id: String
    let type: SmartGoalType
    let title: String
    let targetValue: Double
    let currentValue: Double
    let deadline: Date?
    let isActive: Bool
    let createdDate: Date
    
    /// Progress as percentage (0-100)
    var progressPercentage: Double {
        guard targetValue > 0 else { return 0 }
        return min((currentValue / targetValue) * 100, 100)
    }
    
    /// Remaining value to reach goal
    var remainingValue: Double {
        max(targetValue - currentValue, 0)
    }
    
    /// Smart subtitle based on progress and time remaining
    var smartSubtitle: String {
        let remaining = Int(remainingValue)
        
        guard remaining > 0 else {
            return "Goal completed! 🎉"
        }
        
        if let deadline = deadline {
            let timeRemaining = Calendar.current.dateComponents([.day], from: Date(), to: deadline).day ?? 0
            if timeRemaining > 0 {
                let dailyRate = Double(remaining) / Double(timeRemaining)
                return "\(remaining) \(type.unit) remaining • \(String(format: "%.1f", dailyRate)) per day"
            } else {
                return "\(remaining) \(type.unit) remaining"
            }
        } else {
            return "\(remaining) \(type.unit) remaining"
        }
    }
    
    /// Accessibility description for goal
    var accessibilityDescription: String {
        let progressText = String(format: "%.0f", progressPercentage)
        return "\(title): \(progressText)% complete. Current: \(Int(currentValue)), Target: \(Int(targetValue)) \(type.unit). \(smartSubtitle)"
    }
}

/// Types of smart goals
enum SmartGoalType: String, CaseIterable, Identifiable {
    case annualReading = "annual_reading"
    case culturalDiversity = "cultural_diversity"
    case readingStreak = "reading_streak"
    case genreExploration = "genre_exploration"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .annualReading: return "Annual Reading Goal"
        case .culturalDiversity: return "Cultural Diversity Goal"
        case .readingStreak: return "Reading Streak Goal"
        case .genreExploration: return "Genre Exploration Goal"
        }
    }
    
    var icon: String {
        switch self {
        case .annualReading: return "calendar"
        case .culturalDiversity: return "globe.americas"
        case .readingStreak: return "flame"
        case .genreExploration: return "books.vertical"
        }
    }
    
    var unit: String {
        switch self {
        case .annualReading: return "books"
        case .culturalDiversity: return "cultures"
        case .readingStreak: return "days"
        case .genreExploration: return "genres"
        }
    }
    
    var systemColor: Color {
        switch self {
        case .annualReading: return .blue
        case .culturalDiversity: return .green
        case .readingStreak: return .orange
        case .genreExploration: return .purple
        }
    }
}