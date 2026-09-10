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
