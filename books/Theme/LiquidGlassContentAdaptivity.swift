import SwiftUI

// MARK: - Content Adaptability Extensions for Liquid Glass
// These extensions add Apple-compliant dynamic material adjustment based on underlying content

extension LiquidGlassTheme.GlassMaterial {
    
    // MARK: - Content Adaptability Extensions
    
    /// Adapt material based on content analysis for Apple-compliant dynamic response
    func adaptedFor(contentAnalysis: LiquidGlassContentAnalyzer.ContentAnalysis) -> LiquidGlassTheme.GlassMaterial {
        return adaptedFor(brightness: contentAnalysis.brightness, complexity: contentAnalysis.complexity)
    }
    
    /// Adapt material for specific content brightness (Apple's key specification)
    func adaptedFor(brightness: LiquidGlassContentAnalyzer.ContentBrightness) -> LiquidGlassTheme.GlassMaterial {
        switch (self, brightness) {
        // Light content requires more opaque materials for better contrast
        case (.ultraThin, .light): return .thin
        case (.thin, .light): return .regular
        case (.regular, .light): return .thick
        case (.thick, .light): return .thick  // Already optimal
        case (.chrome, .light): return .chrome // Chrome maintains its properties
        case (.clear, .light): return .thin    // Clear becomes slightly more opaque
        
        // Dark content allows more transparent materials to show content richness
        case (.thick, .dark): return .regular
        case (.regular, .dark): return .thin
        case (.thin, .dark): return .ultraThin
        case (.ultraThin, .dark): return .ultraThin // Already optimal
        case (.chrome, .dark): return .chrome       // Chrome maintains its properties
        case (.clear, .dark): return .clear         // Clear maintains maximum transparency
        
        // Mixed content uses balanced approach
        case (_, .mixed): return .regular  // Balanced material for complex content
        
        // Neutral content maintains original material
        case (_, .neutral): return self
        }
    }
    
    /// Adapt material for content complexity
    func adaptedFor(complexity: LiquidGlassContentAnalyzer.ContentComplexity) -> LiquidGlassTheme.GlassMaterial {
        switch (self, complexity) {
        // Simple content can use more transparent materials
        case (.thick, .simple): return .regular
        case (.regular, .simple): return .thin
        
        // Complex content needs more opaque materials for better separation
        case (.ultraThin, .complex), (.ultraThin, .chaotic): return .thin
        case (.thin, .complex), (.thin, .chaotic): return .regular
        case (.regular, .complex), (.regular, .chaotic): return .thick
        
        // Moderate complexity maintains balance
        default: return self
        }
    }
    
    /// Combined adaptation considering both brightness and complexity
    func adaptedFor(
        brightness: LiquidGlassContentAnalyzer.ContentBrightness,
        complexity: LiquidGlassContentAnalyzer.ContentComplexity
    ) -> LiquidGlassTheme.GlassMaterial {
        return self
            .adaptedFor(brightness: brightness)
            .adaptedFor(complexity: complexity)
    }
    
    /// Get content-adaptive opacity using comprehensive analysis
    func adaptiveOpacity(for contentAnalysis: LiquidGlassContentAnalyzer.ContentAnalysis) -> Double {
        let baseAdaptivity = self.adaptivityFactor
        let contentAdaptivity = contentAnalysis.combinedAdaptiveOpacity
        
        // Blend base material adaptivity with content analysis
        return (baseAdaptivity * 0.6 + contentAdaptivity * 0.4).clamped(to: 0.2...0.95)
    }
    
    /// Get content-adaptive blur radius
    func adaptiveBlurRadius(for contentAnalysis: LiquidGlassContentAnalyzer.ContentAnalysis) -> CGFloat {
        let baseBlur = self.blurRadius
        let contentBlurAdjustment = contentAnalysis.combinedBlurAdjustment
        
        // Apply content-based blur adjustment while respecting Apple's performance guidelines (≤3pt for 60fps)
        return (baseBlur * CGFloat(contentBlurAdjustment)).clamped(to: 0.0...3.0)
    }
}