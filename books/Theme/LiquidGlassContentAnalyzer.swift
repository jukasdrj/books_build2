import SwiftUI

// MARK: - Content Adaptability System for Liquid Glass
// Real-time content analysis enabling dynamic material adjustment based on underlying content
// Following Apple's Liquid Glass specification: "adapts between light and dark appearance in response to underlying content"

@MainActor
class LiquidGlassContentAnalyzer: ObservableObject {
    static let shared = LiquidGlassContentAnalyzer()
    
    // MARK: - Published Properties
    @Published private(set) var contentBrightness: ContentBrightness = .neutral
    @Published private(set) var contentComplexity: ContentComplexity = .simple
    @Published private(set) var contentSaturation: ContentSaturation = .moderate
    
    // MARK: - Performance Optimization
    private var analysisCache: [String: ContentAnalysis] = [:]
    private let maxCacheSize = 50
    private var lastAnalysisTime: Date = .distantPast
    private let analysisThrottleInterval: TimeInterval = 0.1 // 100ms throttling
    
    // MARK: - Content Analysis Types
    
    enum ContentBrightness: CaseIterable {
        case light      // Bright content requiring more opaque glass
        case dark       // Dark content allowing more transparent glass
        case neutral    // Balanced content using standard opacity
        case mixed      // Complex content with mixed brightness
        
        /// Apple-aligned adaptive opacity for glass materials
        var adaptiveOpacity: Double {
            switch self {
            case .light: return 0.85    // Higher opacity on light content for better contrast
            case .dark: return 0.45     // Lower opacity on dark content to show richness
            case .neutral: return 0.65  // Standard balanced opacity
            case .mixed: return 0.70    // Slightly higher for complex content
            }
        }
        
        /// Content legibility enhancement factor
        var legibilityFactor: Double {
            switch self {
            case .light: return 1.2     // Boost legibility on light backgrounds
            case .dark: return 0.8      // Reduce for dark backgrounds
            case .neutral: return 1.0   // Standard
            case .mixed: return 1.1     // Slight boost for mixed content
            }
        }
        
        /// Apple's recommended shadow opacity adjustment
        var shadowOpacityMultiplier: Double {
            switch self {
            case .light: return 1.3     // More shadow on light content
            case .dark: return 0.6      // Less shadow on dark content
            case .neutral: return 1.0   // Standard shadow
            case .mixed: return 1.1     // Balanced shadow for mixed
            }
        }
    }
    
    enum ContentComplexity: CaseIterable {
        case simple     // Single color, minimal patterns
        case moderate   // Some variation, basic patterns
        case complex    // High variation, detailed patterns
        case chaotic    // Very high complexity, many elements
        
        /// Glass blur adjustment for content complexity
        var blurAdjustment: Double {
            switch self {
            case .simple: return 0.8    // Less blur on simple content
            case .moderate: return 1.0  // Standard blur
            case .complex: return 1.2   // More blur for complex content
            case .chaotic: return 1.4   // Maximum blur for chaotic content
            }
        }
        
        /// Material thickness recommendation
        var recommendedMaterialBoost: Double {
            switch self {
            case .simple: return 0.9    // Thinner material for simple content
            case .moderate: return 1.0  // Standard material
            case .complex: return 1.1   // Slightly thicker for complex
            case .chaotic: return 1.3   // Much thicker for chaotic content
            }
        }
    }
    
    enum ContentSaturation: CaseIterable {
        case monochrome // Grayscale content
        case low        // Muted colors
        case moderate   // Balanced colors
        case high       // Vibrant colors
        case vivid      // Extremely saturated colors
        
        /// Vibrancy adjustment for glass effects
        var vibrancyAdjustment: Double {
            switch self {
            case .monochrome: return 1.2    // Boost vibrancy for monochrome
            case .low: return 1.1           // Slight boost for muted colors
            case .moderate: return 1.0      // Standard vibrancy
            case .high: return 0.9          // Reduce for already vibrant content
            case .vivid: return 0.8         // Significant reduction for vivid content
            }
        }
    }
    
    // MARK: - Comprehensive Content Analysis Result
    struct ContentAnalysis: Hashable {
        let brightness: ContentBrightness
        let complexity: ContentComplexity
        let saturation: ContentSaturation
        let timestamp: Date
        
        /// Combined adaptive opacity considering all factors
        var combinedAdaptiveOpacity: Double {
            let base = brightness.adaptiveOpacity
            let complexityFactor = complexity.recommendedMaterialBoost
            let saturationFactor = saturation.vibrancyAdjustment
            
            return (base * complexityFactor * saturationFactor).clamped(to: 0.2...0.95)
        }
        
        /// Combined blur radius adjustment
        var combinedBlurAdjustment: Double {
            return complexity.blurAdjustment * saturation.vibrancyAdjustment
        }
        
        /// Content-aware shadow configuration
        var shadowConfiguration: (opacity: Double, radius: Double) {
            let baseOpacity = 0.15 * brightness.shadowOpacityMultiplier
            let baseRadius = 8.0 * complexity.blurAdjustment
            return (baseOpacity, baseRadius)
        }
    }
    
    init() {
        // Initialize with system color scheme analysis
        analyzeSystemEnvironment()
    }
    
    // MARK: - Public Analysis Methods
    
    /// Primary method for analyzing content and updating glass material properties
    func analyzeContent(
        colorScheme: ColorScheme,
        backgroundColor: Color? = nil,
        contentColors: [Color] = [],
        customAnalysis: ContentAnalysis? = nil
    ) {
        // Throttle analysis calls for performance
        let now = Date()
        guard now.timeIntervalSince(lastAnalysisTime) >= analysisThrottleInterval else {
            return
        }
        lastAnalysisTime = now
        
        // Use custom analysis if provided, otherwise perform analysis
        let analysis = customAnalysis ?? performContentAnalysis(
            colorScheme: colorScheme,
            backgroundColor: backgroundColor,
            contentColors: contentColors
        )
        
        // Cache analysis result
        let cacheKey = generateCacheKey(colorScheme, backgroundColor, contentColors)
        cacheAnalysis(analysis, forKey: cacheKey)
        
        // Update published properties
        updateAnalysisResults(analysis)
    }
    
    /// Convenience method for simple color scheme analysis
    func analyzeColorScheme(_ colorScheme: ColorScheme) {
        analyzeContent(colorScheme: colorScheme)
    }
    
    /// Analyze specific background color
    func analyzeBackground(_ backgroundColor: Color, colorScheme: ColorScheme = .light) {
        analyzeContent(colorScheme: colorScheme, backgroundColor: backgroundColor)
    }
    
    /// Reset to system defaults
    func resetToSystemDefaults() {
        analyzeSystemEnvironment()
    }
    
    // MARK: - Advanced Analysis Methods
    
    /// Perform comprehensive content analysis
    private func performContentAnalysis(
        colorScheme: ColorScheme,
        backgroundColor: Color?,
        contentColors: [Color]
    ) -> ContentAnalysis {
        
        // 1. Brightness Analysis
        let brightness = analyzeBrightness(
            colorScheme: colorScheme,
            backgroundColor: backgroundColor,
            contentColors: contentColors
        )
        
        // 2. Complexity Analysis
        let complexity = analyzeComplexity(contentColors: contentColors)
        
        // 3. Saturation Analysis
        let saturation = analyzeSaturation(contentColors: contentColors)
        
        return ContentAnalysis(
            brightness: brightness,
            complexity: complexity,
            saturation: saturation,
            timestamp: Date()
        )
    }
    
    private func analyzeBrightness(
        colorScheme: ColorScheme,
        backgroundColor: Color?,
        contentColors: [Color]
    ) -> ContentBrightness {
        
        // Start with color scheme as base
        var brightPixels = colorScheme == .light ? 0.6 : 0.2
        
        // Factor in background color if provided
        if let bgColor = backgroundColor {
            let bgLuminance = bgColor.contentLuminance
            brightPixels = (brightPixels + bgLuminance) / 2.0
        }
        
        // Factor in content colors
        if !contentColors.isEmpty {
            let avgContentLuminance = contentColors.map { $0.contentLuminance }.reduce(0, +) / Double(contentColors.count)
            brightPixels = (brightPixels + avgContentLuminance) / 2.0
        }
        
        // Determine brightness category
        switch brightPixels {
        case 0.0..<0.25: return .dark
        case 0.25..<0.4: return .neutral
        case 0.4..<0.75: return .mixed
        default: return .light
        }
    }
    
    private func analyzeComplexity(contentColors: [Color]) -> ContentComplexity {
        let colorCount = contentColors.count
        
        switch colorCount {
        case 0...2: return .simple
        case 3...6: return .moderate
        case 7...12: return .complex
        default: return .chaotic
        }
    }
    
    private func analyzeSaturation(contentColors: [Color]) -> ContentSaturation {
        guard !contentColors.isEmpty else { return .moderate }
        
        let avgSaturation = contentColors.map { $0.contentSaturation }.reduce(0, +) / Double(contentColors.count)
        
        switch avgSaturation {
        case 0.0..<0.1: return .monochrome
        case 0.1..<0.3: return .low
        case 0.3..<0.6: return .moderate
        case 0.6..<0.8: return .high
        default: return .vivid
        }
    }
    
    // MARK: - System Environment Analysis
    
    private func analyzeSystemEnvironment() {
        #if os(iOS)
        let isDarkMode = UIScreen.main.traitCollection.userInterfaceStyle == .dark
        let colorScheme: ColorScheme = isDarkMode ? .dark : .light
        #else
        let colorScheme: ColorScheme = .light // Fallback for other platforms
        #endif
        
        let systemAnalysis = ContentAnalysis(
            brightness: colorScheme == .dark ? .dark : .light,
            complexity: .simple,
            saturation: .moderate,
            timestamp: Date()
        )
        
        updateAnalysisResults(systemAnalysis)
    }
    
    // MARK: - Cache Management
    
    private func generateCacheKey(_ colorScheme: ColorScheme, _ backgroundColor: Color?, _ contentColors: [Color]) -> String {
        var key = "cs_\(colorScheme == .light ? "l" : "d")"
        
        if let bg = backgroundColor {
            key += "_bg_\(bg.description.hashValue)"
        }
        
        if !contentColors.isEmpty {
            let colorsHash = contentColors.map { $0.description.hashValue }.reduce(0, ^)
            key += "_cc_\(colorsHash)"
        }
        
        return key
    }
    
    private func cacheAnalysis(_ analysis: ContentAnalysis, forKey key: String) {
        // Maintain cache size limit
        if analysisCache.count >= maxCacheSize {
            // Remove oldest entries
            let sortedEntries = analysisCache.sorted { $0.value.timestamp < $1.value.timestamp }
            let keysToRemove = sortedEntries.prefix(10).map { $0.key }
            keysToRemove.forEach { analysisCache.removeValue(forKey: $0) }
        }
        
        analysisCache[key] = analysis
    }
    
    private func getCachedAnalysis(forKey key: String) -> ContentAnalysis? {
        guard let cached = analysisCache[key] else { return nil }
        
        // Check if cache entry is still fresh (within 5 seconds)
        let cacheLifetime: TimeInterval = 5.0
        guard Date().timeIntervalSince(cached.timestamp) < cacheLifetime else {
            analysisCache.removeValue(forKey: key)
            return nil
        }
        
        return cached
    }
    
    // MARK: - Result Updates
    
    private func updateAnalysisResults(_ analysis: ContentAnalysis) {
        contentBrightness = analysis.brightness
        contentComplexity = analysis.complexity
        contentSaturation = analysis.saturation
        
        #if DEBUG
        print("[LiquidGlassContentAnalyzer] 📊 Content Analysis Updated:")
        print("  - Brightness: \(analysis.brightness)")
        print("  - Complexity: \(analysis.complexity)")
        print("  - Saturation: \(analysis.saturation)")
        print("  - Combined Opacity: \(String(format: "%.2f", analysis.combinedAdaptiveOpacity))")
        print("  - Combined Blur: \(String(format: "%.2f", analysis.combinedBlurAdjustment))")
        #endif
    }
    
    // MARK: - Public Computed Properties
    
    /// Current comprehensive analysis result
    var currentAnalysis: ContentAnalysis {
        ContentAnalysis(
            brightness: contentBrightness,
            complexity: contentComplexity,
            saturation: contentSaturation,
            timestamp: Date()
        )
    }
    
    /// Quick access to combined adaptive opacity
    var adaptiveOpacity: Double {
        currentAnalysis.combinedAdaptiveOpacity
    }
    
    /// Quick access to combined blur adjustment
    var blurAdjustment: Double {
        currentAnalysis.combinedBlurAdjustment
    }
    
    /// Quick access to shadow configuration
    var shadowConfiguration: (opacity: Double, radius: Double) {
        currentAnalysis.shadowConfiguration
    }
}

// MARK: - Color Extension for Analysis

extension Color {
    /// Calculate luminance (brightness) of a color for content analysis
    var contentLuminance: Double {
        // Convert to RGB components
        guard let components = cgColor?.components else { return 0.5 }
        
        let red = components.count > 0 ? Double(components[0]) : 0
        let green = components.count > 1 ? Double(components[1]) : 0
        let blue = components.count > 2 ? Double(components[2]) : 0
        
        // Calculate relative luminance using standard formula
        return 0.299 * red + 0.587 * green + 0.114 * blue
    }
    
    /// Calculate saturation of a color
    var contentSaturation: Double {
        guard let components = cgColor?.components else { return 0.5 }
        
        let red = components.count > 0 ? Double(components[0]) : 0
        let green = components.count > 1 ? Double(components[1]) : 0
        let blue = components.count > 2 ? Double(components[2]) : 0
        
        let maxValue = max(red, green, blue)
        let minValue = min(red, green, blue)
        
        guard maxValue > 0 else { return 0 }
        
        return (maxValue - minValue) / maxValue
    }
}

// MARK: - Numeric Extensions

extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        return Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - Environment Integration

struct LiquidGlassContentAnalyzerKey: EnvironmentKey {
    @MainActor
    static let defaultValue = LiquidGlassContentAnalyzer()
}

extension EnvironmentValues {
    var liquidGlassContentAnalyzer: LiquidGlassContentAnalyzer {
        get { self[LiquidGlassContentAnalyzerKey.self] }
        set { self[LiquidGlassContentAnalyzerKey.self] = newValue }
    }
}