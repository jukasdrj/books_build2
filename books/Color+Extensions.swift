import SwiftUI

// MARK: - Material Design 3 Color System
// Comprehensive color system following Material Design 3 guidelines
// with support for both light and dark modes

extension Color {
    static let theme = AppColorTheme()
}

struct AppColorTheme {
    
    // MARK: - Material Design 3 Core Colors
    
    // Primary Colors - Main brand colors
    let primary = Color("md3_primary") ?? Color(red: 0.38, green: 0.35, blue: 0.80) // Deep purple
    let onPrimary = Color("md3_on_primary") ?? Color.white
    let primaryContainer = Color("md3_primary_container") ?? Color(red: 0.90, green: 0.88, blue: 1.0)
    let onPrimaryContainer = Color("md3_on_primary_container") ?? Color(red: 0.13, green: 0.11, blue: 0.29)
    
    // Secondary Colors - Supporting colors
    let secondary = Color("md3_secondary") ?? Color(red: 0.38, green: 0.35, blue: 0.55)
    let onSecondary = Color("md3_on_secondary") ?? Color.white
    let secondaryContainer = Color("md3_secondary_container") ?? Color(red: 0.90, green: 0.88, blue: 0.96)
    let onSecondaryContainer = Color("md3_on_secondary_container") ?? Color(red: 0.13, green: 0.11, blue: 0.23)
    
    // Tertiary Colors - Accent colors
    let tertiary = Color("md3_tertiary") ?? Color(red: 0.55, green: 0.35, blue: 0.55)
    let onTertiary = Color("md3_on_tertiary") ?? Color.white
    let tertiaryContainer = Color("md3_tertiary_container") ?? Color(red: 0.96, green: 0.88, blue: 0.96)
    let onTertiaryContainer = Color("md3_on_tertiary_container") ?? Color(red: 0.23, green: 0.11, blue: 0.23)
    
    // Error Colors
    let error = Color("md3_error") ?? Color(red: 0.73, green: 0.11, blue: 0.14)
    let onError = Color("md3_on_error") ?? Color.white
    let errorContainer = Color("md3_error_container") ?? Color(red: 0.98, green: 0.85, blue: 0.85)
    let onErrorContainer = Color("md3_on_error_container") ?? Color(red: 0.25, green: 0.05, blue: 0.06)
    
    // Success Colors (Custom addition for reading app)
    let success = Color("md3_success") ?? Color(red: 0.15, green: 0.55, blue: 0.32)
    let onSuccess = Color("md3_on_success") ?? Color.white
    let successContainer = Color("md3_success_container") ?? Color(red: 0.85, green: 0.95, blue: 0.88)
    let onSuccessContainer = Color("md3_on_success_container") ?? Color(red: 0.05, green: 0.20, blue: 0.11)
    
    // Warning Colors (Custom addition)
    let warning = Color("md3_warning") ?? Color(red: 0.85, green: 0.52, blue: 0.09)
    let onWarning = Color("md3_on_warning") ?? Color.white
    let warningContainer = Color("md3_warning_container") ?? Color(red: 0.98, green: 0.93, blue: 0.84)
    let onWarningContainer = Color("md3_on_warning_container") ?? Color(red: 0.29, green: 0.18, blue: 0.03)
    
    // Surface Colors
    let surface = Color("md3_surface") ?? (Color.primary.colorScheme == .dark ? Color(red: 0.06, green: 0.06, blue: 0.09) : Color(red: 0.99, green: 0.98, blue: 1.0))
    let onSurface = Color("md3_on_surface") ?? (Color.primary.colorScheme == .dark ? Color(red: 0.90, green: 0.90, blue: 0.92) : Color(red: 0.10, green: 0.10, blue: 0.11))
    let surfaceVariant = Color("md3_surface_variant") ?? (Color.primary.colorScheme == .dark ? Color(red: 0.20, green: 0.18, blue: 0.22) : Color(red: 0.89, green: 0.87, blue: 0.92))
    let onSurfaceVariant = Color("md3_on_surface_variant") ?? (Color.primary.colorScheme == .dark ? Color(red: 0.79, green: 0.76, blue: 0.82) : Color(red: 0.29, green: 0.26, blue: 0.32))
    
    // Inverse Colors
    let inverseSurface = Color("md3_inverse_surface") ?? (Color.primary.colorScheme == .dark ? Color(red: 0.90, green: 0.90, blue: 0.92) : Color(red: 0.18, green: 0.18, blue: 0.20))
    let inverseOnSurface = Color("md3_inverse_on_surface") ?? (Color.primary.colorScheme == .dark ? Color(red: 0.18, green: 0.18, blue: 0.20) : Color(red: 0.94, green: 0.94, blue: 0.96))
    let inversePrimary = Color("md3_inverse_primary") ?? (Color.primary.colorScheme == .dark ? Color(red: 0.38, green: 0.35, blue: 0.80) : Color(red: 0.70, green: 0.68, blue: 1.0))
    
    // Outline Colors
    let outline = Color("md3_outline") ?? (Color.primary.colorScheme == .dark ? Color(red: 0.55, green: 0.52, blue: 0.58) : Color(red: 0.46, green: 0.43, blue: 0.49))
    let outlineVariant = Color("md3_outline_variant") ?? (Color.primary.colorScheme == .dark ? Color(red: 0.29, green: 0.26, blue: 0.32) : Color(red: 0.79, green: 0.76, blue: 0.82))
    
    // Background Colors
    let background = Color("md3_background") ?? (Color.primary.colorScheme == .dark ? Color(red: 0.06, green: 0.06, blue: 0.09) : Color(red: 0.99, green: 0.98, blue: 1.0))
    let onBackground = Color("md3_on_background") ?? (Color.primary.colorScheme == .dark ? Color(red: 0.90, green: 0.90, blue: 0.92) : Color(red: 0.10, green: 0.10, blue: 0.11))
    
    // MARK: - Reading Status Colors
    // Vibrant, culturally-inspired colors for reading status
    let statusToRead = Color(red: 0.46, green: 0.43, blue: 0.49) // Neutral gray
    let statusReading = Color(red: 0.25, green: 0.46, blue: 0.85) // Vibrant blue
    let statusRead = Color(red: 0.15, green: 0.55, blue: 0.32) // Success green
    let statusOnHold = Color(red: 0.85, green: 0.52, blue: 0.09) // Warning orange
    let statusDNF = Color(red: 0.73, green: 0.11, blue: 0.14) // Error red
    
    // MARK: - Cultural Theme Colors
    // Colors inspired by different cultures for the diversity tracking feature
    let cultureAfrica = Color(red: 0.85, green: 0.32, blue: 0.09) // Warm terracotta
    let cultureAsia = Color(red: 0.73, green: 0.11, blue: 0.32) // Deep crimson
    let cultureEurope = Color(red: 0.25, green: 0.46, blue: 0.85) // Royal blue
    let cultureAmericas = Color(red: 0.15, green: 0.55, blue: 0.32) // Forest green
    let cultureOceania = Color(red: 0.38, green: 0.70, blue: 0.85) // Ocean blue
    let cultureMiddleEast = Color(red: 0.55, green: 0.35, blue: 0.85) // Rich purple
    let cultureIndigenous = Color(red: 0.85, green: 0.65, blue: 0.13) // Warm gold
    
    // MARK: - Genre Colors
    // Distinct colors for different book genres
    let genreFiction = Color(red: 0.55, green: 0.35, blue: 0.85)
    let genreNonfiction = Color(red: 0.15, green: 0.55, blue: 0.32)
    let genreMystery = Color(red: 0.29, green: 0.26, blue: 0.32)
    let genreRomance = Color(red: 0.85, green: 0.32, blue: 0.46)
    let genreSciFi = Color(red: 0.25, green: 0.46, blue: 0.85)
    let genreFantasy = Color(red: 0.55, green: 0.32, blue: 0.85)
    let genreBiography = Color(red: 0.85, green: 0.52, blue: 0.09)
    let genreHistory = Color(red: 0.73, green: 0.55, blue: 0.32)
    
    // MARK: - Component-Specific Colors
    
    // Card colors with elevation
    var cardBackground: Color {
        Color.primary.colorScheme == .dark ? 
            Color(red: 0.11, green: 0.11, blue: 0.13) : 
            Color.white
    }
    
    var cardBorder: Color {
        outlineVariant.opacity(0.5)
    }
    
    // Action colors
    var primaryAction: Color { primary }
    var secondaryAction: Color { secondary }
    var destructiveAction: Color { error }
    
    // Text colors with hierarchy
    var primaryText: Color { onSurface }
    var secondaryText: Color { onSurfaceVariant }
    var disabledText: Color { onSurface.opacity(0.38) }
    
    // Interactive states
    var pressed: Color { onSurface.opacity(0.12) }
    var hovered: Color { onSurface.opacity(0.08) }
    var focused: Color { onSurface.opacity(0.12) }
    var selected: Color { primary.opacity(0.12) }
    var disabled: Color { onSurface.opacity(0.12) }
}

// MARK: - Reading Status Color Extension
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
            return Color.theme.statusToRead.opacity(0.12)
        case .reading:
            return Color.theme.statusReading.opacity(0.12)
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
            return Color.theme.statusToRead
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