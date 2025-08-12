//
//  ImportPreviewView.swift
//  books
//
//  Preview parsed CSV data before import
//

import SwiftUI

struct ImportPreviewView: View {
    @Environment(\.appTheme) private var currentTheme
    let session: CSVImportSession
    let onNext: () -> Void
    let onBack: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with file info
            FileInfoHeader(session: session)
            
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    // Detection results
                    DetectionResultsCard(session: session)
                    
                    // Phase 3: Data Quality Analysis
                    DataQualityIndicator(session: session)
                    
                    // Sample data preview
                    SampleDataPreview(session: session)
                }
                .padding(Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.xl)
            }
            
            // Navigation buttons
            HStack(spacing: Theme.Spacing.md) {
                Button("Back") {
                    onBack()
                }
                .materialButton(style: .outlined, size: .large)
                .frame(maxWidth: .infinity)
                
                Button(canProceedDirectly ? "Start Import" : "Map Columns") {
                    onNext()
                }
                .materialButton(style: .filled, size: .large)
                .frame(maxWidth: .infinity)
                .disabled(!session.isValidGoodreadsFormat && !canProceedDirectly)
            }
            .padding(Theme.Spacing.md)
            .background(currentTheme.surface)
        }
    }
    
    private var canProceedDirectly: Bool {
        let detectedFields = Set(session.detectedColumns.compactMap { $0.mappedField })
        let hasISBN = detectedFields.contains(.isbn)
        let hasTitleAndAuthor = detectedFields.contains(.title) && detectedFields.contains(.author)
        return hasISBN || hasTitleAndAuthor
    }
}

// MARK: - File Info Header

struct FileInfoHeader: View {
    @Environment(\.appTheme) private var currentTheme
    let session: CSVImportSession
    
    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: "doc.text")
                    .font(.system(size: 24))
                    .foregroundColor(currentTheme.primaryAction)
                
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(session.fileName)
                        .titleMedium()
                        .foregroundColor(currentTheme.primaryText)
                    
                    HStack(spacing: Theme.Spacing.md) {
                        Label("\(session.fileSize.formattedFileSize)", systemImage: "internaldrive")
                        Label("\(session.totalRows) books", systemImage: "book")
                        Label("\(session.detectedColumns.count) columns", systemImage: "tablecells")
                    }
                    .labelSmall()
                    .foregroundColor(currentTheme.secondaryText)
                }
                
                Spacer()
                
                // Format validation indicator
                VStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: session.isValidGoodreadsFormat ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(session.isValidGoodreadsFormat ? currentTheme.success : currentTheme.warning)
                    
                    Text(session.isValidGoodreadsFormat ? "Valid" : "Check Format")
                        .labelSmall()
                        .foregroundColor(session.isValidGoodreadsFormat ? currentTheme.success : currentTheme.warning)
                }
            }
            .padding(Theme.Spacing.md)
            
            Divider()
        }
        .background(currentTheme.surface)
    }
}

// MARK: - Detection Results Card

struct DetectionResultsCard: View {
    @Environment(\.appTheme) private var currentTheme
    let session: CSVImportSession
    
    private var mappedColumns: Int {
        session.detectedColumns.filter { $0.mappedField != nil }.count
    }
    
    private var hasISBN: Bool {
        session.detectedColumns.contains { $0.mappedField == .isbn }
    }
    
    private var hasEssentials: Bool {
        let detectedFields = Set(session.detectedColumns.compactMap { $0.mappedField })
        return hasISBN || (detectedFields.contains(.title) && detectedFields.contains(.author))
    }
    
    private var hasPersonalData: Bool {
        let detectedFields = Set(session.detectedColumns.compactMap { $0.mappedField })
        return detectedFields.contains(.rating) || detectedFields.contains(.personalNotes) || detectedFields.contains(.readingStatus)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "brain")
                    .foregroundColor(currentTheme.primaryAction)
                Text("Smart Detection Results")
                    .titleSmall()
                    .foregroundColor(currentTheme.primaryText)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Theme.Spacing.md) {
                SmartMetricCard(
                    icon: "barcode",
                    label: "ISBN Found",
                    status: hasISBN,
                    description: hasISBN ? "Will fetch fresh metadata" : "Will use CSV data"
                )
                
                SmartMetricCard(
                    icon: "person.text.rectangle",
                    label: "Personal Data",
                    status: hasPersonalData,
                    description: hasPersonalData ? "Ratings & notes preserved" : "No personal data found"
                )
            }
            
            // Status message
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: hasEssentials ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(hasEssentials ? currentTheme.success : currentTheme.warning)
                
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(hasEssentials ? "Ready for Automated Import" : "Manual Mapping Required")
                        .bodyMedium()
                        .foregroundColor(currentTheme.primaryText)
                        .fontWeight(.medium)
                    
                    Text(hasEssentials ? 
                         "Found essential columns. Import will proceed automatically." :
                         "Missing essential columns. You'll need to map them manually.")
                        .bodySmall()
                        .foregroundColor(currentTheme.secondaryText)
                }
            }
            .padding(Theme.Spacing.sm)
            .background(hasEssentials ? currentTheme.successContainer : currentTheme.warningContainer)
            .cornerRadius(Theme.CornerRadius.small)
        }
        .padding(Theme.Spacing.md)
        .materialCard()
    }
}

struct SmartMetricCard: View {
    @Environment(\.appTheme) private var currentTheme
    let icon: String
    let label: String
    let status: Bool
    let description: String
    
    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: icon)
                    .foregroundColor(status ? currentTheme.success : currentTheme.secondaryText)
                
                Image(systemName: status ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(status ? currentTheme.success : currentTheme.error)
            }
            
            VStack(spacing: Theme.Spacing.xs) {
                Text(label)
                    .labelMedium()
                    .foregroundColor(currentTheme.primaryText)
                    .fontWeight(.medium)
                
                Text(description)
                    .labelSmall()
                    .foregroundColor(currentTheme.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.sm)
        .background(status ? currentTheme.successContainer.opacity(0.3) : currentTheme.surfaceVariant)
        .cornerRadius(Theme.CornerRadius.small)
    }
}

// MARK: - Sample Data Preview

struct SampleDataPreview: View {
    @Environment(\.appTheme) private var currentTheme
    let session: CSVImportSession
    
    private var previewRows: [[String]] {
        Array(session.sampleData.prefix(4)) // Header + 3 rows
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "eye")
                    .foregroundColor(currentTheme.primaryAction)
                Text("Data Preview")
                    .titleSmall()
                    .foregroundColor(currentTheme.primaryText)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    ForEach(Array(previewRows.enumerated()), id: \.offset) { rowIndex, row in
                        HStack(spacing: Theme.Spacing.sm) {
                            ForEach(Array(row.enumerated()), id: \.offset) { colIndex, cell in
                                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                    if rowIndex == 0 {
                                        // Header row
                                        Text(cell)
                                            .labelSmall()
                                            .fontWeight(.semibold)
                                            .foregroundColor(currentTheme.primaryAction)
                                            .padding(.horizontal, Theme.Spacing.xs)
                                            .padding(.vertical, Theme.Spacing.xs)
                                            .background(currentTheme.primaryAction.opacity(0.1))
                                            .cornerRadius(Theme.CornerRadius.small)
                                    } else {
                                        // Data row
                                        Text(cell.isEmpty ? "—" : cell)
                                            .bodySmall()
                                            .foregroundColor(cell.isEmpty ? currentTheme.secondaryText : currentTheme.primaryText)
                                            .italic(cell.isEmpty)
                                    }
                                }
                                .frame(minWidth: 100, alignment: .leading)
                                .padding(.trailing, Theme.Spacing.sm)
                            }
                        }
                        .padding(.vertical, Theme.Spacing.xs)
                        
                        if rowIndex < previewRows.count - 1 {
                            Divider()
                        }
                    }
                }
                .padding(Theme.Spacing.sm)
            }
            .background(currentTheme.cardBackground)
            .cornerRadius(Theme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .stroke(currentTheme.outline.opacity(0.5), lineWidth: 0.5)
            )
            
            Text("Showing first 3 rows of data")
                .labelSmall()
                .foregroundColor(currentTheme.secondaryText)
        }
        .padding(Theme.Spacing.md)
        .materialCard()
    }
}


#Preview {
    ImportPreviewView(
        session: CSVImportService.sampleSession(),
        onNext: {},
        onBack: {}
    )
}