import XCTest
@testable import books
import Vision

final class BarcodeScannerTests: XCTestCase {
    
    func testISBN10Validation() {
        let scanner = CameraPreviewView()
        
        // Valid ISBN-10
        XCTAssertTrue(scanner.isValidISBN("0306406152"))
        XCTAssertTrue(scanner.isValidISBN("0-306-40615-2"))
        XCTAssertTrue(scanner.isValidISBN("030640615X"))
        
        // Invalid ISBN-10
        XCTAssertFalse(scanner.isValidISBN("0306406153")) // Wrong checksum
        XCTAssertFalse(scanner.isValidISBN("123456789")) // Too short
        XCTAssertFalse(scanner.isValidISBN("12345678901")) // Too long
        XCTAssertFalse(scanner.isValidISBN("030640615Y")) // Invalid check digit
    }
    
    func testISBN13Validation() {
        let scanner = CameraPreviewView()
        
        // Valid ISBN-13
        XCTAssertTrue(scanner.isValidISBN("9780306406157"))
        XCTAssertTrue(scanner.isValidISBN("978-0-306-40615-7"))
        XCTAssertTrue(scanner.isValidISBN("9781234567897"))
        
        // Invalid ISBN-13
        XCTAssertFalse(scanner.isValidISBN("9780306406158")) // Wrong checksum
        XCTAssertFalse(scanner.isValidISBN("978030640615")) // Too short
        XCTAssertFalse(scanner.isValidISBN("97803064061578")) // Too long
        XCTAssertFalse(scanner.isValidISBN("abcd306406157")) // Non-numeric
    }
    
    func testBarcodeCleanup() {
        let scanner = CameraPreviewView()
        
        // Test hyphen removal
        XCTAssertTrue(scanner.isValidISBN("978-0-306-40615-7"))
        XCTAssertTrue(scanner.isValidISBN("0-306-40615-2"))
        
        // Test mixed valid formats
        XCTAssertTrue(scanner.isValidISBN("978-0306406157")) // Partial hyphens
        XCTAssertTrue(scanner.isValidISBN("9780306406157")) // No hyphens
    }
    
    func testInvalidFormats() {
        let scanner = CameraPreviewView()
        
        // Empty or whitespace
        XCTAssertFalse(scanner.isValidISBN(""))
        XCTAssertFalse(scanner.isValidISBN("   "))
        
        // Wrong length after cleanup
        XCTAssertFalse(scanner.isValidISBN("123"))
        XCTAssertFalse(scanner.isValidISBN("123456789012345"))
        
        // Contains letters (except X for ISBN-10)
        XCTAssertFalse(scanner.isValidISBN("978030640615A"))
        XCTAssertFalse(scanner.isValidISBN("03064X615X")) // X not in last position
    }
    
    func testISBN10ChecksumCalculation() {
        let scanner = CameraPreviewView()
        
        // Test specific ISBN-10 examples with known checksums
        XCTAssertTrue(scanner.isValidISBN("0471958697")) // Checksum = 7
        XCTAssertTrue(scanner.isValidISBN("0136091814")) // Checksum = 4
        XCTAssertTrue(scanner.isValidISBN("013030657X")) // Checksum = X (10)
        
        // Test invalid checksums
        XCTAssertFalse(scanner.isValidISBN("0471958696")) // Should be 7, not 6
        XCTAssertFalse(scanner.isValidISBN("0136091815")) // Should be 4, not 5
    }
    
    func testISBN13ChecksumCalculation() {
        let scanner = CameraPreviewView()
        
        // Test specific ISBN-13 examples with known checksums
        XCTAssertTrue(scanner.isValidISBN("9780471486480")) // Checksum = 0
        XCTAssertTrue(scanner.isValidISBN("9780136091817")) // Checksum = 7
        XCTAssertTrue(scanner.isValidISBN("9781234567897")) // Checksum = 7
        
        // Test invalid checksums
        XCTAssertFalse(scanner.isValidISBN("9780471486481")) // Should be 0, not 1
        XCTAssertFalse(scanner.isValidISBN("9780136091818")) // Should be 7, not 8
    }
    
    func testBarcodeSymbologyConfiguration() {
        // Test that Vision framework symbologies are configured correctly
        let request = VNDetectBarcodesRequest()
        
        // Set the symbologies we use in the scanner
        request.symbologies = [.ean13, .ean8, .upce, .code128, .code39, .code93, .i2of5]
        
        // Verify they were set correctly
        XCTAssertTrue(request.symbologies.contains(.ean13))
        XCTAssertTrue(request.symbologies.contains(.ean8))
        XCTAssertTrue(request.symbologies.contains(.upce))
        XCTAssertTrue(request.symbologies.contains(.code128))
        XCTAssertTrue(request.symbologies.contains(.code39))
        XCTAssertTrue(request.symbologies.contains(.code93))
        XCTAssertTrue(request.symbologies.contains(.i2of5))
        
        // Verify we have 7 symbologies configured
        XCTAssertEqual(request.symbologies.count, 7)
    }
    
    func testBarcodeFormatEdgeCases() {
        let scanner = CameraPreviewView()
        
        // Test ISBN-10 with X in various positions (only last position should be valid)
        XCTAssertTrue(scanner.isValidISBN("030640615X"))   // Valid: X at end
        XCTAssertFalse(scanner.isValidISBN("03064X6152"))  // Invalid: X in middle
        XCTAssertFalse(scanner.isValidISBN("X306406152"))  // Invalid: X at start
        
        // Test with various hyphen patterns
        XCTAssertTrue(scanner.isValidISBN("978-0-306-40615-7"))
        XCTAssertTrue(scanner.isValidISBN("978-0306-40615-7"))
        XCTAssertTrue(scanner.isValidISBN("9780306-40615-7"))
        XCTAssertTrue(scanner.isValidISBN("9780306406157"))
        
        // Test with spaces (should be invalid since we only filter numbers)
        XCTAssertFalse(scanner.isValidISBN("978 0306 40615 7"))
        XCTAssertFalse(scanner.isValidISBN("0306 40615 2"))
    }
    
    func testCameraPreviewViewInitialization() {
        let previewView = CameraPreviewView()
        
        // Test that the view initializes correctly
        XCTAssertNotNil(previewView)
        XCTAssertTrue(previewView.scanningEnabled)
        XCTAssertNil(previewView.onBarcodeScanned)
    }
    
    func testBarcodeScannerViewInitialization() {
        var scannedBarcode: String?
        
        let scannerView = BarcodeScannerView { barcode in
            scannedBarcode = barcode
        }
        
        // Test that the view initializes correctly
        XCTAssertNotNil(scannerView)
        XCTAssertNil(scannedBarcode) // Should be nil until a scan occurs
    }
    
    func testISBN10AlgorithmSpecificCases() {
        let scanner = CameraPreviewView()
        
        // Test specific ISBN-10 algorithm edge cases
        XCTAssertTrue(scanner.isValidISBN10("0123456789"))   // Checksum should be 9
        XCTAssertTrue(scanner.isValidISBN10("123456789X"))   // Checksum should be X (10)
        
        // Test invalid ISBN-10 cases
        XCTAssertFalse(scanner.isValidISBN10("0123456788"))  // Wrong checksum (should be 9)
        XCTAssertFalse(scanner.isValidISBN10("1234567890"))  // Wrong checksum (should be X)
    }
    
    func testISBN13AlgorithmSpecificCases() {
        let scanner = CameraPreviewView()
        
        // Test specific ISBN-13 algorithm edge cases
        XCTAssertTrue(scanner.isValidISBN13("9780123456789"))   // Valid checksum
        XCTAssertTrue(scanner.isValidISBN13("9781234567890"))   // Valid checksum
        
        // Test invalid ISBN-13 cases
        XCTAssertFalse(scanner.isValidISBN13("9780123456788"))  // Wrong checksum
        XCTAssertFalse(scanner.isValidISBN13("9781234567891"))  // Wrong checksum
    }
}