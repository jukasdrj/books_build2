import SwiftUI

// A central place for all our design system values
enum Theme {

    // MARK: - Colors
    // This enum makes it easy and safe to use our custom colors from the Asset Catalog.
    // Example Usage: `Theme.Color.PrimaryAction`
    enum Color {
        static let PrimaryAction = SwiftUI.Color("PrimaryAction")
        static let Surface = SwiftUI.Color("Surface")
        static let CardBackground = SwiftUI.Color("CardBackground")
        static let PrimaryText = SwiftUI.Color("PrimaryText")
        static let SecondaryText = SwiftUI.Color("SecondaryText")
        static let AccentHighlight = SwiftUI.Color("AccentHighlight")
    }
    
    // MARK: - Fonts (Placeholder for next step)
    // We will add our custom fonts here later.
    
}