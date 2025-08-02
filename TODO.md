### Short-Term Needs

* **Material Component Standardization**
    * [ ] In `CulturalDiversityView.swift`, replace custom card styling with the `.materialCard()` modifier.
    * [ ] Refactor `StatCard` in `StatsView.swift` to use `.materialCard()`.
    * [ ] Update the button in `AddBookView.swift` from `.buttonStyle(.borderedProminent)` to the `.materialButton()` modifier.
    * [ ] Add the `.materialInteractive()` modifier to non-button tappable elements like `BookCardView.swift` and `BookListItem` for standard touch feedback.

* **Spacing & Layout Polish**
    * [ ] Audit the project for hardcoded spacing values (e.g., `.padding(8)`, `spacing: 12`) and replace them with `Theme.Spacing` constants.
    * [ ] In forms like `AddBookView.swift` and `EditBookView.swift`, apply consistent spacing between sections (`Theme.Spacing.lg`) and fields (`Theme.Spacing.sm`).
    * [ ] Ensure all main views have standardized bottom padding to account for the tab bar, using `Theme.Spacing.xl`.

---

### New Features

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
