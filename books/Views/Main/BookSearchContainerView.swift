import SwiftUI

struct BookSearchContainerView: View {
    @StateObject private var viewModel = BooksViewModel()
    @State private var searchText = ""
    #if DEBUG
    @State private var showDebugConsole = false
    #endif

    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.isLoading {
                    ProgressView("Searching...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = viewModel.errorMessage {
                    EnhancedErrorView(
                        title: "Search Error",
                        message: viewModel.errorDetails.map { "\(errorMessage)\n\n\($0)" } ?? errorMessage,
                        retryAction: {
                            viewModel.searchBooks(query: searchText)
                        }
                    )
                } else {
                    BookListView(books: viewModel.books)
                }
            }
            .searchable(text: $searchText)
            .onSubmit(of: .search) {
                viewModel.searchBooks(query: searchText)
            }
            .navigationTitle("Book Search")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Export Diagnostics") {
                            let report = viewModel.exportDiagnostics()
                            // Share or save the report
                            print(report)
                        }
                        #if DEBUG
                        Divider()
                        Button("Check Keychain API Key") {
                            print(KeychainService.shared.loadAPIKeyForDebug())
                        }
                        Button("Open Debug Console") {
                            showDebugConsole = true
                        }
                        #endif
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            #if DEBUG
            .sheet(isPresented: $showDebugConsole) {
                DebugConsoleView()
            }
            #endif
        }
    }
}

struct BookListView: View {
    let books: [BookMetadata]

    var body: some View {
        if books.isEmpty {
            // Empty placeholder when there's no active error but also no results
            VStack(spacing: 12) {
                Image(systemName: "book")
                    .font(.system(size: 40))
                    .foregroundColor(.secondary)
                Text("Start typing to search for books")
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(books) { book in
                NavigationLink(value: book) {
                    SearchResultRow(book: book)
                }
            }
            .listStyle(.plain)
        }
    }
}
