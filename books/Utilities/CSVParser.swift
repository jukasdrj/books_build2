//
//  CSVParser.swift
//  books
//
//  Low-level CSV parsing utilities
//

import Foundation

// MARK: - CSV Parser

/// Low-level CSV parsing utility with proper RFC 4180 compliance
struct CSVParser {
    
    /// Errors that can occur during CSV parsing
    enum CSVError: LocalizedError {
        case fileNotFound
        case fileNotReadable
        case invalidEncoding
        case malformedCSV(line: Int, reason: String)
        case emptyFile
        case noHeaders
        case tooManyColumns(limit: Int)
        case fileTooLarge(sizeLimit: Int)
        
        var errorDescription: String? {
            switch self {
            case .fileNotFound:
                return "CSV file not found"
            case .fileNotReadable:
                return "Cannot read CSV file"
            case .invalidEncoding:
                return "File encoding not supported"
            case .malformedCSV(let line, let reason):
                return "Malformed CSV at line \(line): \(reason)"
            case .emptyFile:
                return "CSV file is empty"
            case .noHeaders:
                return "CSV file has no header row"
            case .tooManyColumns(let limit):
                return "Too many columns (limit: \(limit))"
            case .fileTooLarge(let sizeLimit):
                return "File too large (limit: \(sizeLimit) MB)"
            }
        }
    }
    
    /// Configuration for CSV parsing
    struct Config {
        let delimiter: Character = ","
        let quote: Character = "\""
        let escape: Character = "\""
        let maxFileSize: Int = 50 * 1024 * 1024  // 50MB
        let maxColumns: Int = 100
        let maxPreviewRows: Int = 10
        let encoding: String.Encoding = .utf8
        
        static let `default` = Config()
    }
    
    private let config: Config
    
    init(config: Config = .default) {
        self.config = config
    }
    
    /// Parse CSV from URL with basic validation
    func parseCSV(from url: URL) throws -> CSVImportSession {
        // Validate file exists and size
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw CSVError.fileNotFound
        }
        
        let fileAttributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let fileSize = fileAttributes[.size] as? Int ?? 0
        
        if fileSize > config.maxFileSize {
            throw CSVError.fileTooLarge(sizeLimit: config.maxFileSize / (1024 * 1024))
        }
        
        if fileSize == 0 {
            throw CSVError.emptyFile
        }
        
        // Read file content
        guard let content = try? String(contentsOf: url, encoding: config.encoding) else {
            throw CSVError.invalidEncoding
        }
        
        if content.isEmpty {
            throw CSVError.emptyFile
        }
        
        // Parse CSV content
        let rows = try parseCSVContent(content)
        
        guard !rows.isEmpty else {
            throw CSVError.noHeaders
        }
        
        let headers = rows[0]
        let dataRows = Array(rows.dropFirst())
        
        if headers.count > config.maxColumns {
            throw CSVError.tooManyColumns(limit: config.maxColumns)
        }
        
        // Create columns with sample data
        let columns = createColumns(from: headers, dataRows: dataRows)
        
        // Get sample data for preview
        let sampleData = Array(rows.prefix(min(config.maxPreviewRows + 1, rows.count)))
        
        return CSVImportSession(
            fileName: url.lastPathComponent,
            fileSize: fileSize,
            totalRows: dataRows.count,
            detectedColumns: columns,
            sampleData: sampleData
        )
    }
    
    /// Parse CSV content into rows
    private func parseCSVContent(_ content: String) throws -> [[String]] {
        var rows: [[String]] = []
        var currentRow: [String] = []
        var currentField = ""
        var inQuotes = false
        var lineNumber = 1
        
        let lines = content.components(separatedBy: .newlines)
        
        for line in lines {
            if line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                continue // Skip empty lines
            }
            
            for char in line {
                if char == config.quote {
                    if inQuotes {
                        // Check for escaped quote (double quote)
                        let index = line.firstIndex(of: char)!
                        let nextIndex = line.index(after: index)
                        if nextIndex < line.endIndex && line[nextIndex] == config.quote {
                            currentField.append(char)
                            continue
                        } else {
                            inQuotes = false
                        }
                    } else {
                        inQuotes = true
                    }
                } else if char == config.delimiter && !inQuotes {
                    currentRow.append(currentField.trimmingCharacters(in: .whitespacesAndNewlines))
                    currentField = ""
                } else {
                    currentField.append(char)
                }
            }
            
            if !inQuotes {
                // End of row
                currentRow.append(currentField.trimmingCharacters(in: .whitespacesAndNewlines))
                rows.append(currentRow)
                currentRow = []
                currentField = ""
                lineNumber += 1
            } else {
                // Multi-line field continues
                currentField.append("\n")
            }
        }
        
        // Handle last row if needed
        if !currentRow.isEmpty || !currentField.isEmpty {
            if !currentField.isEmpty {
                currentRow.append(currentField.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            if !currentRow.isEmpty {
                rows.append(currentRow)
            }
        }
        
        if inQuotes {
            throw CSVError.malformedCSV(line: lineNumber, reason: "Unclosed quote")
        }
        
        return rows
    }
    
    /// Create column definitions with enhanced auto-detection for Goodreads
    private func createColumns(from headers: [String], dataRows: [[String]]) -> [CSVColumn] {
        return headers.enumerated().map { index, header in
            let sampleValues = dataRows.prefix(5).compactMap { row in
                index < row.count ? row[index] : nil
            }.filter { !$0.isEmpty }
            
            // Enhanced auto-detection for Goodreads columns
            let mappedField = detectGoodreadsColumn(header)
            
            return CSVColumn(
                originalName: header,
                index: index,
                mappedField: mappedField,
                sampleValues: Array(sampleValues)
            )
        }
    }
    
    /// Enhanced Goodreads column detection
    private func detectGoodreadsColumn(_ header: String) -> BookField? {
        let normalized = header.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: "-", with: "")
        
        // ISBN detection (highest priority)
        if normalized.contains("isbn") {
            return .isbn
        }
        
        // Title detection
        if normalized == "title" {
            return .title
        }
        
        // Author detection
        if normalized == "author" || normalized == "authorlfm" || normalized == "authorfirstlast" {
            return .author
        }
        
        // Rating detection (personal rating)
        if normalized.contains("myrating") || normalized.contains("rating") {
            return .rating
        }
        
        // Notes/Review detection
        if normalized.contains("myreview") || normalized.contains("review") || normalized.contains("notes") {
            return .personalNotes
        }
        
        // Reading status detection
        if normalized.contains("exclusiveshelf") || normalized.contains("shelf") || normalized.contains("status") {
            return .readingStatus
        }
        
        // Date read detection
        if normalized.contains("dateread") {
            return .dateRead
        }
        
        // Date added detection
        if normalized.contains("dateadded") {
            return .dateAdded
        }
        
        // Publisher detection
        if normalized.contains("publisher") {
            return .publisher
        }
        
        // Publication year
        if normalized.contains("yearpublished") || normalized.contains("publicationyear") {
            return .publishedDate
        }
        
        // Page count
        if normalized.contains("numberofpages") || normalized.contains("pages") {
            return .pageCount
        }
        
        // Tags/Shelves
        if normalized.contains("mytags") || normalized.contains("bookshelves") {
            return .tags
        }
        
        return nil
    }
    
    /// Parse all rows into ParsedBook objects
    func parseBooks(from session: CSVImportSession, columnMappings: [String: BookField]) -> [ParsedBook] {
        var books: [ParsedBook] = []
        
        // Skip header row, start from index 1
        let dataRows = Array(session.sampleData.dropFirst())
        
        for (rowIndex, row) in dataRows.enumerated() {
            let book = parseBook(from: row, columns: session.detectedColumns, mappings: columnMappings, rowIndex: rowIndex + 2) // +2 because we skip header and are 1-indexed
            books.append(book)
        }
        
        return books
    }
    
    /// Parse a single row into a ParsedBook
    private func parseBook(from row: [String], columns: [CSVColumn], mappings: [String: BookField], rowIndex: Int) -> ParsedBook {
        var book = ParsedBook(rowIndex: rowIndex)
        
        for column in columns {
            guard column.index < row.count,
                  let field = mappings[column.originalName] else { continue }
            
            let value = row[column.index].trimmingCharacters(in: .whitespacesAndNewlines)
            
            switch field {
            case .title:
                book.title = value.isEmpty ? nil : value
            case .author:
                book.author = value.isEmpty ? nil : value
            case .isbn:
                book.isbn = value.isEmpty ? nil : value
            case .publisher:
                book.publisher = value.isEmpty ? nil : value
            case .publishedDate:
                book.publishedDate = value.isEmpty ? nil : value
            case .pageCount:
                book.pageCount = Int(value)
            case .description:
                book.description = value.isEmpty ? nil : value
            case .language:
                book.language = value.isEmpty ? nil : value
            case .originalLanguage:
                book.originalLanguage = value.isEmpty ? nil : value
            case .authorNationality:
                book.authorNationality = value.isEmpty ? nil : value
            case .translator:
                book.translator = value.isEmpty ? nil : value
            case .genre:
                book.genre = parseList(value)
            case .dateRead:
                book.dateRead = parseDate(value)
            case .dateAdded:
                book.dateAdded = parseDate(value)
            case .rating:
                book.rating = Int(value)
            case .readingStatus:
                book.readingStatus = value.isEmpty ? nil : value
            case .personalNotes:
                book.personalNotes = value.isEmpty ? nil : value
            case .tags:
                book.tags = parseList(value)
            case .authorGender:
                <#code#>
            case .culturalThemes:
                <#code#>
            }
        }
        
        return book
    }
    
    /// Parse comma-separated or semicolon-separated lists
    private func parseList(_ value: String) -> [String] {
        if value.isEmpty { return [] }
        
        let separator = value.contains(";") ? ";" : ","
        return value.components(separatedBy: separator)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    /// Parse various date formats
    private func parseDate(_ value: String) -> Date? {
        if value.isEmpty { return nil }
        
        let formatters = [
            "yyyy-MM-dd",
            "MM/dd/yyyy",
            "dd/MM/yyyy",
            "yyyy/MM/dd",
            "MMMM dd, yyyy",
            "dd MMMM yyyy",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy"
        ]
        
        for format in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            if let date = formatter.date(from: value) {
                return date
            }
        }
        
        return nil
    }
}

// MARK: - File Size Formatting Helper

extension Int {
    var formattedFileSize: String {
        let bytes = Double(self)
        let kb = bytes / 1024
        let mb = kb / 1024
        let gb = mb / 1024
        
        if gb >= 1 {
            return String(format: "%.1f GB", gb)
        } else if mb >= 1 {
            return String(format: "%.1f MB", mb)
        } else if kb >= 1 {
            return String(format: "%.1f KB", kb)
        } else {
            return "\(self) bytes"
        }
    }
}
