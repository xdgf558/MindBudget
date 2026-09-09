import Foundation
import CryptoKit

@MainActor
enum ProbeEntry {
    static func runIfRequested() async {
        #if targetEnvironment(simulator)
        let physical = false
        #else
        let physical = true
        #endif
        var journal: ProbeJournal?
        do {
            guard let request = try ProbeRequest.parse(environment: ProcessInfo.processInfo.environment,
                                                       bundle: Bundle.main.bundleIdentifier,
                                                       physical: physical) else { return }
            let support = try FileManager.default.url(for: .applicationSupportDirectory,
                                                      in: .userDomainMask, appropriateFor: nil, create: true)
            let root = support.appendingPathComponent("FXCloudProbe", isDirectory: true)
            try ProbeReservation.claim(root: root, run: request.run)
            let receipt = try ProbeJournal(root: root, run: request.run)
            journal = receipt
            try receipt.save(status: "RUNNING") // an interrupted process remains non-pass
            let driver = ProbeLifecycle(root: root, calendar: .current)
            try await ProbeScenario.execute(driver) { step in
                receipt.completed.append(step)
                try receipt.save(status: "RUNNING")
            }
            try receipt.save(status: "PASS_BOUNDED_SINGLE_DEVICE_ONLY")
            print("FX_CLOUD_PROBE PASS_BOUNDED_SINGLE_DEVICE_ONLY")
        } catch {
            // Never include raw CloudKit errors, account identifiers or remote contents.
            let reason = (error as? ProbeFailure)?.rawValue ?? "operationFailed"
            try? journal?.save(status: "NON_PASS", reason: reason)
            print("FX_CLOUD_PROBE NON_PASS " + reason)
        }
    }
}

@MainActor
private final class ProbeJournal {
    let root: URL
    let run: UUID
    let executableSHA256: String
    var completed: [ProbeStep] = []
    init(root: URL, run: UUID) throws {
        self.root = root
        self.run = run
        guard let executable = Bundle.main.executableURL else { throw ProbeFailure.localState }
        executableSHA256 = SHA256.hash(data: try Data(contentsOf: executable))
            .map { String(format: "%02x", $0) }.joined()
    }

    func save(status: String, reason: String? = nil) throws {
        struct Receipt: Encodable {
            let protocolVersion: Int
            let run: UUID
            let status: String
            let reason: String?
            let completed: [ProbeStep]
            let plannedExpenseCount: Int
            let liveDeletionTested: Bool
            let executableSHA256: String
        }
        let receipt = Receipt(protocolVersion: 1, run: run, status: status, reason: reason,
                              completed: completed, plannedExpenseCount: 4, liveDeletionTested: false,
                              executableSHA256: executableSHA256)
        let data = try JSONEncoder().encode(receipt)
        try data.write(to: root.appendingPathComponent("receipt.json"), options: .atomic)
    }
}
