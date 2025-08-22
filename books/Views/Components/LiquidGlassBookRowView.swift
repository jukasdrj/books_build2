//
//  LiquidGlassBookRowView.swift
//  books
//
//  iOS 26 Liquid Glass book row component
//  Enhanced design with glass materials, depth, and fluid interactions
//

import SwiftUI

struct LiquidGlassBookRowView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.modelContext) private var modelContext
    let userBook: UserBook
    let analysisResult: AnalysisResult?
    let onStatusChange: ((ReadingStatus) -> Void)?
    let onEdit: (() -> Void)?
    let onDelete: (() -> Void)?
    
    @State private var showingDeleteAlert = false
    @State private var showingStatusPicker = false
    
    init(
        userBook: UserBook,
        analysisResult: AnalysisResult? = nil,
        onStatusChange: ((ReadingStatus) -> Void)? = nil,
        onEdit: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil
    ) {
        self.userBook = userBook
        self.analysisResult = analysisResult
        self.onStatusChange = onStatusChange
        self.onEdit = onEdit
        self.onDelete = onDelete
    }
    
    var body: some View {
        buildRowContent()
    }
    
    @ViewBuilder
    private func buildRowContent() -> some View {
        HStack(spacing: Theme.Spacing.md) {
            // Enhanced book cover with glass materials
            LiquidGlassRowBookCoverView(
                imageURL: userBook.metadata?.imageURL?.absoluteString,
                width: 50,
                height: 75,
                style: .row
            )
            
            // Book information with enhanced typography
            VStack(alignment: .leading, spacing: 6) {
                // Title with iOS 26 typography
                Text(userBook.metadata?.title ?? "Unknown Title")
                    .font(LiquidGlassTheme.typography.titleSmall)
                    .foregroundColor(theme.primaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Authors with secondary typography
                if let authors = userBook.metadata?.authors, !authors.isEmpty {
                    Text("by \(authors.joined(separator: ", "))")
                        .font(LiquidGlassTheme.typography.bodySmall)
                        .foregroundColor(theme.secondaryText)
                        .lineLimit(1)
                }
                
                // Enhanced metadata row with glass capsules
                HStack(spacing: 8) {
                    // Reading status with glass styling
                    if userBook.readingStatus != .toRead {
                        Text(userBook.readingStatus.displayName)
                            .font(LiquidGlassTheme.typography.labelSmall)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(.regularMaterial)
                                    .overlay(
                                        Capsule()
                                            .stroke(statusColor.opacity(0.3), lineWidth: 0.5)
                                    )
                            )
                            .foregroundColor(statusColor)
                    }
                    
                    // Completion percentage if available
                    if let result = analysisResult {
                        Text("\(result.completionPercentage)% complete")
                            .font(LiquidGlassTheme.typography.labelSmall)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(.thinMaterial)
                                    .overlay(
                                        Capsule()
                                            .stroke(completionColor(result.completionScore).opacity(0.3), lineWidth: 0.5)
                                    )
                            )
                            .foregroundColor(completionColor(result.completionScore))
                    }
                    
                    Spacer()
                }
                
                // Progress bar for currently reading books
                if userBook.readingStatus == .reading && userBook.readingProgress > 0 {
                    ProgressView(value: userBook.readingProgress)
                        .progressViewStyle(LiquidGlassProgressStyle())
                        .frame(height: 4)
                }
            }
            
            // Trailing info section
            VStack(alignment: .trailing, spacing: 8) {
                // Rating with enhanced star design
                if let rating = userBook.rating {
                    LiquidGlassStarRating(rating: Double(rating), size: .compact)
                }
                
                // Cultural language indicator with glass styling
                if let language = userBook.metadata?.language, language != "en" {
                    LiquidGlassLanguageIndicator(language: language)
                }
                
                Spacer()
                
                // Navigation chevron with vibrancy
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.outline)
                    .liquidGlassVibrancy(.subtle)
            }
        }
        .modifier(RowBaseModifier())
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            trailingSwipeActions
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            leadingSwipeActions
        }
        .contextMenu {
            contextMenuItems
        }
        .modifier(RowPresentationModifier(
            showingDeleteAlert: $showingDeleteAlert,
            showingStatusPicker: $showingStatusPicker,
            userBook: userBook,
            onStatusChange: onStatusChange,
            onDelete: onDelete
        ))
        .modifier(RowAccessibilityModifier(
            userBook: userBook,
            analysisResult: analysisResult,
            onEdit: onEdit,
            onToggleStatus: toggleReadingStatus,
            onShowDeleteAlert: { showingDeleteAlert = true }
        ))
    }
    
    // MARK: - Computed Properties
    
    @ViewBuilder
    private var trailingSwipeActions: some View {
        // Delete action
        Button(role: .destructive) {
            showingDeleteAlert = true
        } label: {
            Label("Delete", systemImage: "trash")
        }
        .tint(.red)
        
        // Edit action
        Button {
            onEdit?()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            Label("Edit", systemImage: "pencil")
        }
        .tint(.orange)
    }
    
    @ViewBuilder
    private var leadingSwipeActions: some View {
        // Quick status change action
        Button {
            toggleReadingStatus()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } label: {
            Label(quickStatusActionLabel, systemImage: quickStatusActionIcon)
        }
        .tint(quickStatusActionColor)
    }
    
    @ViewBuilder
    private var deleteAlert: some View {
        Button("Cancel", role: .cancel) { }
        Button("Delete", role: .destructive) {
            onDelete?()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
    
    // MARK: - Computed Properties
    
    private var statusColor: Color {
        switch userBook.readingStatus {
        case .reading: return theme.primary
        case .read: return Color.green
        case .wantToRead: return Color.orange
        case .dnf: return theme.error
        case .toRead: return theme.outline
        case .onHold: return Color.yellow
        }
    }
    
    private func completionColor(_ score: Double) -> Color {
        switch score {
        case 0.8...: return theme.primary
        case 0.6..<0.8: return Color.orange
        case 0.4..<0.6: return Color.yellow
        default: return theme.error
        }
    }
    
    // MARK: - Swipe Action Properties
    
    private var quickStatusActionLabel: String {
        switch userBook.readingStatus {
        case .toRead, .wantToRead: return "Mark as Reading"
        case .reading: return "Mark as Read"
        case .read: return "Mark as Reading"
        case .dnf, .onHold: return "Mark as Reading"
        }
    }
    
    private var quickStatusActionIcon: String {
        switch userBook.readingStatus {
        case .toRead, .wantToRead: return "play.fill"
        case .reading: return "checkmark.circle.fill"
        case .read: return "arrow.clockwise"
        case .dnf, .onHold: return "play.fill"
        }
    }
    
    private var quickStatusActionColor: Color {
        switch userBook.readingStatus {
        case .toRead, .wantToRead: return .blue
        case .reading: return .green
        case .read: return .orange
        case .dnf, .onHold: return .blue
        }
    }
    
    // MARK: - Context Menu
    
    @ViewBuilder
    private var contextMenuItems: some View {
        // Reading status options
        Section("Reading Status") {
            ForEach(ReadingStatus.allCases, id: \.self) { status in
                Button {
                    onStatusChange?(status)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    HStack {
                        Text(status.displayName)
                        if userBook.readingStatus == status {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        }
        
        Divider()
        
        // Quick actions
        Button {
            onEdit?()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            Label("Edit Book", systemImage: "pencil")
        }
        
        Button {
            showingStatusPicker = true
        } label: {
            Label("Change Status", systemImage: "arrow.up.arrow.down")
        }
        
        Divider()
        
        // Destructive action
        Button(role: .destructive) {
            showingDeleteAlert = true
        } label: {
            Label("Delete Book", systemImage: "trash")
        }
    }
    
    // MARK: - Helper Methods
    
    private func toggleReadingStatus() {
        let newStatus: ReadingStatus
        switch userBook.readingStatus {
        case .toRead, .wantToRead, .dnf, .onHold:
            newStatus = .reading
        case .reading:
            newStatus = .read
        case .read:
            newStatus = .reading
        }
        onStatusChange?(newStatus)
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
                    .liquidGlassVibrancy(.subtle)
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
                    .liquidGlassVibrancy(.medium)
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
            .liquidGlassVibrancy(.prominent)
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
                .liquidGlassVibrancy(.prominent)
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

