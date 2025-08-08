//
//  UnifiedBookComponents.swift
//  books
//
//  VIS-003: Unified design system for all book representations
//  Consistent shadows, spacing, typography, and interactive states
//

import SwiftUI

// MARK: - Unified Book Card Design System

enum UnifiedBookCard {
    
    // MARK: - Standardized Dimensions
    enum Dimensions {
        // Card layout
        static let cardWidth: CGFloat = 140
        static let cardHeight: CGFloat = 280
        
        // Row layout
        static let rowHeight: CGFloat = 110
        
        // Cover sizes for consistency
        static let cardCoverWidth: CGFloat = 120
        static let cardCoverHeight: CGFloat = 180
        static let rowCoverWidth: CGFloat = 60
        static let rowCoverHeight: CGFloat = 90
        
        // Responsive breakpoints
        static let compactWidthThreshold: CGFloat = 400
        static let regularWidthThreshold: CGFloat = 700
    }
    
    // MARK: - Standardized Shadows & Elevation
    enum Elevation {
        static let card = Theme.Elevation.level2
        static let cardHovered = Theme.Elevation.level3
        static let row = Theme.Elevation.level1
        static let rowHovered = Theme.Elevation.level2
        static let cover = Theme.Elevation.level1
    }
    
    // MARK: - Interactive States
    enum InteractiveStates {
        static let pressedScale: CGFloat = 0.96
        static let rowPressedScale: CGFloat = 0.98
        static let pressedOpacity: Double = 0.9
        static let hoverScale: CGFloat = 1.02
        static let animationDuration: TimeInterval = 0.2
    }
    
    // MARK: - Typography Hierarchy
    enum Typography {
        // Card typography
        static let cardTitle = Theme.Typography.titleSmall
        static let cardAuthor = Theme.Typography.bodySmall
        static let cardMeta = Theme.Typography.labelSmall
        
        // Row typography
        static let rowTitle = Theme.Typography.titleMedium
        static let rowAuthor = Theme.Typography.bodyMedium
        static let rowMeta = Theme.Typography.labelMedium
    }
    
    // MARK: - Spacing Consistency
    enum Spacing {
        static let cardInternalSpacing = Theme.Spacing.sm
        static let rowInternalSpacing = Theme.Spacing.md
        static let metaSpacing = Theme.Spacing.xs
        static let ratingSpacing: CGFloat = 2
    }
}

// MARK: - Unified Book Cover Component

struct UnifiedBookCoverView: View {
    let imageURL: String?
    let width: CGFloat
    let height: CGFloat
    let style: BookDisplayStyle
    
    @State private var isImageLoading = true
    
    var body: some View {
        ZStack {
            // Unified placeholder with consistent styling
            RoundedRectangle(cornerRadius: coverCornerRadius)
                .fill(placeholderGradient)
                .overlay(
                    Image(systemName: "book.closed")
                        .font(.system(size: placeholderIconSize, weight: .light))
                        .foregroundStyle(Color.theme.onSurfaceVariant.opacity(0.6))
                )
            
            // Book cover image with consistent treatment
            BookCoverImage(
                imageURL: imageURL,
                width: width,
                height: height
            )
            .clipShape(RoundedRectangle(cornerRadius: coverCornerRadius))
            .onAppear {
                // Simulate loading completion for shimmer effect
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(Theme.Animation.accessible) {
                        isImageLoading = false
                    }
                }
            }
            
            // Unified loading shimmer
            if isImageLoading {
                RoundedRectangle(cornerRadius: coverCornerRadius)
                    .fill(shimmerGradient)
                    .frame(width: width, height: height)
                    .shimmerEffect()
            }
        }
        .frame(width: width, height: height)
        .shadow(
            color: UnifiedBookCard.Elevation.cover.color,
            radius: UnifiedBookCard.Elevation.cover.radius,
            x: UnifiedBookCard.Elevation.cover.x,
            y: UnifiedBookCard.Elevation.cover.y
        )
    }
    
    private var coverCornerRadius: CGFloat {
        switch style {
        case .card: return Theme.CornerRadius.small
        case .row: return Theme.CornerRadius.small
        }
    }
    
    private var placeholderIconSize: CGFloat {
        switch style {
        case .card: return 32
        case .row: return 20
        }
    }
    
    private var placeholderGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.theme.surfaceVariant,
                Color.theme.surfaceVariant.opacity(0.7)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var shimmerGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.theme.primary.opacity(0.1),
                Color.theme.secondary.opacity(0.05),
                Color.theme.primary.opacity(0.1)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Unified Book Information Component

struct UnifiedBookInfoView: View {
    let title: String
    let authors: [String]
    let rating: Int?
    let status: ReadingStatus
    let progress: Double
    let language: String?
    let layout: BookDisplayStyle
    
    var body: some View {
        VStack(alignment: .leading, spacing: internalSpacing) {
            // Title with consistent typography
            Text(title)
                .font(titleFont)
                .foregroundColor(Color.theme.primaryText)
                .lineLimit(titleLineLimit)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: titleHeight, alignment: .top)
            
            // Authors with consistent typography
            if !authors.isEmpty {
                Text(authors.joined(separator: ", "))
                    .font(authorFont)
                    .foregroundColor(Color.theme.secondaryText)
                    .lineLimit(authorLineLimit)
                    .frame(height: authorHeight, alignment: .top)
            }
            
            // Metadata row with unified spacing
            HStack(spacing: UnifiedBookCard.Spacing.metaSpacing) {
                // Rating with consistent design
                UnifiedRatingView(rating: rating, style: layout)
                
                Spacer()
                
                // Status badge with unified design
                if status != .toRead {
                    UnifiedStatusBadge(status: status, style: layout)
                }
            }
            .frame(height: metaRowHeight)
            
            // Progress indicator for reading books
            if layout == .row && status == .reading && progress > 0 {
                UnifiedProgressView(progress: progress)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Layout-specific Properties
    
    private var internalSpacing: CGFloat {
        switch layout {
        case .card: return UnifiedBookCard.Spacing.cardInternalSpacing
        case .row: return UnifiedBookCard.Spacing.rowInternalSpacing
        }
    }
    
    private var titleFont: Font {
        switch layout {
        case .card: return UnifiedBookCard.Typography.cardTitle
        case .row: return UnifiedBookCard.Typography.rowTitle
        }
    }
    
    private var authorFont: Font {
        switch layout {
        case .card: return UnifiedBookCard.Typography.cardAuthor
        case .row: return UnifiedBookCard.Typography.rowAuthor
        }
    }
    
    private var titleLineLimit: Int {
        switch layout {
        case .card: return 2
        case .row: return 2
        }
    }
    
    private var authorLineLimit: Int {
        return 1
    }
    
    private var titleHeight: CGFloat {
        switch layout {
        case .card: return 44 // 2 lines at titleSmall
        case .row: return 44 // 2 lines at titleMedium
        }
    }
    
    private var authorHeight: CGFloat {
        switch layout {
        case .card: return 20 // 1 line at bodySmall
        case .row: return 24 // 1 line at bodyMedium
        }
    }
    
    private var metaRowHeight: CGFloat {
        return 20
    }
}

// MARK: - Unified Rating Component

struct UnifiedRatingView: View {
    let rating: Int?
    let style: BookDisplayStyle
    
    var body: some View {
        HStack(spacing: UnifiedBookCard.Spacing.ratingSpacing) {
            if let rating = rating {
                // Filled stars
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= rating ? "star.fill" : "star")
                        .font(.system(size: starSize, weight: .medium))
                        .foregroundColor(star <= rating ? Color.theme.tertiary : Color.theme.outline.opacity(0.3))
                }
                
                // Rating number for row layout
                if style == .row {
                    Text("(\(rating))")
                        .font(UnifiedBookCard.Typography.rowMeta)
                        .foregroundColor(Color.theme.tertiary)
                        .fontWeight(.medium)
                }
            } else {
                // Empty stars placeholder for consistency
                ForEach(1...5, id: \.self) { _ in
                    Image(systemName: "star")
                        .font(.system(size: starSize))
                        .foregroundColor(Color.theme.outline.opacity(0.2))
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(rating != nil ? "\(rating!) out of 5 stars" : "Not rated")
        .accessibilityAddTraits(.isStaticText)
    }
    
    private var starSize: CGFloat {
        switch style {
        case .card: return 10
        case .row: return 12
        }
    }
}

// MARK: - Unified Status Badge Component

struct UnifiedStatusBadge: View {
    let status: ReadingStatus
    let style: BookDisplayStyle
    
    var body: some View {
        Text(badgeText)
            .font(badgeFont)
            .fontWeight(.medium)
            .foregroundColor(status.textColor)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(
                Capsule()
                    .fill(status.containerColor)
            )
            .accessibilityLabel("Status: \(status.rawValue)")
            .accessibilityAddTraits(.isStaticText)
    }
    
    private var badgeText: String {
        switch style {
        case .card:
            // Abbreviated for space constraints
            switch status {
            case .reading: return "Reading"
            case .read: return "Read"
            case .onHold: return "Hold"
            case .dnf: return "DNF"
            case .toRead: return "TBR"
            }
        case .row:
            return status.rawValue
        }
    }
    
    private var badgeFont: Font {
        switch style {
        case .card: return UnifiedBookCard.Typography.cardMeta
        case .row: return UnifiedBookCard.Typography.rowMeta
        }
    }
    
    private var horizontalPadding: CGFloat {
        switch style {
        case .card: return 6
        case .row: return 8
        }
    }
    
    private var verticalPadding: CGFloat {
        return 2
    }
}

// MARK: - Unified Progress View Component

struct UnifiedProgressView: View {
    let progress: Double
    
    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ProgressView(value: progress)
                .progressViewStyle(
                    LinearProgressViewStyle(tint: Color.theme.primary)
                )
                .frame(width: 100)
                .scaleEffect(y: 0.6)
            
            Text("\(Int(progress * 100))%")
                .font(UnifiedBookCard.Typography.rowMeta)
                .foregroundColor(Color.theme.secondaryText)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(Int(progress * 100))% complete")
        .accessibilityAddTraits(.isStaticText)
    }
}

// MARK: - Unified Language Indicator Component

struct UnifiedLanguageIndicator: View {
    let language: String
    
    var body: some View {
        Text(language.uppercased())
            .font(UnifiedBookCard.Typography.rowMeta)
            .fontWeight(.semibold)
            .foregroundColor(Color.theme.tertiary)
            .padding(.horizontal, Theme.Spacing.xs)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                    .fill(Color.theme.tertiaryContainer.opacity(0.3))
            )
            .accessibilityLabel("Language: \(language)")
            .accessibilityAddTraits(.isStaticText)
    }
}

// MARK: - Supporting Types

enum BookDisplayStyle {
    case card    // Grid layout
    case row     // List layout
}

// MARK: - Shimmer Effect Extension

extension View {
    func shimmerEffect() -> some View {
        self.modifier(ShimmerEffectModifier())
    }
}

struct ShimmerEffectModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.theme.primary.opacity(0.2),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(.degrees(15))
                .offset(x: phase)
                .clipped()
            )
            .onAppear {
                if !UIAccessibility.isReduceMotionEnabled {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        phase = 200
                    }
                }
            }
    }
}

// MARK: - Responsive Design Helpers

extension View {
    func responsiveBookCard(for geometry: GeometryProxy) -> some View {
        let width = geometry.size.width
        
        if width < UnifiedBookCard.Dimensions.compactWidthThreshold {
            // Compact layout
            return self
                .frame(width: UnifiedBookCard.Dimensions.cardWidth * 0.9)
        } else if width < UnifiedBookCard.Dimensions.regularWidthThreshold {
            // Regular layout
            return self
                .frame(width: UnifiedBookCard.Dimensions.cardWidth)
        } else {
            // Large layout
            return self
                .frame(width: UnifiedBookCard.Dimensions.cardWidth * 1.1)
        }
    }
}

// MARK: - Preview Helpers

#Preview("Unified Components") {
    ScrollView {
        VStack(spacing: Theme.Spacing.xl) {
            // Card style preview
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Text("Card Style")
                    .titleLarge()
                
                HStack(spacing: Theme.Spacing.md) {
                    UnifiedBookCoverView(
                        imageURL: nil,
                        width: UnifiedBookCard.Dimensions.cardCoverWidth,
                        height: UnifiedBookCard.Dimensions.cardCoverHeight,
                        style: .card
                    )
                    
                    UnifiedBookInfoView(
                        title: "The Seven Husbands of Evelyn Hugo",
                        authors: ["Taylor Jenkins Reid"],
                        rating: 4,
                        status: .reading,
                        progress: 0.6,
                        language: "en",
                        layout: .card
                    )
                }
            }
            
            Divider()
            
            // Row style preview
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Text("Row Style")
                    .titleLarge()
                
                HStack(spacing: Theme.Spacing.md) {
                    UnifiedBookCoverView(
                        imageURL: nil,
                        width: UnifiedBookCard.Dimensions.rowCoverWidth,
                        height: UnifiedBookCard.Dimensions.rowCoverHeight,
                        style: .row
                    )
                    
                    UnifiedBookInfoView(
                        title: "Persepolis",
                        authors: ["Marjane Satrapi"],
                        rating: 5,
                        status: .read,
                        progress: 1.0,
                        language: "fr",
                        layout: .row
                    )
                    
                    Spacer()
                    
                    UnifiedLanguageIndicator(language: "fr")
                }
            }
        }
        .padding(Theme.Spacing.lg)
    }
    .background(Color.theme.background)
}