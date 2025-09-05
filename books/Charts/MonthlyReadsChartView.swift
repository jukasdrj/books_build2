import SwiftUI
import Charts

struct MonthlyReadsChartView: View {
    @Environment(\.appTheme) private var currentTheme
    
    let books: [UserBook]
    
    private var monthlyData: [BookCount] {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        
        // Create data for all 12 months
        var monthCounts: [String: Int] = [:]
        let monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                         "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        
        // Initialize all months with 0
        for month in monthNames {
            monthCounts[month] = 0
        }
        
        // Count books completed this year
        let completedBooks = books.filter { book in
            guard let dateCompleted = book.dateCompleted else { return false }
            return calendar.component(.year, from: dateCompleted) == currentYear
        }
        
        for book in completedBooks {
            guard let dateCompleted = book.dateCompleted else { continue }
            let monthIndex = calendar.component(.month, from: dateCompleted) - 1
            if monthIndex >= 0 && monthIndex < monthNames.count {
                let monthName = monthNames[monthIndex]
                monthCounts[monthName, default: 0] += 1
            }
        }
        
        // Convert to BookCount array in chronological order
        return monthNames.map { month in
            BookCount(month: month, count: monthCounts[month] ?? 0)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Books Read This Year")
                .titleLarge()
                .foregroundColor(currentTheme.primaryText)
            
            Chart(monthlyData) { item in
                BarMark(
                    x: .value("Month", item.month),
                    y: .value("Books", item.count)
                )
                .foregroundStyle(currentTheme.primary)
                .cornerRadius(Theme.CornerRadius.small)
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                        .foregroundStyle(currentTheme.outline)
                    AxisTick()
                        .foregroundStyle(currentTheme.secondaryText)
                    AxisValueLabel()
                        .foregroundStyle(currentTheme.secondaryText)
                        .font(Theme.Typography.labelSmall)
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisGridLine()
                        .foregroundStyle(currentTheme.outline)
                    AxisTick()
                        .foregroundStyle(currentTheme.secondaryText)
                    AxisValueLabel()
                        .foregroundStyle(currentTheme.secondaryText)
                        .font(Theme.Typography.labelSmall)
                }
            }
            .frame(height: 200)
        }
        .progressiveGlassEffect(material: .ultraThinMaterial, level: .optimized)
    }
}

// Data structure for the chart - now conforms to Equatable for animations
struct BookCount: Identifiable, Equatable {
    let id = UUID()
    let month: String
    let count: Int
    
    static func == (lhs: BookCount, rhs: BookCount) -> Bool {
        return lhs.month == rhs.month && lhs.count == rhs.count
    }
}

#Preview {
    // Sample data setup
    let sampleMetadata1 = BookMetadata(
        googleBooksID: "1",
        title: "Sample Book 1",
        authors: ["Author 1"]
    )
    
    let sampleMetadata2 = BookMetadata(
        googleBooksID: "2", 
        title: "Sample Book 2",
        authors: ["Author 2"]
    )
    
    // Create sample books - using the fact that .read status auto-sets dateCompleted in init
    let sampleBooks = [
        UserBook(readingStatus: .read, metadata: sampleMetadata1),
        UserBook(readingStatus: .read, metadata: sampleMetadata2),
        UserBook(readingStatus: .read, metadata: sampleMetadata1)
    ]
    
    MonthlyReadsChartView(books: sampleBooks)
        .padding()
        .background(.regularMaterial)
}