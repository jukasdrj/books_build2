# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Common Development Commands

### Building the App

```bash
# Build for iPhone 16 simulator
xcodebuild -project books.xcodeproj -scheme books -destination 'platform=iOS Simulator,name=iPhone 16' build

# Build using MCP tools (when available)
call_mcp_tool build_sim { "projectPath": "books.xcodeproj", "scheme": "books", "simulatorName": "iPhone 16" }
```

### Running Tests

```bash
# Run all tests
xcodebuild test -project books.xcodeproj -scheme books -destination 'platform=iOS Simulator,name=iPhone 16'

# Run specific test class
xcodebuild test -project books.xcodeproj -scheme books -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:booksTests/CulturalDiversityTests

# Using MCP tools
call_mcp_tool test_sim { "projectPath": "books.xcodeproj", "scheme": "books", "simulatorName": "iPhone 16" }
```

### Server/API Testing

```bash
# Test CloudFlare Worker staging deployment
cd server && ./test-staging.sh

# Comprehensive optimization tests
cd server && ./comprehensive-test.sh

# Test hybrid cache system
cd server/books-api-proxy && ./test-hybrid-cache.sh
```

### CloudFlare Deployment

```bash
# Deploy books API proxy
cd server/books-api-proxy
npx wrangler deploy --env=""

# Deploy with R2+KV hybrid cache
./deploy-r2-cache.sh

# Set API secrets (required)
npx wrangler secret put google1  # Primary Google Books API key
npx wrangler secret put ISBNdb1  # ISBNdb API key
```

## Architecture Overview

### iOS App Structure

**Entry Point**: `books/App/booksApp.swift`
- Initializes SwiftData ModelContainer with UserBook, BookMetadata, and AuthorProfile models
- Sets up UnifiedThemeStore with 11 theme variants (5 Material Design 3 + 6 Liquid Glass)
- Implements iOS 26 Progressive Enhancement with fallbacks

**Main Navigation**: `books/Views/Main/ContentView.swift`
- Three-tab navigation: Library, Search, Reading Insights
- Automatic one-time migration system for AuthorProfile data
- Modern NavigationStack with value-based routing

### Data Layer (SwiftData)

**Core Models**:
- `UserBook`: Personal reading data with status tracking, ratings, cultural metadata
- `BookMetadata`: Book information from APIs with AuthorProfile relationships
- `AuthorProfile`: Centralized author cultural data with multi-API identifier support

**Migration Strategy**: Safe conversion from string-based authors to AuthorProfile entities with UserDefaults tracking

### Service Architecture

**Primary Services**:
- `BookSearchService`: CloudFlare-optimized search with intelligent caching
  - Endpoints: `https://books-api-proxy.jukasdrj.workers.dev` (primary)
  - Custom domain: `https://books.ooheynerds.com` (configured)
- `AuthorService`: Author profile management and cultural data enhancement
- `CSVImportService`: Goodreads import with background processing
- `CacheWarmer`: Automatic pre-loading of new releases and popular books

**Progressive Enhancement Bridge** (`books/iOS26/iOS26NativeAPIBridge.swift`):
- `.progressiveGlassEffect(material:level:)` - Native .glassEffect with fallbacks
- `.progressiveGlassButton(style:)` - Native .buttonStyle(.glass) with fallbacks
- `.progressiveGlassContainer(content:)` - Native GlassEffectContainer with fallbacks

### CloudFlare Infrastructure

**Multi-tier Caching**:
- KV namespace for hot cache (100k reads/day free tier)
- R2 bucket for cold cache (10M reads/month free tier)
- Smart promotion: R2 hits automatically promoted to KV
- 30-day TTL for searches, 1-year for ISBN lookups

**API Provider Chain**:
1. Google Books (primary)
2. ISBNdb (premium fallback - 31M+ ISBNs)
3. Open Library (free fallback)

**Automatic Cache Warming** (Cron-scheduled):
- Daily 2AM UTC: New releases (last 7 days)
- Weekly Monday 3AM UTC: Popular authors
- Monthly 1st 4AM UTC: Historical bestsellers

## Critical Configuration

### Required API Keys

```bash
# CloudFlare secrets (production)
google1         # Primary Google Books API key
google2         # Backup Google Books API key (optional)
ISBNdb1         # ISBNdb API key (required for fallback)
GOOGLE_SEARCH_API_KEY  # For enhanced author data (configured)
```

### Test Environment Variables

When running tests or debugging, these environment variables are configured in the Xcode scheme:
- `GOOGLE_BOOKS_TEST_MODE=1`
- `GOOGLE_BOOKS_LOG_LEVEL=verbose`
- Launch arguments: `-com.apple.CoreData.SQLDebug 1` and `-APILoggingEnabled YES`

### KV/R2 Resources

Existing CloudFlare resources (do not recreate):
- KV namespace: `BOOKS_CACHE` (already created)
- R2 buckets: `books-cache` and `books-cache-preview` (already created)

## iOS 26 Migration Status

### Completed Components (Stage 4)
- ✅ SearchView with auto-focus and English-first filtering
- ✅ BookDetailsView and EditBookView with progressive glass effects
- ✅ QuickFilterBar with 14+ filtering criteria
- ✅ SearchHistoryService with smart suggestions
- ✅ Skeleton loading states with shimmer effects
- ✅ All 25+ compilation errors resolved

### Testing Infrastructure

**Test Foundation** (`BookTrackerTestSuite.swift`):
- In-memory ModelContainer for isolated testing
- Swift 6 concurrency with @MainActor isolation
- Cultural diversity test data generators

**Protocol-Based Mocking** (`ServiceProtocols.swift`):
- Complete mock implementations for all services
- Configurable error states and performance tracking
- Dependency injection ready

**Test Coverage**:
- Models: 95% coverage
- Services: 90% coverage with mocks
- Cultural features: 100% coverage
- UI/Accessibility: 90% WCAG compliance

## Cultural Diversity Features

The app strongly emphasizes cultural diversity tracking:

**Author Demographics**:
- Nationality, gender (Female, Male, Non-binary, Other, Not specified)
- Cultural background and marginalized voice tracking

**Regional Categorization**:
- Africa, Asia, Europe, Americas, Oceania
- Original language and translation tracking

**Visual Analytics**:
- Reading Insights tab combines stats and cultural diversity
- Progress tracking toward diversity goals

## Quick Troubleshooting

### Build Failures
- Ensure Xcode 16 beta 2 or later
- Target iOS 18.0 minimum deployment
- SwiftData requires iOS 17.0+ for @Model macro

### API Issues
- Verify CloudFlare secrets are set: `npx wrangler secret list`
- Check worker logs: `npx wrangler tail`
- Test health endpoint: `curl https://books-api-proxy.jukasdrj.workers.dev/health`

### Theme System Issues
- UnifiedThemeStore manages 11 variants
- Progressive enhancement requires iOS 26 for native effects
- Fallbacks automatically apply for older iOS versions

### Migration Issues
- AuthorProfile migration runs once on app startup
- Check UserDefaults key `hasPerformedAuthorMigration`
- Manual trigger: `AuthorService.migrateAllBooksToAuthorProfiles()`

## Performance Optimization Tips

### CloudFlare Cache
- Monitor cache hit rates via `/health` endpoint
- Expected 90%+ hit rate within 30 days
- Cache warming runs automatically via cron jobs

### SwiftData Queries
- Use batch operations for CSV imports
- Concurrent ISBN lookups limited to 10-20 requests
- Background processing with iOS BackgroundTasks

### UI Performance
- Skeleton loading states prevent layout shift
- Adaptive debouncing for search (200-500ms)
- Spring physics animations with proper cleanup
