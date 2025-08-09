//
//  ImageCache.swift
//  books
//
//  Created by AI Assistant on [Date]
//

import UIKit
import SwiftUI

/// Singleton image cache for efficient image loading and storage
class ImageCache {
    static let shared = ImageCache()
    
    private let cache = NSCache<NSString, UIImage>()
    private let ioQueue = DispatchQueue(label: "imageCache", qos: .utility)
    private let operationQueue = OperationQueue()
    
    // Track cache keys manually since NSCache doesn't provide allKeys
    private var cacheKeys = Set<String>()
    private let keysQueue = DispatchQueue(label: "cacheKeys", attributes: .concurrent)
    
    private init() {
        // Configure cache limits
        cache.countLimit = 200 // Maximum number of images
        cache.totalCostLimit = 150 * 1024 * 1024 // 150MB limit
        
        // Configure operation queue
        operationQueue.maxConcurrentOperationCount = 4
        operationQueue.qualityOfService = .utility
        
        // Listen for memory warnings
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearCache),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
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
            let cost = self?.calculateImageCost(image) ?? 0
            self?.cache.setObject(image, forKey: url as NSString, cost: cost)
            
            // Track the key
            self?.keysQueue.async(flags: .barrier) {
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
    @objc private func clearCache() {
        cache.removeAllObjects()
        keysQueue.async(flags: .barrier) { [weak self] in
            self?.cacheKeys.removeAll()
        }
        // Cleared all cached images due to memory warning
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