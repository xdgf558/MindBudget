import Foundation

enum ProbeFailure: String, Error {
    case invalidRequest, wrongIdentity, simulator, alreadyUsed, unexpectedRemoteZone
    case localState, transport, unexpectedRecords, comparison, deadline
}

struct ProbeRequest: Equatable {
    static let bundle = "com.xdgf558.MindBudgetFXCloudProbe"
    static let container = "iCloud.com.xdgf558.MindBudgetFXCloudProbe"
    static let actionKey = "MINDBUDGET_FX_PROBE_ACTION"
    static let runKey = "MINDBUDGET_FX_PROBE_RUN"
    static let action = "OWNER_APPROVED_SYNTHETIC_ROUND_TRIP"
    let run: UUID

    // The marker is an accidental-execution guard, NOT owner authorization or a secret.
    // The operator must audit the exact signed app and obtain approval BEFORE installation/run.
    static func parse(environment: [String: String], bundle: String?, physical: Bool) throws -> Self? {
        let keys = Set(environment.keys.filter { $0.hasPrefix("MINDBUDGET_FX_PROBE_") })
        guard !keys.isEmpty else { return nil } // ordinary launch is inert
        guard keys == [actionKey, runKey], environment[actionKey] == action,
              let raw = environment[runKey], let run = UUID(uuidString: raw),
              raw == run.uuidString.lowercased() else { throw ProbeFailure.invalidRequest }
        guard bundle == Self.bundle else { throw ProbeFailure.wrongIdentity }
        guard physical else { throw ProbeFailure.simulator }
        return Self(run: run)
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
