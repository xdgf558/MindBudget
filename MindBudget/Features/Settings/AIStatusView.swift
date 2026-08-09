import SwiftUI

struct AIStatusView: View {
    let userEnabled: Bool
    @Environment(\.locale) private var locale
    @State private var availability: AIAvailability = .unavailable(.unknown)
    #if DEBUG
    @State private var fallbackCounts: [AIFallbackDiagnosticReason: Int] = [:]
    @State private var validationCounts: [AdviceSafetyViolation: Int] = [:]
    #endif

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label {
                Text(verbatim: statusText)
            } icon: {
                Image(systemName: statusSymbol)
            }
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
                        LabeledContent {
                            Text(count, format: .number)
                        } label: {
                            Text(
                                verbatim: LocalizedCatalog.string(
                                    "settings.ai.debug.\(reason.rawValue)",
                                    locale: locale
                                )
                            )
                        }
                        .font(.caption)
                    }
                }
                if !validationCounts.isEmpty {
                    Text("settings.ai.debugValidationDetails")
                        .font(.caption.weight(.semibold))
                    ForEach(AdviceSafetyViolation.allCases, id: \.rawValue) { violation in
                        if let count = validationCounts[violation], count > 0 {
                            LabeledContent {
                                Text(count, format: .number)
                            } label: {
                                Text(
                                    verbatim: LocalizedCatalog.string(
                                        "settings.ai.debug.validation.\(violation.rawValue)",
                                        locale: locale
                                    )
                                )
                            }
                            .font(.caption)
                        }
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
            validationCounts = await AIFallbackDiagnostics.shared.validationSnapshot()
            #endif
        }
    }

    private var statusText: String {
        switch availability {
        case .available:
            LocalizedCatalog.string("settings.ai.status.available", locale: locale)
        case let .unavailable(reason):
            LocalizedCatalog.string(
                "settings.ai.status.\(reason.rawValue)",
                locale: locale
            )
        }
    }

    private var statusSymbol: String {
        availability == .available ? "checkmark.circle" : "info.circle"
    }
}
