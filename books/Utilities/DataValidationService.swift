//
//  DataValidationService.swift
//  books
//
//  Smart data validation and correction service for CSV imports
//  Provides enhanced validation, auto-correction, and quality scoring
//

import Foundation

/// Smart data validation service for CSV import data quality
struct DataValidationService {
    
    // MARK: - Validation Results
    
    struct ValidationResult {
        let isValid: Bool
        let correctedValue: String?
        let issues: [ValidationIssue]
        let confidence: Double // 0.0 to 1.0
    }
    
    struct ValidationIssue {
        let type: IssueType
        let description: String
        let severity: Severity
        
        enum IssueType {
            case invalidFormat
            case checksumMismatch
            case invalidDate
            case malformedAuthor
            case suspiciousData
        }
        
        enum Severity {
            case low, medium, high
        }
    }
    
    // MARK: - Enhanced ISBN Validation
    
    /// Validates and corrects ISBN with comprehensive format support and checksum verification
    static func validateISBN(_ value: String) -> ValidationResult {
        let cleaned = cleanISBN(value)
        var issues: [ValidationIssue] = []
        var correctedValue: String? = nil
        var confidence: Double = 1.0
        
        // Handle empty or obviously invalid cases
        guard !cleaned.isEmpty, cleaned != "0", cleaned != "null", cleaned != "N/A" else {
            return ValidationResult(isValid: false, correctedValue: nil, issues: [], confidence: 0.0)
        }
        
        // Handle common Goodreads formatting issues
        let processedISBN = preprocessGoodreadsISBN(cleaned)
        
        // Validate ISBN-10
        if processedISBN.count == 10 {
            if validateISBN10Checksum(processedISBN) {
                correctedValue = formatISBN10(processedISBN)
                return ValidationResult(isValid: true, correctedValue: correctedValue, issues: issues, confidence: confidence)
            } else {
                issues.append(ValidationIssue(
                    type: .checksumMismatch,
                    description: "ISBN-10 checksum validation failed",
                    severity: .high
                ))
                confidence = 0.3
            }
        }
        
        // Validate ISBN-13
        else if processedISBN.count == 13 {
            if validateISBN13Checksum(processedISBN) {
                correctedValue = formatISBN13(processedISBN)
                return ValidationResult(isValid: true, correctedValue: correctedValue, issues: issues, confidence: confidence)
            } else {
                issues.append(ValidationIssue(
                    type: .checksumMismatch,
                    description: "ISBN-13 checksum validation failed", 
                    severity: .high
                ))
                confidence = 0.3
            }
        }
        
        // Handle malformed but potentially correctable ISBNs
        else if processedISBN.count > 13 {
            // Try to extract valid ISBN from longer string
            if let extractedISBN = extractISBNFromString(processedISBN) {
                let extractedResult = validateISBN(extractedISBN)
                if extractedResult.isValid {
                    issues.append(ValidationIssue(
                        type: .invalidFormat,
                        description: "Extracted valid ISBN from malformed data",
                        severity: .medium
                    ))
                    return ValidationResult(
                        isValid: true,
                        correctedValue: extractedResult.correctedValue,
                        issues: issues,
                        confidence: 0.8
                    )
                }
            }
            
            issues.append(ValidationIssue(
                type: .invalidFormat,
                description: "ISBN too long: \(processedISBN.count) digits",
                severity: .high
            ))
        }
        
        else {
            issues.append(ValidationIssue(
                type: .invalidFormat,
                description: "ISBN too short: \(processedISBN.count) digits (expected 10 or 13)",
                severity: .high
            ))
        }
        
        return ValidationResult(
            isValid: false,
            correctedValue: correctedValue,
            issues: issues,
            confidence: confidence
        )
    }
    
    // MARK: - Advanced Date Parsing
    
    /// Parses dates with natural language support and common format handling
    static func validateDate(_ value: String) -> ValidationResult {
        var issues: [ValidationIssue] = []
        var confidence: Double = 1.0
        
        guard !value.isEmpty, value != "null", value != "N/A", value != "0" else {
            return ValidationResult(isValid: false, correctedValue: nil, issues: [], confidence: 0.0)
        }
        
        let cleanedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Enhanced date parsing with multiple strategies
        if let parsedDate = parseEnhancedDate(cleanedValue) {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            
            return ValidationResult(
                isValid: true,
                correctedValue: formatter.string(from: parsedDate),
                issues: issues,
                confidence: confidence
            )
        }
        
        // Handle partial dates (year only, month/year)
        if let partialDate = parsePartialDate(cleanedValue) {
            issues.append(ValidationIssue(
                type: .invalidDate,
                description: "Partial date converted to full date",
                severity: .low
            ))
            confidence = 0.7
            
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            
            return ValidationResult(
                isValid: true,
                correctedValue: formatter.string(from: partialDate),
                issues: issues,
                confidence: confidence
            )
        }
        
        issues.append(ValidationIssue(
            type: .invalidDate,
            description: "Unrecognized date format: \(cleanedValue)",
            severity: .high
        ))
        
        return ValidationResult(
            isValid: false,
            correctedValue: nil,
            issues: issues,
            confidence: 0.0
        )
    }
    
    // MARK: - Author Name Standardization
    
    /// Standardizes author names with multiple format support
    static func validateAuthor(_ value: String) -> ValidationResult {
        var issues: [ValidationIssue] = []
        var confidence: Double = 1.0
        
        guard !value.isEmpty, value != "null", value != "N/A", value != "Unknown" else {
            return ValidationResult(isValid: false, correctedValue: nil, issues: [], confidence: 0.0)
        }
        
        let cleanedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Standardize author name format
        let standardizedName = standardizeAuthorName(cleanedValue)
        
        // Check for suspicious patterns
        if hasSuspiciousAuthorPatterns(standardizedName) {
            issues.append(ValidationIssue(
                type: .suspiciousData,
                description: "Author name contains suspicious patterns",
                severity: .medium
            ))
            confidence = 0.6
        }
        
        // Handle multiple authors
        let processedAuthors = parseMultipleAuthors(standardizedName)
        
        return ValidationResult(
            isValid: true,
            correctedValue: processedAuthors,
            issues: issues,
            confidence: confidence
        )
    }
    
    // MARK: - Data Quality Scoring
    
    /// Calculates overall data quality score for a parsed book
    static func calculateDataQualityScore(for book: ParsedBook) -> Double {
        var totalWeight: Double = 0
        var scoreSum: Double = 0
        
        // Essential fields with high weights
        if let title = book.title {
            let titleScore = validateTitle(title).confidence
            scoreSum += titleScore * 3.0
            totalWeight += 3.0
        }
        
        if let author = book.author {
            let authorScore = validateAuthor(author).confidence
            scoreSum += authorScore * 2.5
            totalWeight += 2.5
        }
        
        if let isbn = book.isbn {
            let isbnScore = validateISBN(isbn).confidence
            scoreSum += isbnScore * 2.0
            totalWeight += 2.0
        }
        
        // Optional fields with lower weights
        if let publisher = book.publisher {
            let publisherScore = validatePublisher(publisher).confidence
            scoreSum += publisherScore * 1.0
            totalWeight += 1.0
        }
        
        if let dateRead = book.dateRead {
            scoreSum += 1.0 * 1.0 // Valid date gets full score
            totalWeight += 1.0
        }
        
        if let rating = book.rating, rating >= 1 && rating <= 5 {
            scoreSum += 1.0 * 0.5 // Valid rating
            totalWeight += 0.5
        }
        
        return totalWeight > 0 ? scoreSum / totalWeight : 0.0
    }
}

// MARK: - Private Helper Methods

private extension DataValidationService {
    
    /// Clean and preprocess ISBN from various formats
    static func cleanISBN(_ isbn: String) -> String {
        return isbn.replacingOccurrences(of: "-", with: "")
                  .replacingOccurrences(of: " ", with: "")
                  .replacingOccurrences(of: "=", with: "") // Goodreads format
                  .replacingOccurrences(of: "\"", with: "")
                  .filter { $0.isNumber || $0.uppercased() == "X" }
    }
    
    /// Handle common Goodreads ISBN formatting issues
    static func preprocessGoodreadsISBN(_ isbn: String) -> String {
        // Remove common prefixes that appear in Goodreads exports
        var processed = isbn
        
        // Remove leading = sign (Excel formula protection)
        if processed.hasPrefix("=") {
            processed = String(processed.dropFirst())
        }
        
        // Remove quotes
        processed = processed.replacingOccurrences(of: "\"", with: "")
        
        return processed
    }
    
    /// Validate ISBN-10 checksum
    static func validateISBN10Checksum(_ isbn: String) -> Bool {
        guard isbn.count == 10 else { return false }
        
        var sum = 0
        for (index, char) in isbn.enumerated() {
            if index == 9 && char.uppercased() == "X" {
                sum += 10 * (10 - index)
            } else if let digit = char.wholeNumberValue {
                sum += digit * (10 - index)
            } else {
                return false
            }
        }
        
        return sum % 11 == 0
    }
    
    /// Validate ISBN-13 checksum
    static func validateISBN13Checksum(_ isbn: String) -> Bool {
        guard isbn.count == 13, isbn.allSatisfy({ $0.isNumber }) else { return false }
        
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
    
    /// Format ISBN-10 with dashes
    static func formatISBN10(_ isbn: String) -> String {
        guard isbn.count == 10 else { return isbn }
        return "\(isbn.prefix(1))-\(isbn.dropFirst().prefix(3))-\(isbn.dropFirst(4).prefix(5))-\(isbn.suffix(1))"
    }
    
    /// Format ISBN-13 with dashes
    static func formatISBN13(_ isbn: String) -> String {
        guard isbn.count == 13 else { return isbn }
        return "\(isbn.prefix(3))-\(isbn.dropFirst(3).prefix(1))-\(isbn.dropFirst(4).prefix(3))-\(isbn.dropFirst(7).prefix(5))-\(isbn.suffix(1))"
    }
    
    /// Extract ISBN from longer string
    static func extractISBNFromString(_ input: String) -> String? {
        // Look for 13-digit sequences starting with 978 or 979
        let isbn13Pattern = #"(97[89]\d{10})"#
        if let match = input.range(of: isbn13Pattern, options: .regularExpression) {
            return String(input[match])
        }
        
        // Look for 10-digit sequences
        let isbn10Pattern = #"(\d{9}[\dX])"#
        if let match = input.range(of: isbn10Pattern, options: .regularExpression) {
            return String(input[match])
        }
        
        return nil
    }
    
    /// Enhanced date parsing with multiple strategies
    static func parseEnhancedDate(_ dateString: String) -> Date? {
        let formatters = [
            "yyyy-MM-dd", "MM/dd/yyyy", "dd/MM/yyyy", "yyyy/MM/dd",
            "MMMM dd, yyyy", "dd MMMM yyyy", "MMM dd, yyyy", "dd MMM yyyy",
            "yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd'T'HH:mm:ss", "yyyy-MM-dd'T'HH:mm:ssZ"
        ]
        
        for format in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "en_US_POSIX")
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        
        // Try with natural language processing
        if let date = parseNaturalLanguageDate(dateString) {
            return date
        }
        
        return nil
    }
    
    /// Parse natural language dates
    static func parseNaturalLanguageDate(_ dateString: String) -> Date? {
        let lowercased = dateString.lowercased()
        let currentYear = Calendar.current.component(.year, from: Date())
        
        // Handle "last year", "this year", etc.
        if lowercased.contains("last year") {
            return Calendar.current.date(from: DateComponents(year: currentYear - 1, month: 6))
        }
        if lowercased.contains("this year") {
            return Calendar.current.date(from: DateComponents(year: currentYear, month: 6))
        }
        
        return nil
    }
    
    /// Parse partial dates (year only, month/year)
    static func parsePartialDate(_ dateString: String) -> Date? {
        // Year only
        if let year = Int(dateString), year > 1800 && year <= Calendar.current.component(.year, from: Date()) {
            return Calendar.current.date(from: DateComponents(year: year, month: 6, day: 15))
        }
        
        // Month/Year patterns
        let monthYearPattern = #"(\d{1,2})/(\d{4})"#
        if let match = dateString.range(of: monthYearPattern, options: .regularExpression) {
            let components = String(dateString[match]).components(separatedBy: "/")
            if components.count == 2,
               let month = Int(components[0]),
               let year = Int(components[1]),
               month >= 1 && month <= 12 {
                return Calendar.current.date(from: DateComponents(year: year, month: month, day: 15))
            }
        }
        
        return nil
    }
    
    /// Standardize author name format
    static func standardizeAuthorName(_ name: String) -> String {
        var standardized = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Handle "Last, First" format
        if standardized.contains(",") && !standardized.contains(";") {
            let parts = standardized.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            if parts.count == 2 {
                standardized = "\(parts[1]) \(parts[0])"
            }
        }
        
        // Clean up extra whitespace
        standardized = standardized.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        
        // Capitalize properly
        standardized = standardized.capitalized
        
        return standardized
    }
    
    /// Check for suspicious author name patterns
    static func hasSuspiciousAuthorPatterns(_ name: String) -> Bool {
        let suspicious = ["unknown", "various", "n/a", "null", "anonymous", "test", "example"]
        return suspicious.contains(name.lowercased())
    }
    
    /// Parse multiple authors from string
    static func parseMultipleAuthors(_ authorsString: String) -> String {
        // Handle common separators
        let separators = [";", ",", "&", " and ", " AND "]
        
        for separator in separators {
            if authorsString.contains(separator) {
                let authors = authorsString.components(separatedBy: separator)
                    .map { standardizeAuthorName($0) }
                    .filter { !$0.isEmpty }
                
                return authors.joined(separator: ", ")
            }
        }
        
        return authorsString
    }
    
    /// Enhanced title validation with subtitle handling and normalization
    public static func validateTitle(_ title: String) -> ValidationResult {
        let cleaned = title.trimmingCharacters(in: .whitespacesAndNewlines)
        var confidence: Double = 1.0
        var issues: [ValidationIssue] = []
        
        if cleaned.isEmpty {
            return ValidationResult(isValid: false, correctedValue: nil, issues: [], confidence: 0.0)
        }
        
        // Enhanced title normalization with subtitle handling
        let normalizedTitle = normalizeTitleWithSubtitle(cleaned)
        
        // Check for suspicious patterns
        let suspicious = ["unknown", "untitled", "n/a", "null", "test"]
        if suspicious.contains(normalizedTitle.lowercased()) {
            confidence = 0.3
            issues.append(ValidationIssue(
                type: .suspiciousData,
                description: "Title appears to be placeholder text",
                severity: .medium
            ))
        }
        
        // Check for overly long titles that might include extra metadata
        if normalizedTitle.count > 200 {
            confidence = 0.7
            issues.append(ValidationIssue(
                type: .suspiciousData,
                description: "Title is unusually long and may contain extra metadata",
                severity: .low
            ))
        }
        
        // Check for common title formatting issues
        if normalizedTitle != cleaned {
            issues.append(ValidationIssue(
                type: .invalidFormat,
                description: "Title formatting was improved",
                severity: .low
            ))
        }
        
        return ValidationResult(isValid: true, correctedValue: normalizedTitle, issues: issues, confidence: confidence)
    }
    
    /// Normalize title with proper subtitle handling
    public static func normalizeTitleWithSubtitle(_ title: String) -> String {
        var normalized = title.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Handle common subtitle separators
        let subtitleSeparators = [" : ", ": ", " - ", " – ", " — ", " | "]
        
        // Standardize subtitle separators to colon
        for separator in subtitleSeparators {
            if normalized.contains(separator) {
                let components = normalized.components(separatedBy: separator)
                if components.count >= 2 {
                    let mainTitle = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    let subtitle = components.dropFirst().joined(separator: ": ").trimmingCharacters(in: .whitespacesAndNewlines)
                    normalized = "\(mainTitle): \(subtitle)"
                    break
                }
            }
        }
        
        // Clean up multiple spaces
        normalized = normalized.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        
        // Handle series information in parentheses (preserve but standardize)
        normalized = normalized.replacingOccurrences(
            of: #"\s*\(([^)]+)\)\s*"#,
            with: " ($1)",
            options: .regularExpression
        )
        
        // Remove leading/trailing quotes if they wrap the entire title
        if (normalized.hasPrefix("\"") && normalized.hasSuffix("\"")) ||
           (normalized.hasPrefix("'") && normalized.hasSuffix("'")) {
            normalized = String(normalized.dropFirst().dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return normalized.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Validate publisher quality
    public static func validatePublisher(_ publisher: String) -> ValidationResult {
        let cleaned = publisher.trimmingCharacters(in: .whitespacesAndNewlines)
        return ValidationResult(isValid: !cleaned.isEmpty, correctedValue: cleaned, issues: [], confidence: 1.0)
    }
}