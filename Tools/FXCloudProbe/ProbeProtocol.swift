import Foundation
import Dispatch
import Darwin
import CryptoKit

enum ProbeFailure: String, Error {
    case invalidRequest, wrongIdentity, simulator, alreadyUsed, unexpectedRemoteZone
    case localState, transport, unexpectedRecords, comparison, deadline
}

struct ProbeRequest: Equatable {
    static let bundle = "com.xdgf558.MindBudgetFXCloudProbe"
    static let container = "iCloud.com.xdgf558.MindBudgetFXCloudProbe"
    static let actionKey = "MINDBUDGET_FX_PROBE_ACTION"
    static let runKey = "MINDBUDGET_FX_PROBE_RUN"
    static let executableKey = "MINDBUDGET_FX_PROBE_EXECUTABLE_SHA256"
    static let artifactKey = "MINDBUDGET_FX_PROBE_ARTIFACT_SHA256"
    static let action = "OWNER_APPROVED_SYNTHETIC_ROUND_TRIP"
    let run: UUID
    let executableSHA256: String
    let artifactSHA256: String

    // The marker is an accidental-execution guard, NOT owner authorization or a secret.
    // The operator must audit the exact signed app and obtain approval BEFORE installation/run.
    static func parse(environment: [String: String], bundle: String?, physical: Bool) throws -> Self? {
        let keys = Set(environment.keys.filter { $0.hasPrefix("MINDBUDGET_FX_PROBE_") })
        guard !keys.isEmpty else { return nil } // ordinary launch is inert
        guard keys == [actionKey, runKey, executableKey, artifactKey], environment[actionKey] == action,
              let raw = environment[runKey], let run = UUID(uuidString: raw),
              raw == run.uuidString.lowercased(),
              let hash = environment[executableKey], hash.utf8.count == 64,
              hash.utf8.allSatisfy({ (48...57).contains($0) || (97...102).contains($0) }),
              let artifact = environment[artifactKey], artifact.utf8.count == 64,
              artifact.utf8.allSatisfy({ (48...57).contains($0) || (97...102).contains($0) })
        else { throw ProbeFailure.invalidRequest }
        guard bundle == Self.bundle else { throw ProbeFailure.wrongIdentity }
        guard physical else { throw ProbeFailure.simulator }
        return Self(run: run, executableSHA256: hash, artifactSHA256: artifact)
    }
}

// Dedicated Debug host only. Not a Task/MainActor timeout: a stuck awaited operation or
// main-thread stall cannot prevent this independent queue from exiting the test process.
// No journal or CloudKit cleanup is attempted on timeout; a RUNNING receipt is non-pass.
final class ProbeHardDeadline {
    private let timer: DispatchSourceTimer
    init(after seconds: Double = 180) {
        timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .userInitiated))
        timer.schedule(deadline: .now() + seconds, leeway: .milliseconds(0))
        timer.setEventHandler { Darwin._exit(124) }
        timer.resume()
    }
    deinit { timer.cancel() }
}

enum ProbeArtifact {
    // Byte-order canonical inventory shared with runner.artifact. Includes the profile,
    // signature resources and executable; only ASCII paths are accepted in this fixed host.
    static func digest(_ root: URL) throws -> String {
        var entries: [String] = []
        func visit(_ directory: URL, prefix: String) throws {
            for file in try FileManager.default.contentsOfDirectory(at: directory,
                    includingPropertiesForKeys: [.isRegularFileKey, .isSymbolicLinkKey, .isDirectoryKey]) {
                let values = try file.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey, .isDirectoryKey])
                guard values.isSymbolicLink != true else { throw ProbeFailure.wrongIdentity }
                let name = prefix + file.lastPathComponent
                if values.isDirectory == true { try visit(file, prefix: name + "/"); continue }
                guard values.isRegularFile == true else { throw ProbeFailure.wrongIdentity }
                guard name.utf8.allSatisfy({ (32...126).contains($0) }) else { throw ProbeFailure.wrongIdentity }
                let hash = SHA256.hash(data: try Data(contentsOf: file)).map { String(format: "%02x", $0) }.joined()
                entries.append(name + "\0" + hash + "\n")
            }
        }
        try visit(root, prefix: "")
        return SHA256.hash(data: Data(entries.sorted().joined().utf8)).map { String(format: "%02x", $0) }.joined()
    }
}

enum ProbeStep: String, CaseIterable, Codable {
    case remoteAbsence, upload, freshRead, editUpload, originalWriterRead, repeatedRead
}

@MainActor
protocol ProbeDriving: AnyObject {
    func perform(_ step: ProbeStep) async throws
    func stop() async
}

@MainActor
enum ProbeScenario {
    static func execute(_ driver: any ProbeDriving,
                        withinBudget: (() -> Bool)? = nil,
                        record: (ProbeStep) throws -> Void) async throws {
        let started = ContinuousClock.now
        let hasTime = withinBudget ?? { started.duration(to: .now) < .seconds(180) }
        do {
            for step in ProbeStep.allCases {
                try Task.checkCancellation()
                guard hasTime() else { throw ProbeFailure.deadline }
                try await driver.perform(step) // exactly one foreground pass; no retry loop
                guard hasTime() else { throw ProbeFailure.deadline }
                try record(step)
            }
            await driver.stop()
        } catch {
            await driver.stop()
            throw error
        }
    }
}

// One irreversible local run reservation for this app installation. No cleanup/reset API.
enum ProbeReservation {
    static func claim(root: URL, run: UUID) throws {
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let marker = root.appendingPathComponent("used-run.txt")
        do {
            try Data(run.uuidString.lowercased().utf8).write(to: marker, options: .withoutOverwriting)
        } catch { throw ProbeFailure.alreadyUsed }
    }
}
