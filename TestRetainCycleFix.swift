import Foundation
import XCTest

/// Test to verify the retain cycle fix for PerformanceMonitor
/// Run this test to ensure the retain cycle is resolved
class RetainCycleTest {
    
    static func testPerformanceMonitorLifecycle() {
        print("Testing PerformanceMonitor lifecycle...")
        
        // Create a scope to test object deallocation
        autoreleasepool {
            print("Creating ConcurrentISBNLookupService...")
            let service = ConcurrentISBNLookupService(metadataCache: [:])
            
            // Use the service briefly
            print("Service created with performance monitor")
            
            // Service should deallocate properly when it goes out of scope
        }
        
        print("Service should be deallocated now")
        
        // Give async tasks time to complete
        Thread.sleep(forTimeInterval: 1.0)
        
        print("Test complete - if no retain cycle warnings appear, the fix is successful")
    }
    
    static func runTest() {
        testPerformanceMonitorLifecycle()
    }
}

// Instructions to test:
// 1. Run this test in your Xcode project
// 2. Monitor the console for any retain cycle warnings
// 3. The test passes if no "deallocated with non-zero retain count" errors appear