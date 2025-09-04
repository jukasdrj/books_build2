import SwiftUI

// MARK: - Achievement Badge Component for iOS 26 Liquid Glass Design

struct AchievementBadge: View {
    let achievement: UnifiedAchievement
    let onTap: (() -> Void)?
    
    @Environment(\.unifiedThemeStore) private var themeStore
    @State private var isPressed = false
    @State private var showingDetails = false
    
    init(achievement: UnifiedAchievement, onTap: (() -> Void)? = nil) {
        self.achievement = achievement
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: handleTap) {
            VStack(spacing: 8) {
                // Achievement Icon with Rarity Effects
                achievementIcon
                
                // Achievement Title
                Text(achievement.title)
                    .font(.system(size: 11, weight: achievement.rarity.visualWeight, design: .rounded))
                    .foregroundColor(achievement.isUnlocked ? currentTheme.primaryText : currentTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                
                // Progress Indicator (for locked achievements)
                if !achievement.isUnlocked && achievement.progress > 0 {
                    progressIndicator
                }
            }
            .padding(12)
            .frame(width: 90, height: 90)
            .background(achievementBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(rarityBorder)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .opacity(achievement.isUnlocked ? 1.0 : 0.6)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(achievement.accessibilityLabel)
        .accessibilityAddTraits(achievement.isUnlocked ? .isSelected : [])
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) { } onPressingChanged: { pressing in
            isPressed = pressing
        }
        .sheet(isPresented: $showingDetails) {
            AchievementDetailView(achievement: achievement)
        }
    }
    
    // MARK: - Achievement Icon
    
    @ViewBuilder
    private var achievementIcon: some View {
        ZStack {
            // Background Circle with Category Color
            Circle()
                .fill(achievement.category.systemColor.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .fill(.ultraThinMaterial.opacity(0.4))
                )
            
            // Achievement Icon
            Image(systemName: achievement.icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(
                    achievement.isUnlocked 
                        ? AnyShapeStyle(achievement.rarity.colorModifier(baseColor: achievement.color))
                        : AnyShapeStyle(currentTheme.secondaryText.opacity(0.6))
                )
            
            // Unlock Effect for Rare+ Achievements
            if achievement.isUnlocked && achievement.rarity.glowRadius > 0 {
                Circle()
                    .stroke(
                        achievement.rarity.colorModifier(baseColor: achievement.color),
                        lineWidth: 1
                    )
                    .frame(width: 40, height: 40)
                    .blur(radius: achievement.rarity.glowRadius)
                    .opacity(0.8)
            }
        }
    }
    
    // MARK: - Progress Indicator
    
    @ViewBuilder
    private var progressIndicator: some View {
        HStack(spacing: 2) {
            ForEach(0..<4, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(
                        index < Int(achievement.progressPercentage / 25) 
                            ? achievement.category.systemColor 
                            : currentTheme.surface.opacity(0.3)
                    )
                    .frame(width: 12, height: 2)
            }
        }
    }
    
    // MARK: - Background and Border
    
    @ViewBuilder
    private var achievementBackground: some View {
        if achievement.isUnlocked {
            // Unlocked Achievement Background
            RoundedRectangle(cornerRadius: 16)
                .fill(.thinMaterial.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(achievement.color.opacity(0.3), lineWidth: 1)
                )
        } else {
            // Locked Achievement Background
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial.opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(currentTheme.surface.opacity(0.2), lineWidth: 1)
                )
        }
    }
    
    @ViewBuilder
    private var rarityBorder: some View {
        if achievement.isUnlocked && achievement.rarity != .common {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            achievement.rarity.colorModifier(baseColor: achievement.color),
                            achievement.rarity.colorModifier(baseColor: achievement.color).opacity(0.5)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: achievement.rarity == .legendary ? 2 : 1
                )
        }
    }
    
    // MARK: - Actions
    
    private func handleTap() {
        // Haptic Feedback
        #if canImport(UIKit)
        let impactGenerator = UIImpactFeedbackGenerator(style: achievement.rarity.hapticIntensity.uiKitStyle)
        impactGenerator.impactOccurred()
        #endif
        
        if let onTap = onTap {
            onTap()
        } else {
            showingDetails = true
        }
    }
    
    // MARK: - Theme Helper
    
    private var currentTheme: AppColorTheme {
        themeStore.appTheme
    }
}

// MARK: - Achievement Detail View

struct AchievementDetailView: View {
    let achievement: UnifiedAchievement
    @Environment(\.dismiss) private var dismiss
    @Environment(\.unifiedThemeStore) private var themeStore
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 24) {
                // Large Achievement Display
                VStack(spacing: 16) {
                    AchievementBadge(achievement: achievement)
                        .scaleEffect(1.5)
                    
                    VStack(spacing: 8) {
                        Text(achievement.title)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(themeStore.appTheme.primaryText)
                        
                        Text(achievement.description)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(themeStore.appTheme.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, 32)
                .frame(maxWidth: .infinity)
                
                // Achievement Details
                VStack(alignment: .leading, spacing: 16) {
                    detailRow(title: "Category", value: achievement.category.displayName)
                    detailRow(title: "Rarity", value: achievement.rarity.displayName)
                    detailRow(title: "Progress", value: achievement.progressDescription)
                    
                    if let unlockedDate = achievement.unlockedDate {
                        detailRow(
                            title: "Unlocked", 
                            value: DateFormatter.localizedString(from: unlockedDate, dateStyle: .medium, timeStyle: .none)
                        )
                    }
                }
                .optimizedLiquidGlassCard(
                    material: .thin,
                    depth: .elevated,
                    radius: .comfortable,
                    vibrancy: .medium
                )
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .background(
                LinearGradient(
                    colors: [
                        themeStore.appTheme.background.opacity(0.95),
                        themeStore.appTheme.surface.opacity(0.85)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Achievement")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(themeStore.appTheme.primary)
                }
            }
        }
    }
    
    @ViewBuilder
    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(themeStore.appTheme.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(themeStore.appTheme.primaryText)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

// MARK: - Preview

#Preview {
    let sampleAchievement = UnifiedAchievement(
        id: "first_book",
        title: "First Steps",
        description: "Complete your first book",
        icon: "book.fill",
        category: .reading,
        isUnlocked: true,
        unlockedDate: Date(),
        color: .blue,
        rarity: .common,
        progress: 1.0,
        maxProgress: 1.0
    )
    
    VStack {
        HStack {
            AchievementBadge(achievement: sampleAchievement)
            AchievementBadge(achievement: UnifiedAchievement(
                id: "world_explorer",
                title: "World Explorer",
                description: "Read books from 10 different cultures",
                icon: "globe",
                category: .cultural,
                isUnlocked: false,
                color: .green,
                rarity: .rare,
                progress: 7.0,
                maxProgress: 10.0
            ))
        }
        .padding()
    }
    .environment(\.unifiedThemeStore, UnifiedThemeStore())
}