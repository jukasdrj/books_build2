### Short Term (Next 2-4 weeks) 🎯

* **Workflow Improvement**
    * [ ] After a user adds a book from search results, navigate them directly to the `EditBookDetails` view to encourage immediate customization (e.g., setting status, adding tags).

* **Material Component Standardization**
    * [ ] Replace all remaining custom styling for cards, buttons, and chips with their corresponding `.material...()` modifiers from the theme system.
    * [ ] Apply the `.materialInteractive()` modifier to all tappable, non-button elements for consistent touch feedback.
    * [ ] Audit all views to ensure a unified and maintainable UI consistent with Material Design 3.

* **Spacing & Layout Polish**
    * [ ] Perform a project-wide audit to replace all hardcoded padding and spacing values with constants from the `Theme.Spacing` system.
    * [ ] Refine layouts in forms and detail views to ensure proper alignment and readability, following the 8pt grid system.
    * [ ] Standardize safe area handling to ensure a polished look on all device sizes.

* **Reading Progress & Goals**
    * [ ] Implement UI for tracking the current page of a book.
    * [ ] Add functionality for users to set and track daily or weekly reading goals.
    * [ ] Visualize progress toward goals in the `StatsView`.

### Medium Term (1-3 months) 🚀

* **iCloud & Sync**
    * [ ] Integrate CloudKit for automatic backup and cross-device synchronization of the user's library and reading data.
    * [ ] Implement conflict resolution for concurrent edits and ensure a seamless offline mode.

* **Advanced Analytics & Charts**
    * [ ] Enhance the `StatsView` with more detailed charts and visualizations.
    * [ ] Add historical data analysis to show reading trends over time.

* **Import from Photo**
    * [ ] Implement functionality to select a photo from the user's library.
    * [ ] Use text recognition to identify an ISBN or book title from the image.
    * [ ] Fetch book data via an API and allow the user to add it to their library.

* **Social Features (Phase 1)**
    * [ ] Develop a personal recommendation engine based on reading history and cultural diversity goals.
    * [ ] Implement personal reading challenges with progress tracking and achievement badges.
