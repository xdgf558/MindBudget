import Foundation

// Standalone local executable: this compilation contains NO CloudKit or production source.
@main
struct ProtocolTests {
    @MainActor
    static func main() async throws {
        if CommandLine.arguments.count == 3 && CommandLine.arguments[1] == "--artifact-hash" {
            do { print(try ProbeArtifact.digest(URL(fileURLWithPath: CommandLine.arguments[2]))) }
            catch { exit(2) }
            return
        }
        if CommandLine.arguments == [CommandLine.arguments[0], "--blocked-main-watchdog-child"] {
            let watchdog = ProbeHardDeadline(after: 0.15)
            withExtendedLifetime(watchdog) { while true { Thread.sleep(forTimeInterval: 1) } }
            return
        }
        func require(_ value: Bool, _ message: String) throws {
            if !value { throw NSError(domain: "ProbeProtocolTests", code: 1,
                                     userInfo: [NSLocalizedDescriptionKey: message]) }
        }
        let valid = [ProbeRequest.actionKey: ProbeRequest.action,
                     ProbeRequest.runKey: "cc556499-258d-4c26-9364-0224a16458a3",
                     ProbeRequest.executableKey: String(repeating: "a", count: 64),
                     ProbeRequest.artifactKey: String(repeating: "b", count: 64)]
        try require(try ProbeRequest.parse(environment: [:], bundle: nil, physical: false) == nil,
                    "normal launch not inert")
        let request = try ProbeRequest.parse(environment: valid, bundle: ProbeRequest.bundle, physical: true)
        try require(request != nil, "valid request rejected")
        var badEnvironments: [[String: String]] = []
        for key in valid.keys {
            var value = valid; value.removeValue(forKey: key); badEnvironments.append(value)
        }
        for bad in ["", "TRUE", "DELETE_ZONE"] {
            var value = valid; value[ProbeRequest.actionKey] = bad; badEnvironments.append(value)
        }
        for bad in ["", "../writer", "CC556499-258D-4C26-9364-0224A16458A3"] {
            var value = valid; value[ProbeRequest.runKey] = bad; badEnvironments.append(value)
        }
        var extra = valid; extra["MINDBUDGET_FX_PROBE_CONTAINER"] = "other"
        badEnvironments.append(extra)
        for hash in ["", String(repeating: "a", count: 63), String(repeating: "A", count: 64),
                     String(repeating: "g", count: 64)] {
            var bad = valid; bad[ProbeRequest.executableKey] = hash; badEnvironments.append(bad)
            bad = valid; bad[ProbeRequest.artifactKey] = hash; badEnvironments.append(bad)
        }
        for value in badEnvironments {
            do {
                _ = try ProbeRequest.parse(environment: value, bundle: ProbeRequest.bundle, physical: true)
                throw NSError(domain: "escaped request", code: 1)
            } catch is ProbeFailure {} // no other error accepted
        }
        for bundle in [nil, "com.xdgf558.MindBudget", "com.other"] as [String?] {
            do {
                _ = try ProbeRequest.parse(environment: valid, bundle: bundle, physical: true)
                throw NSError(domain: "escaped identity", code: 1)
            } catch ProbeFailure.wrongIdentity {}
        }
        do {
            _ = try ProbeRequest.parse(environment: valid, bundle: ProbeRequest.bundle, physical: false)
            throw NSError(domain: "escaped simulator", code: 1)
        } catch ProbeFailure.simulator {}

        let root = FileManager.default.temporaryDirectory.appendingPathComponent("probe-protocol-test-" + UUID().uuidString)
        // Cleanup is limited to this newly created local synthetic fixture, not an app or cloud zone.
        defer { try? FileManager.default.removeItem(at: root) }
        let first = UUID()
        try ProbeReservation.claim(root: root, run: first)
        for run in [first, UUID()] {
            do {
                try ProbeReservation.claim(root: root, run: run)
                throw NSError(domain: "escaped reuse", code: 1)
            } catch ProbeFailure.alreadyUsed {}
        }
        try require(try String(contentsOf: root.appendingPathComponent("used-run.txt"), encoding: .utf8)
                    == first.uuidString.lowercased(), "run marker overwritten")

        let happy = FakeDriver()
        var recorded: [ProbeStep] = []
        try await ProbeScenario.execute(happy) { recorded.append($0) }
        try require(recorded == ProbeStep.allCases && happy.calls == recorded && happy.stops == 1,
                    "wrong successful order/count")
        for failure in ProbeStep.allCases {
            let driver = FakeDriver(fail: failure)
            var records: [ProbeStep] = []
            do {
                try await ProbeScenario.execute(driver) { records.append($0) }
                throw NSError(domain: "escaped step failure", code: 1)
            } catch ProbeFailure.transport {}
            let prefix = Array(ProbeStep.allCases.prefix { $0 != failure })
            try require(records == prefix && driver.calls == prefix + [failure] && driver.stops == 1,
                        "step was retried or continued")
        }
        let writeFailure = FakeDriver()
        do {
            try await ProbeScenario.execute(writeFailure) { _ in throw ProbeFailure.localState }
            throw NSError(domain: "escaped journal failure", code: 1)
        } catch ProbeFailure.localState {}
        try require(writeFailure.calls == [.remoteAbsence] && writeFailure.stops == 1,
                    "continued after journal failure")
        for allowedChecks in [0, 1] {
            let driver = FakeDriver()
            var checks = 0
            do {
                try await ProbeScenario.execute(driver, withinBudget: {
                    checks += 1; return checks <= allowedChecks
                }) { _ in throw NSError(domain: "late result recorded", code: 1) }
                throw NSError(domain: "escaped deadline", code: 1)
            } catch ProbeFailure.deadline {}
            try require(driver.calls.count == allowedChecks && driver.stops == 1, "deadline continued")
        }
        let cancelled = FakeDriver()
        let task = Task { @MainActor in
            withUnsafeCurrentTask { $0?.cancel() }
            try await ProbeScenario.execute(cancelled) { _ in
                throw NSError(domain: "cancelled result recorded", code: 1)
            }
        }
        do {
            try await task.value
            throw NSError(domain: "escaped cancellation", code: 1)
        } catch is CancellationError {}
        try require(cancelled.calls.isEmpty && cancelled.stops == 1, "cancelled run continued")
        print("PASS: inert launch, exact request/identity/device class, exclusive run marker, six-step order;")
        print("PASS: executable-bound request negatives, 2 reuse refusals, 6 step failures, journal failure, 2 deadlines, cancellation.")
        print("Local protocol doubles only; no CloudKit, device installation or live runtime acceptance.")
    }
}

@MainActor
private final class FakeDriver: ProbeDriving {
    let fail: ProbeStep?
    var calls: [ProbeStep] = []
    var stops = 0
    init(fail: ProbeStep? = nil) { self.fail = fail }
    func perform(_ step: ProbeStep) async throws {
        calls.append(step)
        if step == fail { throw ProbeFailure.transport }
    }
    func stop() async { stops += 1 }
}
