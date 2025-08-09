import UIKit

extension UIColor {
    /// Calculates the perceived luminance of the color using the standard formula
    /// Luminance = 0.299 * R + 0.587 * G + 0.114 * B
    /// These coefficients represent the human eye's sensitivity to different color channels
    var luminance: CGFloat {
        // Get the RGB components of the color
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        // Extract RGB values
        // getRed returns true if successful, false if color space doesn't support RGB
        if !self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            // If we can't get RGB values (e.g., for patterns or certain color spaces),
            // try converting to RGB color space first
            guard let rgbColor = self.cgColor.converted(
                to: CGColorSpace(name: CGColorSpace.sRGB)!,
                intent: .defaultIntent,
                options: nil
            ),
            let components = rgbColor.components,
            components.count >= 3 else {
                // Default to middle luminance if conversion fails
                return 0.5
            }
            
            red = components[0]
            green = components[1]
            blue = components[2]
        }
        
        // Calculate luminance using the standard formula
        // These weights account for human perception where green appears brightest,
        // red is medium, and blue appears darkest
        let luminance = (0.299 * red) + (0.587 * green) + (0.114 * blue)
        
        return luminance
    }
    
    /// Determines if the color is considered "light" based on its luminance
    /// Returns true if luminance > 0.5, indicating a light color that would
    /// need dark text/UI elements for contrast
    var isLight: Bool {
        return luminance > 0.5
    }
    
    /// Convenience property that returns the inverse of isLight
    /// Useful for checking if a color is dark
    var isDark: Bool {
        return !isLight
    }
    
    /// Returns the recommended status bar style for this background color
    /// Light colors need dark status bar (.default), dark colors need light status bar (.lightContent)
    var recommendedStatusBarStyle: UIStatusBarStyle {
        return isLight ? .default : .lightContent
    }
    
    /// Returns a contrasting color (black or white) suitable for text on this background
    var contrastingColor: UIColor {
        return isLight ? .black : .white
    }
    
    /// Returns the luminance as a percentage string for debugging
    var luminanceDescription: String {
        return String(format: "%.1f%%", luminance * 100)
    }
}

// MARK: - SwiftUI Color Bridge
import SwiftUI

extension Color {
    /// Convenience initializer to get UIColor from SwiftUI Color and calculate luminance
    var luminance: CGFloat {
        return UIColor(self).luminance
    }
    
    /// Determines if the SwiftUI color is light
    var isLight: Bool {
        return UIColor(self).isLight
    }
    
    /// Determines if the SwiftUI color is dark
    var isDark: Bool {
        return UIColor(self).isDark
    }
    
    /// Returns the recommended status bar style for this background color
    var recommendedStatusBarStyle: UIStatusBarStyle {
        return UIColor(self).recommendedStatusBarStyle
    }
}
