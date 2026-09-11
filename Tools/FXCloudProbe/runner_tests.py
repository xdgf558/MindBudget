"""Local-only command doubles and a real hung local subprocess. No devicectl/CloudKit calls."""
import copy
import datetime as dt
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time
import uuid

import runner as r


def expect_failure(call):
    try:
        call()
    except (ValueError, OSError, TypeError, KeyError):
        return
    raise ValueError("negative fixture escaped")


def approval():
    return dict(version=2, ownerApproval="APPROVED_FOR_THIS_ONE_RUN", independentReview="synthetic-only",
                run="cc556499-258d-4c26-9364-0224a16458a3", deviceUDID="00000000-0000000000000000",
                bundle=r.BUNDLE, container=r.audit.CONTAINER, executableSHA256="a" * 64,
                artifactSHA256="b" * 64, controllerSHA256=r.controller_hash(),
                expiresAt=(dt.datetime.now(dt.timezone.utc) + dt.timedelta(hours=1)).isoformat(),
                operation="SIX_STAGE_SYNTHETIC_ROUND_TRIP", deletionAllowed=False)


def collection(root, request):
    root.mkdir()
    (root / "used-run.txt").write_text(request["run"])
    r.save_new(root / "receipt.json", dict(protocolVersion=2, run=request["run"].upper(),
                status="PASS_BOUNDED_SINGLE_DEVICE_ONLY", completed=r.STEPS, plannedExpenseCount=4,
                liveDeletionTested=False, executableSHA256=request["executableSHA256"],
                artifactSHA256=request["artifactSHA256"]))
    initial = {kind + "/" + str(uuid.UUID(int=index)): "1" * 64 for index in range(1, 5)
               for kind in ("expense", "expenseForeignCurrencyMetadata")}
    r.save_new(root / "initial-fixture.json", initial)
    r.save_new(root / "edited-fixture.json", {next(iter(initial)): "2" * 64})


def continuation_tests(root, fresh):
    prior = copy.deepcopy(fresh)
    prior["controllerSHA256"] = "c" * 64
    prior_path = root / "prior-approval.json"
    r.save_new(prior_path, prior)
    result = dict(status="NON_PASS", reason="SUSPENDED_LAUNCH_UNCONFIRMED_NO_RESUME_SENT",
                  processStopped=False, run=prior["run"], resumed=False,
                  liveDeletionTested=False, failureType="ValueError",
                  privateFailure="synthetic launch parser refusal", collectionAttempted=False)
    result_path = root / "prior-controller-result.json"
    r.save_new(result_path, result)
    state = root / "reservations"
    state.mkdir()
    retained = r.reservation_path(state, prior["deviceUDID"])
    r.save_new(retained, {"run": prior["run"], "status": "RESERVED"})

    observed_prior, metadata = r.continuation_metadata(
        prior_path, result_path, state, "a" * 64, "b" * 64, prior["deviceUDID"])
    r.require(observed_prior == prior and metadata == {
        "mode": r.CONTINUATION_MODE,
        "priorApprovalSHA256": r.sha(prior_path.read_bytes()),
        "priorControllerResultSHA256": r.sha(result_path.read_bytes()),
        "priorControllerSHA256": "c" * 64,
        "retainedReservationSHA256": r.sha(retained.read_bytes()),
    }, "continuation evidence binding mismatch")
    request = {**prior, "version": 3, "controllerSHA256": r.controller_hash(),
               "continuation": metadata}
    r.validate_approval(request, "a" * 64, "b" * 64, dt.datetime.now(dt.timezone.utc))

    negative_count = 0
    for key in metadata:
        bad = copy.deepcopy(request)
        del bad["continuation"][key]
        expect_failure(lambda bad=bad: r.validate_approval(
            bad, "a" * 64, "b" * 64, dt.datetime.now(dt.timezone.utc)))
        negative_count += 1
    for key, value in [("mode", "RETRY"), ("priorControllerResultSHA256", True),
                       ("priorControllerSHA256", "short"),
                       ("retainedReservationSHA256", "A" * 64)]:
        bad = copy.deepcopy(request); bad["continuation"][key] = value
        expect_failure(lambda bad=bad: r.validate_approval(
            bad, "a" * 64, "b" * 64, dt.datetime.now(dt.timezone.utc)))
        negative_count += 1
    for key in r.CONTINUATION_KEYS - {"mode"}:
        bad = copy.deepcopy(request); bad["continuation"][key] = "0" * 64
        expect_failure(lambda bad=bad: r.bind_continuation(bad, prior, metadata))
        negative_count += 1

    before = retained.read_bytes()
    r.reserve_run(state, request)
    r.require(retained.read_bytes() == before, "continuation rewrote retained reservation")
    claim = r.continuation_claim_path(state, request)
    r.require(r.read_json(claim) == {
        "run": request["run"], "status": "CONTINUATION_RESERVED",
        "controllerSHA256": request["controllerSHA256"],
        "priorApprovalSHA256": metadata["priorApprovalSHA256"],
        "priorControllerResultSHA256": metadata["priorControllerResultSHA256"],
        "retainedReservationSHA256": metadata["retainedReservationSHA256"],
    }, "continuation claim was not exact")
    expect_failure(lambda: r.reserve_run(state, request))
    negative_count += 1
    for transform in (
        lambda p, q, s: ({**p, "run": str(uuid.uuid4())}, q, s),
        lambda p, q, s: ({**p, "controllerSHA256": r.controller_hash()}, q, s),
        lambda p, q, s: (p, {**q, "reason": "controllerOrEvidenceNonPass"}, s),
        lambda p, q, s: (p, {**q, "resumed": True}, s),
        lambda p, q, s: (p, q, {"run": p["run"], "status": "COMPLETE"}),
    ):
        bad_prior, bad_result, bad_reservation = transform(
            copy.deepcopy(prior), copy.deepcopy(result), {"run": prior["run"], "status": "RESERVED"})
        expect_failure(lambda p=bad_prior, q=bad_result, s=bad_reservation:
                       r.validate_prior_continuation(
                           p, q, s, "a" * 64, "b" * 64, prior["deviceUDID"]))
        negative_count += 1
    expect_failure(lambda: r.validate_prior_continuation(
        prior, result, {"run": prior["run"], "status": "RESERVED"},
        "0" * 64, "b" * 64, prior["deviceUDID"]))
    negative_count += 1

    bad = copy.deepcopy(request); bad["run"] = str(uuid.uuid4())
    expect_failure(lambda: r.reserve_run(state, bad))
    bad = copy.deepcopy(request); bad["continuation"]["retainedReservationSHA256"] = "0" * 64
    expect_failure(lambda: r.reserve_run(state, bad))
    negative_count += 2

    fresh_state = root / "fresh-reservations"; fresh_state.mkdir()
    r.reserve_run(fresh_state, fresh)
    fresh_marker = r.reservation_path(fresh_state, fresh["deviceUDID"])
    r.require(r.read_json(fresh_marker) == {"run": fresh["run"], "status": "RESERVED"},
              "fresh reservation was not created")
    expect_failure(lambda: r.reserve_run(fresh_state, fresh))
    negative_count += 1
    print(f"PASS: same-run continuation preserves one exact reservation and adds one claim; "
          f"{negative_count} negatives.")
    return negative_count


def native_document(command_type, outcome, arguments, result=None, error=None):
    value = {"info": {"arguments": arguments, "commandType": command_type,
                      "environment": {"TERM": "dumb"}, "jsonVersion": 5,
                      "outcome": outcome, "version": "synthetic"}}
    if result is not None:
        value["result"] = result
    if error is not None:
        value["error"] = error
    return value


def installed_continuation_tests(root, fresh):
    base = root / "installed-continuation"
    base.mkdir()
    app = base / "SignedProbe.app"
    app.mkdir()
    state = base / "reservations"
    state.mkdir()

    original = copy.deepcopy(fresh)
    original["controllerSHA256"] = "c" * 64
    original_path = base / "original-approval.json"
    original_result_path = base / "original-result.json"
    r.save_new(original_path, original)
    r.save_new(original_result_path, dict(
        status="NON_PASS", reason="SUSPENDED_LAUNCH_UNCONFIRMED_NO_RESUME_SENT",
        processStopped=False, run=original["run"], resumed=False, liveDeletionTested=False,
        failureType="ValueError", privateFailure="synthetic parser refusal",
        collectionAttempted=False))
    retained = r.reservation_path(state, original["deviceUDID"])
    r.save_new(retained, {"run": original["run"], "status": "RESERVED"})
    _, first_metadata = r.continuation_metadata(
        original_path, original_result_path, state, "a" * 64, "b" * 64,
        original["deviceUDID"])
    prior = {**original, "version": 3, "controllerSHA256": "d" * 64,
             "continuation": first_metadata}
    prior_path = base / "prior-v3-approval.json"
    r.save_new(prior_path, prior)
    prior_claim = r.continuation_claim_path(state, prior)
    r.save_new(prior_claim, r.expected_continuation_claim(prior))
    prior_result = dict(
        status="NON_PASS", reason="SUSPENDED_LAUNCH_UNCONFIRMED_NO_RESUME_SENT",
        processStopped=False, run=prior["run"], resumed=False, liveDeletionTested=False,
        failureType="ValueError", privateFailure="native command non-pass",
        collectionAttempted=False)
    prior_result_path = base / "prior-v3-result.json"
    r.save_new(prior_result_path, prior_result)

    launch_environment = {
        "MINDBUDGET_FX_PROBE_ACTION": "OWNER_APPROVED_SYNTHETIC_ROUND_TRIP",
        "MINDBUDGET_FX_PROBE_RUN": prior["run"],
        "MINDBUDGET_FX_PROBE_EXECUTABLE_SHA256": prior["executableSHA256"],
        "MINDBUDGET_FX_PROBE_ARTIFACT_SHA256": prior["artifactSHA256"],
    }
    launch = native_document(
        "devicectl.device.process.launch", "failed",
        ["devicectl", "device", "process", "launch", "--start-stopped",
         "--environment-variables", json.dumps(launch_environment), "--device",
         prior["deviceUDID"], "--timeout", "15", "--json-output",
         "/private/synthetic-launch.json", r.BUNDLE],
        error={"domain": "com.apple.dt.CoreDeviceError", "code": 10002,
               "userInfo": {"BundleIdentifier": {"string": r.BUNDLE},
                            "NSLocalizedFailureReason": {
                                "string": f"The requested application {r.BUNDLE} is not installed."},
                            "NSUnderlyingError": {"error": {
                                "domain": "NSOSStatusErrorDomain", "code": -10814}}}})
    installation = native_document(
        "devicectl.device.install.app", "success",
        ["devicectl", "device", "install", "app", "--device", prior["deviceUDID"],
         str(app), "--timeout", "60", "--json-output", "/private/synthetic-install.json"],
        result={"deviceIdentifier": "synthetic", "installedApplications": [
            {"bundleID": r.BUNDLE}]})
    apps = native_document(
        "devicectl.device.info.apps", "success",
        ["devicectl", "device", "info", "apps", "--bundle-id", r.BUNDLE,
         "--device", prior["deviceUDID"], "--timeout", "10", "--json-output",
         "/private/synthetic-apps.json"],
        result={"deviceIdentifier": "synthetic", "apps": [
            {"bundleIdentifier": r.BUNDLE}]})
    processes = native_document(
        "devicectl.device.info.processes", "success",
        ["devicectl", "device", "info", "processes", "--search", r.PROCESS_SEARCH,
         "--device", prior["deviceUDID"], "--timeout", "5", "--json-output",
         "/private/synthetic-processes.json"],
        result={"deviceIdentifier": "synthetic", "runningProcesses": []})
    evidence = []
    for name, value in [("launch", launch), ("installation", installation),
                        ("apps", apps), ("processes", processes)]:
        path = base / (name + ".json")
        r.save_new(path, value)
        evidence.append(path)

    observed, metadata = r.installed_continuation_metadata(
        prior_path, prior_result_path, state, app, "a" * 64, "b" * 64,
        prior["deviceUDID"], *evidence)
    request = {**observed, "version": 4, "controllerSHA256": r.controller_hash(),
               "continuation": metadata}
    r.validate_approval(request, "a" * 64, "b" * 64, dt.datetime.now(dt.timezone.utc))
    r.require(metadata == {
        "mode": r.INSTALLED_CONTINUATION_MODE,
        "priorApprovalSHA256": r.sha(prior_path.read_bytes()),
        "priorControllerResultSHA256": r.sha(prior_result_path.read_bytes()),
        "priorControllerSHA256": prior["controllerSHA256"],
        "priorContinuationClaimSHA256": r.sha(prior_claim.read_bytes()),
        "priorNativeLaunchResultSHA256": r.sha(evidence[0].read_bytes()),
        "installationResultSHA256": r.sha(evidence[1].read_bytes()),
        "postinstallAppsResultSHA256": r.sha(evidence[2].read_bytes()),
        "postinstallProcessesResultSHA256": r.sha(evidence[3].read_bytes()),
        "retainedReservationSHA256": r.sha(retained.read_bytes()),
    }, "installed continuation evidence binding mismatch")

    negative_count = 0
    for key in metadata:
        bad = copy.deepcopy(request)
        del bad["continuation"][key]
        expect_failure(lambda bad=bad: r.validate_approval(
            bad, "a" * 64, "b" * 64, dt.datetime.now(dt.timezone.utc)))
        negative_count += 1
    for key, value in [("mode", "RETRY"), ("priorContinuationClaimSHA256", True),
                       ("installationResultSHA256", "short"),
                       ("postinstallProcessesResultSHA256", "A" * 64)]:
        bad = copy.deepcopy(request)
        bad["continuation"][key] = value
        expect_failure(lambda bad=bad: r.validate_approval(
            bad, "a" * 64, "b" * 64, dt.datetime.now(dt.timezone.utc)))
        negative_count += 1

    duplicate_environment_launch = copy.deepcopy(launch)
    environment_index = duplicate_environment_launch["info"]["arguments"].index(
        "--environment-variables") + 1
    duplicate_environment_launch["info"]["arguments"][environment_index] = (
        json.dumps(launch_environment)[:-1] +
        f', "MINDBUDGET_FX_PROBE_RUN": "{prior["run"]}"}}')
    relative_installation = copy.deepcopy(installation)
    relative_installation["info"]["arguments"][6] = "relative/Probe.app"
    corruptions = [
        ("result", {**prior_result, "resumed": True}),
        ("claim", {**r.expected_continuation_claim(prior), "status": "COMPLETE"}),
        ("launch", {**launch, "error": {**launch["error"], "code": 7}}),
        ("launch", duplicate_environment_launch),
        ("installation", {**installation, "result": {"installedApplications": [
            {"bundleID": "com.example.wrong"}]}}),
        ("installation", relative_installation),
        ("apps", {**apps, "result": {"apps": []}}),
        ("processes", {**processes, "result": {"runningProcesses": [
            {"processIdentifier": 77, "executable": "file:///private/probe"}]}}),
    ]
    for name, value in corruptions:
        values = {"result": prior_result, "claim": r.expected_continuation_claim(prior),
                  "launch": launch, "installation": installation, "apps": apps,
                  "processes": processes}
        values[name] = value
        expect_failure(lambda values=values: r.validate_prior_installed_continuation(
            prior, values["result"], values["claim"], values["launch"],
            values["installation"], values["apps"], values["processes"],
            {"run": prior["run"], "status": "RESERVED"}, app,
            "a" * 64, "b" * 64, prior["deviceUDID"]))
        negative_count += 1

    run_state = base / "run-order-state"
    run_state.mkdir()
    r.save_new(r.reservation_path(run_state, prior["deviceUDID"]),
               {"run": prior["run"], "status": "RESERVED"})
    r.save_new(r.continuation_claim_path(run_state, prior),
               r.expected_continuation_claim(prior))
    run_metadata = r.installed_continuation_metadata(
        prior_path, prior_result_path, run_state, app, "a" * 64, "b" * 64,
        prior["deviceUDID"], *evidence)[1]
    run_request = {**request, "continuation": run_metadata}
    run_approval_path = base / "run-order-v4-approval.json"
    r.save_new(run_approval_path, run_request)
    run_claim = r.continuation_claim_path(run_state, run_request)
    events = []
    originals = r.artifact, r.native_toolchain_preflight, r.Device, r.supervise

    class GuardDevice:
        def __init__(self, device, out, supplied_env):
            r.require(run_claim.exists(), "device constructed before installed continuation claim")
            r.require(supplied_env == {"DEVELOPER_DIR": "/synthetic/Developer"},
                      "installed continuation preflight environment not passed to device")
            events.append("device")

    try:
        r.artifact = lambda supplied_app, device: ("a" * 64, "b" * 64)
        r.Device = GuardDevice
        r.supervise = lambda device, approval, out: {"status": "NON_PASS"}

        def reject_preflight():
            events.append("preflight-rejected")
            raise ValueError("synthetic missing devicectl")

        r.native_toolchain_preflight = reject_preflight
        rejected_out = base / "run-order-v4-rejected-out"
        expect_failure(lambda: r.run(
            app, run_approval_path, rejected_out, run_state, prior_path,
            prior_result_path, *evidence))
        r.require(events == ["preflight-rejected"] and not run_claim.exists() and
                  not rejected_out.exists(),
                  "v4 toolchain failure consumed claim/output or constructed a device")

        r.native_toolchain_preflight = lambda: (
            events.append("preflight-accepted") or {"DEVELOPER_DIR": "/synthetic/Developer"})
        accepted_out = base / "run-order-v4-accepted-out"
        r.require(r.run(app, run_approval_path, accepted_out, run_state, prior_path,
                        prior_result_path, *evidence) == 1 and
                  events[-2:] == ["preflight-accepted", "device"] and run_claim.exists() and
                  (accepted_out / "approval.json").is_file(),
                  "v4 claim did not precede device construction after accepted preflight")
    finally:
        r.artifact, r.native_toolchain_preflight, r.Device, r.supervise = originals

    retained_before = retained.read_bytes()
    prior_claim_before = prior_claim.read_bytes()
    r.reserve_run(state, request, prior)
    current_claim = r.continuation_claim_path(state, request)
    r.require(retained.read_bytes() == retained_before and
              prior_claim.read_bytes() == prior_claim_before and
              r.read_json(current_claim) == {
                  "run": request["run"], "status": "INSTALLED_CONTINUATION_RESERVED",
                  "controllerSHA256": request["controllerSHA256"],
                  "continuation": metadata},
              "installed continuation rewrote history or created a wrong claim")
    expect_failure(lambda: r.reserve_run(state, request, prior))
    negative_count += 1
    bad = copy.deepcopy(request)
    bad["continuation"]["priorContinuationClaimSHA256"] = "0" * 64
    expect_failure(lambda: r.reserve_run(state, bad, prior))
    negative_count += 1
    print(f"PASS: installed same-run continuation binds prior claim/failure/install; "
          f"{negative_count} negatives.")
    return negative_count


class FakeDevice:
    path = "/private/synthetic/" + r.EXECUTABLE + ".app/" + r.EXECUTABLE

    def __init__(self, request, failure=None):
        self.request, self.failure, self.calls = request, failure, []
        self.running, self.killed, self.time = False, False, 0

    def require_installed(self):
        self.calls.append("installed")
        if self.failure == "notInstalled":
            raise ValueError("synthetic dedicated probe is absent")

    def processes(self):
        self.calls.append("processes")
        if self.failure == "connectionLost" and self.running:
            raise TimeoutError("synthetic offline")
        if self.failure == "existing":
            return {77: self.path}
        if self.failure == "pidReusedAfterExit" and self.time:
            return {77: "/unrelated.app/unrelated"}
        return {77: self.path} if self.running else {}

    def launch_stopped(self, request):
        self.calls.append("launch")
        if self.failure == "unboundLaunch":
            raise ValueError("synthetic unknown launch JSON")
        self.running = True
        return 77, self.path

    def resume(self, pid, seconds):
        self.calls.append("resume")
        if self.failure in ("resume", "connectionLost"):
            raise TimeoutError("synthetic resume")

    def await_exit(self, pid, seconds):
        self.calls.append("await")
        self.time = 181 if self.failure == "deadline" else 1
        if self.failure in ("await", "killFailed"):
            raise TimeoutError("synthetic hung transport")
        self.running = False

    def kill(self, pid):
        self.calls.append("kill")
        if self.failure == "killFailed":
            raise TimeoutError("synthetic termination failure")
        self.killed, self.running = True, False

    def collect(self, destination):
        self.calls.append("collect")
        if self.failure == "collection":
            raise TimeoutError("synthetic collector timeout")
        collection(destination, self.request)
        if self.failure == "receipt":
            (destination / "receipt.json").write_text("{}")


def process_filter_tests(root, request):
    exact = "/MindBudgetFXCloudProbe.app/MindBudgetFXCloudProbe"
    r.require(r.PROCESS_SEARCH == exact, "native search broadened")
    path = "/private/synthetic/MindBudgetFXCloudProbe.app/MindBudgetFXCloudProbe"

    class CommandDevice(r.Device):
        def __init__(self, payload):
            self.payload, self.calls = payload, []

        def command(self, args, seconds):
            self.calls.append((args, seconds))
            r.require(args == ["info", "processes", "--search", exact] and seconds == 5,
                      "unfiltered/widened process query or changed timeout")
            if isinstance(self.payload, Exception):
                raise self.payload
            return self.payload

    valid = {"processIdentifier": 77, "executable": "file://" + path}
    for payload, expected in [({"runningProcesses": []}, {}),
                              ({"runningProcesses": [valid]}, {77: path})]:
        device = CommandDevice(payload)
        r.require(device.processes() == expected and len(device.calls) == 1, "filtered process decoding")
    negatives = [
        {}, {"runningProcesses": None}, {"runningProcesses": {}},
        {"runningProcesses": [valid, valid]}, {"runningProcesses": [{}]},
        {"runningProcesses": [{**valid, "processIdentifier": True}]},
        {"runningProcesses": [{**valid, "executable": {"path": path}}]},
        {"runningProcesses": [{**valid, "executable": "relative/MindBudgetFXCloudProbe.app/MindBudgetFXCloudProbe"}]},
        {"runningProcesses": [{**valid, "executable": "file:///private/MindBudget.app/MindBudget"}]},
        {"runningProcesses": [{**valid, "executable": "file://" + path + "Helper"}]},
        {"runningProcesses": [{**valid, "executable": "file://remote" + path}]},
        {"runningProcesses": [{**valid, "executable": "https://remote" + path}]},
        {"runningProcesses": [valid, {"processIdentifier": 78, "executable": "/private/other"}]},
        ValueError("synthetic native URL predicate failure"),
    ]
    for index, payload in enumerate(negatives):
        device = CommandDevice(payload)
        out = root / ("native-refusal-" + str(index)); out.mkdir()
        result = r.supervise(device, request, out)
        r.require(result["status"] == "NON_PASS" and not result["resumed"] and
                  not result["collectionAttempted"] and len(device.calls) == 1,
                  "invalid native query resumed/retried or lost failure")

    # Exercise real NSPredicate/NSURL, not a JSON string standing in for the native URL.
    executable = root / "predicate-tests"
    subprocess.run(["xcrun", "clang", "-fobjc-arc", "-Wall", "-Wextra", "-Werror",
                    "-framework", "Foundation", str(Path(__file__).with_name("ProcessPredicateTests.m")),
                    "-o", str(executable)], check=True, capture_output=True, timeout=60)
    result = subprocess.run([str(executable)],
                            check=True, capture_output=True, timeout=10)
    print(result.stdout.decode(), end="")
    print(f"PASS: two native process-list positives / {len(negatives)} fail-closed refusals; no fallback/retry.")


def app_inventory_tests(request):
    class CommandDevice(r.Device):
        def __init__(self, payload):
            self.payload, self.calls = payload, []

        def command(self, args, seconds):
            self.calls.append((args, seconds))
            r.require(args == ["info", "apps", "--bundle-id", r.BUNDLE] and seconds == 10,
                      "installed-app query broadened or changed deadline")
            return self.payload

    valid = {"apps": [{"bundleIdentifier": r.BUNDLE}]}
    device = CommandDevice(valid)
    device.require_installed()
    r.require(len(device.calls) == 1, "installed-app query repeated")
    negatives = [{}, {"apps": None}, {"apps": []}, {"apps": {}},
                 {"apps": [{"bundleIdentifier": "com.example.wrong"}]},
                 {"apps": [{"bundleIdentifier": r.BUNDLE},
                            {"bundleIdentifier": r.BUNDLE}]},
                 {"apps": [r.BUNDLE]}]
    for payload in negatives:
        rejected = CommandDevice(payload)
        expect_failure(rejected.require_installed)
        r.require(len(rejected.calls) == 1, "invalid installed-app result retried")
    print(f"PASS: exact installed-app query accepts one dedicated bundle; "
          f"{len(negatives)} fail-closed refusals.")


def launch_argument_order_tests(root, request):
    captured = []
    original_capture = r.capture

    def fake_capture(argv, log, seconds, env):
        captured.append((argv, log, seconds, env))
        output = Path(argv[argv.index("--json-output") + 1])
        r.save_new(output, {"info": {"outcome": "success"}, "result": {
            "process": {"processIdentifier": 77,
                        "executable": "file:///private/synthetic/" + r.EXECUTABLE +
                                      ".app/" + r.EXECUTABLE}}})

    try:
        r.capture = fake_capture
        device = r.Device(request["deviceUDID"], root)
        pid, path = device.launch_stopped(request)
    finally:
        r.capture = original_capture

    r.require(pid == 77 and r.is_probe(path) and len(captured) == 1,
              "launch command fixture did not return the dedicated process")
    argv, log, seconds, env = captured[0]
    bundle_index = argv.index(r.BUNDLE)
    r.require(argv[:5] == ["/usr/bin/xcrun", "devicectl", "device", "process", "launch"] and
              argv[bundle_index:] == [r.BUNDLE],
              "launch positional tail broadened or bundle is not last")
    for flag in ("--start-stopped", "--environment-variables", "--device", "--timeout",
                 "--json-output"):
        r.require(argv.index(flag) < bundle_index, "devicectl option followed launch Bundle ID")
    r.require(argv[argv.index("--device") + 1] == request["deviceUDID"] and
              argv[argv.index("--timeout") + 1] == "15" and seconds == 15,
              "launch binding or timeout changed")
    launch_env = json.loads(argv[argv.index("--environment-variables") + 1])
    r.require(launch_env == {
        "MINDBUDGET_FX_PROBE_ACTION": "OWNER_APPROVED_SYNTHETIC_ROUND_TRIP",
        "MINDBUDGET_FX_PROBE_RUN": request["run"],
        "MINDBUDGET_FX_PROBE_EXECUTABLE_SHA256": request["executableSHA256"],
        "MINDBUDGET_FX_PROBE_ARTIFACT_SHA256": request["artifactSHA256"],
    } and log.name == "native-01.log" and not any(key.startswith("MINDBUDGET_") for key in env),
              "launch environment boundary changed")

    invalid_root = root / "invalid-command-arguments"
    invalid_root.mkdir()
    invalid = r.Device(request["deviceUDID"], invalid_root)
    for args, tail in [(["process", None], ()), (["process"], r.BUNDLE),
                       (["process"], [r.BUNDLE, None])]:
        expect_failure(lambda args=args, tail=tail: invalid.command(args, 1, tail))
    r.require(invalid.count == 3 and not any(invalid_root.glob("native-*.json")),
              "invalid command arguments escaped before native execution")
    print("PASS: launch common options precede the sole Bundle ID positional; no app arguments/retry.")


def toolchain_preflight_and_run_order_tests(root, fresh):
    developer = root / "Xcode.app" / "Contents" / "Developer"
    tool = developer / "usr" / "bin" / "devicectl"
    tool.parent.mkdir(parents=True)
    tool.write_text("synthetic executable")
    tool.chmod(0o700)
    environment = {"DEVELOPER_DIR": str(developer), "MINDBUDGET_FORBIDDEN": "1",
                   "DEVICECTL_CHILD_FORBIDDEN": "1", "PATH": "/usr/bin"}
    lookups = []

    def lookup(argv, **kwargs):
        lookups.append((argv, kwargs))
        return subprocess.CompletedProcess(argv, 0, str(tool) + "\n", "")

    native_env = r.native_toolchain_preflight(environment, lookup)
    r.require(len(lookups) == 1 and lookups[0][0] == [r.XCRUN, "--find", "devicectl"] and
              lookups[0][1]["timeout"] == 5 and
              native_env["DEVELOPER_DIR"] == str(developer) and
              not any(key.startswith(("MINDBUDGET_", "DEVICECTL_CHILD_")) for key in native_env),
              "toolchain lookup was not explicit, bounded and sanitized")
    for bad_env, completed in [
        ({}, subprocess.CompletedProcess([], 0, str(tool) + "\n", "")),
        ({"DEVELOPER_DIR": "relative"}, subprocess.CompletedProcess([], 0, str(tool) + "\n", "")),
        (environment, subprocess.CompletedProcess([], 72, "", "missing")),
        (environment, subprocess.CompletedProcess([], 0, str(tool) + "\nextra\n", "")),
        (environment, subprocess.CompletedProcess([], 0, "/usr/bin/devicectl\n", "")),
    ]:
        expect_failure(lambda bad_env=bad_env, completed=completed:
                       r.native_toolchain_preflight(
                           bad_env, lambda *args, completed=completed, **kwargs: completed))

    prior = copy.deepcopy(fresh)
    prior["controllerSHA256"] = "c" * 64
    prior_path = root / "run-order-prior-approval.json"
    result_path = root / "run-order-prior-result.json"
    r.save_new(prior_path, prior)
    r.save_new(result_path, dict(
        status="NON_PASS", reason="SUSPENDED_LAUNCH_UNCONFIRMED_NO_RESUME_SENT",
        processStopped=False, run=prior["run"], resumed=False, liveDeletionTested=False,
        failureType="ValueError", privateFailure="synthetic parser refusal",
        collectionAttempted=False))
    state = root / "run-order-state"
    state.mkdir()
    retained = r.reservation_path(state, prior["deviceUDID"])
    r.save_new(retained, {"run": prior["run"], "status": "RESERVED"})
    observed_prior, metadata = r.continuation_metadata(
        prior_path, result_path, state, "a" * 64, "b" * 64, prior["deviceUDID"])
    request = {**observed_prior, "version": 3, "controllerSHA256": r.controller_hash(),
               "continuation": metadata}
    approval_path = root / "run-order-approval.json"
    r.save_new(approval_path, request)
    app = root / "synthetic.app"
    app.mkdir()
    claim = r.continuation_claim_path(state, request)
    events = []
    originals = r.artifact, r.native_toolchain_preflight, r.Device, r.supervise

    class GuardDevice:
        def __init__(self, device, out, supplied_env):
            r.require(claim.exists(), "device constructed before continuation claim")
            r.require(supplied_env == {"DEVELOPER_DIR": "/synthetic/Developer"},
                      "preflight environment not passed to device")
            events.append("device")

    try:
        r.artifact = lambda app, device: ("a" * 64, "b" * 64)
        r.Device = GuardDevice
        r.supervise = lambda device, approval, out: {"status": "NON_PASS"}

        def reject_preflight():
            events.append("preflight-rejected")
            raise ValueError("synthetic missing devicectl")

        r.native_toolchain_preflight = reject_preflight
        rejected_out = root / "run-order-rejected-out"
        expect_failure(lambda: r.run(app, approval_path, rejected_out, state,
                                     prior_path, result_path))
        r.require(events == ["preflight-rejected"] and not claim.exists() and
                  not rejected_out.exists(),
                  "toolchain failure consumed claim/output or constructed a device")

        r.native_toolchain_preflight = lambda: (
            events.append("preflight-accepted") or {"DEVELOPER_DIR": "/synthetic/Developer"})
        accepted_out = root / "run-order-accepted-out"
        r.require(r.run(app, approval_path, accepted_out, state,
                        prior_path, result_path) == 1 and
                  events[-2:] == ["preflight-accepted", "device"] and claim.exists() and
                  (accepted_out / "approval.json").is_file(),
                  "claim did not precede device construction after accepted preflight")
    finally:
        r.artifact, r.native_toolchain_preflight, r.Device, r.supervise = originals
    print("PASS: explicit devicectl preflight precedes claim; rejection consumes no run/device authority.")


def self_test():
    request = approval()
    now = dt.datetime.now(dt.timezone.utc)
    r.validate_approval(request, "a" * 64, "b" * 64, now)
    negative_count = 0
    for key in request:
        bad = copy.deepcopy(request)
        del bad[key]
        expect_failure(lambda: r.validate_approval(bad, "a" * 64, "b" * 64, now))
        negative_count += 1
    for key, value in [("ownerApproval", "PENDING"), ("independentReview", "PENDING"),
                       ("version", True), ("deletionAllowed", 0), ("deletionAllowed", True),
                       ("bundle", "com.xdgf558.MindBudget"), ("container", "other"),
                       ("run", request["run"].upper()), ("executableSHA256", "0" * 64),
                       ("artifactSHA256", "0" * 64), ("controllerSHA256", "0" * 64),
                       ("operation", "DELETE"), ("expiresAt", now.isoformat()),
                       ("expiresAt", (now + dt.timedelta(days=2)).isoformat())]:
        bad = copy.deepcopy(request); bad[key] = value
        expect_failure(lambda: r.validate_approval(bad, "a" * 64, "b" * 64, now))
        negative_count += 1
    with tempfile.TemporaryDirectory(prefix="fx-probe-local-controller-tests-") as directory:
        root = Path(directory)
        negative_count += continuation_tests(root, request)
        negative_count += installed_continuation_tests(root, request)
        app_inventory_tests(request)
        process_filter_tests(root, request)
        launch_argument_order_tests(root, request)
        toolchain_preflight_and_run_order_tests(root, request)
        good = root / "good"
        collection(good, request)
        r.verify_collection(good, request)
        receipt = r.read_json(good / "receipt.json")
        for key, value in [("status", "RUNNING"), ("protocolVersion", 1), ("plannedExpenseCount", True),
                           ("liveDeletionTested", 0), ("completed", r.STEPS[:-1]),
                           ("completed", r.STEPS + [r.STEPS[-1]]), ("completed", r.STEPS[::-1]),
                           ("executableSHA256", "c" * 64), ("artifactSHA256", "c" * 64),
                           ("run", str(uuid.uuid4()))]:
            bad = dict(receipt); bad[key] = value
            (good / "receipt.json").write_text(json.dumps(bad))
            expect_failure(lambda: r.verify_collection(good, request))
            negative_count += 1
        (good / "receipt.json").write_text(json.dumps(receipt))
        r.verify_collection(good, request)
        initial = r.read_json(good / "initial-fixture.json")
        for bad in [{}, {"expense/wrong": "1" * 64}, {**initial, "income/other": "1" * 64}]:
            (good / "initial-fixture.json").write_text(json.dumps(bad))
            expect_failure(lambda: r.verify_collection(good, request))
            negative_count += 1
        (good / "initial-fixture.json").write_text(json.dumps(initial))
        (good / "edited-fixture.json").write_text(json.dumps({next(iter(initial)): "1" * 64}))
        expect_failure(lambda: r.verify_collection(good, request))
        duplicate = root / "duplicate.json"
        duplicate.write_text('{"x": 1, "x": 2}')
        expect_failure(lambda: r.read_json(duplicate))
        expect_failure(lambda: r.save_new(duplicate, {}))

        for failure in [None, "notInstalled", "existing", "unboundLaunch", "resume", "await",
                        "deadline", "killFailed", "connectionLost", "pidReusedAfterExit",
                        "collection", "receipt"]:
            out = root / (failure or "happy"); out.mkdir()
            device = FakeDevice(request, failure)
            result = r.supervise(device, request, out, clock=lambda: device.time)
            r.require((result["status"] == "PASS_BOUNDED_SINGLE_DEVICE_ONLY") == (failure is None),
                      "failed controller accepted or success rejected: " + str(failure))
            r.require(device.calls[0] == "installed",
                      "installed-App gate was not the first device operation")
            r.require(all(device.calls.count(name) <= 1 for name in ("launch", "resume", "await", "kill", "collect")),
                      "hidden application/command retry")
            if failure in ("existing", "unboundLaunch", "pidReusedAfterExit"):
                r.require("kill" not in device.calls, "unowned process terminated")
            if failure in ("notInstalled", "existing", "unboundLaunch", "connectionLost"):
                r.require("resume" not in device.calls, "resumed without verified process ownership")
            if failure == "notInstalled":
                r.require(device.calls == ["installed"],
                          "not-installed preflight queried/launched after refusal")
            if failure in ("resume", "await"):
                r.require(device.killed and result["processStopped"], "owned hung process not terminated")
            if failure in ("killFailed", "connectionLost", "pidReusedAfterExit"):
                r.require(result["reason"] == "STOP_UNCONFIRMED", "lost termination status hidden")

        # Real hung local process ignores TERM: process-group SIGKILL enforces deadline.
        began = time.monotonic()
        try:
            r.capture([sys.executable, "-c", "import signal,time; signal.signal(signal.SIGTERM,signal.SIG_IGN); time.sleep(60)"],
                      root / "hung-local.log", 0.2, dict(os.environ))
            raise ValueError("hard watchdog failed")
        except subprocess.TimeoutExpired:
            r.require(time.monotonic() - began < 5, "local timeout did not kill promptly")
    expect_failure(lambda: r.native_result({"info": {"outcome": "failure"}, "result": {}}))
    r.verify_normal_exit({"terminationResult": {"exitCode": 0}})
    for value in [{}, {"exitCode": 1}, {"exitCode": False}, {"exitCode": 0, "signal": 9}]:
        expect_failure(lambda: r.verify_normal_exit({"terminationResult": value}))
    for value in [{}, {"processIdentifier": True, "executable": "/a"},
                  {"processIdentifier": 77, "executable": "https://remote/a"}]:
        expect_failure(lambda: r.process_identity(value))
    r.require(r.process_identity({"processIdentifier": 77, "executable": "file:///private/a"}) == (77, "/private/a"),
              "native file URL parsing")
    print(f"PASS: {negative_count}+ approval/evidence negatives; 12 controller scenarios; real hung-process deadline.")
    print("Local fixtures only; native phone JSON/runtime and CloudKit remain unverified.")


if __name__ == "__main__":
    self_test()
