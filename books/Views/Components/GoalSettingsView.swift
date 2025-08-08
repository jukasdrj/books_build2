import SwiftUI

struct GoalSettingsView: View {
    @StateObject private var goalsManager = ReadingGoalsManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    // Enable/Disable Goals
                    HStack {
                        Image(systemName: "target")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        
                        Toggle("Enable Reading Goals", isOn: $goalsManager.isGoalsEnabled)
                    }
                    
                    if goalsManager.isGoalsEnabled {
                        // Goal Type Selection
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "scope")
                                    .foregroundColor(.purple)
                                    .frame(width: 24)
                                Text("Track By")
                                    .fontWeight(.medium)
                            }
                            
                            Picker("Goal Type", selection: $goalsManager.goalType) {
                                ForEach(ReadingGoalsManager.GoalType.allCases) { type in
                                    Text(type.displayName)
                                        .tag(type)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                } header: {
                    Text("Reading Goals")
                } footer: {
                    if goalsManager.isGoalsEnabled {
                        Text("Set daily and weekly reading targets to build consistent reading habits and track your progress.")
                    } else {
                        Text("Enable reading goals to track your daily and weekly reading progress.")
                    }
                }
                
                if goalsManager.isGoalsEnabled {
                    Section {
                        // Daily Goal Setting
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "sun.max")
                                    .foregroundColor(.orange)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Daily Goal")
                                        .fontWeight(.medium)
                                    Text(goalsManager.goalType.dailyUnit)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if goalsManager.goalType == .pages {
                                    Text("\(goalsManager.dailyPagesGoal)")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                } else {
                                    Text("\(goalsManager.dailyMinutesGoal)")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                }
                            }
                            
                            if goalsManager.goalType == .pages {
                                Slider(
                                    value: Binding(
                                        get: { Double(goalsManager.dailyPagesGoal) },
                                        set: { goalsManager.dailyPagesGoal = Int($0) }
                                    ),
                                    in: 1...100,
                                    step: 1
                                ) {
                                    Text("Pages per day")
                                } minimumValueLabel: {
                                    Text("1")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } maximumValueLabel: {
                                    Text("100")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .accentColor(Color.theme.primary)
                            } else {
                                Slider(
                                    value: Binding(
                                        get: { Double(goalsManager.dailyMinutesGoal) },
                                        set: { goalsManager.dailyMinutesGoal = Int($0) }
                                    ),
                                    in: 5...120,
                                    step: 5
                                ) {
                                    Text("Minutes per day")
                                } minimumValueLabel: {
                                    Text("5")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } maximumValueLabel: {
                                    Text("120")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .accentColor(Color.theme.primary)
                            }
                        }
                        
                        // Weekly Goal Setting
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "calendar.badge.clock")
                                    .foregroundColor(.green)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Weekly Goal")
                                        .fontWeight(.medium)
                                    Text(goalsManager.goalType.weeklyUnit)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if goalsManager.goalType == .pages {
                                    Text("\(goalsManager.weeklyPagesGoal)")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                } else {
                                    Text("\(goalsManager.weeklyMinutesGoal)")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                }
                            }
                            
                            if goalsManager.goalType == .pages {
                                Slider(
                                    value: Binding(
                                        get: { Double(goalsManager.weeklyPagesGoal) },
                                        set: { goalsManager.weeklyPagesGoal = Int($0) }
                                    ),
                                    in: 7...700,
                                    step: 7
                                ) {
                                    Text("Pages per week")
                                } minimumValueLabel: {
                                    Text("7")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } maximumValueLabel: {
                                    Text("700")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .accentColor(Color.theme.secondary)
                            } else {
                                Slider(
                                    value: Binding(
                                        get: { Double(goalsManager.weeklyMinutesGoal) },
                                        set: { goalsManager.weeklyMinutesGoal = Int($0) }
                                    ),
                                    in: 35...840,
                                    step: 35
                                ) {
                                    Text("Minutes per week")
                                } minimumValueLabel: {
                                    Text("35")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } maximumValueLabel: {
                                    Text("840")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .accentColor(Color.theme.secondary)
                            }
                        }
                    } header: {
                        Text("Goal Targets")
                    } footer: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Recommended daily goals:")
                            Text("• Pages: 20-40 pages (about 30-60 minutes)")
                            Text("• Minutes: 30-60 minutes reading time")
                        }
                        .font(.caption)
                    }
                    
                    // Current Streak Display
                    if goalsManager.currentStreak > 0 {
                        Section {
                            HStack {
                                Image(systemName: "flame.fill")
                                    .foregroundColor(.orange)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Current Streak")
                                        .fontWeight(.medium)
                                    Text("Keep it up! You're doing great.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("\(goalsManager.currentStreak)")
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(.orange)
                                    Text(goalsManager.currentStreak == 1 ? "day" : "days")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        } header: {
                            Text("Progress")
                        }
                    }
                    
                    // Quick Setup Suggestions
                    Section {
                        VStack(spacing: 12) {
                            GoalPresetButton(
                                title: "Light Reader",
                                description: "Perfect for starting a reading habit",
                                pagesGoal: 10,
                                minutesGoal: 15,
                                action: { setLightReaderGoals() }
                            )
                            
                            Divider()
                            
                            GoalPresetButton(
                                title: "Regular Reader",
                                description: "For consistent daily reading",
                                pagesGoal: 25,
                                minutesGoal: 30,
                                action: { setRegularReaderGoals() }
                            )
                            
                            Divider()
                            
                            GoalPresetButton(
                                title: "Avid Reader",
                                description: "For dedicated book enthusiasts",
                                pagesGoal: 50,
                                minutesGoal: 60,
                                action: { setAvidReaderGoals() }
                            )
                        }
                    } header: {
                        Text("Quick Setup")
                    } footer: {
                        Text("Tap a preset to quickly configure your reading goals based on common reading habits.")
                    }
                }
            }
            .navigationTitle("Reading Goals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        HapticFeedbackManager.shared.lightImpact()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func setLightReaderGoals() {
        goalsManager.dailyPagesGoal = 10
        goalsManager.dailyMinutesGoal = 15
        goalsManager.weeklyPagesGoal = 70
        goalsManager.weeklyMinutesGoal = 105
        HapticFeedbackManager.shared.mediumImpact()
    }
    
    private func setRegularReaderGoals() {
        goalsManager.dailyPagesGoal = 25
        goalsManager.dailyMinutesGoal = 30
        goalsManager.weeklyPagesGoal = 175
        goalsManager.weeklyMinutesGoal = 210
        HapticFeedbackManager.shared.mediumImpact()
    }
    
    private func setAvidReaderGoals() {
        goalsManager.dailyPagesGoal = 50
        goalsManager.dailyMinutesGoal = 60
        goalsManager.weeklyPagesGoal = 350
        goalsManager.weeklyMinutesGoal = 420
        HapticFeedbackManager.shared.mediumImpact()
    }
}

struct GoalPresetButton: View {
    let title: String
    let description: String
    let pagesGoal: Int
    let minutesGoal: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 16) {
                        Text("\(pagesGoal) pages/day")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.theme.primary.opacity(0.1))
                            .cornerRadius(8)
                        
                        Text("\(minutesGoal) min/day")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.theme.secondary.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    GoalSettingsView()
}