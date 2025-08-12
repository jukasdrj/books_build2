//
//  CulturalSelectionPickers.swift
//  books
//
//  Selection UI components for cultural diversity tracking
//  Provides standardized language and cultural background pickers
//

import SwiftUI

// MARK: - Language Selection Picker

struct LanguageSelectionPicker: View {
    @Binding var selectedLanguage: String?
    @Environment(\.appTheme) private var theme
    @State private var showingPicker = false
    @State private var searchText = ""
    
    private var filteredLanguages: [LanguageOption] {
        if searchText.isEmpty {
            return CulturalSelections.languages
        }
        return CulturalSelections.languages.filter { language in
            language.name.localizedCaseInsensitiveContains(searchText) ||
            language.id.localizedCaseInsensitiveContains(searchText) ||
            (language.nativeName?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            (language.region?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    var body: some View {
        Button {
            showingPicker = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Original Language")
                        .labelMedium()
                        .foregroundColor(theme.secondaryText)
                    
                    if let languageCode = selectedLanguage,
                       let language = CulturalSelections.language(for: languageCode) {
                        Text(language.displayName)
                            .bodyMedium()
                            .foregroundColor(theme.primaryText)
                    } else {
                        Text("Select language...")
                            .bodyMedium()
                            .foregroundColor(theme.secondaryText)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(theme.secondaryText)
            }
            .padding(Theme.Spacing.md)
            .materialCard()
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingPicker) {
            LanguagePickerModal(
                selectedLanguage: $selectedLanguage,
                searchText: $searchText
            )
        }
    }
}

struct LanguagePickerModal: View {
    @Binding var selectedLanguage: String?
    @Binding var searchText: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    
    private var filteredLanguages: [LanguageOption] {
        if searchText.isEmpty {
            return CulturalSelections.languages
        }
        return CulturalSelections.languages.filter { language in
            language.name.localizedCaseInsensitiveContains(searchText) ||
            language.id.localizedCaseInsensitiveContains(searchText) ||
            (language.nativeName?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            (language.region?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(theme.secondaryText)
                    
                    TextField("Search languages...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(Theme.Spacing.md)
                .background(theme.surfaceVariant)
                .cornerRadius(12)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.md)
                
                // Language list
                List {
                    // Clear selection option
                    Button {
                        selectedLanguage = nil
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "xmark.circle")
                                .foregroundColor(theme.error)
                            Text("No Original Language")
                                .bodyMedium()
                                .foregroundColor(theme.error)
                            Spacer()
                            if selectedLanguage == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(theme.primary)
                            }
                        }
                    }
                    .listRowBackground(theme.surface)
                    
                    ForEach(filteredLanguages) { language in
                        Button {
                            selectedLanguage = language.id
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                    Text(language.displayName)
                                        .bodyMedium()
                                        .foregroundColor(theme.primaryText)
                                    
                                    if let nativeName = language.nativeName {
                                        Text(nativeName)
                                            .labelMedium()
                                            .foregroundColor(theme.secondaryText)
                                    }
                                }
                                
                                Spacer()
                                
                                if selectedLanguage == language.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(theme.primary)
                                }
                            }
                        }
                        .listRowBackground(theme.surface)
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Select Language")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Cultural Background Selection Picker

struct CulturalBackgroundSelectionPicker: View {
    @Binding var selectedBackground: String?
    @Environment(\.appTheme) private var theme
    @State private var showingPicker = false
    @State private var searchText = ""
    
    var body: some View {
        Button {
            showingPicker = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Author's Cultural Background")
                        .labelMedium()
                        .foregroundColor(theme.secondaryText)
                    
                    if let backgroundId = selectedBackground,
                       let background = CulturalSelections.culturalBackground(for: backgroundId) {
                        Text(background.displayName)
                            .bodyMedium()
                            .foregroundColor(theme.primaryText)
                    } else {
                        Text("Select cultural background...")
                            .bodyMedium()
                            .foregroundColor(theme.secondaryText)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(theme.secondaryText)
            }
            .padding(Theme.Spacing.md)
            .materialCard()
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingPicker) {
            CulturalBackgroundPickerModal(
                selectedBackground: $selectedBackground,
                searchText: $searchText
            )
        }
    }
}

struct CulturalBackgroundPickerModal: View {
    @Binding var selectedBackground: String?
    @Binding var searchText: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    
    private var groupedBackgrounds: [String: [CulturalBackground]] {
        let filtered: [CulturalBackground]
        if searchText.isEmpty {
            filtered = CulturalSelections.culturalBackgrounds
        } else {
            filtered = CulturalSelections.culturalBackgrounds.filter { background in
                background.name.localizedCaseInsensitiveContains(searchText) ||
                background.continent.localizedCaseInsensitiveContains(searchText) ||
                (background.region?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        return Dictionary(grouping: filtered) { $0.continent }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(theme.secondaryText)
                    
                    TextField("Search cultural backgrounds...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(Theme.Spacing.md)
                .background(theme.surfaceVariant)
                .cornerRadius(12)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.md)
                
                // Cultural background list
                List {
                    // Clear selection option
                    Button {
                        selectedBackground = nil
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "xmark.circle")
                                .foregroundColor(theme.error)
                            Text("No Cultural Background")
                                .bodyMedium()
                                .foregroundColor(theme.error)
                            Spacer()
                            if selectedBackground == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(theme.primary)
                            }
                        }
                    }
                    .listRowBackground(theme.surface)
                    
                    ForEach(groupedBackgrounds.keys.sorted(), id: \.self) { continent in
                        Section(continent) {
                            ForEach(groupedBackgrounds[continent]?.sorted { $0.name < $1.name } ?? []) { background in
                                Button {
                                    selectedBackground = background.id
                                    dismiss()
                                } label: {
                                    HStack {
                                        Text(background.displayName)
                                            .bodyMedium()
                                            .foregroundColor(theme.primaryText)
                                        
                                        Spacer()
                                        
                                        if selectedBackground == background.id {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(theme.primary)
                                        }
                                    }
                                }
                                .listRowBackground(theme.surface)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Cultural Background")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Combined Cultural Section

struct CulturalSelectionSection: View {
    @Binding var originalLanguage: String?
    @Binding var authorNationality: String?
    
    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            LanguageSelectionPicker(selectedLanguage: $originalLanguage)
            CulturalBackgroundSelectionPicker(selectedBackground: $authorNationality)
        }
    }
}

#Preview {
    @Previewable @State var language: String? = "en"
    @Previewable @State var background: String? = "us"
    
    return VStack(spacing: 20) {
        LanguageSelectionPicker(selectedLanguage: $language)
        CulturalBackgroundSelectionPicker(selectedBackground: $background)
    }
    .padding()
    .preferredColorScheme(.dark)
}