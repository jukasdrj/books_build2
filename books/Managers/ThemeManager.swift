import SwiftUI
import Observation

@Observable
class ThemeManager {
    static let shared = ThemeManager()
    
    var currentTheme: ThemeVariant {
        didSet {
            saveTheme()
            updateAppColorTheme()
        }
    }
    
    private init() {
        self.currentTheme = Self.loadSavedTheme()
        updateAppColorTheme()
    }
    
    private func saveTheme() {
        UserDefaults.standard.set(currentTheme.rawValue, forKey: "selectedTheme")
    }
    
    private static func loadSavedTheme() -> ThemeVariant {
        let savedTheme = UserDefaults.standard.string(forKey: "selectedTheme") ?? ThemeVariant.purpleBoho.rawValue
        return ThemeVariant(rawValue: savedTheme) ?? .purpleBoho
    }
    
    private func updateAppColorTheme() {
        Color.theme = AppColorTheme(variant: currentTheme)
    }
    
    func switchTheme(to theme: ThemeVariant, animated: Bool = true) {
        if animated {
            withAnimation(.easeInOut(duration: 0.6)) {
                currentTheme = theme
            }
        } else {
            currentTheme = theme
        }
    }
}