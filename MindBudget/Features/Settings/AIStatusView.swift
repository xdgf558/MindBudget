import SwiftUI

struct AIStatusView: View {
    let userEnabled: Bool
    @State private var availability: AIAvailability = .unavailable(.unknown)
    #if DEBUG
    @State private var fallbackCounts: [AIFallbackDiagnosticReason: Int] = [:]
    #endif

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(statusKey, systemImage: statusSymbol)
                .foregroundStyle(availability == .available ? .green : .secondary)
            Text("settings.ai.fallback")
                .font(.footnote)
                .foregroundStyle(.secondary)
            #if DEBUG
            if !fallbackCounts.isEmpty {
                Text("settings.ai.debugFallbacks")
                    .font(.caption.weight(.semibold))
                ForEach(AIFallbackDiagnosticReason.allCases, id: \.rawValue) { reason in
                    if let count = fallbackCounts[reason], count > 0 {
                        LabeledContent(
                            LocalizedStringKey("settings.ai.debug.\(reason.rawValue)"),
                            value: count.formatted()
                        )
                        .font(.caption)
                    }
                }
            }
            #endif
        }
        .task(id: userEnabled) {
            availability = await AIEnhancementCapability(
                userEnabled: userEnabled
            ).availability
            #if DEBUG
            fallbackCounts = await AIFallbackDiagnostics.shared.snapshot()
            #endif
        }
    }

    private var statusKey: LocalizedStringKey {
        switch availability {
        case .available:
            "settings.ai.status.available"
        case let .unavailable(reason):
            LocalizedStringKey("settings.ai.status.\(reason.rawValue)")
        }
    }

    private var statusSymbol: String {
        availability == .available ? "checkmark.circle" : "info.circle"
    }
}
