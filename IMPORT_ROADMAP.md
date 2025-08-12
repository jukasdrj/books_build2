# Import System Roadmap

## Overview
This roadmap outlines planned enhancements to the CSV import system based on identified gaps in user functionality and import management capabilities.

## Current State
The import system successfully handles CSV imports with:
- ✅ Real-time progress tracking
- ✅ Automatic fallback strategies (ISBN → Title/Author → CSV data)
- ✅ Basic completion notifications
- ✅ Review modal for problematic books
- ✅ Comprehensive background processing

## Missing Functionality & Enhancement Roadmap

### Phase 1: Enhanced Error Management 🔍
**Priority: High | Timeline: 2-4 weeks**

#### 1.1 Detailed Error Log View
- **Feature**: Comprehensive error viewer showing all import failures
- **Location**: New `ImportErrorLogView.swift`
- **Contents**:
  - Complete list of failed books with CSV row numbers
  - Specific error messages and failure reasons
  - Searchable and filterable error list
  - Export error log as CSV for external analysis
- **Access**: Via Settings → Import History → View Errors

#### 1.2 Failed Book Retry System
- **Feature**: Individual and batch retry functionality for failed imports
- **Components**:
  - Retry button for each failed book in error log
  - "Retry All Failed" bulk action
  - Enhanced API fallback with different search strategies
  - Manual data entry form for completely failed books
- **Smart Retry Logic**:
  - Automatic retry with different search terms
  - Fallback to alternative book APIs (OpenLibrary, etc.)
  - User-guided search with suggested matches

#### 1.3 Import Diagnostics Dashboard
- **Feature**: Technical diagnostics for troubleshooting imports
- **Metrics**:
  - API success/failure rates by endpoint
  - Network timeout and rate limiting statistics
  - CSV parsing error patterns
  - Performance metrics (books/second, memory usage)
- **Alerts**: Automatic detection of systematic import issues

### Phase 2: Import History & Management 📚
**Priority: Medium | Timeline: 3-5 weeks**

#### 2.1 Persistent Import History
- **Feature**: Complete log of all import sessions
- **Data Model**: New `ImportSession` entity with:
  - Import timestamp and duration
  - File name and size
  - Success/failure statistics
  - List of imported book IDs
  - Error summaries and retry history
- **UI**: New `ImportHistoryView.swift` accessible from Settings

#### 2.2 Import Session Management
- **Features**:
  - View detailed results of past imports
  - Re-download import summaries as PDF/CSV
  - Delete old import sessions with data cleanup
  - Search import history by date, filename, or results
- **Smart Insights**:
  - "You've imported 234 books across 12 sessions this year"
  - Import success rate trends over time
  - Most common import error patterns

#### 2.3 Import Templates & Presets
- **Feature**: Save and reuse column mapping configurations
- **Components**:
  - Save current mapping as template
  - Quick-apply saved templates for similar CSV formats
  - Community template sharing (future)
  - Auto-detection of known CSV formats (Goodreads, LibraryThing, etc.)

### Phase 3: Advanced Import Features 🚀
**Priority: Medium-Low | Timeline: 4-8 weeks**

#### 3.1 Manual Book Editor
- **Feature**: In-app editing for problematic import books
- **Interface**: New `ManualBookEntryView.swift`
- **Capabilities**:
  - Edit book metadata directly from CSV data
  - Search and select from multiple API results
  - Add custom book covers
  - Merge duplicate detection with manual override
- **Integration**: Accessible from error log and review modal

#### 3.2 Enhanced Import Preview
- **Feature**: More detailed pre-import analysis
- **Enhancements**:
  - Data quality scoring with specific recommendations
  - Estimated success rates based on data completeness
  - Column mapping validation with warnings
  - Duplicate prediction before import starts
- **Smart Suggestions**: Auto-fix common CSV data issues

#### 3.3 Import Error Export & Analysis
- **Feature**: Export detailed error reports for external analysis
- **Formats**: 
  - CSV with full error details and suggestions
  - PDF report with import summary and troubleshooting guide
  - JSON for developer analysis
- **Content**:
  - Per-book error details with original CSV data
  - Recommended fixes for each error type
  - Import session metadata and performance stats

### Phase 4: Advanced User Experience 🎨
**Priority: Low | Timeline: 6-10 weeks**

#### 4.1 Import Progress Enhancements
- **Features**:
  - Live Activity improvements with book titles
  - Progress indicators showing specific books being processed
  - Estimated time remaining with dynamic updates
  - Pausable imports with resume capability

#### 4.2 Smart Import Assistance
- **AI-Powered Features**:
  - Automatic CSV format detection
  - Smart column mapping suggestions
  - Intelligent duplicate resolution
  - Auto-correction of common data entry errors
- **Machine Learning**: Learn from user corrections to improve future imports

#### 4.3 Collaborative Import Features
- **Community Features**:
  - Share CSV templates with other users
  - Crowdsourced book metadata corrections
  - Import success rate sharing (anonymous)
  - Community troubleshooting guides

## Technical Implementation Notes

### Data Architecture Changes
- New `ImportSession` SwiftData model for history
- Enhanced `ImportError` model with more metadata
- Retry tracking in existing `ImportProgress` model
- Template storage for column mappings

### UI Architecture
- New navigation section: Settings → Import Management
- Enhanced error modal with actionable buttons
- Dedicated import history and diagnostics screens
- Integration with existing background import system

### Performance Considerations
- Limit import history retention (configurable, default 6 months)
- Implement efficient error log pagination
- Background cleanup of old import data
- Memory-efficient large CSV preview

## Success Metrics
- **User Satisfaction**: Reduced support queries about "failed imports"
- **Import Success Rate**: Target 95%+ overall success rate
- **User Retention**: Increased usage of import feature
- **Error Resolution**: 80%+ of failed books successfully retried

## Future Considerations
- Integration with cloud storage services (iCloud, Google Drive)
- Batch import from multiple CSV files
- API integrations with library management systems
- Advanced book matching algorithms using ML

---

*Last Updated: December 2024*
*Status: Planning Phase*