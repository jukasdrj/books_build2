//
//  ColumnMappingView.swift
//  books
//
//  Interface for mapping CSV columns to book fields
//

import SwiftUI

struct ColumnMappingView: View {
    @Environment(\.appTheme) private var currentTheme
    let session: CSVImportSession
    @Binding var columnMappings: [String: BookField]
    let onNext: () -> Void
    let onBack: () -> Void
    
    @State private var searchText = ""
    
    private var requiredMappingsComplete: Bool {
        let requiredFields: Set<BookField> = [.title, .author]
        let mappedFields = Set(columnMappings.values)
        return requiredFields.isSubset(of: mappedFields)
    }
    
    private var filteredColumns: [CSVColumn] {
        if searchText.isEmpty {
            return session.detectedColumns
        } else {
            return session.detectedColumns.filter { column in
                column.originalName.localizedCaseInsensitiveContains(searchText) ||
                column.mappedField?.displayName.localizedCaseInsensitiveContains(searchText) == true
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            MappingHeader(
                totalColumns: session.detectedColumns.count,
                mappedColumns: columnMappings.count,
                requiredComplete: requiredMappingsComplete
            )
            
            // Search bar
            SearchBar(searchText: $searchText)
            
            // Column mappings list
            ScrollView {
                LazyVStack(spacing: Theme.Spacing.sm) {
                    ForEach(filteredColumns) { column in
                        ColumnMappingRow(
                            column: column,
                            selectedField: columnMappings[column.originalName],
                            onFieldSelected: { field in
                                if let field = field {
                                    columnMappings[column.originalName] = field
                                } else {
                                    columnMappings.removeValue(forKey: column.originalName)
                                }
                            }
                        )
                    }
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
                
                Button("Start Import") {
                    onNext()
                }
                .materialButton(style: .filled, size: .large)
                .frame(maxWidth: .infinity)
                .disabled(!requiredMappingsComplete)
            }
            .padding(Theme.Spacing.md)
            .background(currentTheme.surface)
        }
    }
}

// MARK: - Mapping Header

struct MappingHeader: View {
    @Environment(\.appTheme) private var currentTheme
    let totalColumns: Int
    let mappedColumns: Int
    let requiredComplete: Bool
    
    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Map Columns")
                        .titleLarge()
                        .foregroundColor(currentTheme.primaryText)
                    
                    Text("Connect your CSV columns to book fields")
                        .bodyMedium()
                        .foregroundColor(currentTheme.secondaryText)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: Theme.Spacing.xs) {
                    Text("\(mappedColumns)/\(totalColumns)")
                        .titleMedium()
                        .foregroundColor(currentTheme.primaryAction)
                        .fontWeight(.bold)
                    
                    Text("mapped")
                        .labelSmall()
                        .foregroundColor(currentTheme.secondaryText)
                }
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(currentTheme.outline.opacity(0.3))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(currentTheme.primaryAction)
                        .frame(
                            width: geometry.size.width * (totalColumns > 0 ? Double(mappedColumns) / Double(totalColumns) : 0),
                            height: 4
                        )
                        .cornerRadius(2)
                        .animation(.easeInOut(duration: 0.3), value: mappedColumns)
                }
            }
            .frame(height: 4)
            
            // Required fields status
            if !requiredComplete {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "exclamationmark.circle")
                        .foregroundColor(currentTheme.warning)
                    
                    Text("Title and Author columns are required")
                        .bodySmall()
                        .foregroundColor(currentTheme.secondaryText)
                }
                .padding(Theme.Spacing.sm)
                .background(currentTheme.warningContainer)
                .cornerRadius(Theme.CornerRadius.small)
            }
            
            Divider()
        }
        .padding(Theme.Spacing.md)
        .background(currentTheme.surface)
    }
}

// MARK: - Search Bar

struct SearchBar: View {
    @Environment(\.appTheme) private var currentTheme
    @Binding var searchText: String
    
    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(currentTheme.secondaryText)
            
            TextField("Search columns...", text: $searchText)
                .bodyMedium()
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(currentTheme.secondaryText)
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(currentTheme.surfaceVariant)
        .cornerRadius(Theme.CornerRadius.medium)
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.sm)
    }
}

// MARK: - Column Mapping Row

struct ColumnMappingRow: View {
    @Environment(\.appTheme) private var currentTheme
    let column: CSVColumn
    let selectedField: BookField?
    let onFieldSelected: (BookField?) -> Void
    
    @State private var showingFieldPicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Main row
            HStack(spacing: Theme.Spacing.md) {
                // Column info
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(column.originalName)
                        .bodyMedium()
                        .foregroundColor(currentTheme.primaryText)
                        .fontWeight(.medium)
                    
                    if column.hasSampleData {
                        Text("Sample: \(column.sampleValues.first ?? "")")
                            .labelSmall()
                            .foregroundColor(currentTheme.secondaryText)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Field selection
                Button(action: { showingFieldPicker = true }) {
                    HStack(spacing: Theme.Spacing.xs) {
                        if let field = selectedField {
                            VStack(alignment: .trailing, spacing: Theme.Spacing.xs) {
                                Text(field.displayName)
                                    .bodyMedium()
                                    .foregroundColor(currentTheme.primaryAction)
                                
                                if field.isRequired {
                                    Text("Required")
                                        .labelSmall()
                                        .foregroundColor(currentTheme.success)
                                        .fontWeight(.medium)
                                }
                            }
                        } else {
                            Text("Select field...")
                                .bodyMedium()
                                .foregroundColor(currentTheme.secondaryText)
                        }
                        
                        Image(systemName: "chevron.down")
                            .labelSmall()
                            .foregroundColor(currentTheme.secondaryText)
                    }
                }
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, Theme.Spacing.xs)
                .background(currentTheme.surfaceVariant)
                .cornerRadius(Theme.CornerRadius.small)
            }
            
            // Sample values (if any)
            if column.hasSampleData && column.sampleValues.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.Spacing.xs) {
                        ForEach(Array(column.sampleValues.prefix(3).enumerated()), id: \.offset) { _, value in
                            Text(value)
                                .labelSmall()
                                .foregroundColor(currentTheme.secondaryText)
                                .padding(.horizontal, Theme.Spacing.xs)
                                .padding(.vertical, 2)
                                .background(currentTheme.outline.opacity(0.1))
                                .cornerRadius(Theme.CornerRadius.small)
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.xs)
                }
            }
        }
        .padding(Theme.Spacing.md)
        .materialCard()
        .confirmationDialog(
            "Map \(column.originalName)",
            isPresented: $showingFieldPicker,
            titleVisibility: .visible
        ) {
            Button("None") {
                onFieldSelected(nil)
            }
            
            ForEach(BookField.allCases) { field in
                Button(field.displayName + (field.isRequired ? " (Required)" : "")) {
                    onFieldSelected(field)
                }
            }
            
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Choose which book field this column should map to.")
        }
    }
}

#Preview {
    ColumnMappingView(
        session: CSVImportService.sampleSession(),
        columnMappings: .constant([
            "Title": .title,
            "Author": .author,
            "My Rating": .rating
        ]),
        onNext: {},
        onBack: {}
    )
}