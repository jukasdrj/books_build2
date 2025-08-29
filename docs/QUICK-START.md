# ⚡ **QUICK START**

*For developers jumping into this project*

## **Build & Run** (30 seconds)

```bash
open books.xcodeproj
# Select iPhone 16 Pro simulator
# ⌘+R to run
```

**Expected**: App launches successfully with Material Design 3 themes + new Liquid Glass themes available.

## **Key Files** (Know these 4 files)

1. **`CLAUDE.md`** - Complete project context (read this first)
2. **`books/Theme/ThemeSystemBridge.swift`** - How themes work
3. **`books/Theme/LiquidGlassComponents.swift`** - New components ready to use
4. **`docs/PHASE-STATUS.md`** - Current implementation status

## **Adding Features** (Pick your approach)

### **New Features** (Use Liquid Glass)
```swift
@Environment(\.unifiedThemeStore) private var themeStore

LiquidGlassButton("Add Feature") {
    // Your action
}
```

### **Existing Features** (Gradual Migration)
```swift
if themeStore.currentTheme.isLiquidGlass {
    LiquidGlassButton("Action") { /* action */ }
} else {
    Button("Action") { /* action */ }.buttonStyle(.borderedProminent)
}
```

## **Testing**

```swift
// Switch themes in Settings to test both systems
// Liquid Glass themes: Crystal Clear, Aurora Glow, etc.
// Material Design 3 themes: Purple Boho, Forest Sage, etc.
```

## **Problems?**

1. **Build issues**: Check if you have iOS 26 SDK + Xcode 16.4+
2. **Theme issues**: All themes should work - if not, check `UnifiedThemeStore`
3. **Performance issues**: Use `.optimizedLiquidGlassCard()` instead of `.liquidGlassCard()`

---

*This is all you need to know to be productive immediately.*