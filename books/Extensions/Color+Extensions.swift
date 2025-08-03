import SwiftUI

// MARK: - Material Design 3 Color System with Enhanced Purple Boho Theme 💜✨
// Comprehensive color system following Material Design 3 guidelines
// Enhanced with vibrant purple boho aesthetics and modern design

extension Color {
    static let theme = AppColorTheme()
}

// Helper to create adaptive colors for light/dark mode
private func adaptiveColor(light: UIColor, dark: UIColor) -> Color {
    return Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark ? dark : light
    })
}

struct AppColorTheme {
    
    // MARK: - Enhanced Purple Boho Color Palette 💜✨
    
    // Primary Colors - Beautiful purple boho theme
    let primary = adaptiveColor(
        light: UIColor(red: 0.45, green: 0.25, blue: 0.75, alpha: 1.0), // Rich violet 
        dark: UIColor(red: 0.75, green: 0.60, blue: 0.95, alpha: 1.0)   // Soft lavender
    )
    let onPrimary = adaptiveColor(light: .white, dark: UIColor(red: 0.25, green: 0.15, blue: 0.45, alpha: 1.0))
    let primaryContainer = adaptiveColor(
        light: UIColor(red: 0.92, green: 0.88, blue: 0.98, alpha: 1.0), // Soft lavender mist
        dark: UIColor(red: 0.35, green: 0.20, blue: 0.60, alpha: 1.0)   // Deep purple
    )
    let onPrimaryContainer = adaptiveColor(
        light: UIColor(red: 0.25, green: 0.15, blue: 0.45, alpha: 1.0),
        dark: UIColor(red: 0.92, green: 0.88, blue: 0.98, alpha: 1.0)
    )
    
    // Secondary Colors - Warm complement to purple
    let secondary = adaptiveColor(
        light: UIColor(red: 0.65, green: 0.45, blue: 0.55, alpha: 1.0), // Dusty rose
        dark: UIColor(red: 0.85, green: 0.70, blue: 0.80, alpha: 1.0)   // Soft rose
    )
    let onSecondary = adaptiveColor(light: .white, dark: UIColor(red: 0.35, green: 0.20, blue: 0.30, alpha: 1.0))
    let secondaryContainer = adaptiveColor(
        light: UIColor(red: 0.95, green: 0.90, blue: 0.93, alpha: 1.0), // Pale rose
        dark: UIColor(red: 0.45, green: 0.30, blue: 0.40, alpha: 1.0)   // Deep rose
    )
    let onSecondaryContainer = adaptiveColor(
        light: UIColor(red: 0.35, green: 0.20, blue: 0.30, alpha: 1.0),
        dark: UIColor(red: 0.95, green: 0.90, blue: 0.93, alpha: 1.0)
    )
    
    // Tertiary Colors - Earthy boho accent
    let tertiary = adaptiveColor(
        light: UIColor(red: 0.75, green: 0.55, blue: 0.35, alpha: 1.0), // Warm terracotta
        dark: UIColor(red: 0.95, green: 0.80, blue: 0.65, alpha: 1.0)   // Soft peach
    )
    let onTertiary = adaptiveColor(light: .white, dark: UIColor(red: 0.45, green: 0.25, blue: 0.15, alpha: 1.0))
    let tertiaryContainer = adaptiveColor(
        light: UIColor(red: 0.98, green: 0.92, blue: 0.88, alpha: 1.0), // Cream
        dark: UIColor(red: 0.55, green: 0.35, blue: 0.25, alpha: 1.0)   // Deep earth
    )
    let onTertiaryContainer = adaptiveColor(
        light: UIColor(red: 0.45, green: 0.25, blue: 0.15, alpha: 1.0),
        dark: UIColor(red: 0.98, green: 0.92, blue: 0.88, alpha: 1.0)
    )
    
    // Error Colors - Harmonious with purple theme
    let error = adaptiveColor(
        light: UIColor(red: 0.75, green: 0.25, blue: 0.35, alpha: 1.0), // Deep rose red
        dark: UIColor(red: 0.95, green: 0.70, blue: 0.75, alpha: 1.0)   // Soft coral
    )
    let onError = adaptiveColor(light: .white, dark: UIColor(red: 0.45, green: 0.10, blue: 0.15, alpha: 1.0))
    let errorContainer = adaptiveColor(
        light: UIColor(red: 0.98, green: 0.88, blue: 0.90, alpha: 1.0),
        dark: UIColor(red: 0.55, green: 0.15, blue: 0.20, alpha: 1.0)
    )
    let onErrorContainer = adaptiveColor(
        light: UIColor(red: 0.45, green: 0.10, blue: 0.15, alpha: 1.0),
        dark: UIColor(red: 0.98, green: 0.88, blue: 0.90, alpha: 1.0)
    )
    
    // Success Colors - Natural boho green
    let success = adaptiveColor(
        light: UIColor(red: 0.25, green: 0.65, blue: 0.45, alpha: 1.0), // Forest sage
        dark: UIColor(red: 0.60, green: 0.85, blue: 0.70, alpha: 1.0)   // Soft mint
    )
    let onSuccess = adaptiveColor(light: .white, dark: UIColor(red: 0.10, green: 0.35, blue: 0.20, alpha: 1.0))
    let successContainer = adaptiveColor(
        light: UIColor(red: 0.88, green: 0.95, blue: 0.90, alpha: 1.0), // Pale mint
        dark: UIColor(red: 0.15, green: 0.45, blue: 0.30, alpha: 1.0)   // Deep forest
    )
    let onSuccessContainer = adaptiveColor(
        light: UIColor(red: 0.10, green: 0.35, blue: 0.20, alpha: 1.0),
        dark: UIColor(red: 0.88, green: 0.95, blue: 0.90, alpha: 1.0)
    )
    
    // Warning Colors - Warm amber boho
    let warning = adaptiveColor(
        light: UIColor(red: 0.85, green: 0.65, blue: 0.25, alpha: 1.0), // Golden amber
        dark: UIColor(red: 0.95, green: 0.80, blue: 0.55, alpha: 1.0)   // Soft gold
    )
    let onWarning = adaptiveColor(light: .white, dark: UIColor(red: 0.45, green: 0.35, blue: 0.10, alpha: 1.0))
    let warningContainer = adaptiveColor(
        light: UIColor(red: 0.98, green: 0.95, blue: 0.88, alpha: 1.0), // Cream yellow
        dark: UIColor(red: 0.55, green: 0.45, blue: 0.15, alpha: 1.0)   // Deep amber
    )
    let onWarningContainer = adaptiveColor(
        light: UIColor(red: 0.45, green: 0.35, blue: 0.10, alpha: 1.0),
        dark: UIColor(red: 0.98, green: 0.95, blue: 0.88, alpha: 1.0)
    )
    
    // MARK: - Adaptive Colors for Dark Mode Support
    
    // Surface Colors - Enhanced for boho aesthetic
    var surface: Color { 
        adaptiveColor(
            light: UIColor(red: 0.98, green: 0.97, blue: 0.99, alpha: 1.0), // Soft white with purple hint
            dark: UIColor(red: 0.12, green: 0.10, blue: 0.15, alpha: 1.0)   // Deep purple black
        )
    }
    var onSurface: Color { Color(.label) }
    var surfaceVariant: Color { 
        adaptiveColor(
            light: UIColor(red: 0.95, green: 0.93, blue: 0.97, alpha: 1.0), // Lavender mist
            dark: UIColor(red: 0.18, green: 0.16, blue: 0.22, alpha: 1.0)   // Purple grey
        )
    }
    var onSurfaceVariant: Color { Color(.secondaryLabel) }
    
    // Inverse Colors
    var inverseSurface: Color { Color(.label) }
    var inverseOnSurface: Color { Color(.systemBackground) }
    let inversePrimary = adaptiveColor(
        light: UIColor(red: 0.75, green: 0.60, blue: 0.95, alpha: 1.0),
        dark: UIColor(red: 0.45, green: 0.25, blue: 0.75, alpha: 1.0)
    )
    
    // Outline Colors
    var outline: Color { 
        adaptiveColor(
            light: UIColor(red: 0.85, green: 0.80, blue: 0.90, alpha: 1.0), // Soft purple grey
            dark: UIColor(red: 0.40, green: 0.35, blue: 0.45, alpha: 1.0)   // Medium purple grey
        )
    }
    var outlineVariant: Color { Color(.opaqueSeparator) }
    
    // Background Colors
    var background: Color { surface }
    var onBackground: Color { Color(.label) }
    
    // MARK: - Enhanced Reading Status Colors 💜
    var statusToRead: Color { 
        adaptiveColor(
            light: UIColor(red: 0.60, green: 0.55, blue: 0.70, alpha: 1.0), // Muted purple
            dark: UIColor(red: 0.75, green: 0.70, blue: 0.85, alpha: 1.0)   // Soft lavender
        )
    }
    var statusReading: Color { 
        adaptiveColor(
            light: UIColor(red: 0.35, green: 0.55, blue: 0.85, alpha: 1.0), // Vibrant blue
            dark: UIColor(red: 0.65, green: 0.80, blue: 1.0, alpha: 1.0)    // Bright sky blue
        )
    }
    var statusRead: Color { success }
    var statusOnHold: Color { warning }
    var statusDNF: Color { error }
    
    // MARK: - Enhanced Cultural Theme Colors with Boho Warmth 🌍✨
    let cultureAfrica = adaptiveColor(
        light: UIColor(red: 0.90, green: 0.45, blue: 0.25, alpha: 1.0), // Warm terracotta
        dark: UIColor(red: 1.0, green: 0.70, blue: 0.55, alpha: 1.0)    // Soft coral
    )
    let cultureAsia = adaptiveColor(
        light: UIColor(red: 0.85, green: 0.25, blue: 0.45, alpha: 1.0), // Deep rose
        dark: UIColor(red: 1.0, green: 0.65, blue: 0.75, alpha: 1.0)    // Soft cherry
    )
    let cultureEurope = adaptiveColor(
        light: UIColor(red: 0.35, green: 0.55, blue: 0.85, alpha: 1.0), // Royal blue
        dark: UIColor(red: 0.70, green: 0.80, blue: 1.0, alpha: 1.0)    // Sky blue
    )
    let cultureAmericas = adaptiveColor(
        light: UIColor(red: 0.25, green: 0.70, blue: 0.45, alpha: 1.0), // Forest green
        dark: UIColor(red: 0.60, green: 0.90, blue: 0.70, alpha: 1.0)   // Mint green
    )
    let cultureOceania = adaptiveColor(
        light: UIColor(red: 0.25, green: 0.75, blue: 0.85, alpha: 1.0), // Ocean turquoise
        dark: UIColor(red: 0.60, green: 0.90, blue: 0.95, alpha: 1.0)   // Aqua blue
    )
    let cultureMiddleEast = adaptiveColor(
        light: UIColor(red: 0.65, green: 0.35, blue: 0.85, alpha: 1.0), // Rich amethyst
        dark: UIColor(red: 0.85, green: 0.70, blue: 0.95, alpha: 1.0)   // Soft lavender
    )
    let cultureIndigenous = adaptiveColor(
        light: UIColor(red: 0.85, green: 0.70, blue: 0.25, alpha: 1.0), // Warm gold
        dark: UIColor(red: 0.95, green: 0.85, blue: 0.60, alpha: 1.0)   // Soft amber
    )
    
    // MARK: - Enhanced Genre Colors with Boho Vibes 🎨
    let genreFiction = adaptiveColor(
        light: UIColor(red: 0.65, green: 0.35, blue: 0.85, alpha: 1.0), // Vibrant purple
        dark: UIColor(red: 0.85, green: 0.70, blue: 0.95, alpha: 1.0)   // Soft lavender
    )
    let genreNonfiction = adaptiveColor(
        light: UIColor(red: 0.25, green: 0.65, blue: 0.45, alpha: 1.0), // Sage green
        dark: UIColor(red: 0.60, green: 0.85, blue: 0.70, alpha: 1.0)   // Mint green
    )
    let genreMystery = adaptiveColor(
        light: UIColor(red: 0.35, green: 0.30, blue: 0.45, alpha: 1.0), // Deep plum
        dark: UIColor(red: 0.85, green: 0.80, blue: 0.90, alpha: 1.0)   // Soft grey lavender
    )
    let genreRomance = adaptiveColor(
        light: UIColor(red: 0.85, green: 0.35, blue: 0.55, alpha: 1.0), // Rose pink
        dark: UIColor(red: 1.0, green: 0.70, blue: 0.80, alpha: 1.0)    // Soft pink
    )
    let genreSciFi = adaptiveColor(
        light: UIColor(red: 0.25, green: 0.55, blue: 0.85, alpha: 1.0), // Electric blue
        dark: UIColor(red: 0.65, green: 0.80, blue: 1.0, alpha: 1.0)    // Bright blue
    )
    let genreFantasy = adaptiveColor(
        light: UIColor(red: 0.55, green: 0.25, blue: 0.85, alpha: 1.0), // Mystical purple
        dark: UIColor(red: 0.80, green: 0.65, blue: 0.95, alpha: 1.0)   // Dreamy lavender
    )
    let genreBiography = adaptiveColor(
        light: UIColor(red: 0.85, green: 0.65, blue: 0.25, alpha: 1.0), // Golden amber
        dark: UIColor(red: 0.95, green: 0.80, blue: 0.55, alpha: 1.0)   // Soft gold
    )
    let genreHistory = adaptiveColor(
        light: UIColor(red: 0.75, green: 0.55, blue: 0.35, alpha: 1.0), // Warm brown
        dark: UIColor(red: 0.90, green: 0.75, blue: 0.60, alpha: 1.0)   // Soft tan
    )
    
    // MARK: - Component-Specific Colors with Enhanced Boho Style 💫
    
    // Card colors with beautiful boho elevation
    var cardBackground: Color { 
        adaptiveColor(
            light: UIColor(red: 0.99, green: 0.98, blue: 1.0, alpha: 1.0), // Pure white with purple hint
            dark: UIColor(red: 0.15, green: 0.13, blue: 0.18, alpha: 1.0)   // Deep purple card
        )
    }
    var cardBorder: Color { outline.opacity(0.3) }
    
    // Action colors
    var primaryAction: Color { primary }
    var secondaryAction: Color { secondary }
    var destructiveAction: Color { error }
    
    // Text colors with enhanced hierarchy
    var primaryText: Color { 
        adaptiveColor(
            light: UIColor(red: 0.20, green: 0.15, blue: 0.25, alpha: 1.0), // Rich dark purple
            dark: UIColor(red: 0.95, green: 0.93, blue: 0.97, alpha: 1.0)   // Soft white
        )
    }
    var secondaryText: Color { 
        adaptiveColor(
            light: UIColor(red: 0.50, green: 0.45, blue: 0.55, alpha: 1.0), // Muted purple
            dark: UIColor(red: 0.80, green: 0.75, blue: 0.85, alpha: 1.0)   // Light lavender
        )
    }
    var disabledText: Color { Color(.tertiaryLabel) }
    
    // Interactive states with boho warmth
    var pressed: Color { primary.opacity(0.12) }
    var hovered: Color { primary.opacity(0.08) }
    var focused: Color { primary.opacity(0.12) }
    var selected: Color { primary.opacity(0.15) }
    var disabled: Color { Color(.systemFill) }
    
    // MARK: - Additional Boho Helper Colors ✨
    var accentHighlight: Color { tertiary }
    
    // Gradient colors for boho effects
    var gradientStart: Color { 
        adaptiveColor(
            light: UIColor(red: 0.85, green: 0.75, blue: 0.95, alpha: 1.0), // Soft lavender
            dark: UIColor(red: 0.25, green: 0.20, blue: 0.35, alpha: 1.0)   // Deep purple
        )
    }
    var gradientEnd: Color { 
        adaptiveColor(
            light: UIColor(red: 0.95, green: 0.85, blue: 0.90, alpha: 1.0), // Soft rose
            dark: UIColor(red: 0.35, green: 0.25, blue: 0.40, alpha: 1.0)   // Deep rose
        )
    }
}

// MARK: - Reading Status Color Extension with Dark Mode Support
extension ReadingStatus {
    var color: Color {
        switch self {
        case .toRead:
            return Color.theme.statusToRead
        case .reading:
            return Color.theme.statusReading
        case .read:
            return Color.theme.statusRead
        case .onHold:
            return Color.theme.statusOnHold
        case .dnf:
            return Color.theme.statusDNF
        }
    }
    
    var containerColor: Color {
        switch self {
        case .toRead:
            return Color.theme.onSurface.opacity(0.08)
        case .reading:
            return Color.theme.statusReading.opacity(0.15)
        case .read:
            return Color.theme.successContainer
        case .onHold:
            return Color.theme.warningContainer
        case .dnf:
            return Color.theme.errorContainer
        }
    }
    
    var textColor: Color {
        switch self {
        case .toRead:
            return Color.theme.secondaryText
        case .reading:
            return Color.theme.statusReading
        case .read:
            return Color.theme.onSuccessContainer
        case .onHold:
            return Color.theme.onWarningContainer
        case .dnf:
            return Color.theme.onErrorContainer
        }
    }
}

// MARK: - Cultural Region Colors
extension String {
    var culturalColor: Color {
        let lowercased = self.lowercased()
        
        // African countries and regions
        if ["nigeria", "ghana", "kenya", "south africa", "morocco", "egypt", "ethiopia", "senegal", "mali", "burkina faso", "ivory coast", "cameroon", "tanzania", "uganda", "zimbabwe", "botswana", "zambia", "malawi", "algeria", "tunisia", "libya", "sudan", "chad", "niger", "mauritania", "gambia", "guinea", "sierra leone", "liberia", "togo", "benin", "rwanda", "burundi", "djibouti", "somalia", "eritrea", "central african republic", "democratic republic of congo", "republic of congo", "gabon", "equatorial guinea", "sao tome and principe", "cape verde", "comoros", "mauritius", "seychelles", "madagascar", "lesotho", "swaziland", "namibia", "angola", "mozambique"].contains(lowercased) {
            return Color.theme.cultureAfrica
        }
        
        // Asian countries and regions
        if ["china", "japan", "india", "korea", "south korea", "north korea", "thailand", "vietnam", "singapore", "malaysia", "indonesia", "philippines", "taiwan", "hong kong", "macau", "myanmar", "cambodia", "laos", "brunei", "bangladesh", "pakistan", "sri lanka", "nepal", "bhutan", "maldives", "afghanistan", "uzbekistan", "kazakhstan", "kyrgyzstan", "tajikistan", "turkmenistan", "mongolia", "tibet"].contains(lowercased) {
            return Color.theme.cultureAsia
        }
        
        // European countries
        if ["united kingdom", "france", "germany", "italy", "spain", "portugal", "netherlands", "belgium", "switzerland", "austria", "sweden", "norway", "denmark", "finland", "iceland", "ireland", "poland", "czech republic", "slovakia", "hungary", "romania", "bulgaria", "greece", "croatia", "slovenia", "bosnia and herzegovina", "serbia", "montenegro", "north macedonia", "albania", "kosovo", "moldova", "ukraine", "belarus", "russia", "lithuania", "latvia", "estonia", "luxembourg", "monaco", "andorra", "san marino", "vatican city", "malta", "cyprus"].contains(lowercased) {
            return Color.theme.cultureEurope
        }
        
        // Americas
        if ["united states", "canada", "mexico", "brazil", "argentina", "chile", "colombia", "peru", "venezuela", "ecuador", "bolivia", "paraguay", "uruguay", "guyana", "suriname", "french guiana", "guatemala", "belize", "honduras", "el salvador", "nicaragua", "costa rica", "panama", "cuba", "jamaica", "haiti", "dominican republic", "puerto rico", "barbados", "trinidad and tobago", "antigua and barbuda", "saint lucia", "saint vincent and the grenadines", "grenada", "dominica", "saint kitts and nevis", "bahamas"].contains(lowercased) {
            return Color.theme.cultureAmericas
        }
        
        // Oceania
        if ["australia", "new zealand", "fiji", "papua new guinea", "solomon islands", "vanuatu", "samoa", "tonga", "micronesia", "palau", "marshall islands", "nauru", "kiribati", "tuvalu"].contains(lowercased) {
            return Color.theme.cultureOceania
        }
        
        // Middle East
        if ["saudi arabia", "iran", "turkey", "iraq", "israel", "palestine", "jordan", "lebanon", "syria", "yemen", "oman", "united arab emirates", "qatar", "kuwait", "bahrain"].contains(lowercased) {
            return Color.theme.cultureMiddleEast
        }
        
        // Default to primary color
        return Color.theme.primary
    }
}

// MARK: - Genre Colors Extension
extension String {
    var genreColor: Color {
        let lowercased = self.lowercased()
        
        switch lowercased {
        case "fiction", "literary fiction", "contemporary fiction":
            return Color.theme.genreFiction
        case "non-fiction", "nonfiction", "biography", "autobiography", "memoir":
            return Color.theme.genreNonfiction
        case "mystery", "thriller", "crime", "detective":
            return Color.theme.genreMystery
        case "romance", "love story":
            return Color.theme.genreRomance
        case "science fiction", "sci-fi", "scifi":
            return Color.theme.genreSciFi
        case "fantasy", "urban fantasy", "epic fantasy":
            return Color.theme.genreFantasy
        case "history", "historical", "historical fiction":
            return Color.theme.genreHistory
        default:
            return Color.theme.secondary
        }
    }
}