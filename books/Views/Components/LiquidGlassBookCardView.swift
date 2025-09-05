import SwiftUI

// MARK: - iOS 26 HIG-Compliant Book Card
// Book content card using standard materials per Apple HIG (content layer)
// Glass effects removed to comply with iOS 26 guidelines

struct LiquidGlassBookCardView: View {
    let book: UserBook
    @Environment(\.unifiedThemeStore) private var themeStore
    @Environment(\.colorScheme) private var colorScheme
    @State private var hoverIntensity: CGFloat = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Book cover section
            bookCoverSection
            
            // Book information section with content layer styling
            bookInfoSection
        }
        .layerStyle(.content, intensity: .medium, themeStore: themeStore)
        .brightness(hoverIntensity * 0.05) // Reduced brightness effect for content
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                hoverIntensity = hovering ? 1.0 : 0.0
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Double tap to view book details")
    }
    
    // MARK: - Book Cover Section
    
    @ViewBuilder
    private var bookCoverSection: some View {
        ZStack {
            // Subtle background gradient for content layer
            LinearGradient(
                colors: [
                    themeStore.textColor(for: .content, prominence: .primary).opacity(0.03),
                    themeStore.textColor(for: .content, prominence: .secondary).opacity(0.02)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Enhanced book cover (removed blur for image clarity)
            LiquidGlassBookCoverView(
                imageURL: book.metadata?.imageURL?.absoluteString,
                width: 120,
                height: 180
            )
            
            // Status overlay with liquid glass effect
            if book.readingStatus != .wantToRead && book.readingStatus != .toRead {
                VStack {
                    HStack {
                        Spacer()
                        statusIndicator(for: book.readingStatus)
                    }
                    Spacer()
                }
                .padding(8)
            }
        }
        .frame(height: 180)
        .clipShape(
            RoundedRectangle(
                cornerRadius: LiquidGlassTheme.GlassRadius.comfortable.value,
                style: .continuous
            )
        )
    }
    
    // MARK: - Book Information Section
    
    @ViewBuilder
    private var bookInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title with content layer typography
            Text(book.metadata?.title ?? "Unknown Title")
                .font(.system(size: 16, weight: .semibold, design: .default))
                .layerText(.content, prominence: .primary, themeStore: themeStore)
                .lineLimit(2)
                .minimumScaleFactor(0.9)
                .multilineTextAlignment(.leading)
            
            // Authors with content layer styling
            if let authors = book.metadata?.authors, !authors.isEmpty {
                Text(authors.joined(separator: ", "))
                    .font(.system(size: 14, weight: .regular, design: .default))
                    .layerText(.content, prominence: .secondary, themeStore: themeStore)
                    .lineLimit(1)
            }
            
            // Enhanced metadata row
            HStack(spacing: 12) {
                // Rating with vibrancy
                if let rating = book.rating, rating > 0 {
                    ratingView(rating: Double(rating))
                }
                
                Spacer()
                
                // Reading progress with liquid glass styling
                if book.readingProgress > 0 {
                    progressView(progress: book.readingProgress)
                }
            }
            
            // Cultural metadata with enhanced styling
            if let region = book.metadata?.culturalRegion {
                culturalIndicator(region: region)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(.thinMaterial.opacity(0.5))
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private func statusIndicator(for status: ReadingStatus) -> some View {
        Image(systemName: status.systemImage)
            .font(.caption)
            .foregroundColor(.white)
            .padding(6)
            .background(
                Circle()
                    .fill(.regularMaterial)
                    .overlay(
                        Circle()
                            .fill(status.color(theme: themeStore.appTheme))
                            .opacity(0.8)
                    )
            )
            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
            .liquidGlassVibrancy(.prominent)
    }
    
    @ViewBuilder
    private func ratingView(rating: Double) -> some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= Int(rating) ? "star.fill" : "star")
                    .font(.caption2)
                    .foregroundColor(.amber)
                    .liquidGlassVibrancy(.prominent)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(.regularMaterial.opacity(0.6))
        .clipShape(Capsule())
    }
    
    @ViewBuilder
    private func progressView(progress: Double) -> some View {
        HStack(spacing: 4) {
            ProgressView(value: progress / 100.0)
                .progressViewStyle(LinearProgressViewStyle())
                .frame(width: 40)
                .tint(themeStore.textColor(for: .content, prominence: .primary))
            
            Text("\(Int(progress))%")
                .font(.system(size: 11, weight: .medium, design: .default))
                .layerText(.content, prominence: .primary, themeStore: themeStore)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.thinMaterial.opacity(0.7))
        .clipShape(Capsule())
    }
    
    @ViewBuilder
    private func culturalIndicator(region: CulturalRegion) -> some View {
        HStack(spacing: 4) {
            Text(region.emoji)
                .font(.caption2)
            
            Text(region.shortName)
                .font(.system(size: 11, weight: .medium, design: .default))
                .foregroundColor(region.color(theme: themeStore.appTheme))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            region.color(theme: themeStore.appTheme).opacity(0.1)
                .overlay(.ultraThinMaterial.opacity(0.5))
        )
        .clipShape(Capsule())
    }
    
    // MARK: - Accessibility
    
    private var accessibilityLabel: String {
        var label = book.metadata?.title ?? "Unknown Title"
        
        if let authors = book.metadata?.authors, !authors.isEmpty {
            label += ", by \(authors.joined(separator: ", "))"
        }
        
        if let rating = book.rating, rating > 0 {
            label += ", rated \(rating) out of 5 stars"
        }
        
        if book.readingProgress > 0 {
            label += ", \(Int(book.readingProgress * 100))% complete"
        }
        
        label += ", status: \(book.readingStatus.displayName)"
        
        return label
    }
}

// MARK: - Enhanced Book Cover for Liquid Glass

struct LiquidGlassBookCoverView: View {
    let imageURL: String?
    let width: CGFloat
    let height: CGFloat
    
    @State private var isLoading = true
    @State private var loadError = false
    
    var body: some View {
        ZStack {
            // Background with liquid glass effect
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
            color: .black.opacity(0.1),
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
                .scaleEffect(0.8)
                .liquidGlassVibrancy(.medium)
        }
        .redacted(reason: .placeholder)
        .shimmering()
    }
    
    @ViewBuilder
    private var bookPlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.primary.opacity(0.2),
                    Color.primary.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 8) {
                Image(systemName: "book.fill")
                    .font(.title2)
                    .foregroundColor(.primary.opacity(0.6))
                
                Text("No Cover")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .liquidGlassVibrancy(.subtle)
        }
    }
}

// MARK: - Shimmer Effect for Loading States

extension View {
    func shimmering() -> some View {
        self.overlay(
            shimmerOverlay
        )
        .clipped()
    }
    
    private var shimmerOverlay: some View {
        LinearGradient(
            colors: [
                .clear,
                .white.opacity(0.3),
                .clear
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(width: 200)
        .offset(x: -100)
        .animation(
            .easeInOut(duration: 1.5).repeatForever(autoreverses: false),
            value: UUID()
        )
    }
}


// MARK: - Color Extensions

extension Color {
    static let amber = Color(red: 1.0, green: 0.75, blue: 0.0)
}

// MARK: - Preview

#Preview {
    ScrollView {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            ForEach(0..<4) { _ in
                LiquidGlassBookCardView(book: UserBook.sampleBook())
            }
        }
        .padding()
    }
    .preferredColorScheme(.dark)
    .environment(\.appTheme, AppColorTheme(variant: .purpleBoho))
}

// MARK: - Sample Data Extension

extension UserBook {
    static func sampleBook() -> UserBook {
        let book = UserBook()
        book.metadata = BookMetadata(
            googleBooksID: "sample_book_id",
            title: "The Design of Everyday Things",
            authors: ["Don Norman"],
            culturalRegion: .northAmerica
        )
        book.rating = 4
        book.readingStatus = .reading
        book.readingProgress = 0.65
        return book
    }
}