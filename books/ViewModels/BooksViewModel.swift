import SwiftUI
import Combine

final class BooksViewModel: ObservableObject {
    @Published var books: [BookMetadata] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var errorDetails: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let diagnostics = GoogleBooksDiagnostics.shared
    
    func searchBooks(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            // Clear state when query is empty
            books = []
            isLoading = false
            errorMessage = nil
            errorDetails = nil
            return
        }
        
        isLoading = true
        errorMessage = nil
        errorDetails = nil
        
        GoogleBooksService.shared.searchBooks(query: trimmed)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isLoading = false
                    if case .failure(let error) = completion {
                        self.handleError(error)
                    }
                },
                receiveValue: { [weak self] books in
                    guard let self = self else { return }
                    self.books = books
                    if books.isEmpty {
                        self.errorMessage = "No results found"
                        self.errorDetails = "Try a different search term"
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    private func handleError(_ error: GoogleBooksError) {
        errorMessage = error.errorDescription
        errorDetails = error.recoverySuggestion
        
        // Log to console for debugging
        print("🔴 Search Error: \(error.errorDescription ?? "Unknown")")
        if let suggestion = error.recoverySuggestion {
            print("💡 Suggestion: \(suggestion)")
        }
    }
    
    func exportDiagnostics() -> String {
        return diagnostics.exportDiagnostics()
    }
}

