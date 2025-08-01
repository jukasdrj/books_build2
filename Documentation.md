# Books Reading Tracker - Documentation

## Overview

The Books Reading Tracker is a comprehensive iOS app built with SwiftUI and SwiftData that helps users track their reading habits with a special focus on cultural diversity. The app enables users to catalog books, track reading progress, and analyze the cultural representation in their reading choices.

## Core Features

### 📚 Library Management
- **Book Cataloging**: Add books manually or search online database (Google Books API)
- **Reading Status Tracking**: To Read, Reading, Read, On Hold, Did Not Finish
- **Rating System**: 5-star rating system for personal book reviews
- **Personal Notes**: Private notes and reflections for each book
- **Cover Images**: Automatic cover image loading with intelligent caching

### 🌍 Cultural Diversity Tracking
- **Author Nationality**: Track the cultural background of authors
- **Original Language**: Record the original publication language
- **Translation Information**: Track translators and translated works
- **Cultural Regions**: Categorize books by cultural regions (Africa, Asia, Europe, Americas, etc.)
- **Diversity Analytics**: Visual charts showing reading diversity patterns

### 📊 Statistics & Analytics
- **Reading Progress**: Monthly reading goals and progress tracking
- **Genre Breakdown**: Visual representation of reading genres
- **Cultural Distribution**: Charts showing cultural diversity in reading
- **Reading Pace**: Track reading speed and completion times

### 🔍 Search & Discovery
- **Online Search**: Integration with Google Books API for book discovery
- **Advanced Filters**: Filter by status, rating, cultural information
- **Author Search**: Quick access to books by specific authors

### ⭐ Wishlist Management
- **Future Reading**: Curated list of books to read
- **Priority System**: Organize wishlist by reading priority
- **Cultural Goals**: Track wishlist diversity for balanced reading

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

#### UserBook
User-specific book tracking including:
- Reading status with automatic date tracking
- Personal ratings and notes
- Progress tracking (current page, reading sessions)
- Cultural goal contribution tracking
- Social features (recommendations, discussions)

### Key Components

#### Theme System
- **Material Design 3**: Comprehensive color system with proper dark mode
- **Typography Scale**: Consistent text styling across the app
- **Spacing System**: 8pt grid-based layout system
- **Animation Framework**: Smooth transitions and micro-interactions

#### Views Architecture
- **TabView Navigation**: 5 main sections (Library, Wishlist, Search, Stats, Diversity)
- **Modular Components**: Reusable BookCardView, BookRowView, StatusBadge
- **Responsive Design**: Adaptive layouts for different screen sizes

## UX Pathways

### Adding a New Book
1. **Search Online**: User searches Google Books database
2. **Select Book**: Choose from search results with detailed preview
3. **Customize Details**: Edit/add cultural information and personal data
4. **Save to Library**: Book added with automatic status and date tracking

### Reading Progress Management
1. **Status Updates**: Change reading status with automatic date logging
2. **Progress Tracking**: Update current page and reading sessions
3. **Completion**: Mark as read with rating and notes
4. **Analytics Update**: Statistics automatically refresh

### Cultural Diversity Analysis
1. **Diversity Dashboard**: Visual overview of reading cultural distribution
2. **Goal Setting**: Set targets for reading from different cultures
3. **Progress Monitoring**: Track progress toward diversity goals
4. **Insights**: Discover reading patterns and suggestions for improvement

## Design Philosophy

### Cultural Sensitivity
- **Inclusive Language**: Respectful terminology throughout the app
- **Diverse Representation**: Color schemes inspired by global cultures
- **Accessibility First**: Full VoiceOver support and inclusive design

### Reading-Focused Experience
- **Distraction-Free**: Clean interface focused on books and reading
- **Personal Journey**: Emphasizes individual reading growth and discovery
- **Data Privacy**: All personal notes and ratings remain private

### Adaptive Interface
- **Dark Mode**: Full support with proper contrast ratios
- **Dynamic Type**: Scales with user's preferred text size
- **Color Accessibility**: High contrast options and colorblind-friendly design

## Integration Points

### External Services
- **Google Books API**: Book search and metadata retrieval
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
- **Background Processing**: Non-blocking API calls and data processing
- **Memory Management**: Proper cleanup and resource management

## Future Expansion

The app is designed with extensibility in mind:
- **Social Features**: Book clubs and friend recommendations
- **Reading Challenges**: Community-driven reading goals
- **Enhanced Analytics**: More detailed reading insights
- **Export Capabilities**: Reading data export for external analysis
- **Additional APIs**: Integration with library systems and bookstores