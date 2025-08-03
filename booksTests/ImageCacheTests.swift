//
// NEW: booksTests/ImageCacheTests.swift
//
import Testing
import UIKit
@testable import books

@Suite("Image Cache Tests")
struct ImageCacheTests {
    
    @Test("ImageCache Singleton - Should provide shared instance")
    func testImageCacheSingleton() {
        let cache1 = ImageCache.shared
        let cache2 = ImageCache.shared
        
        #expect(cache1 === cache2, "Should be the same singleton instance")
    }
    
    @Test("ImageCache Storage and Retrieval - Should cache images correctly")
    func testImageCacheStorageAndRetrieval() throws {
        let cache = ImageCache.shared
        let testURL = "https://example.com/test-image.jpg"
        
        // Create a test image
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        let testImage = renderer.image { context in
            UIColor.red.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        
        // Cache should be empty initially
        #expect(cache.image(for: testURL) == nil)
        
        // Cache the image
        cache.cache(image: testImage, for: testURL)
        
        // Should now retrieve the cached image
        let cachedImage = cache.image(for: testURL)
        #expect(cachedImage != nil)
        #expect(cachedImage?.size == testImage.size)
    }
    
    @Test("ImageCacheError - Should have correct descriptions")
    func testImageCacheError() throws {
        let invalidURLError = ImageCacheError.invalidURL
        let httpError = ImageCacheError.httpError(404)
        let invalidImageError = ImageCacheError.invalidImageData
        
        #expect(invalidURLError.errorDescription == "Invalid URL provided")
        #expect(httpError.errorDescription == "HTTP error with status code: 404")
        #expect(invalidImageError.errorDescription == "Unable to create image from downloaded data")
    }
    
    @Test("ImageCache Info - Should provide cache statistics")
    func testImageCacheInfo() throws {
        let cache = ImageCache.shared
        let info = cache.cacheInfo
        
        #expect(info.count >= 0) // Should be non-negative
        #expect(!info.estimatedSize.isEmpty) // Should have some size string
    }
}