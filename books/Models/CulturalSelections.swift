//
//  CulturalSelections.swift
//  books
//
//  Cultural diversity selection models with standardized data
//  Provides ISO language codes and standardized cultural backgrounds
//

import Foundation

// MARK: - Language Selection

struct LanguageOption: Identifiable, Codable, Hashable, Sendable {
    let id: String // ISO 639-1 code
    let name: String
    let nativeName: String?
    let region: String?
    
    init(code: String, name: String, nativeName: String? = nil, region: String? = nil) {
        self.id = code
        self.name = name
        self.nativeName = nativeName
        self.region = region
    }
    
    var displayName: String {
        if let region = region {
            return "\(id.uppercased()) - \(name) (\(region))"
        } else {
            return "\(id.uppercased()) - \(name)"
        }
    }
}

// MARK: - Cultural Background Selection

struct CulturalBackground: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let name: String
    let continent: String
    let region: String?
    
    init(id: String, name: String, continent: String, region: String? = nil) {
        self.id = id
        self.name = name
        self.continent = continent
        self.region = region
    }
    
    var displayName: String {
        if let region = region {
            return "\(name) (\(region))"
        } else {
            return name
        }
    }
}

// MARK: - Predefined Options

struct CulturalSelections {
    
    // MARK: - Language Options (ISO 639-1 codes)
    
    static let languages: [LanguageOption] = [
        // Major world languages
        LanguageOption(code: "en", name: "English", region: "United States/UK"),
        LanguageOption(code: "es", name: "Spanish", nativeName: "Español", region: "Spain/Latin America"),
        LanguageOption(code: "fr", name: "French", nativeName: "Français", region: "France"),
        LanguageOption(code: "de", name: "German", nativeName: "Deutsch", region: "Germany"),
        LanguageOption(code: "it", name: "Italian", nativeName: "Italiano", region: "Italy"),
        LanguageOption(code: "pt", name: "Portuguese", nativeName: "Português", region: "Portugal/Brazil"),
        LanguageOption(code: "ru", name: "Russian", nativeName: "Русский", region: "Russia"),
        LanguageOption(code: "zh", name: "Chinese", nativeName: "中文", region: "China"),
        LanguageOption(code: "ja", name: "Japanese", nativeName: "日本語", region: "Japan"),
        LanguageOption(code: "ko", name: "Korean", nativeName: "한국어", region: "South Korea"),
        LanguageOption(code: "ar", name: "Arabic", nativeName: "العربية", region: "Middle East/North Africa"),
        LanguageOption(code: "hi", name: "Hindi", nativeName: "हिन्दी", region: "India"),
        LanguageOption(code: "bn", name: "Bengali", nativeName: "বাংলা", region: "Bangladesh/India"),
        LanguageOption(code: "ur", name: "Urdu", nativeName: "اردو", region: "Pakistan/India"),
        LanguageOption(code: "fa", name: "Persian", nativeName: "فارسی", region: "Iran"),
        LanguageOption(code: "tr", name: "Turkish", nativeName: "Türkçe", region: "Turkey"),
        LanguageOption(code: "pl", name: "Polish", nativeName: "Polski", region: "Poland"),
        LanguageOption(code: "nl", name: "Dutch", nativeName: "Nederlands", region: "Netherlands"),
        LanguageOption(code: "sv", name: "Swedish", nativeName: "Svenska", region: "Sweden"),
        LanguageOption(code: "da", name: "Danish", nativeName: "Dansk", region: "Denmark"),
        LanguageOption(code: "no", name: "Norwegian", nativeName: "Norsk", region: "Norway"),
        LanguageOption(code: "fi", name: "Finnish", nativeName: "Suomi", region: "Finland"),
        LanguageOption(code: "hu", name: "Hungarian", nativeName: "Magyar", region: "Hungary"),
        LanguageOption(code: "cs", name: "Czech", nativeName: "Čeština", region: "Czech Republic"),
        LanguageOption(code: "sk", name: "Slovak", nativeName: "Slovenčina", region: "Slovakia"),
        LanguageOption(code: "ro", name: "Romanian", nativeName: "Română", region: "Romania"),
        LanguageOption(code: "bg", name: "Bulgarian", nativeName: "Български", region: "Bulgaria"),
        LanguageOption(code: "hr", name: "Croatian", nativeName: "Hrvatski", region: "Croatia"),
        LanguageOption(code: "sr", name: "Serbian", nativeName: "Српски", region: "Serbia"),
        LanguageOption(code: "uk", name: "Ukrainian", nativeName: "Українська", region: "Ukraine"),
        LanguageOption(code: "he", name: "Hebrew", nativeName: "עברית", region: "Israel"),
        LanguageOption(code: "th", name: "Thai", nativeName: "ไทย", region: "Thailand"),
        LanguageOption(code: "vi", name: "Vietnamese", nativeName: "Tiếng Việt", region: "Vietnam"),
        LanguageOption(code: "id", name: "Indonesian", nativeName: "Bahasa Indonesia", region: "Indonesia"),
        LanguageOption(code: "ms", name: "Malay", nativeName: "Bahasa Melayu", region: "Malaysia"),
        LanguageOption(code: "tl", name: "Filipino", nativeName: "Filipino", region: "Philippines"),
        LanguageOption(code: "sw", name: "Swahili", nativeName: "Kiswahili", region: "East Africa"),
        LanguageOption(code: "am", name: "Amharic", nativeName: "አማርኛ", region: "Ethiopia"),
        LanguageOption(code: "yo", name: "Yoruba", nativeName: "Yorùbá", region: "Nigeria"),
        LanguageOption(code: "ig", name: "Igbo", nativeName: "Igbo", region: "Nigeria"),
        LanguageOption(code: "ha", name: "Hausa", nativeName: "Hausa", region: "Nigeria"),
        LanguageOption(code: "zu", name: "Zulu", nativeName: "IsiZulu", region: "South Africa"),
        LanguageOption(code: "xh", name: "Xhosa", nativeName: "IsiXhosa", region: "South Africa"),
        LanguageOption(code: "af", name: "Afrikaans", nativeName: "Afrikaans", region: "South Africa")
    ]
    
    // MARK: - Cultural Background Options
    
    static let culturalBackgrounds: [CulturalBackground] = [
        // North America
        CulturalBackground(id: "us", name: "United States", continent: "North America"),
        CulturalBackground(id: "ca", name: "Canada", continent: "North America"),
        CulturalBackground(id: "mx", name: "Mexico", continent: "North America"),
        
        // South America
        CulturalBackground(id: "br", name: "Brazil", continent: "South America"),
        CulturalBackground(id: "ar", name: "Argentina", continent: "South America"),
        CulturalBackground(id: "cl", name: "Chile", continent: "South America"),
        CulturalBackground(id: "co", name: "Colombia", continent: "South America"),
        CulturalBackground(id: "pe", name: "Peru", continent: "South America"),
        CulturalBackground(id: "ve", name: "Venezuela", continent: "South America"),
        CulturalBackground(id: "ec", name: "Ecuador", continent: "South America"),
        CulturalBackground(id: "bo", name: "Bolivia", continent: "South America"),
        CulturalBackground(id: "uy", name: "Uruguay", continent: "South America"),
        CulturalBackground(id: "py", name: "Paraguay", continent: "South America"),
        
        // Europe
        CulturalBackground(id: "gb", name: "United Kingdom", continent: "Europe"),
        CulturalBackground(id: "fr", name: "France", continent: "Europe"),
        CulturalBackground(id: "de", name: "Germany", continent: "Europe"),
        CulturalBackground(id: "it", name: "Italy", continent: "Europe"),
        CulturalBackground(id: "es", name: "Spain", continent: "Europe"),
        CulturalBackground(id: "pt", name: "Portugal", continent: "Europe"),
        CulturalBackground(id: "ru", name: "Russia", continent: "Europe", region: "Eastern Europe"),
        CulturalBackground(id: "pl", name: "Poland", continent: "Europe", region: "Eastern Europe"),
        CulturalBackground(id: "ua", name: "Ukraine", continent: "Europe", region: "Eastern Europe"),
        CulturalBackground(id: "cz", name: "Czech Republic", continent: "Europe", region: "Central Europe"),
        CulturalBackground(id: "hu", name: "Hungary", continent: "Europe", region: "Central Europe"),
        CulturalBackground(id: "ro", name: "Romania", continent: "Europe", region: "Eastern Europe"),
        CulturalBackground(id: "gr", name: "Greece", continent: "Europe", region: "Southern Europe"),
        CulturalBackground(id: "tr", name: "Turkey", continent: "Europe", region: "Western Asia"),
        CulturalBackground(id: "nl", name: "Netherlands", continent: "Europe", region: "Western Europe"),
        CulturalBackground(id: "be", name: "Belgium", continent: "Europe", region: "Western Europe"),
        CulturalBackground(id: "ch", name: "Switzerland", continent: "Europe", region: "Western Europe"),
        CulturalBackground(id: "at", name: "Austria", continent: "Europe", region: "Central Europe"),
        CulturalBackground(id: "se", name: "Sweden", continent: "Europe", region: "Northern Europe"),
        CulturalBackground(id: "no", name: "Norway", continent: "Europe", region: "Northern Europe"),
        CulturalBackground(id: "dk", name: "Denmark", continent: "Europe", region: "Northern Europe"),
        CulturalBackground(id: "fi", name: "Finland", continent: "Europe", region: "Northern Europe"),
        CulturalBackground(id: "is", name: "Iceland", continent: "Europe", region: "Northern Europe"),
        
        // Asia
        CulturalBackground(id: "cn", name: "China", continent: "Asia", region: "East Asia"),
        CulturalBackground(id: "jp", name: "Japan", continent: "Asia", region: "East Asia"),
        CulturalBackground(id: "kr", name: "South Korea", continent: "Asia", region: "East Asia"),
        CulturalBackground(id: "in", name: "India", continent: "Asia", region: "South Asia"),
        CulturalBackground(id: "pk", name: "Pakistan", continent: "Asia", region: "South Asia"),
        CulturalBackground(id: "bd", name: "Bangladesh", continent: "Asia", region: "South Asia"),
        CulturalBackground(id: "lk", name: "Sri Lanka", continent: "Asia", region: "South Asia"),
        CulturalBackground(id: "np", name: "Nepal", continent: "Asia", region: "South Asia"),
        CulturalBackground(id: "ir", name: "Iran", continent: "Asia", region: "Western Asia"),
        CulturalBackground(id: "iq", name: "Iraq", continent: "Asia", region: "Western Asia"),
        CulturalBackground(id: "sy", name: "Syria", continent: "Asia", region: "Western Asia"),
        CulturalBackground(id: "lb", name: "Lebanon", continent: "Asia", region: "Western Asia"),
        CulturalBackground(id: "jo", name: "Jordan", continent: "Asia", region: "Western Asia"),
        CulturalBackground(id: "il", name: "Israel", continent: "Asia", region: "Western Asia"),
        CulturalBackground(id: "sa", name: "Saudi Arabia", continent: "Asia", region: "Western Asia"),
        CulturalBackground(id: "ae", name: "United Arab Emirates", continent: "Asia", region: "Western Asia"),
        CulturalBackground(id: "th", name: "Thailand", continent: "Asia", region: "Southeast Asia"),
        CulturalBackground(id: "vn", name: "Vietnam", continent: "Asia", region: "Southeast Asia"),
        CulturalBackground(id: "id", name: "Indonesia", continent: "Asia", region: "Southeast Asia"),
        CulturalBackground(id: "my", name: "Malaysia", continent: "Asia", region: "Southeast Asia"),
        CulturalBackground(id: "ph", name: "Philippines", continent: "Asia", region: "Southeast Asia"),
        CulturalBackground(id: "sg", name: "Singapore", continent: "Asia", region: "Southeast Asia"),
        
        // Africa
        CulturalBackground(id: "ng", name: "Nigeria", continent: "Africa", region: "West Africa"),
        CulturalBackground(id: "gh", name: "Ghana", continent: "Africa", region: "West Africa"),
        CulturalBackground(id: "sn", name: "Senegal", continent: "Africa", region: "West Africa"),
        CulturalBackground(id: "ml", name: "Mali", continent: "Africa", region: "West Africa"),
        CulturalBackground(id: "bf", name: "Burkina Faso", continent: "Africa", region: "West Africa"),
        CulturalBackground(id: "ci", name: "Ivory Coast", continent: "Africa", region: "West Africa"),
        CulturalBackground(id: "ke", name: "Kenya", continent: "Africa", region: "East Africa"),
        CulturalBackground(id: "tz", name: "Tanzania", continent: "Africa", region: "East Africa"),
        CulturalBackground(id: "ug", name: "Uganda", continent: "Africa", region: "East Africa"),
        CulturalBackground(id: "rw", name: "Rwanda", continent: "Africa", region: "East Africa"),
        CulturalBackground(id: "et", name: "Ethiopia", continent: "Africa", region: "East Africa"),
        CulturalBackground(id: "so", name: "Somalia", continent: "Africa", region: "East Africa"),
        CulturalBackground(id: "za", name: "South Africa", continent: "Africa", region: "Southern Africa"),
        CulturalBackground(id: "zw", name: "Zimbabwe", continent: "Africa", region: "Southern Africa"),
        CulturalBackground(id: "bw", name: "Botswana", continent: "Africa", region: "Southern Africa"),
        CulturalBackground(id: "na", name: "Namibia", continent: "Africa", region: "Southern Africa"),
        CulturalBackground(id: "eg", name: "Egypt", continent: "Africa", region: "North Africa"),
        CulturalBackground(id: "ma", name: "Morocco", continent: "Africa", region: "North Africa"),
        CulturalBackground(id: "dz", name: "Algeria", continent: "Africa", region: "North Africa"),
        CulturalBackground(id: "tn", name: "Tunisia", continent: "Africa", region: "North Africa"),
        CulturalBackground(id: "ly", name: "Libya", continent: "Africa", region: "North Africa"),
        
        // Oceania
        CulturalBackground(id: "au", name: "Australia", continent: "Oceania"),
        CulturalBackground(id: "nz", name: "New Zealand", continent: "Oceania"),
        CulturalBackground(id: "fj", name: "Fiji", continent: "Oceania", region: "Pacific Islands"),
        CulturalBackground(id: "pg", name: "Papua New Guinea", continent: "Oceania", region: "Pacific Islands"),
        
        // Mixed/Multi-cultural
        CulturalBackground(id: "mixed", name: "Mixed Cultural Heritage", continent: "Global"),
        CulturalBackground(id: "diaspora", name: "Diaspora Community", continent: "Global"),
        CulturalBackground(id: "immigrant", name: "Immigrant Experience", continent: "Global"),
        CulturalBackground(id: "indigenous", name: "Indigenous Heritage", continent: "Global")
    ]
    
    // MARK: - Helper Methods
    
    static func language(for code: String) -> LanguageOption? {
        return languages.first { $0.id == code.lowercased() }
    }
    
    static func culturalBackground(for id: String) -> CulturalBackground? {
        return culturalBackgrounds.first { $0.id == id.lowercased() }
    }
    
    static func languagesByRegion() -> [String: [LanguageOption]] {
        Dictionary(grouping: languages) { language in
            language.region ?? "Other"
        }
    }
    
    static func culturalBackgroundsByContinent() -> [String: [CulturalBackground]] {
        Dictionary(grouping: culturalBackgrounds) { background in
            background.continent
        }
    }
}