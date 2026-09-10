import Foundation
import CryptoKit
import Darwin

@MainActor
enum ProbeEntry {
    static func runIfRequested() async {
        #if targetEnvironment(simulator)
        let physical = false
        #else
        let physical = true
        #endif
        var journal: ProbeJournal?
        var deadline: ProbeHardDeadline?
        var exitCode: Int32 = 1
        do {
            guard let request = try ProbeRequest.parse(environment: ProcessInfo.processInfo.environment,
                                                       bundle: Bundle.main.bundleIdentifier,
                                                       physical: physical) else { return }
            deadline = ProbeHardDeadline() // armed before filesystem, hash read or CloudKit construction
            guard let executable = Bundle.main.executableURL,
                  SHA256.hash(data: try Data(contentsOf: executable))
                    .map({ String(format: "%02x", $0) }).joined() == request.executableSHA256,
                  try ProbeArtifact.digest(Bundle.main.bundleURL) == request.artifactSHA256
            else { throw ProbeFailure.wrongIdentity }
            let support = try FileManager.default.url(for: .applicationSupportDirectory,
                                                      in: .userDomainMask, appropriateFor: nil, create: true)
            let root = support.appendingPathComponent("FXCloudProbe", isDirectory: true)
            try ProbeReservation.claim(root: root, run: request.run)
            let receipt = try ProbeJournal(root: root, run: request.run, artifact: request.artifactSHA256)
            journal = receipt
            try receipt.save(status: "RUNNING") // an interrupted process remains non-pass
            let driver = ProbeLifecycle(root: root, calendar: .current)
            try await ProbeScenario.execute(driver) { step in
                receipt.completed.append(step)
                try receipt.save(status: "RUNNING")
            }
            try receipt.save(status: "PASS_BOUNDED_SINGLE_DEVICE_ONLY")
            print("FX_CLOUD_PROBE PASS_BOUNDED_SINGLE_DEVICE_ONLY")
            exitCode = 0
        } catch {
            // Never include raw CloudKit errors, account identifiers or remote contents.
            let reason = (error as? ProbeFailure)?.rawValue ?? "operationFailed"
            try? journal?.save(status: "NON_PASS", reason: reason)
            print("FX_CLOUD_PROBE NON_PASS " + reason)
        }
        // No dormant network-capable host after completion. Keep hard timer alive even if
        // failure journalling/driver.stop hangs. This never terminates the everyday app.
        withExtendedLifetime(deadline) { Darwin.exit(exitCode) }
    }

}

@MainActor
private final class ProbeJournal {
    let root: URL
    let run: UUID
    let executableSHA256: String
    let artifactSHA256: String
    var completed: [ProbeStep] = []
    init(root: URL, run: UUID, artifact: String) throws {
        self.root = root
        self.run = run
        self.artifactSHA256 = artifact
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
            let artifactSHA256: String
        }
        let receipt = Receipt(protocolVersion: 2, run: run, status: status, reason: reason,
                              completed: completed, plannedExpenseCount: 4, liveDeletionTested: false,
                              executableSHA256: executableSHA256, artifactSHA256: artifactSHA256)
        let data = try JSONEncoder().encode(receipt)
        try data.write(to: root.appendingPathComponent("receipt.json"), options: .atomic)
    }
}
