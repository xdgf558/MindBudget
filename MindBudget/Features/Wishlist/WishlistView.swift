import SwiftUI

struct WishlistView: View {
    var body: some View {
        NavigationStack {
            EmptyStateView(
                symbolName: "heart.text.square",
                titleKey: "wishlist.empty.title",
                messageKey: "wishlist.empty.message"
            )
            .navigationTitle("tab.wishlist")
            .accessibilityIdentifier("wishlist.empty")
        }
    }
}
