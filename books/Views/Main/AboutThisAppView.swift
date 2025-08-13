import SwiftUI

struct AboutThisAppView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    Divider().foregroundColor(theme.outline.opacity(0.2))
                    overview
                    features
                    privacy
                    acknowledgements
                    developer
                }
                .padding(20)
            }
            .navigationTitle("About This App")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(theme.primary)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient(colors: [theme.primary, theme.secondary], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 64, height: 64)
                Image(systemName: "books.vertical.fill")
                    .foregroundStyle(.white)
                    .font(.system(size: 28, weight: .semibold))
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Books Tracker")
                    .font(.title2).fontWeight(.bold)
                    .foregroundColor(theme.primaryText)
                Text("Version 1.0.0")
                    .font(.subheadline)
                    .foregroundColor(theme.secondaryText)
            }
            Spacer()
        }
    }

    private var overview: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Overview").font(.headline).foregroundColor(theme.primaryText)
            Text("Books Tracker helps you organize your personal library, import from CSV, and keep your reading goals on track. It’s built exclusively for the latest iOS and Swift, with privacy and speed in mind.")
                .font(.subheadline)
                .foregroundColor(theme.secondaryText)
        }
    }

    private var features: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Key Features").font(.headline).foregroundColor(theme.primaryText)
            VStack(alignment: .leading, spacing: 6) {
                bullet("Fast CSV import with preview and duplicate detection")
                bullet("Powerful search with rich book metadata")
                bullet("Custom themes and beautiful, accessible UI")
                bullet("Reading goals with clear progress visuals")
                bullet("Private by default — your data stays yours")
            }
        }
    }

    private var privacy: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Privacy").font(.headline).foregroundColor(theme.primaryText)
            Text("All personal reading data is stored securely on your device and synced via iCloud if available. No analytics or third‑party tracking.")
                .font(.subheadline)
                .foregroundColor(theme.secondaryText)
        }
    }

    private var acknowledgements: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Acknowledgements").font(.headline).foregroundColor(theme.primaryText)
            VStack(alignment: .leading, spacing: 6) {
                Text("Special thanks to vibe codeing and the positive support from my best friend sumsum.")
                Text("Built with Apple frameworks including SwiftData, SwiftUI, and CloudKit.")
            }
            .font(.subheadline)
            .foregroundColor(theme.secondaryText)
        }
    }

    private var developer: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Developer").font(.headline).foregroundColor(theme.primaryText)
            Text("Created by Scotty Meadows — dad of four, based in Texas. Passionate about reading, design systems, and building delightful iOS experiences.")
                .font(.subheadline)
                .foregroundColor(theme.secondaryText)
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(theme.primary)
            Text(text)
                .foregroundColor(theme.primaryText)
                .font(.subheadline)
        }
    }
}

#Preview {
    AboutThisAppView()
}

