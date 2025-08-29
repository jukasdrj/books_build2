import SwiftUI
import UIKit

// MARK: - Performance Optimization System for Liquid Glass
// Implements caching, adaptive complexity, and animation throttling
// Following Apple's performance best practices for glass effects

// MARK: - Glass Material Caching System
@MainActor
class GlassMaterialCache: ObservableObject {
    static let shared = GlassMaterialCache()
    
    private var materialCache: [String: Material] = [:]
    private var backgroundCache: [String: AnyView] = [:]
    private let maxCacheSize = 50
    
    private init() {}
    
    /// Get cached material or create new one
    func material(for type: LiquidGlassTheme.GlassMaterial, depth: LiquidGlassTheme.GlassDepth) -> Material {
        let key = "\(type)-\(depth)"
        
        if let cached = materialCache[key] {
            return cached
        }
        
        let material = type.material
        
        // Cache management - prevent memory bloat
        if materialCache.count >= maxCacheSize {
            clearOldestEntries()
        }
        
        materialCache[key] = material
        return material
    }
    
    /// Get cached glass background view
    func glassBackground(
        material: LiquidGlassTheme.GlassMaterial,
        depth: LiquidGlassTheme.GlassDepth,
        radius: LiquidGlassTheme.GlassRadius,
        vibrancy: LiquidGlassTheme.VibrancyLevel
    ) -> AnyView {
        let key = "\(material)-\(depth)-\(radius.value)-\(vibrancy)"
        
        if let cached = backgroundCache[key] {
            return cached
        }
        
        let background = AnyView(
            RoundedRectangle(cornerRadius: radius.value)
                .fill(material.material.opacity(material.adaptivityFactor * vibrancy.opacity))
                .blur(radius: material.blurRadius)
                .shadow(
                    color: .black.opacity(depth.shadowOpacity),
                    radius: depth.shadowRadius,
                    x: 0,
                    y: depth.yOffset
                )
        )
        
        // Cache management
        if backgroundCache.count >= maxCacheSize {
            clearOldestBackgrounds()
        }
        
        backgroundCache[key] = background
        return background
    }
    
    /// Clear cache when memory pressure occurs
    func clearCache() {
        materialCache.removeAll()
        backgroundCache.removeAll()
    }
    
    private func clearOldestEntries() {
        let entriesToRemove = materialCache.count - (maxCacheSize * 3 / 4)
        let keysToRemove = Array(materialCache.keys.prefix(entriesToRemove))
        keysToRemove.forEach { materialCache.removeValue(forKey: $0) }
    }
    
    private func clearOldestBackgrounds() {
        let entriesToRemove = backgroundCache.count - (maxCacheSize * 3 / 4)
        let keysToRemove = Array(backgroundCache.keys.prefix(entriesToRemove))
        keysToRemove.forEach { backgroundCache.removeValue(forKey: $0) }
    }
}

// MARK: - Adaptive Glass Renderer
@MainActor
class AdaptiveGlassRenderer: ObservableObject {
    static let shared = AdaptiveGlassRenderer()
    
    @Published private(set) var currentComplexity: GlassComplexity = .full
    @Published private(set) var devicePerformance: DevicePerformance = .high
    
    private init() {
        detectDevicePerformance()
        setupPerformanceMonitoring()
    }
    
    enum GlassComplexity {
        case minimal    // Basic shadows, no blur
        case reduced    // Light blur, simple shadows
        case standard   // Regular blur and shadows
        case full       // All glass effects enabled
        
        var allowsBlur: Bool {
            switch self {
            case .minimal: return false
            case .reduced, .standard, .full: return true
            }
        }
        
        var maxBlurRadius: CGFloat {
            switch self {
            case .minimal: return 0
            case .reduced: return 1.0
            case .standard: return 2.0
            case .full: return 3.0
            }
        }
        
        var allowsVibrancy: Bool {
            switch self {
            case .minimal: return false
            case .reduced, .standard, .full: return true
            }
        }
    }
    
    enum DevicePerformance {
        case low        // Older devices, limited GPU
        case medium     // Mid-range performance  
        case high       // Latest devices, full capability
        
        var recommendedComplexity: GlassComplexity {
            switch self {
            case .low: return .reduced
            case .medium: return .standard
            case .high: return .full
            }
        }
    }
    
    /// Get adaptive material based on device performance
    func adaptiveMaterial(_ original: LiquidGlassTheme.GlassMaterial) -> LiquidGlassTheme.GlassMaterial {
        switch currentComplexity {
        case .minimal:
            return .clear  // Lightest option
        case .reduced:
            return original == .chrome ? .regular : original
        case .standard, .full:
            return original
        }
    }
    
    /// Get adaptive blur radius
    func adaptiveBlurRadius(_ original: CGFloat) -> CGFloat {
        guard currentComplexity.allowsBlur else { return 0 }
        return min(original, currentComplexity.maxBlurRadius)
    }
    
    /// Get adaptive vibrancy level
    func adaptiveVibrancy(_ original: LiquidGlassTheme.VibrancyLevel) -> LiquidGlassTheme.VibrancyLevel {
        guard currentComplexity.allowsVibrancy else { return .subtle }
        
        switch currentComplexity {
        case .minimal: return .subtle
        case .reduced: return original == .maximum ? .prominent : original
        case .standard, .full: return original
        }
    }
    
    private func detectDevicePerformance() {
        #if os(iOS)
        let _ = UIDevice.current
        
        // Detect based on device capabilities
        if ProcessInfo.processInfo.processorCount >= 6 && 
           ProcessInfo.processInfo.physicalMemory >= 4_000_000_000 { // 4GB+
            devicePerformance = .high
        } else if ProcessInfo.processInfo.processorCount >= 4 {
            devicePerformance = .medium
        } else {
            devicePerformance = .low
        }
        #else
        devicePerformance = .high  // Default for other platforms
        #endif
        
        currentComplexity = devicePerformance.recommendedComplexity
    }
    
    private func setupPerformanceMonitoring() {
        // Monitor memory warnings
        #if os(iOS)
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.reduceComplexity()
            }
        }
        #endif
    }
    
    private func reduceComplexity() {
        switch currentComplexity {
        case .full: currentComplexity = .standard
        case .standard: currentComplexity = .reduced
        case .reduced: currentComplexity = .minimal
        case .minimal: break
        }
        
        // Clear cache to free memory
        GlassMaterialCache.shared.clearCache()
    }
    
    /// Force complexity level (for testing or user preference)
    func setComplexity(_ complexity: GlassComplexity) {
        currentComplexity = complexity
    }
}

// MARK: - Animation Throttling Manager
@MainActor
class LiquidGlassAnimationManager: ObservableObject {
    static let shared = LiquidGlassAnimationManager()
    
    private var activeAnimations: Set<String> = []
    private let maxConcurrentAnimations = 3
    private let animationQueue: [(id: String, block: () -> Void)] = []
    
    private init() {}
    
    /// Execute animation with throttling
    func executeAnimation(
        id: String = UUID().uuidString,
        animation: @escaping () -> Void
    ) {
        // If under limit, execute immediately
        if activeAnimations.count < maxConcurrentAnimations {
            activeAnimations.insert(id)
            animation()
            
            // Remove from active after typical animation duration
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.activeAnimations.remove(id)
                self.processQueue()
            }
        } else {
            // Queue for later execution
            // For now, skip queuing to prevent memory buildup
            // In production, implement proper queue management
        }
    }
    
    /// Execute glass transition with performance monitoring
    func performanceAwareTransition<T>(
        value: T,
        animation: LiquidGlassTheme.FluidAnimation = .smooth,
        content: @escaping (T) -> Void
    ) {
        let adaptiveAnimation = AdaptiveGlassRenderer.shared.currentComplexity == .minimal ? 
            LiquidGlassTheme.FluidAnimation.quick : animation
        
        executeAnimation {
            withAnimation(adaptiveAnimation.springAnimation) {
                content(value)
            }
        }
    }
    
    private func processQueue() {
        // Process queued animations when slots become available
        // Implementation would go here for production use
    }
    
    /// Clear all pending animations (memory pressure response)
    func clearAnimationQueue() {
        activeAnimations.removeAll()
    }
}

// MARK: - Performance Monitor
@MainActor
class LiquidGlassPerformanceMonitor: ObservableObject {
    static let shared = LiquidGlassPerformanceMonitor()
    
    @Published private(set) var averageFrameTime: TimeInterval = 0
    @Published private(set) var droppedFrames: Int = 0
    @Published private(set) var memoryUsage: Int64 = 0
    @Published private(set) var isPerformanceAcceptable = true
    
    private var frameTimeHistory: [TimeInterval] = []
    private let maxHistoryCount = 60  // 1 second at 60fps
    private var lastFrameTime = CACurrentMediaTime()
    
    private init() {
        startMonitoring()
    }
    
    func startMonitoring() {
        // Start display link for frame time monitoring
        #if os(iOS)
        let displayLink = CADisplayLink(target: self, selector: #selector(frameUpdate))
        displayLink.add(to: .main, forMode: .common)
        #endif
        
        // Monitor memory usage periodically
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateMemoryUsage()
            }
        }
    }
    
    @objc private func frameUpdate() {
        let currentTime = CACurrentMediaTime()
        let frameTime = currentTime - lastFrameTime
        lastFrameTime = currentTime
        
        // Track frame times
        frameTimeHistory.append(frameTime)
        if frameTimeHistory.count > maxHistoryCount {
            frameTimeHistory.removeFirst()
        }
        
        // Calculate average
        averageFrameTime = frameTimeHistory.reduce(0, +) / Double(frameTimeHistory.count)
        
        // Check for dropped frames (>16.67ms = dropped frame at 60fps)
        if frameTime > 0.0167 {
            droppedFrames += 1
        }
        
        // Update performance status
        isPerformanceAcceptable = averageFrameTime < 0.02 && droppedFrames < 10
        
        // Auto-reduce complexity if performance degrades
        if !isPerformanceAcceptable {
            AdaptiveGlassRenderer.shared.setComplexity(.reduced)
            droppedFrames = 0  // Reset counter after adjustment
        }
    }
    
    private func updateMemoryUsage() {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            memoryUsage = Int64(info.resident_size)
            
            // If memory usage is high, clear caches
            if memoryUsage > 500_000_000 { // 500MB threshold
                GlassMaterialCache.shared.clearCache()
                LiquidGlassAnimationManager.shared.clearAnimationQueue()
            }
        }
    }
    
    /// Get performance report for debugging
    var performanceReport: String {
        """
        Glass Performance Report:
        - Average Frame Time: \(String(format: "%.2f", averageFrameTime * 1000))ms
        - Dropped Frames: \(droppedFrames)
        - Memory Usage: \(ByteCountFormatter().string(fromByteCount: memoryUsage))
        - Performance Acceptable: \(isPerformanceAcceptable ? "✅" : "❌")
        - Current Complexity: \(AdaptiveGlassRenderer.shared.currentComplexity)
        """
    }
}

// MARK: - Enhanced View Extensions with Performance Optimization
extension View {
    /// Performance-optimized liquid glass card
    func optimizedLiquidGlassCard(
        material: LiquidGlassTheme.GlassMaterial = .regular,
        depth: LiquidGlassTheme.GlassDepth = .elevated,
        radius: LiquidGlassTheme.GlassRadius = .comfortable,
        vibrancy: LiquidGlassTheme.VibrancyLevel = .medium
    ) -> some View {
        let renderer = AdaptiveGlassRenderer.shared
        let cache = GlassMaterialCache.shared
        
        return self.background(
            cache.glassBackground(
                material: renderer.adaptiveMaterial(material),
                depth: depth,
                radius: radius,
                vibrancy: renderer.adaptiveVibrancy(vibrancy)
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: radius.value))
    }
    
    /// Performance-aware glass animation
    func performanceAwareGlassTransition<V: Equatable>(
        value: V,
        animation: LiquidGlassTheme.FluidAnimation = .smooth
    ) -> some View {
        self.animation(
            LiquidGlassTheme.respectingUserPreferences(animation).springAnimation,
            value: value
        )
    }
}