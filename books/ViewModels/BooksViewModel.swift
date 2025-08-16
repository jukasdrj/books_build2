import SwiftUI
import Combine

final class BooksViewModel: ObservableObject {
    @Published var books: [BookMetadata] = []
    @Published var isLoading = false
    @Published var error: GoogleBooksError?

    private var cancellables = Set<AnyCancellable>()
    private let diagnostics = GoogleBooksDiagnostics.shared

    func searchBooks(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            // Clear state when query is empty
            books = []
            isLoading = false
            error = nil
            return
        }

        isLoading = true
        error = nil

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
                        self.error = .unknownError
                    }
                }
            )
            .store(in: &cancellables)
    }

    private func handleError(_ error: GoogleBooksError) {
        self.error = error
        
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

