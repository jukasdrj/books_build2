import SwiftUI

struct WishlistView: View {
    var body: some View {
        LibraryView(filter: .wishlist)
    }
}

#Preview {
    WishlistView()
        .modelContainer(for: [UserBook.self, BookMetadata.self], inMemory: true)
}