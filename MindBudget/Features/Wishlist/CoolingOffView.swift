import Foundation
import SwiftUI

enum CoolingOffStartError: Error, Equatable, Sendable {
    case stateChanged
    case invalidStoredData
    case persistence

    static func mapped(from error: Error) -> CoolingOffStartError {
        if error is WishItemTransitionError {
            return .stateChanged
        }
        if let validationError = error as? DataValidationError {
            switch validationError {
            case .invalidCoolingOffPlan, .invalidWishItem, .modelNotFound:
                return .stateChanged
            default:
                return .persistence
            }
        }
        if error is PersistedModelError {
            return .invalidStoredData
        }
        return .persistence
    }
}

struct CoolingOffView: View {
    private enum DurationChoice: String, CaseIterable, Identifiable {
        case hours24, hours72, custom
        var id: String { rawValue }
    }

    let dataActor: DataActor
    let wishItem: WishItemSummary
    let completed: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.calendar) private var calendar
    @State private var choice: DurationChoice = .hours24
    @State private var customHoursText = "48"
    @State private var startedAt: Date
    @State private var error: CoolingOffStartError?
    @State private var isStarting = false

    init(
        dataActor: DataActor,
        wishItem: WishItemSummary,
        startedAt: Date = Date(),
        completed: @escaping () -> Void
    ) {
        self.dataActor = dataActor
        self.wishItem = wishItem
        self.completed = completed
        _startedAt = State(initialValue: startedAt)
        switch wishItem.coolingOffHours {
        case 24:
            _choice = State(initialValue: .hours24)
        case 72:
            _choice = State(initialValue: .hours72)
        default:
            _choice = State(initialValue: .custom)
            _customHoursText = State(initialValue: String(wishItem.coolingOffHours))
        }
    }

    var body: some View {
        Form {
            Section("wishlist.cooling.title") {
                Text(wishItem.name).font(.headline)
                Picker("wishlist.cooling.duration", selection: $choice) {
                    Text("wishlist.duration.24h").tag(DurationChoice.hours24)
                    Text("wishlist.duration.72h").tag(DurationChoice.hours72)
                    Text("wishlist.duration.custom").tag(DurationChoice.custom)
                }
                .pickerStyle(.segmented)
                if choice == .custom {
                    TextField("wishlist.duration.customHours", text: $customHoursText)
                        .keyboardType(.numberPad)
                        .accessibilityIdentifier("wishlist.customHours")
                }
                if let reviewAt {
                    LabeledContent("wishlist.reviewAt") {
                        Text(reviewAt, format: .dateTime.month().day().hour().minute())
                    }
                }
                Text("wishlist.cooling.noNotification")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            if let error {
                Section {
                    Label(errorKey(error), systemImage: "info.circle")
                        .foregroundStyle(.orange)
                }
            }
        }
        .navigationTitle("wishlist.action.startCooling")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("common.cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("wishlist.cooling.start") {
                    Task { await start() }
                }
                .disabled(durationHours == nil || isStarting)
                .accessibilityIdentifier("wishlist.cooling.start")
            }
        }
    }

    private var durationHours: Int? {
        switch choice {
        case .hours24: return 24
        case .hours72: return 72
        case .custom:
            guard let value = Int(customHoursText), value > 0 else { return nil }
            return value
        }
    }

    private var reviewAt: Date? {
        guard let durationHours else { return nil }
        return calendar.date(byAdding: .hour, value: durationHours, to: startedAt)
    }

    private func start() async {
        guard let durationHours else { return }
        isStarting = true
        defer { isStarting = false }
        do {
            _ = try await dataActor.startCoolingOff(
                wishItemId: wishItem.id,
                durationHours: durationHours,
                startedAt: startedAt,
                calendar: calendar
            )
            error = nil
            completed()
        } catch {
            self.error = CoolingOffStartError.mapped(from: error)
        }
    }

    private func errorKey(_ error: CoolingOffStartError) -> LocalizedStringKey {
        switch error {
        case .stateChanged: "wishlist.cooling.error.stateChanged"
        case .invalidStoredData: "wishlist.cooling.error.invalidStoredData"
        case .persistence: "wishlist.cooling.error.persistence"
        }
    }
}

struct CoolingOffCountdownLabel: View {
    let reviewAt: Date
    let calendar: Calendar

    @Environment(\.locale) private var locale

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            let countdown = CoolingOffCountdown.remaining(
                from: context.date,
                until: reviewAt,
                calendar: calendar
            )
            Label(
                CoolingOffCountdownText.string(for: countdown, locale: locale),
                systemImage: "hourglass"
            )
                .foregroundStyle(.tint)
        }
    }
}
