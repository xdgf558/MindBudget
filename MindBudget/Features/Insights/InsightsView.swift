import SwiftUI

struct InsightsView: View {
    var body: some View {
        NavigationStack {
            EmptyStateView(
                symbolName: "chart.xyaxis.line",
                titleKey: "insights.empty.title",
                messageKey: "insights.empty.message"
            )
            .navigationTitle("tab.insights")
            .accessibilityIdentifier("insights.empty")
        }
    }
}
