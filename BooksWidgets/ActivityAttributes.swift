//
//  ActivityAttributes.swift
//  BooksWidgets
//
//  Shared ActivityAttributes for Live Activities
//  This file is shared between the main app and widget extension
//

import Foundation
import ActivityKit

/// Activity attributes for CSV import Live Activities
@available(iOS 16.1, *)
struct CSVImportActivityAttributes: ActivityAttributes {
    
    public struct ContentState: Codable, Hashable {
        var progress: Double
        var currentStep: String
        var booksProcessed: Int
        var totalBooks: Int
        var successCount: Int
        var duplicateCount: Int
        var failureCount: Int
        var currentBookTitle: String?
        var currentBookAuthor: String?
        
        var formattedProgress: String {
            return "\(Int(progress * 100))%"
        }
        
        var statusSummary: String {
            if totalBooks == 0 { return "Preparing..." }
            return "\(booksProcessed)/\(totalBooks) books"
        }
        
        var isComplete: Bool {
            return progress >= 1.0
        }
        
        var hasErrors: Bool {
            return failureCount > 0
        }
        
        var hasDuplicates: Bool {
            return duplicateCount > 0
        }
        
        var completionSummary: String {
            var parts: [String] = []
            
            if successCount > 0 {
                parts.append("\(successCount) imported")
            }
            
            if duplicateCount > 0 {
                parts.append("\(duplicateCount) duplicates")
            }
            
            if failureCount > 0 {
                parts.append("\(failureCount) failed")
            }
            
            return parts.isEmpty ? "No books processed" : parts.joined(separator: ", ")
        }
    }
    
    var fileName: String
    var sessionId: UUID
    var fileSize: Int64?
    var estimatedDuration: TimeInterval?
    
    var displayName: String {
        return "Importing \(fileName)"
    }
    
    var shortDisplayName: String {
        let name = fileName.replacingOccurrences(of: ".csv", with: "")
        return name.count > 20 ? String(name.prefix(17)) + "..." : name
    }
}