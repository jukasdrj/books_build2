//
//  ImageCache.swift
//  books
//
//  Created by AI Assistant on [Date]
//

import UIKit
import SwiftUI

/// Singleton image cache for efficient image loading and storage
class ImageCache: @unchecked Sendable {
    static let shared = ImageCache()
    
    private let cache = NSCache<NSString, UIImage>()
    private let ioQueue = DispatchQueue(label: "imageCache", qos: .utility)
    private let operationQueue = OperationQueue()
    
    // Track cache keys manually since NSCache doesn't provide allKeys
    private var cacheKeys = Set<String>()
    private let keysQueue = DispatchQueue(label: "cacheKeys", attributes: .concurrent)
    
    private init() {
        // Configure cache limits with device-appropriate sizing
        configureMemoryLimits()
        
        // Configure operation queue
        operationQueue.maxConcurrentOperationCount = 4
        operationQueue.qualityOfService = .utility
        
        // Listen for memory warnings and app lifecycle events
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryPressure),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillTerminate),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
    }
    
    /// Configure memory limits based on device capabilities
    private func configureMemoryLimits() {
        let physicalMemory = ProcessInfo.processInfo.physicalMemory
        let availableMemory = physicalMemory / (1024 * 1024) // Convert to MB
        
        // Scale cache size based on available memory (iOS device considerations)
        let maxCacheSize: Int
        let maxImageCount: Int
        
        if availableMemory >= 6144 { // 6GB+ devices (Pro models)
            maxCacheSize = 200 * 1024 * 1024 // 200MB
            maxImageCount = 300
        } else if availableMemory >= 4096 { // 4GB+ devices
            maxCacheSize = 150 * 1024 * 1024 // 150MB  
            maxImageCount = 200
        } else if availableMemory >= 3072 { // 3GB+ devices
            maxCacheSize = 100 * 1024 * 1024 // 100MB
            maxImageCount = 150
        } else { // Lower memory devices
            maxCacheSize = 75 * 1024 * 1024 // 75MB
            maxImageCount = 100
        }
        
        cache.countLimit = maxImageCount
        cache.totalCostLimit = maxCacheSize
        
        print("[ImageCache] Configured for device with \(availableMemory)MB RAM: \(maxImageCount) images, \(maxCacheSize / (1024*1024))MB limit")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    /// Retrieve cached image for URL
    func image(for url: String) -> UIImage? {
        return cache.object(forKey: url as NSString)
    }
    
    /// Cache image for URL with automatic cost calculation
    func cache(image: UIImage, for url: String) {
        ioQueue.async { [weak self] in
            guard let self = self else { return }
            let cost = self.calculateImageCost(image)
            self.cache.setObject(image, forKey: url as NSString, cost: cost)
            
            // Track the key
            self.keysQueue.async(flags: .barrier) { [weak self] in
                self?.cacheKeys.insert(url)
            }
        }
    }
    
    /// Load image from URL with caching
    func loadImage(from urlString: String) async throws -> UIImage {
        // Check cache first
        if let cachedImage = image(for: urlString) {
            return cachedImage
        }
        
        // Validate URL
        guard let url = URL(string: urlString) else {
            throw ImageCacheError.invalidURL
        }
        
        // Download image
        let (data, response) = try await URLSession.shared.data(from: url)
        
        // Validate response
        if let httpResponse = response as? HTTPURLResponse {
            guard httpResponse.statusCode == 200 else {
                throw ImageCacheError.httpError(httpResponse.statusCode)
            }
        }
        
        // Create image
        guard let uiImage = UIImage(data: data) else {
            throw ImageCacheError.invalidImageData
        }
        
        // Cache the image
        cache(image: uiImage, for: urlString)
        
        return uiImage
    }
    
    /// Calculate the memory cost of an image
    private func calculateImageCost(_ image: UIImage) -> Int {
        guard let cgImage = image.cgImage else { return 0 }
        return cgImage.width * cgImage.height * 4 // 4 bytes per pixel for RGBA
    }
    
    /// Clear all cached images
    /// Manually clear all cached images
    func clear() {
        cache.removeAllObjects()
        keysQueue.async(flags: .barrier) { [weak self] in
            self?.cacheKeys.removeAll()
        }
    }
    
    @objc private func handleMemoryPressure() {
        print("[ImageCache] Memory pressure detected - performing aggressive cleanup")
        
        // Clear 75% of cache during memory pressure
        let targetCount = cache.countLimit / 4 // Keep only 25%
        
        keysQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            // Get current keys and remove oldest 75%
            let currentKeys = Array(self.cacheKeys)
            let keysToRemove = currentKeys.dropLast(targetCount)
            
            for key in keysToRemove {
                self.cache.removeObject(forKey: key as NSString)
                self.cacheKeys.remove(key)
            }
            
            print("[ImageCache] Cleared \(keysToRemove.count) images, \(self.cacheKeys.count) remaining")
        }
        
        // Notify other components about memory pressure
        NotificationCenter.default.post(name: .memoryPressureDetected, object: nil)
    }
    
    @objc private func applicationDidEnterBackground() {
        print("[ImageCache] App backgrounded - reducing cache size by 50%")
        
        // Reduce cache by 50% when app goes to background
        let targetCount = cache.countLimit / 2
        
        keysQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            let currentKeys = Array(self.cacheKeys)
            if currentKeys.count > targetCount {
                let keysToRemove = currentKeys.dropLast(targetCount)
                
                for key in keysToRemove {
                    self.cache.removeObject(forKey: key as NSString)
                    self.cacheKeys.remove(key)
                }
                
                print("[ImageCache] Background cleanup: removed \(keysToRemove.count) images")
            }
        }
    }
    
    @objc private func applicationWillTerminate() {
        print("[ImageCache] App terminating - clearing all cached images")
        clear()
    }
    
    @objc private func clearCache() {
        // Legacy method - redirect to new memory pressure handling
        handleMemoryPressure()
    }
    
    /// Get cache statistics
    var cacheInfo: (count: Int, estimatedSize: String) {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        
        var count = 0
        var totalSize = 0
        
        keysQueue.sync {
            count = cacheKeys.count
            
            // Estimate total size based on cached keys
            for key in cacheKeys {
                if let image = cache.object(forKey: key as NSString) {
                    totalSize += calculateImageCost(image)
                }
            }
        }
        
        return (count: count, estimatedSize: formatter.string(fromByteCount: Int64(totalSize)))
    }
}

/// Errors that can occur during image caching operations
enum ImageCacheError: LocalizedError {
    case invalidURL
    case httpError(Int)
    case invalidImageData
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL provided"
        case .httpError(let code):
            return "HTTP error with status code: \(code)"
        case .invalidImageData:
            return "Unable to create image from downloaded data"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Memory Pressure Notifications

extension Notification.Name {
    static let memoryPressureDetected = Notification.Name("memoryPressureDetected")
}