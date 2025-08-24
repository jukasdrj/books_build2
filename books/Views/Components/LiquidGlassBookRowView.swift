//
//  LiquidGlassBookRowView.swift
//  books
//
//  iOS 26 Liquid Glass book row component - Unified with card design
//  Clean, focused display component matching LiquidGlassBookCardView aesthetic
//

import SwiftUI

// MARK: - Simplified Liquid Glass Book Row View

struct LiquidGlassBookRowView: View {
    let book: UserBook
    @Environment(\.appTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    @State private var hoverIntensity: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 16) {
            // Enhanced book cover with glass materials - consistent with card
            LiquidGlassRowBookCover(
                imageURL: book.metadata?.imageURL?.absoluteString,
                width: 60,
                height: 90
            )
            
            // Book information section - matches card hierarchy
            VStack(alignment: .leading, spacing: 8) {
                // Title with iOS 26 typography - consistent with card
                Text(book.metadata?.title ?? "Unknown Title")
                    .font(LiquidGlassTheme.typography.titleMedium)
                    .foregroundColor(theme.primaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Authors - consistent with card
                if let authors = book.metadata?.authors, !authors.isEmpty {
                    Text("by \(authors.joined(separator: ", "))")
                        .font(LiquidGlassTheme.typography.bodySmall)
                        .foregroundColor(theme.secondaryText)
                        .lineLimit(1)
                }
                
                // Metadata row with unified glass styling
                HStack(spacing: 12) {
                    // Rating - matches card design
                    if let rating = book.rating, rating > 0 {
                        HStack(spacing: 3) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= Int(rating) ? "star.fill" : "star")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(star <= Int(rating) ? .amber : .secondary.opacity(0.4))
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.primary.opacity(0.05))
                        .clipShape(Capsule())
                    }
                    
                    // Reading progress - matches card
                    if book.readingProgress > 0 && book.readingStatus == .reading {
                        HStack(spacing: 6) {
                            ProgressView(value: book.readingProgress / 100.0)
                                .progressViewStyle(LinearProgressViewStyle())
                                .frame(width: 50)
                                .tint(theme.primary)
                            
                            Text("\(Int(book.readingProgress))%")
                                .font(LiquidGlassTheme.typography.labelSmall)
                                .foregroundColor(theme.primary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(theme.primary.opacity(0.1))
                        .clipShape(Capsule())
                    }
                    
                    Spacer()
                }
            }
            
            // Trailing section - status and cultural info
            VStack(alignment: .trailing, spacing: 8) {
                // Status indicator - consistent with card
                if book.readingStatus != .toRead && book.readingStatus != .wantToRead {
                    HStack(spacing: 4) {
                        Image(systemName: book.readingStatus.systemImage)
                            .font(.caption2)
                            .foregroundColor(statusColor)
                        
                        Text(book.readingStatus.displayName)
                            .font(LiquidGlassTheme.typography.labelSmall)
                            .foregroundColor(statusColor)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.15))
                    .clipShape(Capsule())
                }
                
                // Cultural language indicator - matches card design
                if let language = book.metadata?.language, language != "en" {
                    Text(language.uppercased())
                        .font(LiquidGlassTheme.typography.labelSmall)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(theme.primary.opacity(0.15))
                        .foregroundColor(theme.primary)
                        .clipShape(Capsule())
                }
                
                // Cultural region indicator if available
                if let region = book.metadata?.culturalRegion {
                    HStack(spacing: 4) {
                        Text(region.emoji)
                            .font(.caption2)
                        
                        Text(region.shortName)
                            .font(LiquidGlassTheme.typography.labelSmall)
                            .foregroundColor(region.color(theme: theme))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(region.color(theme: theme).opacity(0.15))
                    .clipShape(Capsule())
                }
                
                Spacer()
                
                // Navigation chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.outline.opacity(0.6))
            }
        }
        .frame(minHeight: 100)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.primary.opacity(colorScheme == .dark ? 0.05 : 0.03))
                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
        )
        .brightness(hoverIntensity * 0.05)
        .onHover { hovering in
            withAnimation(LiquidGlassTheme.FluidAnimation.smooth.springAnimation) {
                hoverIntensity = hovering ? 1.0 : 0.0
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Double tap to view book details")
    }
    
    // MARK: - Helper Properties
    
    private var statusColor: Color {
        switch book.readingStatus {
        case .reading: return theme.primary
        case .read: return .green
        case .wantToRead: return .orange
        case .dnf: return theme.error
        case .toRead: return theme.outline
        case .onHold: return .yellow
        }
    }
    
    private var accessibilityLabel: String {
        var label = book.metadata?.title ?? "Unknown Title"
        
        if let authors = book.metadata?.authors, !authors.isEmpty {
            label += ", by \(authors.joined(separator: ", "))"
        }
        
        if let rating = book.rating, rating > 0 {
            label += ", rated \(rating) out of 5 stars"
        }
        
        if book.readingProgress > 0 {
            label += ", \(Int(book.readingProgress))% complete"
        }
        
        label += ", status: \(book.readingStatus.displayName)"
        
        return label
    }
}

// MARK: - Enhanced Book Cover for Row Layout

struct LiquidGlassRowBookCover: View {
    let imageURL: String?
    let width: CGFloat
    let height: CGFloat
    
    @State private var isLoading = true
    @State private var loadError = false
    
    var body: some View {
        ZStack {
            // Background with liquid glass effect - consistent with card
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.regularMaterial)
                .overlay(
                    LinearGradient(
                        colors: [
                            Color.primary.opacity(0.1),
                            Color.primary.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Book cover image or placeholder
            Group {
                if let urlString = imageURL, let url = URL(string: urlString), !loadError {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure(_):
                            bookPlaceholder
                        case .empty:
                            loadingPlaceholder
                        @unknown default:
                            loadingPlaceholder
                        }
                    }
                } else {
                    bookPlaceholder
                }
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(
            color: .black.opacity(0.08),
            radius: 4,
            x: 0,
            y: 2
        )
    }
    
    @ViewBuilder
    private var loadingPlaceholder: some View {
        ZStack {
            Color.secondary.opacity(0.1)
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .primary))
                .scaleEffect(0.7)
        }
        .redacted(reason: .placeholder)
    }
    
    @ViewBuilder
    private var bookPlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.primary.opacity(0.15),
                    Color.primary.opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            Image(systemName: "book.fill")
                .font(.title3)
                .foregroundColor(.primary.opacity(0.5))
        }
    }
}

// MARK: - Status Picker Sheet

struct StatusPickerSheet: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    let userBook: UserBook
    let onStatusChange: (ReadingStatus) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Book info header
                HStack(spacing: 12) {
                    LiquidGlassBookCoverView(
                        imageURL: userBook.metadata?.imageURL?.absoluteString,
                        width: 60,
                        height: 90
                    )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(userBook.metadata?.title ?? "Unknown Title")
                            .font(LiquidGlassTheme.typography.titleMedium)
                            .foregroundColor(theme.primaryText)
                            .lineLimit(2)
                        
                        if let authors = userBook.metadata?.authors, !authors.isEmpty {
                            Text("by \(authors.joined(separator: ", "))")
                                .font(LiquidGlassTheme.typography.bodySmall)
                                .foregroundColor(theme.secondaryText)
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                // Status options
                VStack(spacing: 8) {
                    ForEach(ReadingStatus.allCases, id: \.self) { status in
                        Button {
                            onStatusChange(status)
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: statusIcon(for: status))
                                    .foregroundColor(statusColor(for: status))
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(status.displayName)
                                        .font(LiquidGlassTheme.typography.titleSmall)
                                        .foregroundColor(theme.primaryText)
                                    
                                    Text(statusDescription(for: status))
                                        .font(LiquidGlassTheme.typography.bodySmall)
                                        .foregroundColor(theme.secondaryText)
                                }
                                
                                Spacer()
                                
                                if userBook.readingStatus == status {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(theme.primary)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(userBook.readingStatus == status ? theme.primary.opacity(0.1) : .clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(userBook.readingStatus == status ? theme.primary.opacity(0.3) : theme.outline.opacity(0.2), lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Reading Status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func statusIcon(for status: ReadingStatus) -> String {
        switch status {
        case .toRead: return "book.closed"
        case .wantToRead: return "heart"
        case .reading: return "book.open"
        case .read: return "checkmark.circle"
        case .dnf: return "xmark.circle"
        case .onHold: return "pause.circle"
        }
    }
    
    private func statusColor(for status: ReadingStatus) -> Color {
        switch status {
        case .toRead: return .gray
        case .wantToRead: return .pink
        case .reading: return .blue
        case .read: return .green
        case .dnf: return .orange
        case .onHold: return .yellow
        }
    }
    
    private func statusDescription(for status: ReadingStatus) -> String {
        switch status {
        case .toRead: return "Haven't started reading yet"
        case .wantToRead: return "Added to your reading wishlist"
        case .reading: return "Currently reading this book"
        case .read: return "Finished reading"
        case .dnf: return "Stopped reading before completion"
        case .onHold: return "Paused reading temporarily"
        }
    }
}

// MARK: - Supporting Components for Row View

// Custom book cover for row view with enhanced styling options
struct LiquidGlassRowBookCoverView: View {
    let imageURL: String?
    let width: CGFloat
    let height: CGFloat
    let style: CoverStyle
    
    enum CoverStyle {
        case row, card, detail
        
        var cornerRadius: CGFloat {
            switch self {
            case .row: return 8
            case .card: return 12
            case .detail: return 16
            }
        }
        
        var shadowRadius: CGFloat {
            switch self {
            case .row: return 4
            case .card: return 8
            case .detail: return 12
            }
        }
    }
    
    var body: some View {
        AsyncImage(url: URL(string: imageURL ?? "")) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            ZStack {
                RoundedRectangle(cornerRadius: style.cornerRadius)
                    .fill(.regularMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: style.cornerRadius)
                            .stroke(.separator.opacity(0.3), lineWidth: 0.5)
                    )
                
                Image(systemName: "book.closed")
                    .foregroundColor(.secondary)
                    .font(.title3)
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: style.cornerRadius))
        .shadow(
            color: .black.opacity(0.1),
            radius: style.shadowRadius,
            x: 0,
            y: style.shadowRadius / 2
        )
    }
}

struct LiquidGlassStarRating: View {
    let rating: Double
    let size: StarSize
    
    enum StarSize {
        case compact, standard, large
        
        var fontSize: Font {
            switch self {
            case .compact: return .caption2
            case .standard: return .caption
            case .large: return .subheadline
            }
        }
        
        var spacing: CGFloat {
            switch self {
            case .compact: return 2
            case .standard: return 3
            case .large: return 4
            }
        }
    }
    
    var body: some View {
        HStack(spacing: size.spacing) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= Int(rating) ? "star.fill" : "star")
                    .font(size.fontSize)
                    .fontWeight(.medium)
                    .foregroundColor(star <= Int(rating) ? .amber : .secondary)
            }
        }
    }
}

struct LiquidGlassLanguageIndicator: View {
    @Environment(\.appTheme) private var theme
    let language: String
    
    var body: some View {
        Text(language.uppercased())
            .font(LiquidGlassTheme.typography.labelSmall)
            .fontWeight(.bold)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .stroke(theme.primary.opacity(0.4), lineWidth: 0.5)
                    )
            )
            .foregroundColor(theme.primary)
    }
}

struct LiquidGlassProgressStyle: ProgressViewStyle {
    @Environment(\.appTheme) private var theme
    
    func makeBody(configuration: Configuration) -> some View {
        ZStack(alignment: .leading) {
            // Background track
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(.separator.opacity(0.3), lineWidth: 0.5)
                )
            
            // Progress fill
            Capsule()
                .fill(theme.primary.gradient)
                .scaleEffect(x: configuration.fractionCompleted ?? 0, y: 1, anchor: .leading)
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: configuration.fractionCompleted)
    }
}

// MARK: - Custom View Modifiers for LiquidGlassBookRowView

struct RowBaseModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(minHeight: 90)
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .liquidGlassCard(
                material: .regular,
                depth: .floating,
                radius: .comfortable,
                vibrancy: .medium
            )
            .materialInteractive(
                pressedScale: 0.98,
                pressedOpacity: 0.9
            )
            .contentShape(Rectangle())
    }
}

struct RowPresentationModifier: ViewModifier {
    @Binding var showingDeleteAlert: Bool
    @Binding var showingStatusPicker: Bool
    let userBook: UserBook
    let onStatusChange: ((ReadingStatus) -> Void)?
    let onDelete: (() -> Void)?
    
    func body(content: Content) -> some View {
        content
            .alert("Delete Book", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    onDelete?()
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            } message: {
                Text("Are you sure you want to delete \"\(userBook.metadata?.title ?? "this book")\"? This action cannot be undone.")
            }
            .sheet(isPresented: $showingStatusPicker) {
                StatusPickerSheet(
                    userBook: userBook,
                    onStatusChange: { newStatus in
                        onStatusChange?(newStatus)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
    }
}

struct RowAccessibilityModifier: ViewModifier {
    let userBook: UserBook
    let analysisResult: AnalysisResult?
    let onEdit: (() -> Void)?
    let onToggleStatus: () -> Void
    let onShowDeleteAlert: () -> Void
    
    func body(content: Content) -> some View {
        content
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityDescription)
            .accessibilityHint("Double tap to view book details. Swipe left for quick actions, swipe right to mark as read.")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction(named: "Mark as Read") {
                onToggleStatus()
            }
            .accessibilityAction(named: "Edit") {
                onEdit?()
            }
            .accessibilityAction(named: "Delete") {
                onShowDeleteAlert()
            }
    }
    
    private var accessibilityDescription: String {
        var description = userBook.metadata?.title ?? "Unknown Title"
        
        if let authors = userBook.metadata?.authors, !authors.isEmpty {
            description += " by \(authors.joined(separator: ", "))"
        }
        
        if let rating = userBook.rating {
            description += ". Rated \(rating) out of 5 stars"
        }
        
        if userBook.readingStatus != .toRead {
            description += ". Status: \(userBook.readingStatus.displayName)"
            
            if userBook.readingStatus == .reading && userBook.readingProgress > 0 {
                description += ". \(Int(userBook.readingProgress * 100))% complete"
            }
        }
        
        if let language = userBook.metadata?.language, language != "en" {
            description += ". Language: \(language)"
        }
        
        if let result = analysisResult {
            description += ". \(result.completionPercentage)% metadata complete, \(result.missingFields.count) fields missing"
        }
        
        return description
    }
}

// MARK: - Row View Extensions
// Note: Color extensions are centralized in LiquidGlassBookCardView.swift

