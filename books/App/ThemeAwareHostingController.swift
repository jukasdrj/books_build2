import SwiftUI
import UIKit

/// Custom UIHostingController that properly handles status bar appearance based on theme
class ThemeAwareHostingController<Content: View>: UIHostingController<Content> {
    
    /// Track if we need to force a refresh
    private var needsThemeRefresh = false
    
    override init(rootView: Content) {
        super.init(rootView: rootView)
        setupThemeObserver()
        updateBackgroundColor()
    }
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupThemeObserver() {
        // Listen for theme changes
        NotificationCenter.default.addObserver(
            forName: .themeDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleThemeChange()
        }
        
        // Listen for system color scheme changes
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        // Always return the current value from StatusBarStyleManager
        // This ensures we're always using the most up-to-date style
        let currentStyle = StatusBarStyleManager.shared.preferredStyle
        
        // If we need a theme refresh, mark it for the next layout cycle
        if needsThemeRefresh {
            DispatchQueue.main.async { [weak self] in
                self?.forceViewRefresh()
            }
        }
        
        return currentStyle
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        // Update status bar when color scheme changes
        if traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
            setNeedsStatusBarAppearanceUpdate()
            
            // Also refresh the theme manager when system appearance changes
            ThemeManager.shared.refreshThemeForAppearanceChange()
            
            // Update background color for new color scheme
            updateBackgroundColor()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Ensure background color is set when view loads
        updateBackgroundColor()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Always ensure status bar style is current
        setNeedsStatusBarAppearanceUpdate()
    }
    
    // MARK: - Theme Management
    
    /// Handles theme change notifications
    private func handleThemeChange() {
        // Mark that we need a refresh
        needsThemeRefresh = true
        
        // Update status bar appearance
        setNeedsStatusBarAppearanceUpdate()
        
        // Update background color to match new theme
        updateBackgroundColor()
        
        // Force a view refresh
        forceViewRefresh()
    }
    
    /// Forces the SwiftUI view to refresh
    private func forceViewRefresh() {
        needsThemeRefresh = false
        
        // Force the hosting controller to re-evaluate its content
        // This triggers SwiftUI to re-render with the new theme
        if let window = view.window {
            // Trigger a layout pass
            view.setNeedsLayout()
            view.layoutIfNeeded()
            
            // Force SwiftUI content to update
            // This is a bit of a hack but ensures the SwiftUI content refreshes
            view.alpha = 0.99999
            UIView.animate(withDuration: 0.1) {
                self.view.alpha = 1.0
            }
        }
    }
    
    /// Updates the hosting controller's background color to match the current theme
    func updateBackgroundColor() {
        // Get the current theme
        let theme = Color.theme
        
        // Determine the current color scheme
        let colorScheme: ColorScheme = traitCollection.userInterfaceStyle == .dark ? .dark : .light
        
        // Get the appropriate background color
        let backgroundColor = colorScheme == .dark
            ? theme.variant.colorDefinition.background.dark
            : theme.variant.colorDefinition.background.light
        
        // Apply the background color to the view
        view.backgroundColor = backgroundColor
        
        // Also update the safe area background color
        // This ensures the entire screen matches the theme
        if #available(iOS 15.0, *) {
            // For iOS 15+, we can use the safeAreaRegions
            self.safeAreaRegions = .all
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
