import SwiftUI

struct GoalProgressRing: View {
    let progress: Double // 0.0 to 1.0
    let current: Int
    let goal: Int
    let title: String
    let subtitle: String?
    let color: Color
    let size: CGFloat
    
    init(progress: Double, current: Int, goal: Int, title: String, subtitle: String? = nil, color: Color = .blue, size: CGFloat = 120) {
        self.progress = progress
        self.current = current
        self.goal = goal
        self.title = title
        self.subtitle = subtitle
        self.color = color
        self.size = size
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Background circle
                Circle()
                    .stroke(
                        color.opacity(0.2),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: size, height: size)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        color,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: progress)
                
                // Center content
                VStack(spacing: 2) {
                    Text("\(current)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("/ \(goal)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct GoalProgressCard: View {
    @StateObject private var goalsManager = ReadingGoalsManager.shared
    let books: [UserBook]
    
    var body: some View {
        VStack(spacing: 16) {
            if goalsManager.isGoalsEnabled {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Reading Goals")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(goalsManager.getMotivationalMessage(
                            dailyPercentage: goalsManager.getDailyProgress(from: books).percentage,
                            weeklyPercentage: goalsManager.getWeeklyProgress(from: books).percentage
                        ))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Streak counter
                    if goalsManager.currentStreak > 0 {
                        VStack(spacing: 2) {
                            Text("🔥")
                                .font(.title2)
                            Text("\(goalsManager.currentStreak)")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            Text("day streak")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                
                // Progress rings
                HStack(spacing: 20) {
                    let dailyProgress = goalsManager.getDailyProgress(from: books)
                    let weeklyProgress = goalsManager.getWeeklyProgress(from: books)
                    
                    GoalProgressRing(
                        progress: dailyProgress.percentage,
                        current: dailyProgress.current,
                        goal: dailyProgress.goal,
                        title: "Today",
                        subtitle: goalsManager.goalType.displayName,
                        color: Color.theme.primary,
                        size: 100
                    )
                    
                    GoalProgressRing(
                        progress: weeklyProgress.percentage,
                        current: weeklyProgress.current,
                        goal: weeklyProgress.goal,
                        title: "This Week",
                        subtitle: goalsManager.goalType.displayName,
                        color: Color.theme.secondary,
                        size: 100
                    )
                }
                
                // Achievement message
                let dailyProgress = goalsManager.getDailyProgress(from: books)
                if let message = goalsManager.getDailyAchievementMessage(
                    current: dailyProgress.current,
                    goal: dailyProgress.goal
                ) {
                    Text(message)
                        .font(.callout)
                        .foregroundColor(dailyProgress.current >= dailyProgress.goal ? .green : .secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            (dailyProgress.current >= dailyProgress.goal ? Color.green : Color.gray)
                                .opacity(0.1)
                        )
                        .cornerRadius(8)
                }
                
            } else {
                // Goals disabled state
                VStack(spacing: 12) {
                    Image(systemName: "target")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 4) {
                        Text("Set Reading Goals")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Track daily and weekly reading progress")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.vertical, 20)
            }
        }
        .padding(20)
        .materialCard()
        .task {
            // Use task instead of onAppear to properly handle async operations
            if goalsManager.isGoalsEnabled {
                goalsManager.checkAndUpdateStreak(from: books)
            }
        }
    }
}

struct CompactGoalProgressView: View {
    @StateObject private var goalsManager = ReadingGoalsManager.shared
    let books: [UserBook]
    
    var body: some View {
        if goalsManager.isGoalsEnabled {
            let dailyProgress = goalsManager.getDailyProgress(from: books)
            
            HStack(spacing: 12) {
                // Mini progress ring
                ZStack {
                    Circle()
                        .stroke(Color.theme.primary.opacity(0.2), lineWidth: 4)
                        .frame(width: 40, height: 40)
                    
                    Circle()
                        .trim(from: 0, to: dailyProgress.percentage)
                        .stroke(Color.theme.primary, lineWidth: 4)
                        .frame(width: 40, height: 40)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.8), value: dailyProgress.percentage)
                    
                    Text("\(Int(dailyProgress.percentage * 100))%")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Today's Goal")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("\(dailyProgress.current) / \(dailyProgress.goal) \(goalsManager.goalType.displayName.lowercased())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if goalsManager.currentStreak > 0 {
                    HStack(spacing: 4) {
                        Text("🔥")
                            .font(.caption)
                        Text("\(goalsManager.currentStreak)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(12)
            .task {
                // Handle streak updates asynchronously
                if goalsManager.isGoalsEnabled {
                    goalsManager.checkAndUpdateStreak(from: books)
                }
            }
        }
    }
}

#Preview("Goal Progress Ring") {
    GoalProgressRing(
        progress: 0.75,
        current: 150,
        goal: 200,
        title: "Today",
        subtitle: "Pages",
        color: .blue
    )
    .padding()
}

#Preview("Goal Progress Card") {
    GoalProgressCard(books: [])
        .padding()
}