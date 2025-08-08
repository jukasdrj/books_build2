import Foundation
import SwiftUI

@MainActor
class ReadingGoalsManager: ObservableObject {
    static let shared = ReadingGoalsManager()
    
    // MARK: - Goal Settings (Persistent via @AppStorage)
    @AppStorage("dailyPagesGoal") var dailyPagesGoal: Int = 20
    @AppStorage("dailyMinutesGoal") var dailyMinutesGoal: Int = 30
    @AppStorage("weeklyPagesGoal") var weeklyPagesGoal: Int = 140
    @AppStorage("weeklyMinutesGoal") var weeklyMinutesGoal: Int = 210
    @AppStorage("goalType") var goalType: GoalType = .pages
    @AppStorage("isGoalsEnabled") var isGoalsEnabled: Bool = false
    
    // MARK: - Streak Tracking
    @AppStorage("currentStreak") private var currentStreakDays: Int = 0
    @AppStorage("lastGoalCompletionDate") private var lastGoalCompletionDateString: String = ""
    
    private init() {}
    
    // MARK: - Goal Types
    enum GoalType: String, CaseIterable, Identifiable {
        case pages = "pages"
        case minutes = "minutes"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .pages: return "Pages"
            case .minutes: return "Minutes"
            }
        }
        
        var dailyUnit: String {
            switch self {
            case .pages: return "pages/day"
            case .minutes: return "minutes/day"
            }
        }
        
        var weeklyUnit: String {
            switch self {
            case .pages: return "pages/week"
            case .minutes: return "minutes/week"
            }
        }
    }
    
    // MARK: - Progress Calculation
    func getDailyProgress(from books: [UserBook]) -> (current: Int, goal: Int, percentage: Double) {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        let todaySessions = books.flatMap { book in
            book.readingSessions.filter { session in
                session.date >= today && session.date < tomorrow
            }
        }
        
        let current: Int
        let goal: Int
        
        switch goalType {
        case .pages:
            current = todaySessions.reduce(0) { $0 + $1.pagesRead }
            goal = dailyPagesGoal
        case .minutes:
            current = todaySessions.reduce(0) { $0 + $1.durationMinutes }
            goal = dailyMinutesGoal
        }
        
        let percentage = goal > 0 ? min(Double(current) / Double(goal), 1.0) : 0.0
        return (current, goal, percentage)
    }
    
    func getWeeklyProgress(from books: [UserBook]) -> (current: Int, goal: Int, percentage: Double) {
        let calendar = Calendar.current
        let now = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
        
        let weekSessions = books.flatMap { book in
            book.readingSessions.filter { session in
                session.date >= weekStart && session.date < weekEnd
            }
        }
        
        let current: Int
        let goal: Int
        
        switch goalType {
        case .pages:
            current = weekSessions.reduce(0) { $0 + $1.pagesRead }
            goal = weeklyPagesGoal
        case .minutes:
            current = weekSessions.reduce(0) { $0 + $1.durationMinutes }
            goal = weeklyMinutesGoal
        }
        
        let percentage = goal > 0 ? min(Double(current) / Double(goal), 1.0) : 0.0
        return (current, goal, percentage)
    }
    
    // MARK: - Streak Management
    var currentStreak: Int {
        // Update streak check but don't modify state during property access
        Task {
            await updateStreakIfNeeded()
        }
        return currentStreakDays
    }
    
    private var lastGoalCompletionDate: Date? {
        get {
            guard !lastGoalCompletionDateString.isEmpty else { return nil }
            return ISO8601DateFormatter().date(from: lastGoalCompletionDateString)
        }
        set {
            if let date = newValue {
                lastGoalCompletionDateString = ISO8601DateFormatter().string(from: date)
            } else {
                lastGoalCompletionDateString = ""
            }
        }
    }
    
    func checkAndUpdateStreak(from books: [UserBook]) {
        // Dispatch to next run loop to avoid "Publishing changes from within view updates"
        Task {
            await performStreakUpdate(from: books)
        }
    }
    
    @MainActor
    private func performStreakUpdate(from books: [UserBook]) async {
        let dailyProgress = getDailyProgress(from: books)
        let isGoalMet = dailyProgress.current >= dailyProgress.goal
        let today = Calendar.current.startOfDay(for: Date())
        
        guard isGoalMet else { return }
        
        // Check if we haven't already recorded today
        if let lastCompletion = lastGoalCompletionDate,
           Calendar.current.isDate(lastCompletion, inSameDayAs: today) {
            return // Already recorded today
        }
        
        // Batch all state changes together
        var newStreakDays = currentStreakDays
        var shouldTriggerHaptic = false
        
        // Check if this continues the streak
        if let lastCompletion = lastGoalCompletionDate {
            let daysBetween = Calendar.current.dateComponents([.day], from: lastCompletion, to: today).day ?? 0
            
            if daysBetween == 1 {
                // Consecutive day - extend streak
                newStreakDays += 1
                shouldTriggerHaptic = true
            } else if daysBetween == 0 {
                // Same day - no change
                return
            } else {
                // Gap in days - reset streak to 1
                newStreakDays = 1
                shouldTriggerHaptic = true
            }
        } else {
            // First goal completion
            newStreakDays = 1
            shouldTriggerHaptic = true
        }
        
        // Apply all changes at once
        currentStreakDays = newStreakDays
        lastGoalCompletionDate = today
        
        // Trigger haptic feedback after state updates
        if shouldTriggerHaptic {
            HapticFeedbackManager.shared.goalCompleted()
        }
    }
    
    @MainActor
    private func updateStreakIfNeeded() async {
        guard let lastCompletion = lastGoalCompletionDate else {
            if currentStreakDays != 0 {
                currentStreakDays = 0
            }
            return
        }
        
        let today = Calendar.current.startOfDay(for: Date())
        let daysSinceLastCompletion = Calendar.current.dateComponents([.day], from: lastCompletion, to: today).day ?? 0
        
        // If more than 1 day has passed without completing a goal, reset streak
        if daysSinceLastCompletion > 1 {
            currentStreakDays = 0
            lastGoalCompletionDate = nil
        }
    }
    
    // MARK: - Goal Achievement Status
    func getDailyAchievementMessage(current: Int, goal: Int) -> String? {
        guard isGoalsEnabled && goal > 0 else { return nil }
        
        if current >= goal {
            let unit = goalType == .pages ? "pages" : "minutes"
            return "🎉 Daily goal achieved! \(current) \(unit)"
        } else {
            let remaining = goal - current
            let unit = goalType == .pages ? "pages" : "minutes"
            return "\(remaining) \(unit) to go today"
        }
    }
    
    // MARK: - Motivational Messages
    func getMotivationalMessage(dailyPercentage: Double, weeklyPercentage: Double) -> String {
        if dailyPercentage >= 1.0 && weeklyPercentage >= 1.0 {
            return "🔥 Crushing your goals!"
        } else if dailyPercentage >= 1.0 {
            return "✨ Daily goal smashed!"
        } else if dailyPercentage >= 0.8 {
            return "🚀 Almost there!"
        } else if weeklyPercentage >= 0.8 {
            return "📈 Great weekly progress!"
        } else if dailyPercentage > 0 {
            return "📚 Keep reading!"
        } else {
            return "Start your reading journey"
        }
    }
}

// MARK: - HapticFeedbackManager Extension
extension HapticFeedbackManager {
    func goalCompleted() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Success notification feedback
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
}