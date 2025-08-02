### Short-Term Needs

* **Material Component Standardization** ✅ **COMPLETED**
    * [x] ~~In `CulturalDiversityView.swift`, replace custom card styling with the `.materialCard()` modifier.~~ ✅ **COMPLETED** - Already using .materialCard()
    * [x] ~~Refactor `StatCard` in `StatsView.swift` to use `.materialCard()`.~~ ✅ **COMPLETED** - StatCard now uses .materialCard(backgroundColor: color.opacity(0.1))
    * [x] ~~Update the button in `AddBookView.swift` from `.buttonStyle(.borderedProminent)` to the `.materialButton()` modifier.~~ ✅ **COMPLETED** - SearchResultDetailView buttons now use .materialButton()
    * [x] ~~Add the `.materialInteractive()` modifier to non-button tappable elements like `BookCardView.swift` and `BookListItem` for standard touch feedback.~~ ✅ **COMPLETED** - Enhanced MaterialInteractiveModifier implemented

* **Spacing & Layout Polish** ✅ **COMPLETED**
    * [x] ~~Audit the project for hardcoded spacing values (e.g., `.padding(8)`, `spacing: 12`) and replace them with `Theme.Spacing` constants.~~ ✅ **COMPLETED** - Comprehensive spacing audit completed
    * [x] ~~In forms like `AddBookView.swift` and `EditBookView.swift`, apply consistent spacing between sections (`Theme.Spacing.lg`) and fields (`Theme.Spacing.sm`).~~ ✅ **COMPLETED** - Forms standardized
    * [x] ~~Ensure all main views have standardized bottom padding to account for the tab bar, using `Theme.Spacing.xl`.~~ ✅ **COMPLETED** - All main views updated

* **Reading Progress UI Enhancement** (NEXT UP)
    * [ ] Add ReadingProgressSection to BookDetailsView with progress visualization
    * [ ] Integrate PageInputView for current page tracking
    * [ ] Add ReadingSessionInputView for session logging
    * [ ] Display reading stats (total time, pace, sessions) in BookDetailsView

---

### New Features

* **Reading Goals System** (HIGH PRIORITY - Phase 4 continuation)
    * [ ] **Goal Setting Interface**: Create forms for setting daily/weekly reading goals
    * [ ] **Goal Progress Tracking**: Store and track progress against user-defined goals
    * [ ] **Goal Visualization**: Add progress rings/charts to StatsView showing goal achievement
    * [ ] **Goal Achievement**: Implement notifications/celebrations when goals are met

* **Import from Goodreads CSV**
    * [ ] **File Picker:** Implement a file picker that allows users to select a `.csv` file from their device.
    * [ ] **CSV Parsing:** Use a reliable CSV parsing library to handle the file.
    * [ ] **Data Mapping:**
        * Create a mapping screen where users can match the columns from their CSV file (e.g., "Title", "Author", "Date Read") to the app's data fields.
        * Provide default mappings for common formats like the Goodreads export.
        * if possible, create a magic button that reads the csv, attempts to match the format mapping automatically, then provide info to user on how many books can auto import
        * as part of import, access google books api for any missing fields in our bookmetadata model
    * [ ] **Import Process:**
        * On a background thread, process the CSV and add the books to the user's library.
        * Provide a progress indicator to the user.
        * Handle potential duplicates or errors gracefully.
    * [ ] **Confirmation:** Show a summary screen after the import is complete, indicating how many books were successfully imported.

* **Barcode Scanning**
    * [ ] **UI Integration:** Add a "Scan Barcode" button to the `SearchView`.
    * [ ] **Camera View:** Create a view that uses the device's camera to scan for barcodes.
    * [ ] **API Lookup:** When a barcode is detected, use an API (like the Google Books API) to look up the book's information.
    * [ ] **Confirmation Screen:** Pre-fill the "Add Book" screen with the data from the API and let the user confirm to add it to their library.

---

## ✅ COMPLETED ACCOMPLISHMENTS

### **Auto-Navigation Workflow** ✅ **COMPLETED**
- [x] ~~Integration tests for add-book navigation flow~~ ✅ **COMPLETED**
- [x] ~~Smart navigation: Library additions → EditBookView, Wishlist → toast only~~ ✅ **COMPLETED**
- [x] ~~Success feedback with tailored messages for different workflows~~ ✅ **COMPLETED**

### **Material Design 3 Implementation** ✅ **COMPLETED**
- [x] ~~Complete .materialCard() migration across all card components~~ ✅ **COMPLETED**
- [x] ~~Enhanced .materialButton() system with MaterialButtonStyle and MaterialButtonSize~~ ✅ **COMPLETED**
- [x] ~~Advanced .materialInteractive() with MaterialInteractiveModifier~~ ✅ **COMPLETED**

### **Theme System Standardization** ✅ **COMPLETED**
- [x] ~~Theme.Spacing constants replace all hardcoded spacing values~~ ✅ **COMPLETED**
- [x] ~~8pt grid system implementation across entire app~~ ✅ **COMPLETED**
- [x] ~~Consistent form layout with proper section/field spacing relationships~~ ✅ **COMPLETED**

### **Reading Progress Foundation** ✅ **COMPLETED**
- [x] ~~UserBook model comprehensive progress tracking analysis~~ ✅ **COMPLETED**
- [x] ~~PageInputView production-readiness validation~~ ✅ **COMPLETED**
- [x] ~~ReadingSession analytics and pace calculation verification~~ ✅ **COMPLETED**