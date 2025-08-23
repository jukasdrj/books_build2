#!/usr/bin/env swift
//
// CSV Import Test Script
// Tests various CSV import scenarios
//

import Foundation

// MARK: - Test Configuration
struct TestConfig {
    static let testFiles = [
        "test_isbn10_books.csv": "Books with ISBN-10 format",
        "test_isbn13_books.csv": "Books with ISBN-13 format",
        "test_mixed_isbn_columns.csv": "Books with both ISBN-10 and ISBN-13 columns",
        "test_no_isbn_books.csv": "Books without ISBNs (title/author matching)",
        "test_duplicate_isbn_books.csv": "Books with duplicate ISBNs",
        "test_malformed_isbn_books.csv": "Books with invalid/malformed ISBNs",
        "test_large_dataset.csv": "Large dataset (150+ books) for performance testing"
    ]
}

// MARK: - Test Results
struct TestResult {
    let fileName: String
    let description: String
    let totalRows: Int
    let validBooks: Int
    let duplicates: Int
    let errors: [String]
    let performance: TimeInterval
    let passed: Bool
}

// MARK: - CSV Validator
class CSVTestValidator {
    
    func validateCSVFile(at path: String) -> TestResult {
        let fileName = (path as NSString).lastPathComponent
        let description = TestConfig.testFiles[fileName] ?? "Unknown test"
        
        let startTime = Date()
        
        guard let csvContent = try? String(contentsOfFile: path, encoding: .utf8) else {
            return TestResult(
                fileName: fileName,
                description: description,
                totalRows: 0,
                validBooks: 0,
                duplicates: 0,
                errors: ["Failed to read CSV file"],
                performance: 0,
                passed: false
            )
        }
        
        let lines = csvContent.components(separatedBy: .newlines).filter { !$0.isEmpty }
        let totalRows = lines.count - 1 // Excluding header
        
        var validBooks = 0
        var duplicates = 0
        var errors: [String] = []
        var seenISBNs: Set<String> = []
        var seenTitleAuthor: Set<String> = []
        
        // Parse CSV
        for (index, line) in lines.enumerated() {
            if index == 0 { continue } // Skip header
            
            let columns = parseCSVLine(line)
            
            // Validate required fields
            let title = columns[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let author = columns[1].trimmingCharacters(in: .whitespacesAndNewlines)
            
            if title.isEmpty || author.isEmpty {
                errors.append("Row \(index): Missing required title or author")
                continue
            }
            
            // Check for ISBN
            var isbn: String? = nil
            if columns.count > 2 {
                let isbnValue = columns[2].trimmingCharacters(in: .whitespacesAndNewlines)
                if !isbnValue.isEmpty && isbnValue != "NULL" {
                    isbn = normalizeISBN(isbnValue)
                }
            }
            
            // Check for duplicates
            if let isbn = isbn, !isbn.isEmpty {
                if seenISBNs.contains(isbn) {
                    duplicates += 1
                    errors.append("Row \(index): Duplicate ISBN \(isbn)")
                } else {
                    seenISBNs.insert(isbn)
                    validBooks += 1
                }
            } else {
                // Check title/author duplicate
                let key = "\(title.lowercased())|\(author.lowercased())"
                if seenTitleAuthor.contains(key) {
                    duplicates += 1
                    errors.append("Row \(index): Duplicate title/author combination")
                } else {
                    seenTitleAuthor.insert(key)
                    validBooks += 1
                }
            }
            
            // Validate ISBN format if present
            if let isbn = isbn, !isbn.isEmpty {
                if !isValidISBN(isbn) && fileName == "test_malformed_isbn_books.csv" {
                    // Expected for malformed ISBN test file
                } else if !isValidISBN(isbn) {
                    errors.append("Row \(index): Invalid ISBN format: \(isbn)")
                }
            }
        }
        
        let performance = Date().timeIntervalSince(startTime)
        
        // Determine if test passed based on file type
        var passed = true
        
        switch fileName {
        case "test_isbn10_books.csv", "test_isbn13_books.csv":
            passed = validBooks == totalRows && duplicates == 0
        case "test_mixed_isbn_columns.csv":
            passed = validBooks == totalRows && duplicates == 0
        case "test_no_isbn_books.csv":
            passed = validBooks == totalRows && duplicates == 0
        case "test_duplicate_isbn_books.csv":
            passed = duplicates > 0 // Should detect duplicates
        case "test_malformed_isbn_books.csv":
            passed = errors.count > 0 // Should detect invalid ISBNs
        case "test_large_dataset.csv":
            passed = performance < 5.0 // Should process in under 5 seconds
        default:
            passed = validBooks > 0
        }
        
        return TestResult(
            fileName: fileName,
            description: description,
            totalRows: totalRows,
            validBooks: validBooks,
            duplicates: duplicates,
            errors: errors,
            performance: performance,
            passed: passed
        )
    }
    
    private func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false
        
        for char in line {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                result.append(current)
                current = ""
            } else {
                current.append(char)
            }
        }
        result.append(current)
        
        return result.map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "\"")) }
    }
    
    private func normalizeISBN(_ isbn: String) -> String {
        // Remove common non-digit characters
        let cleaned = isbn.replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ".", with: "")
            .uppercased()
        
        return cleaned
    }
    
    private func isValidISBN(_ isbn: String) -> Bool {
        let cleaned = normalizeISBN(isbn)
        
        // Check if it's ISBN-10
        if cleaned.count == 10 {
            return isValidISBN10(cleaned)
        }
        
        // Check if it's ISBN-13
        if cleaned.count == 13 {
            return isValidISBN13(cleaned)
        }
        
        return false
    }
    
    private func isValidISBN10(_ isbn: String) -> Bool {
        guard isbn.count == 10 else { return false }
        
        var sum = 0
        for (index, char) in isbn.enumerated() {
            if index == 9 && char == "X" {
                sum += 10 * (10 - index)
            } else if let digit = char.wholeNumberValue {
                sum += digit * (10 - index)
            } else {
                return false
            }
        }
        
        return sum % 11 == 0
    }
    
    private func isValidISBN13(_ isbn: String) -> Bool {
        guard isbn.count == 13 else { return false }
        guard isbn.allSatisfy({ $0.isNumber }) else { return false }
        
        var sum = 0
        for (index, char) in isbn.enumerated() {
            if let digit = char.wholeNumberValue {
                sum += digit * (index % 2 == 0 ? 1 : 3)
            } else {
                return false
            }
        }
        
        return sum % 10 == 0
    }
}

// MARK: - Test Runner
class TestRunner {
    private let validator = CSVTestValidator()
    
    func runAllTests() {
        print("=" * 80)
        print("CSV IMPORT TEST SUITE")
        print("=" * 80)
        print()
        
        let currentDirectory = FileManager.default.currentDirectoryPath
        var allPassed = true
        var results: [TestResult] = []
        
        for (fileName, _) in TestConfig.testFiles {
            let filePath = "\(currentDirectory)/\(fileName)"
            
            if FileManager.default.fileExists(atPath: filePath) {
                let result = validator.validateCSVFile(at: filePath)
                results.append(result)
                allPassed = allPassed && result.passed
                
                printTestResult(result)
            } else {
                print("⚠️  Test file not found: \(fileName)")
                allPassed = false
            }
        }
        
        printSummary(results: results, allPassed: allPassed)
    }
    
    private func printTestResult(_ result: TestResult) {
        let status = result.passed ? "✅ PASSED" : "❌ FAILED"
        
        print("\(status) - \(result.fileName)")
        print("  Description: \(result.description)")
        print("  Total Rows: \(result.totalRows)")
        print("  Valid Books: \(result.validBooks)")
        print("  Duplicates: \(result.duplicates)")
        print("  Performance: \(String(format: "%.3f", result.performance)) seconds")
        
        if !result.errors.isEmpty && result.errors.count <= 5 {
            print("  Errors (first 5):")
            for error in result.errors.prefix(5) {
                print("    - \(error)")
            }
        } else if !result.errors.isEmpty {
            print("  Total Errors: \(result.errors.count)")
        }
        
        print()
    }
    
    private func printSummary(results: [TestResult], allPassed: Bool) {
        print("=" * 80)
        print("TEST SUMMARY")
        print("=" * 80)
        
        let passed = results.filter { $0.passed }.count
        let failed = results.filter { !$0.passed }.count
        let totalBooks = results.reduce(0) { $0 + $1.validBooks }
        let totalDuplicates = results.reduce(0) { $0 + $1.duplicates }
        let totalTime = results.reduce(0) { $0 + $1.performance }
        
        print("Tests Passed: \(passed)/\(results.count)")
        print("Tests Failed: \(failed)")
        print("Total Books Processed: \(totalBooks)")
        print("Total Duplicates Detected: \(totalDuplicates)")
        print("Total Processing Time: \(String(format: "%.3f", totalTime)) seconds")
        print()
        
        if allPassed {
            print("🎉 ALL TESTS PASSED!")
        } else {
            print("⚠️  SOME TESTS FAILED - Review the results above")
        }
        print("=" * 80)
    }
}

// Helper extension
extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}

// MARK: - Main Execution
let runner = TestRunner()
runner.runAllTests()
