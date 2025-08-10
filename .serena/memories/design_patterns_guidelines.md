# Design Patterns & Guidelines

## Core Design Philosophy
### Purple Boho Aesthetic
- **Default Theme**: Rich purples, dusty roses, warm earth tones
- **Visual Hierarchy**: Golden star ratings, cultural diversity badges
- **Cards**: Fixed 140x260 dimensions for uniform grid layout
- **Gradients**: Subtle background gradients for depth and warmth

### Material Design 3 Implementation
- **Component System**: All UI uses `.materialCard()`, `.materialButton()`, `.materialInteractive()`
- **Spacing System**: 8pt grid with `Theme.Spacing` constants
- **Elevation**: Proper shadows and depth for interactive elements
- **Adaptive Colors**: Automatic light/dark mode support

## Key Design Patterns

### Multi-Theme Architecture
- **5 Theme Variants**: Purple Boho, Forest Sage, Ocean Blues, Sunset Warmth, Monochrome
- **Instant Switching**: Theme changes propagate immediately across all views
- **Persistent Storage**: Theme preferences saved and restored
- **Reactive Updates**: `@Bindable ThemeStore` ensures proper view updates

### Navigation Architecture
- **Consolidated Routing**: Single navigation destination per type at ContentView
- **Value-Based Navigation**: `NavigationLink(value:)` with centralized handling
- **Warning-Free**: Eliminates multiple navigationDestination conflicts
- **Stable Performance**: No multiple updates per frame

### Data Flow Patterns
- **SwiftData Integration**: Models use `@Model` with proper Hashable implementation
- **Navigation Compatibility**: Use `modelContext.fetch()` not `@Query` in destinations  
- **State Management**: Clear separation of view state vs. persistent data
- **Migration Support**: Fallback strategies for schema changes

## UI Component Guidelines

### Book Cards (`BookCardView`)
- Fixed dimensions for grid consistency
- Golden star ratings with amber colors
- Cultural language badges with theme colors
- Clean, gesture-free interaction (tap only)

### Import System
- **5-Step Flow**: Select → Preview → Map → Import → Complete
- **Smart Detection**: Automatic Goodreads column recognition
- **Fallback Strategies**: ISBN → Title/Author → CSV data preservation
- **Beautiful Integration**: Accessible from Settings and empty states

### Cultural Diversity Features
- **Progress Visualization**: Beautiful rings and emoji indicators
- **Regional Tracking**: Africa, Asia, Europe, Americas categorization
- **Language Support**: Original language and translation tracking
- **Goal Setting**: Cultural diversity targets and progress

## Performance Guidelines

### Image Loading
- **In-Memory Cache**: `ImageCache` for book covers
- **Async Loading**: Non-blocking image downloads
- **Placeholder System**: Purple boho gradients for missing covers
- **Shimmer Effects**: Loading states with theme-appropriate animations

### Data Operations
- **Batch Processing**: Efficient CSV import with progress tracking
- **Duplicate Detection**: ISBN-first strategy with title/author fallback
- **Background Operations**: Heavy processing off main thread
- **Error Handling**: Graceful failure with user feedback

## Accessibility Considerations
- **VoiceOver Support**: Proper accessibility labels and hints
- **Dynamic Type**: Text scales with user preferences
- **High Contrast**: Themes work with accessibility settings
- **Touch Targets**: Minimum 44pt touch targets for all interactive elements