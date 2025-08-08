import Foundation

enum ScreenshotMode {
    /// Returns true if Screenshot Mode is enabled via launch argument or environment variable.
    static var isEnabled: Bool {
        // You can set this in Product > Scheme > Edit Scheme > Arguments
        ProcessInfo.processInfo.arguments.contains("screenshotMode") ||
        ProcessInfo.processInfo.environment["SCREENSHOT_MODE"] == "1"
    }
    
    /// Optionally disables onboarding, popups, or debug banners.
    static var disablesOverlays: Bool { isEnabled }
    
    /// If enabled, always uses light mode for screenshots.
    static var forceLightMode: Bool { isEnabled }
    
    /// Optionally disables network calls (for search etc.).
    static var disablesNetwork: Bool { isEnabled }
    
    /// Returns a seeded list of UserBook/BookMetadata demo objects for every screenshot you want to take.
    /// You may want to enhance these with beautiful covers and perfect progress values!
    static func demoBooks() -> [UserBook] {
        let books: [UserBook] = [
            // Hero book for Library view - 85% complete, beautiful cover, purple theme
            UserBook(
                dateAdded: Date(timeIntervalSinceNow: -86400 * 100),
                readingStatus: .reading,
                currentPage: 320,
                dailyReadingGoal: 35,
                personalRating: 4.5,
                contributesToCulturalGoal: true,
                culturalGoalCategory: "African Literature",
                metadata: BookMetadata(
                    googleBooksID: "demo1",
                    title: "Homegoing",
                    authors: ["Yaa Gyasi"],
                    publishedDate: "2016",
                    pageCount: 352,
                    bookDescription: "An epic story of African and African-American history through generations.",
                    imageURL: nil, // Add a valid URL for best screenshots
                    language: "en",
                    genre: ["Historical Fiction", "Family Saga"],
                    culturalRegion: .africa,
                    marginalizedVoice: true
                )
            ),
            // Hero for Search view - diverse title, visible in search state
            UserBook(
                dateAdded: Date(timeIntervalSinceNow: -86400 * 50),
                readingStatus: .toRead,
                currentPage: 0,
                personalRating: nil,
                contributesToCulturalGoal: true,
                culturalGoalCategory: "Asian Literature",
                metadata: BookMetadata(
                    googleBooksID: "demo2",
                    title: "Pachinko",
                    authors: ["Min Jin Lee"],
                    publishedDate: "2017",
                    pageCount: 496,
                    bookDescription: "A multi-generational Korean family story about resilience and hope.",
                    genre: ["Fiction", "Historical"],
                    culturalRegion: .asia,
                    marginalizedVoice: true
                )
            ),
            // Cultural Diversity Progress - 100% complete, different region
            UserBook(
                dateAdded: Date(timeIntervalSinceNow: -86400 * 180),
                readingStatus: .read,
                currentPage: 416,
                personalRating: 5.0,
                contributesToCulturalGoal: true,
                culturalGoalCategory: "Latin American",
                metadata: BookMetadata(
                    googleBooksID: "demo3",
                    title: "One Hundred Years of Solitude",
                    authors: ["Gabriel García Márquez"],
                    publishedDate: "1967",
                    pageCount: 416,
                    bookDescription: "A classic of magical realism, chronicling the Buendía family's history.",
                    genre: ["Magic Realism", "Classic"],
                    culturalRegion: .southAmerica,
                    marginalizedVoice: false
                )
            ),
            // For Theme Picker (showcase all 5 themes with various books)
            UserBook(
                dateAdded: Date(timeIntervalSinceNow: -86400 * 10),
                readingStatus: .toRead,
                metadata: BookMetadata(
                    googleBooksID: "demo4",
                    title: "Braiding Sweetgrass",
                    authors: ["Robin Wall Kimmerer"],
                    publishedDate: "2013",
                    pageCount: 390,
                    bookDescription: "A blend of indigenous wisdom, scientific knowledge, and plant lore.",
                    genre: ["Nature", "Memoir"],
                    culturalRegion: .indigenous,
                    marginalizedVoice: true
                )
            ),
            // Stats view - lots of progress, sessions, ratings
            UserBook(
                dateAdded: Date(timeIntervalSinceNow: -86400 * 70),
                readingStatus: .read,
                currentPage: 205,
                personalRating: 5,
                contributesToCulturalGoal: true,
                dailyReadingGoal: 20,
                readingSessions: [
                    .init(date: Date(timeIntervalSinceNow: -86400 * 3), durationMinutes: 45, pagesRead: 20),
                    .init(date: Date(timeIntervalSinceNow: -86400 * 2), durationMinutes: 30, pagesRead: 15),
                    .init(date: Date(timeIntervalSinceNow: -86400 * 1), durationMinutes: 60, pagesRead: 25)
                ],
                metadata: BookMetadata(
                    googleBooksID: "demo5",
                    title: "Minor Feelings",
                    authors: ["Cathy Park Hong"],
                    publishedDate: "2020",
                    pageCount: 210,
                    bookDescription: "An incendiary memoir and cultural critique exploring Asian American consciousness.",
                    genre: ["Nonfiction", "Memoir"],
                    culturalRegion: .asia,
                    marginalizedVoice: true
                )
            )
        ]
        return books
    }
}