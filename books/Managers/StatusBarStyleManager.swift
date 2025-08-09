import UIKit
import SwiftUI

/// A global manager to coordinate status bar styling across the app
class StatusBarStyleManager: ObservableObject {
    static let shared = StatusBarStyleManager()
    
    @Published var preferredStyle: UIStatusBarStyle = .default {
        didSet {
            // Notify all view controllers to update their status bar appearance
            DispatchQueue.main.async {
                self.notifyStatusBarUpdate()
            }
        }
    }
    
    private init() {}
    
    /// Updates the status bar style based on the theme's background color luminance
    /// - Parameters:
    ///   - theme: The current theme variant
    ///   - colorScheme: The current color scheme (light/dark mode)
    func updateStyle(for theme: ThemeVariant, colorScheme: ColorScheme) {
        // Get the appropriate background color based on color scheme
        let backgroundColor = colorScheme == .dark 
            ? theme.colorDefinition.background.dark 
            : theme.colorDefinition.background.light
        
        // Calculate the luminance of the background color
        let luminance = calculateLuminance(for: backgroundColor)
        
        // If the background is dark (low luminance), use light content
        // If the background is light (high luminance), use dark content
        // Using 0.5 as the threshold for determining light vs dark
        preferredStyle = luminance < 0.5 ? .lightContent : .darkContent
    }
    
    /// Calculates the relative luminance of a color
    /// Uses the WCAG formula: 0.2126 * R + 0.7152 * G + 0.0722 * B
    /// - Parameter color: The UIColor to calculate luminance for
    /// - Returns: A value between 0 (darkest) and 1 (brightest)
    private func calculateLuminance(for color: UIColor) -> CGFloat {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        // Get the RGB components
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Apply gamma correction (sRGB to linear RGB)
        func gammaCorrect(_ component: CGFloat) -> CGFloat {
            if component <= 0.03928 {
                return component / 12.92
            } else {
                return pow((component + 0.055) / 1.055, 2.4)
            }
        }
        
        let linearRed = gammaCorrect(red)
        let linearGreen = gammaCorrect(green)
        let linearBlue = gammaCorrect(blue)
        
        // Calculate relative luminance using WCAG formula
        return 0.2126 * linearRed + 0.7152 * linearGreen + 0.0722 * linearBlue
    }
    
    private func notifyStatusBarUpdate() {
        // Update all windows' status bar appearance
        for windowScene in UIApplication.shared.connectedScenes {
            if let windowScene = windowScene as? UIWindowScene {
                for window in windowScene.windows {
                    window.rootViewController?.setNeedsStatusBarAppearanceUpdate()
                }
            }
        }
    }
}
