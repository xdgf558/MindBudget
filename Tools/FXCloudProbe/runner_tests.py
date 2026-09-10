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


class FakeDevice:
    path = "/private/synthetic/" + r.EXECUTABLE + ".app/" + r.EXECUTABLE

    def __init__(self, request, failure=None):
        self.request, self.failure, self.calls = request, failure, []
        self.running, self.killed, self.time = False, False, 0

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
        process_filter_tests(root, request)
        launch_argument_order_tests(root, request)
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

        for failure in [None, "existing", "unboundLaunch", "resume", "await", "deadline", "killFailed",
                        "connectionLost", "pidReusedAfterExit", "collection", "receipt"]:
            out = root / (failure or "happy"); out.mkdir()
            device = FakeDevice(request, failure)
            result = r.supervise(device, request, out, clock=lambda: device.time)
            r.require((result["status"] == "PASS_BOUNDED_SINGLE_DEVICE_ONLY") == (failure is None),
                      "failed controller accepted or success rejected: " + str(failure))
            r.require(all(device.calls.count(name) <= 1 for name in ("launch", "resume", "await", "kill", "collect")),
                      "hidden application/command retry")
            if failure in ("existing", "unboundLaunch", "pidReusedAfterExit"):
                r.require("kill" not in device.calls, "unowned process terminated")
            if failure in ("existing", "unboundLaunch", "connectionLost"):
                r.require("resume" not in device.calls, "resumed without verified process ownership")
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
    print(f"PASS: {negative_count}+ approval/evidence negatives; 11 controller scenarios; real hung-process deadline.")
    print("Local fixtures only; native phone JSON/runtime and CloudKit remain unverified.")


if __name__ == "__main__":
    self_test()
