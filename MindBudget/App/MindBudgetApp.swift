import SwiftData
import SwiftUI

@MainActor
private final class AppBootstrap: ObservableObject {
    @Published private(set) var environment: AppEnvironment?
    @Published private(set) var failureDescription: String?

    init() {
        retry()
    }

    func retry() {
        do {
            environment = try AppEnvironment.live()
            failureDescription = nil
        } catch {
            environment = nil
            failureDescription = String(describing: error)
        }
    }
}

@main
struct MindBudgetApp: App {
    @StateObject private var bootstrap = AppBootstrap()

    var body: some Scene {
        WindowGroup {
            if let environment = bootstrap.environment {
                AppRouter(dataController: environment.dataController)
                    .modelContainer(environment.dataController.container)
                    .environmentObject(environment.settingsStore)
            } else {
                StoreRecoveryView(
                    failureDescription: bootstrap.failureDescription,
                    retry: bootstrap.retry
                )
            }
        }
    }
}

private struct StoreRecoveryView: View {
    let failureDescription: String?
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "externaldrive.badge.exclamationmark")
                .font(.largeTitle)
                .foregroundStyle(.orange)
                .accessibilityHidden(true)
            Text("storage.recovery.title")
                .font(.headline)
            Text("storage.recovery.message")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            if let failureDescription {
                Text(failureDescription)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                    .accessibilityIdentifier("storage.recovery.error")
            }
            Button("storage.recovery.retry", action: retry)
                .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .accessibilityIdentifier("storage.recovery.view")
    }
}
