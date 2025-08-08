# Books Reading Tracker - Documentation

## Overview

The Books Reading Tracker is a comprehensive iOS app built with SwiftUI and SwiftData that helps users track their reading habits with a special focus on cultural diversity. The app enables users to catalog books, track reading progress, and analyze the cultural representation in their reading choices with a polished, professional interface following Apple's design patterns.

## Core Features

### 📚 Library Management
- **Book Cataloging**: Add books manually or search online database (Google Books API)
- **Simplified Format Tracking**: Categorize books as Physical, E-book, or Audiobook
- **Reading Status Tracking**: To Read, Reading, Read, On Hold, Did Not Finish
- **Rating System**: 5-star rating system for personal book reviews
- **Personal Notes**: Private notes and reflections for each book
- **Tag System**: Organize books with custom tags for easy categorization
- **Cover Images**: Automatic cover image loading with intelligent caching
- **Integrated Wishlist**: Access wishlist items through filtering instead of separate tab

### 🎨 Multi-Theme System
- **5 Gorgeous Themes**: Purple Boho (default), Forest Sage, Ocean Blues, Sunset Warmth, Monochrome Elegance
- **Instant Theme Switching**: One-tap theme application with haptic feedback
- **Automatic Refresh**: Library view updates immediately when theme changes
- **Light/Dark Mode**: Full support for both color schemes across all themes

### 🌍 Cultural Diversity Tracking
- **Author Nationality**: Track the cultural background of authors
- **Original Language**: Record the original publication language
- **Translation Information**: Track translators and translated works
- **Cultural Regions**: Categorize books by cultural regions (Africa, Asia, Europe, Americas, etc.)
- **Diversity Analytics**: Visual charts showing reading diversity patterns
- **Cultural Goal Setting**: Set and track targets for diverse reading

### 📊 Statistics & Analytics
- **Reading Progress**: Monthly reading goals and progress tracking
- **Genre Breakdown**: Visual representation of reading genres
- **Format Distribution**: Track reading across Physical, E-book, and Audiobook formats
- **Cultural Distribution**: Charts showing cultural diversity in reading
- **Reading Pace**: Track reading speed and completion times
- **Progress Visualization**: Clean, scannable progress displays

### 🔍 Enhanced Search & Discovery
- **Online Search**: Integration with Google Books API for book discovery
- **Clean Results Display**: Year-only publication dates for better scannability
- **Advanced Filters**: Filter by status, rating, cultural information
- **Author Search**: Quick access to books by specific authors
- **Consistent Navigation**: Standard iOS disclosure indicators and navigation patterns

### 🎯 Smart Filtering System
- **Quick Filter Chips**: Horizontal scrolling chips for instant filtering (Reading Status, Wishlist)
- **Comprehensive Filter Sheet**: Detailed filtering options with reading status, wishlist, owned, favorites
- **Dynamic UI**: Context-aware titles and empty states based on active filters
- **Manual Refresh**: Refresh button for instant UI updates when needed

## Architecture

### Technology Stack
- **Framework**: SwiftUI (iOS 17+)
- **Persistence**: SwiftData with CloudKit sync capability
- **Design System**: Material Design 3 with adaptive dark/light mode
- **Image Caching**: Custom NSCache-based image management
- **Network**: URLSession for API calls with proper error handling

### Data Models

#### BookMetadata
Core book information including:
- Basic details (title, authors, ISBN, publisher)
- Publication information (date, page count, language)
- Cultural metadata (original language, author nationality, translator)
- Enhanced diversity tracking (cultural region, indigenous/marginalized voices)
- Reading experience data (difficulty level, content warnings, awards)
- **Simplified Format**: Physical, E-book, or Audiobook categories

#### UserBook
User-specific book tracking including:
- Reading status with automatic date tracking
- Personal ratings and notes
- Progress tracking (current page, reading sessions)
- Cultural goal contribution tracking
- Tag organization system
- Social features (recommendations, discussions)
- **Wishlist Integration**: `onWishlist` property for integrated wishlist functionality

### Key Components

#### Enhanced UI System
- **Apple Music/Photos Style Headers**: 16pt semibold headers with secondary color for optimal visual hierarchy
- **iOS Settings Layout**: Left-aligned labels with right-aligned values for familiar, scannable interface
- **Section Dividers**: Subtle dividers between content sections for better organization
- **Consistent Navigation**: Standard iOS disclosure indicators throughout

#### Multi-Theme System
- **5 Theme Variants**: Comprehensive color definitions for Purple Boho, Forest Sage, Ocean Blues, Sunset Warmth, Monochrome Elegance
- **Adaptive Colors**: Proper light/dark mode support with accessibility considerations
- **Theme Manager**: Centralized theme management with persistence and animation support
- **Real-time Updates**: Views automatically refresh when themes change

#### Views Architecture
- **TabView Navigation**: 4 main sections (Library, Search, Stats, Culture) with optimized NavigationStack
- **Modular Components**: Reusable BookCardView, BookRowView, StatusBadge, QuickFilterBar
- **Responsive Design**: Adaptive layouts for different screen sizes
- **Professional Polish**: Consistent with Apple's design patterns throughout

## UX Pathways

### Adding a New Book
1. **Search Online**: User searches Google Books database with clean, professional interface
2. **Select Book**: Choose from search results with year-only dates for better scannability
3. **Set Format**: Choose from Physical, E-book, or Audiobook (simplified from 6 options)
4. **Customize Details**: Edit/add cultural information and personal data
5. **Save to Library**: Book added with automatic status and date tracking

### Reading Progress Management
1. **Status Updates**: Prominent status selector in book header for easy access
2. **Progress Tracking**: Update current page and reading sessions
3. **Completion**: Mark as read with rating and notes
4. **Analytics Update**: Statistics automatically refresh with enhanced visualizations

### Cultural Diversity Analysis
1. **Diversity Dashboard**: Visual overview of reading cultural distribution
2. **Goal Setting**: Set targets for reading from different cultures
3. **Progress Monitoring**: Track progress toward diversity goals with clear metrics
4. **Insights**: Discover reading patterns and suggestions for improvement

### Theme Management
1. **Access Themes**: Open Settings → Theme to browse available themes
2. **Select Theme**: Tap any theme card to apply instantly with haptic feedback
3. **View Results**: Library view automatically refreshes with new theme colors
4. **Switch Anytime**: Change themes at any time with one-tap application

### Library Filtering
1. **Quick Filters**: Use horizontal chips for instant reading status filtering
2. **Wishlist Access**: Tap "💜 Wishlist" chip to view wishlist items
3. **Advanced Filters**: Tap filter button for comprehensive filtering options
4. **Clear Filters**: "Show All" button appears when filters are active

## Design Philosophy

### Apple Design Consistency
- **Native Patterns**: Follows iOS Settings, Apple Music, and Photos app design patterns
- **Familiar Navigation**: Standard disclosure indicators and navigation flows
- **Professional Polish**: Consistent typography, spacing, and visual hierarchy
- **Accessibility First**: Full VoiceOver support with improved layouts

### Cultural Sensitivity
- **Inclusive Language**: Respectful terminology throughout the app
- **Diverse Representation**: Color schemes inspired by global cultures
- **Educational Focus**: Emphasizes learning about different cultures through reading

### Reading-Focused Experience
- **Distraction-Free**: Clean interface focused on books and reading (removed unnecessary features like favorites)
- **Simplified Choices**: Streamlined format options reduce decision fatigue
- **Personal Journey**: Emphasizes individual reading growth and discovery
- **Data Privacy**: All personal notes and ratings remain private

### Adaptive Interface
- **Dark Mode**: Full support with proper contrast ratios
- **Dynamic Type**: Scales with user's preferred text size
- **Color Accessibility**: High contrast options and colorblind-friendly design
- **Enhanced Scannability**: iOS Settings-style layouts for easy information consumption

## Integration Points

### External Services
- **Google Books API**: Book search and metadata retrieval with enhanced date formatting
- **Image CDN**: Cover image loading with fallback options

### System Integration
- **iCloud Sync**: Automatic backup and sync across devices (planned)
- **Shortcuts**: Siri integration for quick book status updates (planned)
- **Widget Support**: Home screen widgets for reading progress (planned)

## Performance Considerations

### Image Management
- **Smart Caching**: NSCache-based system with memory pressure handling
- **Lazy Loading**: Images load only when needed
- **Retry Logic**: Automatic retry for failed image loads

### Data Optimization
- **SwiftData Efficiency**: Optimized queries and relationship management
- **Simplified Data Model**: Reduced enum complexity for better performance
- **Background Processing**: Non-blocking API calls and data processing
- **Memory Management**: Proper cleanup and resource management

## Recent Enhancements

### UI Polish & Consistency
- **Search Results**: Removed double arrows, implemented year-only date display
- **Book Details**: Redesigned with Apple Music-style headers and iOS Settings layout
- **Status Management**: Moved status selector to prominent header position
- **Visual Hierarchy**: Enhanced typography and spacing throughout

### Feature Simplification
- **Format Options**: Reduced from 6 complex options to 3 clear categories (Physical, E-book, Audiobook)
- **Interface Cleanup**: Removed unnecessary favorite/heart functionality for focused reading experience
- **Navigation Consistency**: Standardized disclosure indicators across all views

### Technical Improvements
- **Clean Migration**: Implemented database reset for enum compatibility
- **Enhanced Accessibility**: Improved layouts and navigation for all users
- **Performance Optimization**: Simplified data models and reduced complexity

### Multi-Theme System
- **5 Gorgeous Themes**: Purple Boho, Forest Sage, Ocean Blues, Sunset Warmth, Monochrome Elegance
- **Instant Application**: One-tap theme switching with haptic feedback
- **Automatic Refresh**: Library view updates immediately when theme changes
- **Settings Integration**: Direct access to theme picker from Settings view

### Integrated Filtering
- **Wishlist Integration**: Wishlist items accessible through filtering instead of separate tab
- **Quick Filter Chips**: Horizontal chips for instant reading status filtering
- **Comprehensive Filter Sheet**: Detailed filtering options with wishlist, owned, favorites
- **Dynamic UI**: Context-aware titles and empty states based on active filters

## Screenshot Mode (App Store Asset Generation)

- To create professional, on-brand screenshots, enable Screenshot Mode via launch argument or environment variable.
- When enabled:
    - Launches with seeded demo books for “hero” states in Library, Search, Stats, Diversity, and Theme picker.
    - Automatically switches to light mode for App Store consistency.
    - Disables popups, network noise, and onboarding modals for clean screenshots.
    - Adds a purple “Screenshot Mode” banner for visual clarity that demo data is active.
- Usage:  
    - In Xcode: Product > Scheme > Edit Scheme > Arguments > add `screenshotMode`
    - Or set `SCREENSHOT_MODE=1` in the environment.

### Benefits

- One-click to reproduce screenshot-ready hero scenes on any device or simulator (iPhone/iPad).
- Ensures App Store submissions are pixel-perfect and safe for reviewers/marketing.
- Will not affect end-user builds or production data.

## Future Expansion

The app is designed with extensibility in mind:
- **Social Features**: Book clubs and friend recommendations
- **Reading Challenges**: Community-driven reading goals
- **Enhanced Analytics**: More detailed reading insights with improved visualizations
- **Export Capabilities**: Reading data export for external analysis
- **Additional APIs**: Integration with library systems and bookstores
- **Cross-Platform**: Potential macOS and watchOS companions

The Books Reading Tracker provides a professional, polished reading management experience that emphasizes cultural diversity while maintaining simplicity and usability. The interface follows Apple's design patterns to create a familiar, native experience that serious readers will appreciate, enhanced with gorgeous multi-theme options and integrated filtering.