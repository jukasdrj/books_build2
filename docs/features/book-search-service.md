# BookSearchService - Current Implementation

## Overview

The BookSearchService is a proxy-based book search service that provides intelligent book lookup capabilities through the CloudFlare Workers proxy. It supports multiple API providers with automatic fallback and provider-specific routing.

## Architecture

### Core Service
- **File**: `books/Services/BookSearchService.swift`
- **Pattern**: Singleton service (`BookSearchService.shared`)
- **Proxy URL**: `https://books-api-proxy.jukasdrj.workers.dev`

### Provider System
```swift
enum APIProvider: String, CaseIterable {
    case auto = ""            // Automatic provider selection
    case isbndb = "isbndb"     // ISBNdb API
    case google = "google"     // Google Books API  
    case openlibrary = "openlibrary" // Open Library API
    
    // Additional properties for UI display
    var displayName: String { ... }
    var systemImage: String { ... }
    var description: String { ... }
}
```

## Current Features ✅

### 1. Search Methods
- `search(query:sortBy:maxResults:includeTranslations:provider:)` - General search with provider selection
- `searchByAuthor(_:sortBy:maxResults:includeTranslations:)` - Author-specific search using "inauthor:" query
- `searchByTitle(_:sortBy:maxResults:includeTranslations:)` - Title-specific search using "intitle:" query
- `searchByISBN(_:provider:)` - Direct ISBN lookup with provider selection
- `searchWithFallback(query:sortBy:maxResults:includeTranslations:provider:)` - Search with automatic provider fallback
- `searchWithISBNDBFallback(query:sortBy:maxResults:)` - Search with ISBNdb-specific fallback chain
- `searchByISBNWithISBNDBFallback(_:provider:)` - ISBN lookup with ISBNdb fallback

### 2. Provider Routing
```swift
// CSV Imports → ISBNdb (best metadata quality)
let results = try await bookSearchService.searchByISBN(isbn, provider: .isbndb)

// User Search → Google Books (fastest, most comprehensive)
let results = try await bookSearchService.search(query: query, provider: .google)

// Fallback → Open Library (free tier)
let results = try await bookSearchService.search(query: query, provider: .openlibrary)
```

### 3. Intelligent Fallback Chain
1. **Primary Provider** (user specified or auto-selected)
2. **Secondary Fallback** - Automatic fallback to other providers
3. **Merge Results** - Combines metadata from multiple sources using `mergeBookMetadata(primary:secondary:)`
4. **Query Optimization** - Automatic query enhancement with `optimizeQuery(_:)`
5. **Duplicate Removal** - Advanced duplicate detection using `removeDuplicates(_:)`

### 4. Search Optimization
- **Query Optimization**: Automatically optimizes search queries with `optimizeQuery(_:)`
- **Duplicate Removal**: Advanced duplicate detection using title/author similarity
- **Relevance Scoring**: Custom scoring with `calculateRelevanceScore(_:query:)`
- **Popularity Scoring**: Publication recency and page count weighting with `calculatePopularityScore(_:)`
- **Result Sorting**: Multiple sort options (relevance, newest, popularity)
- **ISBN Detection**: Automatic ISBN format recognition with `isISBN(_:)`
- **String Similarity**: Levenshtein distance and fuzzy matching algorithms

### 5. Error Handling
```swift
enum BookError: Error {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case noData
    case proxyError(ProxyError)
}
```

## CloudFlare Proxy Integration

### Current Endpoints
- `GET /search?q={query}&provider={provider}` - Text search
- `GET /isbn?isbn={isbn}&provider={provider}` - ISBN lookup
- `GET /health` - Proxy health check

### Provider Fallback Chain
1. **Google Books** (primary) → fast, comprehensive results
2. **ISBNdb** → reliable ISBN lookups, good metadata
3. **Open Library** → free fallback option

### Response Headers
```
X-Cache: HIT-KV-HOT | HIT-R2-ARCHIVE | MISS
X-Provider: google-books | isbndb | open-library
X-Request-ID: {uuid}
X-Rate-Limit-Remaining: {count}
```

## Usage Patterns

### CSV Import Integration
```swift
// In CSVImportService - uses provider routing for better metadata
if let isbn = csvBook.isbn {
    // Force ISBNdb for CSV imports - better metadata quality
    let bookData = try await BookSearchService.shared.searchByISBN(isbn, provider: .isbndb)
}
```

### User Search Interface
```swift
// In SearchView - uses Google Books for speed
let results = try await BookSearchService.shared.search(
    query: searchQuery,
    provider: .google
)
```

### Author-Specific Search
```swift
let results = try await BookSearchService.shared.searchByAuthor(
    "Margaret Atwood",
    sortBy: .relevance
)
```

## Performance Characteristics

### Response Times (Typical)
- **Cache Hit**: ~50ms
- **Google Books**: 200-800ms
- **ISBNdb**: 500-1500ms  
- **Open Library**: 1000-3000ms

### Provider Strengths
- **Google Books**: Fast, comprehensive catalog, good search relevance
- **ISBNdb**: High-quality metadata, reliable ISBN lookups
- **Open Library**: Free tier, extensive catalog, slower responses

## Configuration

### Search Tips
The service provides built-in search tips:
```swift
let tips = BookSearchService.shared.searchTips
// Returns array of search optimization suggestions
```

### Sort Options
```swift
enum SortOption {
    case relevance  // Default - best match first
    case newest     // Publication date descending
    case popularity // Based on various popularity metrics
}
```

## Error Handling & Recovery

### Automatic Fallbacks
1. If primary provider fails → try secondary provider
2. If specific provider fails → fall back to auto selection
3. If all providers fail → return appropriate error

### Network Resilience
- Automatic retry with exponential backoff
- Graceful degradation when proxy is unavailable
- Local caching through CloudFlare edge network

## Security Features

### Input Validation
- ISBN checksum validation
- Query sanitization
- Protocol injection prevention

### Rate Limiting
- Proxy-level rate limiting with user fingerprinting
- Adaptive limits based on usage patterns
- Proper rate limit headers in responses

## Integration Points

### SwiftData Models
Results are automatically converted to:
- `BookMetadata` objects for storage
- Compatible with existing `UserBook` relationships

### Background Processing
- Fully compatible with background CSV imports
- Thread-safe for concurrent usage
- Proper error propagation for background tasks

## Future Enhancement Opportunities

### Potential Improvements
1. **Client-Side Caching**: Local result caching for offline access
2. **Search History**: User search pattern analysis
3. **Personalization**: Results ranking based on user preferences
4. **Batch Processing**: API-level batch support when providers offer it

### Provider Expansion
- Additional API providers (WorldCat, LibraryThing, etc.)
- Enhanced metadata sources for cultural diversity data
- Regional API providers for localized content

This service provides a robust, scalable foundation for book search with intelligent provider routing and comprehensive error handling.