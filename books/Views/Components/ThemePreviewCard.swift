import SwiftUI

struct ThemePreviewCard: View {
    let theme: ThemeVariant
    let isSelected: Bool
    let onSelect: () -> Void
    
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Theme info
            themeInfoSection
            
            // Theme preview
            themePreviewSection
            
            // Selection indicator
            if isSelected {
                Label("Selected", systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.medium))
                    .foregroundColor(Color.theme.success)
                    .padding(.top, Theme.Spacing.sm)
            } else {
                // Placeholder to maintain layout consistency
                Label("Selected", systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.medium))
                    .foregroundColor(Color.clear)
                    .padding(.top, Theme.Spacing.sm)
            }
        }
        .padding(Theme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                .fill(Color.theme.cardBackground)
                .shadow(color: .black.opacity(0.05), radius: 5, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                .stroke(
                    isSelected ? Color.theme.primary : Color.theme.outline.opacity(0.2),
                    lineWidth: isSelected ? 2 : 1
                )
        )
        .scaleEffect(scale)
        .materialInteractive()
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                scale = 1.0
            }
            onSelect()
        }
        .onLongPressGesture(minimumDuration: 0.05) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                scale = 0.98
            }
        } onPressingChanged: { isPressing in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                scale = isPressing ? 0.98 : 1.0
            }
        }
    }
    
    @ViewBuilder
    private var themeInfoSection: some View {
        HStack(spacing: Theme.Spacing.md) {
            Text(theme.emoji)
                .font(.largeTitle)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(theme.displayName)
                    .font(.headline)
                    .foregroundColor(Color.theme.primaryText)
                
                Text(theme.description)
                    .font(.subheadline)
                    .foregroundColor(Color.theme.secondaryText)
            }
            Spacer()
        }
    }
    
    @ViewBuilder
    private var themePreviewSection: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(theme.colorDefinition.previewColors[index])
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .stroke(Color.black.opacity(0.1), lineWidth: 1)
                    )
            }
        }
    }
}