//
//  DataCompletenessService.swift
//  books
//
//  Phase 3: Data source tracking and quality analysis service
//

import Foundation
import SwiftData

// MARK: - Library Quality Report

struct LibraryQualityReport {
    let overallCompleteness: Double
    let booksNeedingAttention: Int
    let dataSourceBreakdown: [DataSource: Int]
    let qualityMetrics: QualityMetrics
    let recommendations: [LibraryRecommendation]
    
    struct QualityMetrics {
        let averageBookCompleteness: Double
        let averageUserCompleteness: Double
        let booksWithRatings: Int
        let booksWithNotes: Int
        let booksWithCulturalData: Int
        let booksNeedingValidation: Int
    }
}

struct LibraryRecommendation {
    let type: RecommendationType
    let priority: RecommendationPriority
    let title: String
    let description: String
    let actionCount: Int
    
    enum RecommendationType {
        case addRatings
        case addNotes
        case validateImports
        case completeCulturalData
        case updateProgress
        case addTags
    }
    
    enum RecommendationPriority {
        case high, medium, low
    }
}

// MARK: - Data Completeness Service

@MainActor
class DataCompletenessService {
    
    // MARK: - Book Completeness Calculation
    
    /// Calculate overall book data completeness (0.0-1.0)
    static func calculateBookCompleteness(_ book: UserBook) -> Double {
        guard let metadata = book.metadata else { return 0.0 }
        
        let metadataCompleteness = calculateMetadataCompleteness(metadata)
        let userCompleteness = calculateUserCompleteness(book)
        
        // Weight metadata at 60%, user data at 40%
        return (metadataCompleteness * 0.6) + (userCompleteness * 0.4)
    }
    
    /// Calculate metadata completeness
    static func calculateMetadataCompleteness(_ metadata: BookMetadata) -> Double {
        var completeness: Double = 0.0
        let totalFields: Double = 12.0 // Extended field set for comprehensive analysis
        
        // Core book information (high weight)
        if !metadata.title.isEmpty { completeness += 1.0 }
        if !metadata.authors.isEmpty { completeness += 1.0 }
        
        // Publication details
        if metadata.publishedDate != nil && !metadata.publishedDate!.isEmpty { completeness += 1.0 }
        if metadata.pageCount != nil && metadata.pageCount! > 0 { completeness += 1.0 }
        if metadata.publisher != nil && !metadata.publisher!.isEmpty { completeness += 1.0 }
        if metadata.isbn != nil && !metadata.isbn!.isEmpty { completeness += 1.0 }
        
        // Rich content
        if metadata.bookDescription != nil && !metadata.bookDescription!.isEmpty { completeness += 1.0 }
        if metadata.imageURL != nil { completeness += 1.0 }
        if !metadata.genre.isEmpty { completeness += 1.0 }
        if metadata.language != nil { completeness += 1.0 }
        
        // Cultural and diversity data
        if metadata.culturalRegion != nil { completeness += 1.0 }
        if metadata.authorGender != nil { completeness += 1.0 }
        
        return completeness / totalFields
    }
    
    /// Calculate user-specific completeness
    static func calculateUserCompleteness(_ book: UserBook) -> Double {
        var completeness: Double = 0.0
        let totalFields: Double = 8.0 // User engagement fields
        
        // Personal ratings and feedback
        if book.rating != nil { completeness += 1.0 }
        if book.personalRating != nil { completeness += 1.0 }
        if book.notes != nil && !book.notes!.isEmpty { completeness += 1.0 }
        
        // Reading progress and status
        if book.readingStatus != .toRead { completeness += 1.0 }
        if book.readingProgress > 0.0 { completeness += 1.0 }
        
        // Organization and tagging
        if !book.tags.isEmpty { completeness += 1.0 }
        
        // Social features
        if book.wouldRecommend != nil { completeness += 1.0 }
        
        // Cultural engagement
        if book.contributesToCulturalGoal { completeness += 1.0 }
        
        return completeness / totalFields
    }
    
    // MARK: - Smart Prompt Generation
    
    /// Generate smart user prompts based on data gaps
    static func generateUserPrompts(_ book: UserBook) -> [UserInputPrompt] {
        var prompts: [UserInputPrompt] = []
        
        // Personal rating prompts
        if book.rating == nil && book.readingStatus == .read {
            prompts.append(.addPersonalRating)
        }
        
        // Notes prompts
        if (book.notes == nil || book.notes!.isEmpty) && book.readingStatus != .toRead {
            prompts.append(.addPersonalNotes)
        }
        
        // Cultural data prompts
        if let metadata = book.metadata {
            if metadata.culturalRegion == nil || metadata.authorGender == nil {
                prompts.append(.reviewCulturalData)
            }
        }
        
        // CSV import validation
        if book.metadata?.dataSource == .csvImport {
            let confidence = getAverageFieldConfidence(book.metadata!)
            if confidence < 0.9 {
                prompts.append(.validateImportedData)
            }
        }
        
        // Tagging prompts
        if book.tags.isEmpty && book.readingStatus != .toRead {
            prompts.append(.addTags)
        }
        
        // Reading progress for active books
        if book.readingStatus == .reading && book.readingProgress == 0.0 {
            prompts.append(.updateReadingProgress)
        }
        
        // Book details confirmation for low-confidence imports
        if let metadata = book.metadata,
           metadata.dataSource != .googleBooksAPI && metadata.dataQualityScore < 0.8 {
            prompts.append(.confirmBookDetails)
        }
        
        return prompts
    }
    
    // MARK: - Library Analysis
    
    /// Analyze data quality across entire library
    static func analyzeLibraryQuality(_ books: [UserBook]) -> LibraryQualityReport {
        guard !books.isEmpty else {
            return LibraryQualityReport(
                overallCompleteness: 0.0,
                booksNeedingAttention: 0,
                dataSourceBreakdown: [:],
                qualityMetrics: LibraryQualityReport.QualityMetrics(
                    averageBookCompleteness: 0.0,
                    averageUserCompleteness: 0.0,
                    booksWithRatings: 0,
                    booksWithNotes: 0,
                    booksWithCulturalData: 0,
                    booksNeedingValidation: 0
                ),
                recommendations: []
            )
        }
        
        // Calculate completeness metrics
        let bookCompletenesses = books.map { calculateBookCompleteness($0) }
        let userCompletenesses = books.map { calculateUserCompleteness($0) }
        let metadataCompletenesses = books.compactMap { $0.metadata }.map { calculateMetadataCompleteness($0) }
        
        let overallCompleteness = bookCompletenesses.reduce(0, +) / Double(books.count)
        let averageUserCompleteness = userCompletenesses.reduce(0, +) / Double(books.count)
        let averageBookCompleteness = metadataCompletenesses.isEmpty ? 0.0 : metadataCompletenesses.reduce(0, +) / Double(metadataCompletenesses.count)
        
        // Count books needing attention (completeness < 70%)
        let booksNeedingAttention = books.filter { calculateBookCompleteness($0) < 0.7 }.count
        
        // Data source breakdown
        var dataSourceBreakdown: [DataSource: Int] = [:]
        for book in books {
            if let metadata = book.metadata {
                dataSourceBreakdown[metadata.dataSource, default: 0] += 1
            }
        }
        
        // Quality metrics
        let booksWithRatings = books.filter { $0.rating != nil }.count
        let booksWithNotes = books.filter { $0.notes != nil && !$0.notes!.isEmpty }.count
        let booksWithCulturalData = books.filter { 
            $0.metadata?.culturalRegion != nil || $0.metadata?.authorGender != nil 
        }.count
        let booksNeedingValidation = books.filter { 
            $0.metadata?.dataSource == .csvImport && ($0.metadata?.dataQualityScore ?? 1.0) < 0.9 
        }.count
        
        let qualityMetrics = LibraryQualityReport.QualityMetrics(
            averageBookCompleteness: averageBookCompleteness,
            averageUserCompleteness: averageUserCompleteness,
            booksWithRatings: booksWithRatings,
            booksWithNotes: booksWithNotes,
            booksWithCulturalData: booksWithCulturalData,
            booksNeedingValidation: booksNeedingValidation
        )
        
        // Generate recommendations
        let recommendations = generateLibraryRecommendations(books: books, metrics: qualityMetrics)
        
        return LibraryQualityReport(
            overallCompleteness: overallCompleteness,
            booksNeedingAttention: booksNeedingAttention,
            dataSourceBreakdown: dataSourceBreakdown,
            qualityMetrics: qualityMetrics,
            recommendations: recommendations
        )
    }
    
    // MARK: - Helper Methods
    
    private static func getAverageFieldConfidence(_ metadata: BookMetadata) -> Double {
        let fieldSources = metadata.fieldDataSources
        guard !fieldSources.isEmpty else { return 1.0 }
        
        let totalConfidence = fieldSources.values.reduce(0) { $0 + $1.confidence }
        return totalConfidence / Double(fieldSources.count)
    }
    
    private static func generateLibraryRecommendations(books: [UserBook], metrics: LibraryQualityReport.QualityMetrics) -> [LibraryRecommendation] {
        var recommendations: [LibraryRecommendation] = []
        
        // Rating recommendations
        let booksWithoutRatings = books.filter { $0.rating == nil && $0.readingStatus == .read }.count
        if booksWithoutRatings > 0 {
            recommendations.append(LibraryRecommendation(
                type: .addRatings,
                priority: booksWithoutRatings > 5 ? .high : .medium,
                title: "Add ratings to finished books",
                description: "Rate \(booksWithoutRatings) books you've completed to track your preferences",
                actionCount: booksWithoutRatings
            ))
        }
        
        // Notes recommendations
        let booksWithoutNotes = books.filter { 
            ($0.notes == nil || $0.notes!.isEmpty) && $0.readingStatus != .toRead 
        }.count
        if booksWithoutNotes > 0 {
            recommendations.append(LibraryRecommendation(
                type: .addNotes,
                priority: .medium,
                title: "Add personal notes",
                description: "Capture your thoughts on \(booksWithoutNotes) books",
                actionCount: booksWithoutNotes
            ))
        }
        
        // Validation recommendations
        if metrics.booksNeedingValidation > 0 {
            recommendations.append(LibraryRecommendation(
                type: .validateImports,
                priority: .high,
                title: "Validate imported book data",
                description: "Review \(metrics.booksNeedingValidation) books imported from CSV for accuracy",
                actionCount: metrics.booksNeedingValidation
            ))
        }
        
        // Cultural data recommendations
        let booksWithoutCulturalData = books.count - metrics.booksWithCulturalData
        if booksWithoutCulturalData > 0 {
            recommendations.append(LibraryRecommendation(
                type: .completeCulturalData,
                priority: .medium,
                title: "Complete cultural diversity data",
                description: "Add cultural information to \(booksWithoutCulturalData) books",
                actionCount: booksWithoutCulturalData
            ))
        }
        
        // Reading progress recommendations
        let booksNeedingProgress = books.filter { 
            $0.readingStatus == .reading && $0.readingProgress == 0.0 
        }.count
        if booksNeedingProgress > 0 {
            recommendations.append(LibraryRecommendation(
                type: .updateProgress,
                priority: .high,
                title: "Update reading progress",
                description: "Track progress for \(booksNeedingProgress) books you're currently reading",
                actionCount: booksNeedingProgress
            ))
        }
        
        // Sort by priority and action count
        return recommendations.sorted { rec1, rec2 in
            if rec1.priority != rec2.priority {
                return rec1.priority == .high
            }
            return rec1.actionCount > rec2.actionCount
        }
    }
}

// MARK: - Data Source Confidence Helpers

extension DataCompletenessService {
    
    /// Get confidence level for a specific data source
    static func getSourceConfidence(for source: DataSource) -> Double {
        switch source {
        case .googleBooksAPI:
            return 1.0  // Highest confidence - direct from publisher/API
        case .userInput:
            return 1.0  // High confidence - user verified
        case .manualEntry:
            return 0.9  // High confidence but manual entry can have typos
        case .csvImport:
            return 0.7  // Moderate confidence - depends on source quality
        case .mixedSources:
            return 0.8  // Good confidence - combination of sources
        }
    }
    
    /// Update data quality scores based on user validation
    static func updateQualityAfterUserValidation(_ metadata: BookMetadata, validatedFields: [String]) {
        var updatedSources = metadata.fieldDataSources
        
        for field in validatedFields {
            if let existingSource = updatedSources[field] {
                // Boost confidence for user-validated fields
                let boostedConfidence = min(1.0, existingSource.confidence + 0.2)
                updatedSources[field] = DataSourceInfo(
                    source: existingSource.source,
                    timestamp: Date(),
                    confidence: boostedConfidence,
                    fieldPath: field
                )
            }
        }
        
        metadata.fieldDataSources = updatedSources
        metadata.dataQualityScore = min(1.0, metadata.dataQualityScore + 0.1)
        metadata.lastDataUpdate = Date()
    }
    
    /// Calculate data freshness score (how recently was data updated)
    static func calculateDataFreshness(_ metadata: BookMetadata) -> Double {
        let daysSinceUpdate = Calendar.current.dateComponents([.day], from: metadata.lastDataUpdate, to: Date()).day ?? 0
        
        if daysSinceUpdate <= 7 {
            return 1.0  // Very fresh
        } else if daysSinceUpdate <= 30 {
            return 0.8  // Fresh
        } else if daysSinceUpdate <= 90 {
            return 0.6  // Moderately fresh
        } else {
            return 0.4  // Stale
        }
    }
}