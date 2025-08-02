import SwiftUI

// MARK: - Material Design 3 Color System
// Comprehensive color system following Material Design 3 guidelines
// with support for both light and dark modes

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
    
    // MARK: - Material Design 3 Core Colors
    
    // Primary Colors - Main brand colors with proper dark mode support
    let primary = adaptiveColor(light: UIColor(red: 0.38, green: 0.35, blue: 0.80, alpha: 1.0), dark: UIColor(red: 0.70, green: 0.68, blue: 1.0, alpha: 1.0))
    let onPrimary = adaptiveColor(light: .white, dark: UIColor(red: 0.23, green: 0.20, blue: 0.49, alpha: 1.0))
    let primaryContainer = adaptiveColor(light: UIColor(red: 0.90, green: 0.88, blue: 1.0, alpha: 1.0), dark: UIColor(red: 0.31, green: 0.29, blue: 0.63, alpha: 1.0))
    let onPrimaryContainer = adaptiveColor(light: UIColor(red: 0.13, green: 0.11, blue: 0.29, alpha: 1.0), dark: UIColor(red: 0.90, green: 0.88, blue: 1.0, alpha: 1.0))
    
    // Secondary Colors - Supporting colors
    let secondary = adaptiveColor(light: UIColor(red: 0.38, green: 0.35, blue: 0.55, alpha: 1.0), dark: UIColor(red: 0.79, green: 0.76, blue: 0.92, alpha: 1.0))
    let onSecondary = adaptiveColor(light: .white, dark: UIColor(red: 0.23, green: 0.20, blue: 0.36, alpha: 1.0))
    let secondaryContainer = adaptiveColor(light: UIColor(red: 0.90, green: 0.88, blue: 0.96, alpha: 1.0), dark: UIColor(red: 0.31, green: 0.29, blue: 0.44, alpha: 1.0))
    let onSecondaryContainer = adaptiveColor(light: UIColor(red: 0.13, green: 0.11, blue: 0.23, alpha: 1.0), dark: UIColor(red: 0.90, green: 0.88, blue: 0.97, alpha: 1.0))
    
    // Tertiary Colors - Accent colors
    let tertiary = adaptiveColor(light: UIColor(red: 0.55, green: 0.35, blue: 0.55, alpha: 1.0), dark: UIColor(red: 0.93, green: 0.74, blue: 0.93, alpha: 1.0))
    let onTertiary = adaptiveColor(light: .white, dark: UIColor(red: 0.36, green: 0.19, blue: 0.36, alpha: 1.0))
    let tertiaryContainer = adaptiveColor(light: UIColor(red: 0.96, green: 0.88, blue: 0.96, alpha: 1.0), dark: UIColor(red: 0.48, green: 0.27, blue: 0.48, alpha: 1.0))
    let onTertiaryContainer = adaptiveColor(light: UIColor(red: 0.23, green: 0.11, blue: 0.23, alpha: 1.0), dark: UIColor(red: 0.96, green: 0.88, blue: 0.96, alpha: 1.0))
    
    // Error Colors
    let error = adaptiveColor(light: UIColor(red: 0.73, green: 0.11, blue: 1.14, alpha: 1.0), dark: UIColor(red: 0.98, green: 0.70, blue: 0.67, alpha: 1.0))
    let onError = adaptiveColor(light: .white, dark: UIColor(red: 0.38, green: 0.0, blue: 0.05, alpha: 1.0))
    let errorContainer = adaptiveColor(light: UIColor(red: 0.98, green: 0.85, blue: 0.85, alpha: 1.0), dark: UIColor(red: 0.58, green: 0.06, blue: 0.09, alpha: 1.0))
    let onErrorContainer = adaptiveColor(light: UIColor(red: 0.25, green: 0.05, blue: 0.06, alpha: 1.0), dark: UIColor(red: 0.98, green: 0.85, blue: 0.85, alpha: 1.0))
    
    // Success Colors (Custom addition for reading app)
    let success = adaptiveColor(light: UIColor(red: 0.15, green: 0.55, blue: 0.32, alpha: 1.0), dark: UIColor(red: 0.45, green: 0.85, blue: 0.62, alpha: 1.0))
    let onSuccess = adaptiveColor(light: .white, dark: UIColor(red: 0.0, green: 0.22, blue: 0.11, alpha: 1.0))
    let successContainer = adaptiveColor(light: UIColor(red: 0.85, green: 0.95, blue: 0.88, alpha: 1.0), dark: UIColor(red: 0.0, green: 0.33, blue: 0.17, alpha: 1.0))
    let onSuccessContainer = adaptiveColor(light: UIColor(red: 0.05, green: 0.20, blue: 0.11, alpha: 1.0), dark: UIColor(red: 0.85, green: 0.95, blue: 0.88, alpha: 1.0))
    
    // Warning Colors (Custom addition)
    let warning = adaptiveColor(light: UIColor(red: 0.85, green: 0.52, blue: 0.09, alpha: 1.0), dark: UIColor(red: 1.0, green: 0.72, blue: 0.45, alpha: 1.0))
    let onWarning = adaptiveColor(light: .white, dark: UIColor(red: 0.35, green: 0.21, blue: 0.0, alpha: 1.0))
    let warningContainer = adaptiveColor(light: UIColor(red: 0.98, green: 0.93, blue: 0.84, alpha: 1.0), dark: UIColor(red: 0.5, green: 0.32, blue: 0.0, alpha: 1.0))
    let onWarningContainer = adaptiveColor(light: UIColor(red: 0.29, green: 0.18, blue: 0.03, alpha: 1.0), dark: UIColor(red: 0.98, green: 0.93, blue: 0.84, alpha: 1.0))
    
    // MARK: - Adaptive Colors for Dark Mode Support
    
    // Surface Colors - Using adaptive system colors for proper dark mode support
    var surface: Color { Color(.systemBackground) }
    var onSurface: Color { Color(.label) }
    var surfaceVariant: Color { Color(.secondarySystemBackground) }
    var onSurfaceVariant: Color { Color(.secondaryLabel) }
    
    // Inverse Colors - Using adaptive system colors
    var inverseSurface: Color { Color(.label) }
    var inverseOnSurface: Color { Color(.systemBackground) }
    let inversePrimary = adaptiveColor(light: UIColor(red: 0.70, green: 0.68, blue: 1.0, alpha: 1.0), dark: UIColor(red: 0.38, green: 0.35, blue: 0.80, alpha: 1.0))
    
    // Outline Colors - Using adaptive system colors
    var outline: Color { Color(.separator) }
    var outlineVariant: Color { Color(.opaqueSeparator) }
    
    // Background Colors - Using adaptive system colors
    var background: Color { Color(.systemBackground) }
    var onBackground: Color { Color(.label) }
    
    // MARK: - Reading Status Colors with Dark Mode Support
    // Vibrant, culturally-inspired colors for reading status
    var statusToRead: Color { Color(.tertiaryLabel) }
    var statusReading: Color { adaptiveColor(light: UIColor(red: 0.25, green: 0.46, blue: 0.85, alpha: 1.0), dark: UIColor(red: 0.65, green: 0.76, blue: 1.0, alpha: 1.0)) }
    var statusRead: Color { success }
    var statusOnHold: Color { warning }
    var statusDNF: Color { error }
    
    // MARK: - Cultural Theme Colors with Dark Mode Considerations
    // Colors inspired by different cultures for the diversity tracking feature
    let cultureAfrica = adaptiveColor(light: UIColor(red: 0.85, green: 0.32, blue: 0.09, alpha: 1.0), dark: UIColor(red: 1.0, green: 0.55, blue: 0.40, alpha: 1.0)) // Warm terracotta
    let cultureAsia = adaptiveColor(light: UIColor(red: 0.73, green: 0.11, blue: 0.32, alpha: 1.0), dark: UIColor(red: 1.0, green: 0.60, blue: 0.65, alpha: 1.0)) // Deep crimson
    let cultureEurope = adaptiveColor(light: UIColor(red: 0.25, green: 0.46, blue: 0.85, alpha: 1.0), dark: UIColor(red: 0.65, green: 0.76, blue: 1.0, alpha: 1.0)) // Royal blue
    let cultureAmericas = adaptiveColor(light: UIColor(red: 0.15, green: 0.55, blue: 0.32, alpha: 1.0), dark: UIColor(red: 0.45, green: 0.85, blue: 0.62, alpha: 1.0)) // Forest green
    let cultureOceania = adaptiveColor(light: UIColor(red: 0.38, green: 0.70, blue: 0.85, alpha: 1.0), dark: UIColor(red: 0.58, green: 0.90, blue: 1.0, alpha: 1.0)) // Ocean blue
    let cultureMiddleEast = adaptiveColor(light: UIColor(red: 0.55, green: 0.35, blue: 0.85, alpha: 1.0), dark: UIColor(red: 0.85, green: 0.65, blue: 1.0, alpha: 1.0)) // Rich purple
    let cultureIndigenous = adaptiveColor(light: UIColor(red: 0.85, green: 0.65, blue: 0.13, alpha: 1.0), dark: UIColor(red: 1.0, green: 0.85, blue: 0.43, alpha: 1.0)) // Warm gold
    
    // MARK: - Genre Colors
    // Distinct colors for different book genres
    let genreFiction = adaptiveColor(light: UIColor(red: 0.55, green: 0.35, blue: 0.85, alpha: 1.0), dark: UIColor(red: 0.85, green: 0.65, blue: 1.0, alpha: 1.0))
    let genreNonfiction = adaptiveColor(light: UIColor(red: 0.15, green: 0.55, blue: 0.32, alpha: 1.0), dark: UIColor(red: 0.45, green: 0.85, blue: 0.62, alpha: 1.0))
    let genreMystery = adaptiveColor(light: UIColor(red: 0.29, green: 0.26, blue: 0.32, alpha: 1.0), dark: UIColor(red: 0.89, green: 0.86, blue: 0.92, alpha: 1.0))
    let genreRomance = adaptiveColor(light: UIColor(red: 0.85, green: 0.32, blue: 0.46, alpha: 1.0), dark: UIColor(red: 1.0, green: 0.60, blue: 0.70, alpha: 1.0))
    let genreSciFi = adaptiveColor(light: UIColor(red: 0.25, green: 0.46, blue: 0.85, alpha: 1.0), dark: UIColor(red: 0.65, green: 0.76, blue: 1.0, alpha: 1.0))
    let genreFantasy = adaptiveColor(light: UIColor(red: 0.55, green: 0.32, blue: 0.85, alpha: 1.0), dark: UIColor(red: 0.85, green: 0.62, blue: 1.0, alpha: 1.0))
    let genreBiography = adaptiveColor(light: UIColor(red: 0.85, green: 0.52, blue: 0.09, alpha: 1.0), dark: UIColor(red: 1.0, green: 0.72, blue: 0.45, alpha: 1.0))
    let genreHistory = adaptiveColor(light: UIColor(red: 0.73, green: 0.55, blue: 0.32, alpha: 1.0), dark: UIColor(red: 1.0, green: 0.80, blue: 0.60, alpha: 1.0))
    
    // MARK: - Component-Specific Colors with Dark Mode Support
    
    // Card colors with elevation - Using adaptive colors
    var cardBackground: Color { Color(.secondarySystemBackground) }
    var cardBorder: Color { outlineVariant.opacity(0.5) }
    
    // Action colors
    var primaryAction: Color { primary }
    var secondaryAction: Color { secondary }
    var destructiveAction: Color { error }
    
    // Text colors with hierarchy - Using adaptive colors
    var primaryText: Color { Color(.label) }
    var secondaryText: Color { Color(.secondaryLabel) }
    var disabledText: Color { Color(.tertiaryLabel) }
    
    // Interactive states - Using adaptive colors with better contrast
    var pressed: Color { Color(.systemFill) }
    var hovered: Color { Color(.systemFill).opacity(0.5) }
    var focused: Color { primary.opacity(0.12) }
    var selected: Color { primary.opacity(0.12) }
    var disabled: Color { Color(.systemFill) }
    
    // MARK: - Additional Helper Colors
    var accentHighlight: Color { tertiary }
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