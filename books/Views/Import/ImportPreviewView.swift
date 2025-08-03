//
//  ImportPreviewView.swift
//  books
//
//  Preview parsed CSV data before import
//

import SwiftUI

struct ImportPreviewView: View {
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
                    
                    // Sample data preview
                    SampleDataPreview(session: session)
                    
                    // Column detection
                    ColumnDetectionCard(session: session)
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
            .background(Color.theme.surface)
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
    let session: CSVImportSession
    
    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: "doc.text")
                    .font(.system(size: 24))
                    .foregroundColor(Color.theme.primaryAction)
                
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(session.fileName)
                        .titleMedium()
                        .foregroundColor(Color.theme.primaryText)
                    
                    HStack(spacing: Theme.Spacing.md) {
                        Label("\(session.fileSize.formattedFileSize)", systemImage: "internaldrive")
                        Label("\(session.totalRows) books", systemImage: "book")
                        Label("\(session.detectedColumns.count) columns", systemImage: "tablecells")
                    }
                    .labelSmall()
                    .foregroundColor(Color.theme.secondaryText)
                }
                
                Spacer()
                
                // Format validation indicator
                VStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: session.isValidGoodreadsFormat ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(session.isValidGoodreadsFormat ? Color.theme.success : Color.theme.warning)
                    
                    Text(session.isValidGoodreadsFormat ? "Valid" : "Check Format")
                        .labelSmall()
                        .foregroundColor(session.isValidGoodreadsFormat ? Color.theme.success : Color.theme.warning)
                }
            }
            .padding(Theme.Spacing.md)
            
            Divider()
        }
        .background(Color.theme.surface)
    }
}

// MARK: - Detection Results Card

struct DetectionResultsCard: View {
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
                    .foregroundColor(Color.theme.primaryAction)
                Text("Smart Detection Results")
                    .titleSmall()
                    .foregroundColor(Color.theme.primaryText)
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
                    .foregroundColor(hasEssentials ? Color.theme.success : Color.theme.warning)
                
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(hasEssentials ? "Ready for Automated Import" : "Manual Mapping Required")
                        .bodyMedium()
                        .foregroundColor(Color.theme.primaryText)
                        .fontWeight(.medium)
                    
                    Text(hasEssentials ? 
                         "Found essential columns. Import will proceed automatically." :
                         "Missing essential columns. You'll need to map them manually.")
                        .bodySmall()
                        .foregroundColor(Color.theme.secondaryText)
                }
            }
            .padding(Theme.Spacing.sm)
            .background(hasEssentials ? Color.theme.successContainer : Color.theme.warningContainer)
            .cornerRadius(Theme.CornerRadius.small)
        }
        .padding(Theme.Spacing.md)
        .materialCard()
    }
}

struct SmartMetricCard: View {
    let icon: String
    let label: String
    let status: Bool
    let description: String
    
    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: icon)
                    .foregroundColor(status ? Color.theme.success : Color.theme.secondaryText)
                
                Image(systemName: status ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(status ? Color.theme.success : Color.theme.error)
            }
            
            VStack(spacing: Theme.Spacing.xs) {
                Text(label)
                    .labelMedium()
                    .foregroundColor(Color.theme.primaryText)
                    .fontWeight(.medium)
                
                Text(description)
                    .labelSmall()
                    .foregroundColor(Color.theme.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.sm)
        .background(status ? Color.theme.successContainer.opacity(0.3) : Color.theme.surfaceVariant)
        .cornerRadius(Theme.CornerRadius.small)
    }
}

// MARK: - Sample Data Preview

struct SampleDataPreview: View {
    let session: CSVImportSession
    
    private var previewRows: [[String]] {
        Array(session.sampleData.prefix(4)) // Header + 3 rows
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "eye")
                    .foregroundColor(Color.theme.primaryAction)
                Text("Data Preview")
                    .titleSmall()
                    .foregroundColor(Color.theme.primaryText)
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
                                            .foregroundColor(Color.theme.primaryAction)
                                            .padding(.horizontal, Theme.Spacing.xs)
                                            .padding(.vertical, Theme.Spacing.xs)
                                            .background(Color.theme.primaryAction.opacity(0.1))
                                            .cornerRadius(Theme.CornerRadius.small)
                                    } else {
                                        // Data row
                                        Text(cell.isEmpty ? "—" : cell)
                                            .bodySmall()
                                            .foregroundColor(cell.isEmpty ? Color.theme.secondaryText : Color.theme.primaryText)
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
            .background(Color.theme.cardBackground)
            .cornerRadius(Theme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .stroke(Color.theme.outline.opacity(0.5), lineWidth: 0.5)
            )
            
            Text("Showing first 3 rows of data")
                .labelSmall()
                .foregroundColor(Color.theme.secondaryText)
        }
        .padding(Theme.Spacing.md)
        .materialCard()
    }
}

// MARK: - Column Detection Card

struct ColumnDetectionCard: View {
    let session: CSVImportSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "tablecells")
                    .foregroundColor(Color.theme.primaryAction)
                Text("Column Detection")
                    .titleSmall()
                    .foregroundColor(Color.theme.primaryText)
            }
            
            LazyVStack(spacing: Theme.Spacing.sm) {
                ForEach(session.detectedColumns) { column in
                    ColumnDetectionRow(column: column)
                }
            }
        }
        .padding(Theme.Spacing.md)
        .materialCard()
    }
}

struct ColumnDetectionRow: View {
    let column: CSVColumn
    
    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Status indicator
            Circle()
                .fill(column.mappedField != nil ? Color.theme.success : Color.theme.outline)
                .frame(width: 8, height: 8)
            
            // Column info
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(column.originalName)
                    .bodyMedium()
                    .foregroundColor(Color.theme.primaryText)
                
                if let mappedField = column.mappedField {
                    Text("→ \(mappedField.displayName)")
                        .labelSmall()
                        .foregroundColor(Color.theme.success)
                } else {
                    Text("Not mapped")
                        .labelSmall()
                        .foregroundColor(Color.theme.secondaryText)
                }
            }
            
            Spacer()
            
            // Sample data
            if column.hasSampleData {
                VStack(alignment: .trailing, spacing: Theme.Spacing.xs) {
                    Text("Sample:")
                        .labelSmall()
                        .foregroundColor(Color.theme.secondaryText)
                    
                    Text(column.sampleValues.first ?? "")
                        .labelSmall()
                        .foregroundColor(Color.theme.primaryText)
                        .lineLimit(1)
                        .frame(maxWidth: 100, alignment: .trailing)
                }
            }
        }
        .padding(.vertical, Theme.Spacing.xs)
    }
}

#Preview {
    ImportPreviewView(
        session: CSVImportService.sampleSession(),
        onNext: {},
        onBack: {}
    )
}