# CSV Import Functionality Analysis

## Current Implementation Review

### How It's Currently Working

The CSV import does attempt to use ISBN for API lookups, but there's a critical issue with the implementation:

#### The Good ✅
1. **ISBN Detection**: The code correctly identifies when an ISBN is present in the CSV
2. **API Call Structure**: Uses `BookSearchService.shared.search(query: "isbn:\(cleanISBN)")`
3. **Fallback Strategy**: If ISBN lookup fails, it tries title/author search
4. **Caching**: Implements caching to avoid duplicate API calls

#### The Problem ❌
The ISBN search is formatted incorrectly for the Google Books API!

### Current Flow
```swift
// In CSVImportService.swift
if let isbn = parsedBook.isbn, !isbn.isEmpty {
    let cleanISBN = isbn.replacingOccurrences(of: "-", with: "").replacingOccurrences(of: " ", with: "")
    
    // This creates query: "isbn:9780451524935"
    let searchResult = await BookSearchService.shared.search(query: "isbn:\(cleanISBN)")
}

// In BookSearchService.swift
private func buildOptimizedQuery(_ query: String) -> String {
    // Problem: When it receives "isbn:9780451524935", it checks if the ENTIRE string is an ISBN
    if isISBN(trimmed) {  // This will be FALSE because "isbn:9780451524935" is not just digits!
        return "isbn:\(trimmed.replacingOccurrences(of: "-", with: ""))"
    }
    // ... so it falls through to general search
    return "intitle:\(trimmed) OR inauthor:\(trimmed) OR \(trimmed)"
    // Results in: "intitle:isbn:9780451524935 OR inauthor:isbn:9780451524935 OR isbn:9780451524935"
}
```

## The Issue

The `BookSearchService` is **double-processing** ISBN queries:
1. CSVImportService already formats it as `"isbn:1234567890"`
2. BookSearchService tries to detect if it's an ISBN again
3. Since `"isbn:1234567890"` doesn't pass the `isISBN()` check (it has "isbn:" prefix), it gets treated as a general search
4. This creates a malformed query that might not return the correct book

## Recommended Fix

### Option 1: Pass Raw ISBN (Preferred)
```swift
// In CSVImportService.swift
private func fetchMetadataFromISBN(_ isbn: String) async throws -> BookMetadata? {
    let cleanISBN = isbn.replacingOccurrences(of: "-", with: "").replacingOccurrences(of: " ", with: "")
    
    // Pass just the ISBN number, let BookSearchService handle formatting
    let searchResult = await BookSearchService.shared.search(query: cleanISBN)
    // BookSearchService will detect it's an ISBN and format as "isbn:1234567890"
}
```

### Option 2: Fix BookSearchService Detection
```swift
// In BookSearchService.swift
private func buildOptimizedQuery(_ query: String) -> String {
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    
    // Check if it's already an ISBN query
    if trimmed.hasPrefix("isbn:") {
        return trimmed  // Already formatted, use as-is
    }
    
    // Check if it's a raw ISBN
    if isISBN(trimmed) {
        return "isbn:\(trimmed.replacingOccurrences(of: "-", with: ""))"
    }
    // ... rest of the logic
}
```

## Verification Steps

To verify the issue:
1. Add logging to see the actual API query being sent
2. Test with a known ISBN from Goodreads export
3. Check if the book cover image is retrieved

## Expected Behavior

When importing a CSV with ISBN:
1. ✅ Parse ISBN from CSV
2. ✅ Clean ISBN (remove hyphens/spaces)
3. ✅ Query Google Books API: `https://www.googleapis.com/books/v1/volumes?q=isbn:9780451524935`
4. ✅ Receive full book metadata including cover image URL
5. ✅ Import book with cover image and all metadata

## Current Behavior

When importing a CSV with ISBN:
1. ✅ Parse ISBN from CSV
2. ✅ Clean ISBN
3. ❌ Query becomes malformed: `intitle:isbn:9780451524935 OR inauthor:isbn:9780451524935`
4. ❌ May not find the correct book or any results
5. ❌ Falls back to title/author search (less accurate)
6. ❌ May import without cover image

## Impact

- Books imported from CSV may lack cover images even when ISBN is available
- Metadata may be less accurate (wrong edition, missing details)
- Duplicate detection may fail if different metadata is retrieved

## Recommended Implementation

```swift
// CSVImportService.swift - Updated fetchMetadataFromISBN
private func fetchMetadataFromISBN(_ isbn: String) async throws -> BookMetadata? {
    let cleanISBN = isbn.replacingOccurrences(of: "-", with: "")
                        .replacingOccurrences(of: " ", with: "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
    
    // Add logging for debugging
    print("[CSV Import] Searching for book with ISBN: \(cleanISBN)")
    
    // Rate limiting
    try await Task.sleep(nanoseconds: 100_000_000)
    
    // Pass clean ISBN without prefix - let BookSearchService handle formatting
    let searchResult = await BookSearchService.shared.search(query: cleanISBN)
    
    switch searchResult {
    case .success(let books):
        if let book = books.first {
            print("[CSV Import] Found book via ISBN: \(book.title) - Has image: \(book.imageURL != nil)")
            return book
        } else {
            print("[CSV Import] No results for ISBN: \(cleanISBN)")
            return nil
        }
    case .failure(let error):
        print("[CSV Import] ISBN search failed: \(error.localizedDescription)")
        return nil
    }
}
```

This will ensure proper ISBN lookups and maximize the chance of getting book covers and accurate metadata.
