//
//  DataValidationService.swift
//  books
//
//  Simplified data validation focusing on successful imports
//

import Foundation

/// Simplified data validation service - ISBN validation and required fields only
struct DataValidationService {
    
    struct ValidationResult {
        let isValid: Bool
        let correctedValue: String?
        let confidence: Double // 0.0 to 1.0
    }
    
    // MARK: - Core Validation Methods
    
    /// Validates and corrects ISBN with comprehensive format support
    static func validateISBN(_ value: String) -> ValidationResult {
        let cleaned = cleanISBN(value)
        
        // Empty ISBN is valid (will use title/author search)
        if cleaned.isEmpty {
            return ValidationResult(isValid: true, correctedValue: nil, confidence: 0.5)
        }
        
        // ISBN-13 validation
        if cleaned.count == 13 && cleaned.allSatisfy({ $0.isNumber }) {
            let isValid = validateISBN13Checksum(cleaned)
            return ValidationResult(
                isValid: true, // Always allow through - let API decide
                correctedValue: cleaned,
                confidence: isValid ? 1.0 : 0.8
            )
        }
        
        // ISBN-10 validation
        if cleaned.count == 10 {
            let isValid = validateISBN10Checksum(cleaned)
            return ValidationResult(
                isValid: true, // Always allow through - let API decide
                correctedValue: cleaned,
                confidence: isValid ? 1.0 : 0.8
            )
        }
        
        // Invalid length - but still allow through
        return ValidationResult(isValid: true, correctedValue: cleaned, confidence: 0.3)
    }
    
    /// Check if book has required fields for import
    static func hasRequiredFields(_ book: ParsedBook) -> Bool {
        guard let title = book.title?.trimmingCharacters(in: .whitespacesAndNewlines),
              !title.isEmpty else { return false }
        
        guard let author = book.author?.trimmingCharacters(in: .whitespacesAndNewlines),
              !author.isEmpty else { return false }
        
        return true
    }
}

// MARK: - Private Helper Methods
private extension DataValidationService {
    
    /// Clean and preprocess ISBN from various formats
    static func cleanISBN(_ isbn: String) -> String {
        return isbn.replacingOccurrences(of: "-", with: "")
                  .replacingOccurrences(of: " ", with: "")
                  .replacingOccurrences(of: "=", with: "") // Remove Goodreads leading =
                  .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Validate ISBN-13 checksum
    static func validateISBN13Checksum(_ isbn: String) -> Bool {
        guard isbn.count == 13 else { return false }
        
        let digits = isbn.compactMap { $0.wholeNumberValue }
        guard digits.count == 13 else { return false }
        
        let checksum = digits.prefix(12).enumerated().reduce(0) { sum, element in
            let (index, digit) = element
            return sum + digit * (index % 2 == 0 ? 1 : 3)
        }
        
        let calculatedCheck = (10 - (checksum % 10)) % 10
        return calculatedCheck == digits[12]
    }
    
    /// Validate ISBN-10 checksum
    static func validateISBN10Checksum(_ isbn: String) -> Bool {
        guard isbn.count == 10 else { return false }
        
        let characters = Array(isbn)
        var checksum = 0
        
        for i in 0..<9 {
            guard let digit = characters[i].wholeNumberValue else { return false }
            checksum += digit * (10 - i)
        }
        
        let lastChar = characters[9]
        let checkDigit: Int
        if lastChar == "X" || lastChar == "x" {
            checkDigit = 10
        } else {
            guard let digit = lastChar.wholeNumberValue else { return false }
            checkDigit = digit
        }
        
        return (checksum + checkDigit) % 11 == 0
    }
}