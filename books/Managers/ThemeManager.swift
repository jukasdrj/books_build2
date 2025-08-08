import SwiftUI
import Observation

#if os(iOS)
import UIKit
#endif

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
        // Force update the static theme reference
        Color.theme = AppColorTheme(variant: currentTheme)
        
        // Apply theme to system UI elements with a slight delay to ensure theme is updated
        #if os(iOS)
        DispatchQueue.main.async {
            self.updateNavigationBarAppearance()
            self.updateTabBarAppearance()
            self.updateStatusBarStyle()
            
            // Force all windows to refresh their appearance
            self.forceRefreshAllWindows()
        }
        #endif
    }
    
    /// Public method to refresh theme when system appearance changes
    func refreshThemeForAppearanceChange() {
        updateAppColorTheme()
    }
    
    func switchTheme(to theme: ThemeVariant, animated: Bool = true) {
        if animated {
            withAnimation(.easeInOut(duration: 0.6)) {
                currentTheme = theme
            }
        } else {
            currentTheme = theme
        }
        
        // Force refresh system UI elements after theme change
        #if os(iOS)
        DispatchQueue.main.asyncAfter(deadline: .now() + (animated ? 0.1 : 0.0)) {
            self.refreshSystemUI()
        }
        #endif
    }
    
    // MARK: - iOS System UI Theming
    
    #if os(iOS)
    private func updateNavigationBarAppearance() {
        let theme = Color.theme
        
        // Configure navigation bar appearance
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        
        // Background colors
        navBarAppearance.backgroundColor = UIColor(theme.surface)
        navBarAppearance.shadowColor = UIColor(theme.outline.opacity(0.1))
        
        // Title text attributes
        navBarAppearance.titleTextAttributes = [
            .foregroundColor: UIColor(theme.primaryText),
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]
        
        // Large title text attributes
        navBarAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(theme.primaryText),
            .font: UIFont.systemFont(ofSize: 32, weight: .bold)
        ]
        
        // Button appearance
        navBarAppearance.buttonAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(theme.primary)
        ]
        navBarAppearance.doneButtonAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(theme.primary)
        ]
        
        // Apply to all navigation bar states
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        
        // Set tint color for navigation controls
        UINavigationBar.appearance().tintColor = UIColor(theme.primary)
        
        // Force existing navigation bars to update immediately
        DispatchQueue.main.async {
            for windowScene in UIApplication.shared.connectedScenes {
                if let windowScene = windowScene as? UIWindowScene {
                    for window in windowScene.windows {
                        self.updateNavigationBarsInWindow(window)
                    }
                }
            }
        }
    }
    
    private func updateNavigationBarsInWindow(_ window: UIWindow) {
        func updateNavigationController(_ navController: UINavigationController) {
            let theme = Color.theme
            
            // Apply appearance to the specific navigation controller
            navController.navigationBar.standardAppearance = UINavigationBar.appearance().standardAppearance
            navController.navigationBar.compactAppearance = UINavigationBar.appearance().compactAppearance
            navController.navigationBar.scrollEdgeAppearance = UINavigationBar.appearance().scrollEdgeAppearance
            navController.navigationBar.tintColor = UIColor(theme.primary)
            
            // Force layout update
            navController.navigationBar.setNeedsLayout()
            navController.navigationBar.layoutIfNeeded()
        }
        
        func traverseViewControllers(_ vc: UIViewController) {
            if let navController = vc as? UINavigationController {
                updateNavigationController(navController)
            }
            
            // Check children
            for child in vc.children {
                traverseViewControllers(child)
            }
            
            // Check presented controllers
            if let presented = vc.presentedViewController {
                traverseViewControllers(presented)
            }
        }
        
        if let rootVC = window.rootViewController {
            traverseViewControllers(rootVC)
        }
    }
    
    private func updateTabBarAppearance() {
        let theme = Color.theme
        
        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        
        // Background color
        tabBarAppearance.backgroundColor = UIColor(theme.surface)
        tabBarAppearance.shadowColor = UIColor(theme.outline.opacity(0.1))
        
        // Tab item colors
        tabBarAppearance.stackedLayoutAppearance.normal.iconColor = UIColor(theme.secondaryText)
        tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(theme.secondaryText)
        ]
        
        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = UIColor(theme.primary)
        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(theme.primary)
        ]
        
        // Apply to tab bar
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        // Set tint colors
        UITabBar.appearance().tintColor = UIColor(theme.primary)
        UITabBar.appearance().unselectedItemTintColor = UIColor(theme.secondaryText)
        
        // Force existing tab bars to update immediately
        DispatchQueue.main.async {
            for windowScene in UIApplication.shared.connectedScenes {
                if let windowScene = windowScene as? UIWindowScene {
                    for window in windowScene.windows {
                        self.updateTabBarsInWindow(window)
                    }
                }
            }
        }
    }
    
    private func updateTabBarsInWindow(_ window: UIWindow) {
        func updateTabBarController(_ tabController: UITabBarController) {
            let theme = Color.theme
            
            // Apply appearance to the specific tab bar controller
            tabController.tabBar.standardAppearance = UITabBar.appearance().standardAppearance
            tabController.tabBar.scrollEdgeAppearance = UITabBar.appearance().scrollEdgeAppearance
            tabController.tabBar.tintColor = UIColor(theme.primary)
            tabController.tabBar.unselectedItemTintColor = UIColor(theme.secondaryText)
            
            // Force layout update
            tabController.tabBar.setNeedsLayout()
            tabController.tabBar.layoutIfNeeded()
        }
        
        func traverseViewControllers(_ vc: UIViewController) {
            if let tabController = vc as? UITabBarController {
                updateTabBarController(tabController)
            }
            
            // Check children
            for child in vc.children {
                traverseViewControllers(child)
            }
            
            // Check presented controllers
            if let presented = vc.presentedViewController {
                traverseViewControllers(presented)
            }
        }
        
        if let rootVC = window.rootViewController {
            traverseViewControllers(rootVC)
        }
    }
    
    private func updateStatusBarStyle() {
        Task { @MainActor in
            // Update status bar style based on theme and color scheme
            let colorScheme = UITraitCollection.current.userInterfaceStyle
            let theme = Color.theme
            
            // Determine if we need light or dark content
            // For most themes, we'll use dark content on light backgrounds and light content on dark backgrounds
            let preferredStyle: UIStatusBarStyle = colorScheme == .dark ? .lightContent : .darkContent
            
            // Update all windows' status bar style
            for windowScene in UIApplication.shared.connectedScenes {
                if let windowScene = windowScene as? UIWindowScene {
                    for window in windowScene.windows {
                        window.rootViewController?.setNeedsStatusBarAppearanceUpdate()
                    }
                }
            }
        }
    }
    
    /// Force refresh all system UI elements when theme changes
    func refreshSystemUI() {
        #if os(iOS)
        Task { @MainActor in
            updateNavigationBarAppearance()
            updateTabBarAppearance()
            updateStatusBarStyle()
            forceRefreshAllWindows()
        }
        #endif
    }
    
    private func forceRefreshAllWindows() {
        #if os(iOS)
        // Force all view controllers to update their appearance
        for windowScene in UIApplication.shared.connectedScenes {
            if let windowScene = windowScene as? UIWindowScene {
                for window in windowScene.windows {
                    // Clear any cached UIKit appearances
                    window.overrideUserInterfaceStyle = window.overrideUserInterfaceStyle
                    
                    // Force refresh status bar
                    window.rootViewController?.setNeedsStatusBarAppearanceUpdate()
                    
                    // Force navigation controllers to refresh
                    if let navController = window.rootViewController as? UINavigationController {
                        navController.navigationBar.setNeedsLayout()
                        navController.navigationBar.layoutIfNeeded()
                    }
                    
                    // Force tab bar controllers to refresh
                    if let tabController = window.rootViewController as? UITabBarController {
                        tabController.tabBar.setNeedsLayout()
                        tabController.tabBar.layoutIfNeeded()
                    }
                    
                    // Recursively update all view controllers
                    updateViewControllerAppearance(window.rootViewController)
                    
                    // Force window redraw
                    window.setNeedsDisplay()
                    window.layoutIfNeeded()
                }
            }
        }
        #endif
    }
    
    private func updateViewControllerAppearance(_ viewController: UIViewController?) {
        #if os(iOS)
        guard let viewController = viewController else { return }
        
        viewController.setNeedsStatusBarAppearanceUpdate()
        viewController.view.setNeedsDisplay()
        
        // Recursively update child view controllers
        for child in viewController.children {
            updateViewControllerAppearance(child)
        }
        
        // Handle presented view controllers
        if let presented = viewController.presentedViewController {
            updateViewControllerAppearance(presented)
        }
        #endif
    }
    #endif
}