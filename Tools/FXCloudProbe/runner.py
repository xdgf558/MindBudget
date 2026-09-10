#!/usr/bin/env python3
"""Offline preparation, or separately authorized ONE-shot dedicated probe supervision.

No install/delete/reset/account API. --prepare and --self-test never contact a device.
--run requires an exact artifact/device approval file AND separate human authorization;
the file is an operational guard, not a permission credential.
"""
import argparse
import datetime as dt
import hashlib
import json
import math
import os
from pathlib import Path
import re
import signal
import subprocess
import sys
import time
from urllib.parse import unquote, urlparse
import uuid

import audit

BUNDLE = audit.BUNDLE
EXECUTABLE = "MindBudgetFXCloudProbe"
# devicectl's executable is a native NSURL and its field resolver rejects executable.path.
# Its documented plain-text search handles displayable values. Require an exact decoded
# path below as a second boundary; never request an unfiltered list or retry with a fallback.
PROCESS_SEARCH = "/MindBudgetFXCloudProbe.app/MindBudgetFXCloudProbe"
STEPS = ["remoteAbsence", "upload", "freshRead", "editUpload", "originalWriterRead", "repeatedRead"]
FILES = ["used-run.txt", "receipt.json", "initial-fixture.json", "edited-fixture.json"]
BUDGET = 180
APPROVAL_KEYS = {"version", "ownerApproval", "independentReview", "run", "deviceUDID",
                 "bundle", "container", "executableSHA256", "artifactSHA256", "controllerSHA256",
                 "expiresAt", "operation", "deletionAllowed"}


def require(value, message):
    if not value:
        raise ValueError(message)


def sha(data):
    return hashlib.sha256(data).hexdigest()


def read_json(path):
    require(path.is_file() and not path.is_symlink() and path.stat().st_size <= 2_000_000,
            "missing/oversized/linked evidence")
    def unique(pairs):
        value = {}
        for key, item in pairs:
            require(key not in value, "duplicate JSON key")
            value[key] = item
        return value
    return json.loads(path.read_text(), object_pairs_hook=unique)


def save_new(path, value):
    # Evidence paths are never reused. No silent overwrite, including a prior NON_PASS.
    with os.fdopen(os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600), "w") as stream:
        json.dump(value, stream, indent=2, sort_keys=True)
        stream.write("\n")


def controller_hash():
    root = Path(__file__).resolve().parent
    names = ["runner.py", "audit.py"]
    return sha(json.dumps({n: sha((root / n).read_bytes()) for n in names}, sort_keys=True).encode())


def artifact(app, device):
    require(re.fullmatch(r"(?:[0-9A-Fa-f]{8}-[0-9A-Fa-f]{16}|[0-9A-Fa-f]{40})", device),
            "use exact selected provisioning UDID, not a name/alias")
    profile = audit.audit(app)  # offline, bounded codesign/profile checks
    require(profile["ProvisionedDevices"] == [device], "profile must contain ONLY the selected device")
    hashes = {str(p.relative_to(app)): sha(p.read_bytes()) for p in sorted(app.rglob("*")) if p.is_file()}
    require(EXECUTABLE in hashes, "missing signed executable")
    require(all(all(32 <= ord(char) <= 126 for char in name) for name in hashes), "unsafe artifact path")
    return hashes[EXECUTABLE], sha("".join(name + "\0" + hashes[name] + "\n" for name in sorted(hashes)).encode())


def prepare(app, device, out):
    exe, package = artifact(app, device)
    save_new(out, dict(version=2, ownerApproval="PENDING", independentReview="PENDING",
                       run=str(uuid.uuid4()), deviceUDID=device, bundle=BUNDLE, container=audit.CONTAINER,
                       executableSHA256=exe, artifactSHA256=package, controllerSHA256=controller_hash(),
                       expiresAt=(dt.datetime.now(dt.timezone.utc) + dt.timedelta(hours=24)).isoformat(),
                       operation="SIX_STAGE_SYNTHETIC_ROUND_TRIP", deletionAllowed=False))
    print("Prepared local approval request. NOT approved; no device command executed.")


def validate_approval(value, exe, package, now):
    require(isinstance(value, dict) and set(value) == APPROVAL_KEYS, "approval schema mismatch")
    require(type(value["version"]) is int and value["version"] == 2, "wrong protocol")
    require(value["ownerApproval"] == "APPROVED_FOR_THIS_ONE_RUN", "separate owner approval required")
    require(isinstance(value["independentReview"], str) and
            value["independentReview"].strip() not in ("", "PENDING"), "independent review required")
    require(value["run"] == str(uuid.UUID(value["run"])), "noncanonical run")
    require(value["bundle"] == BUNDLE and value["container"] == audit.CONTAINER, "wrong isolation")
    require(value["executableSHA256"] == exe and value["artifactSHA256"] == package and
            value["controllerSHA256"] == controller_hash(), "approval artifact/controller drift")
    require(value["deletionAllowed"] is False and value["operation"] == "SIX_STAGE_SYNTHETIC_ROUND_TRIP",
            "unapproved operation")
    expiry = dt.datetime.fromisoformat(value["expiresAt"])
    require(expiry.tzinfo is not None and dt.timedelta(0) < expiry - now <= dt.timedelta(hours=24),
            "expired/unbounded approval")


def capture(argv, log, seconds, env):
    """Actual local process-group hard watchdog; does not trust devicectl's own timeout."""
    require(seconds > 0, "deadline")
    with log.open("xb") as stream:
        child = subprocess.Popen(argv, stdout=stream, stderr=subprocess.STDOUT,
                                 start_new_session=True, env=env)
        try:
            code = child.wait(timeout=seconds)
        except BaseException:
            try:
                os.killpg(child.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            child.wait(timeout=5)
            raise
    require(code == 0, "native command non-pass")


def native_result(value):
    require(isinstance(value, dict) and value.get("info", {}).get("outcome") == "success" and
            isinstance(value.get("result"), dict), "native result not success/unknown schema")
    return value["result"]


def process_identity(process):
    require(isinstance(process, dict) and type(process.get("processIdentifier")) is int and
            process["processIdentifier"] > 1 and isinstance(process.get("executable"), str),
            "unknown native process identity")
    raw = process["executable"]
    parsed = urlparse(raw)
    require(parsed.scheme in ("", "file") and not parsed.netloc, "unexpected executable URL")
    return process["processIdentifier"], unquote(parsed.path)


def verify_normal_exit(result):
    # Explicit adapter contract, not inferred from devicectl's own exit code. If the
    # selected toolchain uses a different shape, approved native preflight must stop.
    termination = result.get("terminationResult")
    require(isinstance(termination, dict) and type(termination.get("exitCode")) is int and
            termination["exitCode"] == 0 and (termination.get("signal") is None or
                (type(termination.get("signal")) is int and termination["signal"] == 0)),
            "nonzero/signalled/unknown native termination result")


def is_probe(path):
    return Path(path).parts[-2:] == (EXECUTABLE + ".app", EXECUTABLE)


class Device:
    """No fallback parsing: unsupported native JSON stops before resume/acceptance.

    Native JSON contracts are local fixture-tested, NOT physically verified yet.
    Raw command output stays in the private evidence directory, never public notes.
    """
    def __init__(self, device, out):
        self.device, self.out, self.count = device, out, 0
        self.env = {k: v for k, v in os.environ.items()
                    if not k.startswith(("DEVICECTL_CHILD_", "MINDBUDGET_"))}

    def command(self, args, seconds):
        self.count += 1
        stem = self.out / f"native-{self.count:02d}"
        destination = stem.with_suffix(".json")
        require(not destination.exists(), "native output path already used")
        command = ["/usr/bin/xcrun", "devicectl", "device", *args, "--device", self.device,
                   "--timeout", str(max(1, math.ceil(seconds))), "--json-output", str(destination)]
        capture(command, stem.with_suffix(".log"), seconds, self.env)
        return native_result(read_json(destination))

    def processes(self):
        value = self.command(["info", "processes", "--search", PROCESS_SEARCH], 5)
        require(isinstance(value.get("runningProcesses"), list), "unknown native process-list schema")
        pairs = [process_identity(p) for p in value["runningProcesses"]]
        require(all(path.startswith("/") and is_probe(path) for _, path in pairs),
                "native process filter returned an unexpected executable")
        require(len({p for p, _ in pairs}) == len(pairs), "duplicate native PID")
        return dict(pairs)

    def launch_stopped(self, approval):
        env = {"MINDBUDGET_FX_PROBE_ACTION": "OWNER_APPROVED_SYNTHETIC_ROUND_TRIP",
               "MINDBUDGET_FX_PROBE_RUN": approval["run"],
               "MINDBUDGET_FX_PROBE_EXECUTABLE_SHA256": approval["executableSHA256"],
               "MINDBUDGET_FX_PROBE_ARTIFACT_SHA256": approval["artifactSHA256"]}
        value = self.command(["process", "launch", "--start-stopped", "--environment-variables",
                              json.dumps(env), BUNDLE], 15)
        pid, path = process_identity(value.get("process"))
        require(is_probe(path), "launch returned wrong executable")
        return pid, path

    def resume(self, pid, seconds):
        self.command(["process", "resume", "--pid", str(pid)], min(5, seconds))

    def await_exit(self, pid, seconds):
        verify_normal_exit(self.command(["process", "awaitTermination", "--pid", str(pid)], seconds))

    def kill(self, pid):
        self.command(["process", "terminate", "--pid", str(pid), "--kill"], 5)

    def collect(self, destination):
        destination.mkdir(mode=0o700)
        for name in FILES:
            self.command(["copy", "from", "--domain-type", "appDataContainer",
                          "--domain-identifier", BUNDLE, "--source",
                          "Library/Application Support/FXCloudProbe/" + name,
                          "--destination", str(destination / name)], 5)


def verify_collection(root, approval):
    require(set(p.name for p in root.iterdir()) == set(FILES), "unexpected/missing collected file")
    for path in root.iterdir():
        require(path.is_file() and not path.is_symlink() and path.stat().st_size <= 2_000_000,
                "unsafe collected file")
    require((root / "used-run.txt").read_text() == approval["run"], "wrong run reservation")
    receipt = read_json(root / "receipt.json")
    require(set(receipt) == {"protocolVersion", "run", "status", "completed", "plannedExpenseCount",
                             "liveDeletionTested", "executableSHA256", "artifactSHA256"}, "unexpected receipt schema")
    require(type(receipt["protocolVersion"]) is int and receipt["protocolVersion"] == 2 and
            receipt["run"].lower() == approval["run"] and
            receipt["executableSHA256"] == approval["executableSHA256"] and
            receipt["artifactSHA256"] == approval["artifactSHA256"], "receipt binding mismatch")
    require(receipt["status"] == "PASS_BOUNDED_SINGLE_DEVICE_ONLY" and receipt["completed"] == STEPS and
            type(receipt["plannedExpenseCount"]) is int and receipt["plannedExpenseCount"] == 4 and
            receipt["liveDeletionTested"] is False, "incomplete/non-pass receipt")
    initial, edited = (read_json(root / name) for name in FILES[2:])
    require(isinstance(initial, dict) and len(initial) == 8 and isinstance(edited, dict) and
            0 < len(edited) <= 8 and set(edited) <= set(initial), "invalid synthetic manifest set")
    parents, companions = set(), set()
    for key, value in initial.items():
        kind, identifier = key.split("/")
        require(identifier == str(uuid.UUID(identifier)), "noncanonical synthetic ID")
        require(kind in ("expense", "expenseForeignCurrencyMetadata"), "unexpected entity")
        (parents if kind == "expense" else companions).add(identifier)
    require(len(parents) == 4 and parents == companions, "missing parent/companion pair")
    for value in [*initial.values(), *edited.values()]:
        require(isinstance(value, str) and re.fullmatch(r"[a-f0-9]{64}", value), "invalid digest")
    require(any(initial[k] != v for k, v in edited.items()), "edit did not change any envelope")
    return {p.name: sha(p.read_bytes()) for p in root.iterdir()}


def supervise(device, approval, out, clock=time.monotonic):
    """A green receipt cannot override timeout, native failure or unconfirmed termination."""
    pid, path, started, launch_attempted, collection_attempted = None, None, None, False, False
    result = dict(status="NON_PASS", reason="notStarted", processStopped=False,
                  run=approval["run"], resumed=False, liveDeletionTested=False)
    try:
        before = device.processes()
        require(not any(is_probe(p) for p in before.values()), "probe already running; never replace it")
        # Suspended launch must produce a new owned PID before the app is allowed to run.
        launch_attempted = True
        candidate_pid, candidate_path = device.launch_stopped(approval)
        require(candidate_pid not in before and is_probe(candidate_path), "not a newly launched dedicated process")
        pid, path = candidate_pid, candidate_path
        require(device.processes().get(pid) == path, "suspended process identity drift")
        started = clock()
        result["resumed"] = True  # resume outcome may be uncertain: take the conservative boundary
        device.resume(pid, BUDGET)
        device.await_exit(pid, BUDGET - (clock() - started))
        require(clock() - started < BUDGET, "hard deadline exceeded")
        require(pid not in device.processes(), "process termination unconfirmed")
        result["processStopped"] = True
        collection_attempted = True
        device.collect(out / "collected")
        result["fileSHA256"] = verify_collection(out / "collected", approval)
        result.update(status="PASS_BOUNDED_SINGLE_DEVICE_ONLY", reason=None)
    except (Exception, KeyboardInterrupt) as error:
        # Closed public reason; raw native logs stay private and retain precise errors.
        result["reason"] = "controllerOrEvidenceNonPass"
        result["failureType"] = type(error).__name__
        result["privateFailure"] = str(error)[:500]
    finally:
        if pid is not None and not result["processStopped"]:
            try:
                current = device.processes()
                if current.get(pid) == path and is_probe(path):
                    device.kill(pid)  # only the scoped launch PID/path, never killall or existing app
                require(pid not in device.processes(), "stop unconfirmed")
                result["processStopped"] = True
            except (Exception, KeyboardInterrupt):
                result["reason"] = "STOP_UNCONFIRMED"
        if launch_attempted and pid is None:
            result["reason"] = "SUSPENDED_LAUNCH_UNCONFIRMED_NO_RESUME_SENT"
        if pid is not None and result["processStopped"] and not collection_attempted:
            # Best-effort ONE bounded copy of failure receipts after confirmed stop. A missing
            # later-stage manifest is expected on early failure, never permission to rerun.
            collection_attempted = True
            try:
                device.collect(out / "collected")
            except (Exception, KeyboardInterrupt):
                result["failureCollection"] = "PARTIAL_OR_UNAVAILABLE"
        result["collectionAttempted"] = collection_attempted
        if started is not None:
            result["elapsedSeconds"] = clock() - started
        save_new(out / "controller-result.json", result)
    return result


def run(app, approval_path, out, state_root):
    approval = read_json(approval_path)
    exe, package = artifact(app, approval.get("deviceUDID", ""))
    validate_approval(approval, exe, package, dt.datetime.now(dt.timezone.utc))
    # Persistent host reservation also prevents a different run UUID bypassing app-lifetime use.
    # Never remove these markers to obtain a green rerun. Changing state root is not permission.
    state_root.mkdir(parents=True, exist_ok=True, mode=0o700)
    key = sha((approval["deviceUDID"] + ":" + BUNDLE).encode())
    save_new(state_root / (key + ".json"), {"run": approval["run"], "status": "RESERVED"})
    out.mkdir(mode=0o700)  # MUST be new; retained failures are never overwritten
    save_new(out / "approval.json", approval)
    result = supervise(Device(approval["deviceUDID"], out), approval, out)
    print(result["status"] + "; raw evidence retained privately; no cleanup performed.")
    return 0 if result["status"] == "PASS_BOUNDED_SINGLE_DEVICE_ONLY" else 1


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    modes = parser.add_mutually_exclusive_group(required=True)
    modes.add_argument("--self-test", action="store_true")
    modes.add_argument("--prepare", action="store_true")
    modes.add_argument("--run", action="store_true")
    parser.add_argument("--app", type=Path)
    parser.add_argument("--device-udid")
    parser.add_argument("--approval", type=Path)
    parser.add_argument("--out", type=Path)
    parser.add_argument("--state-root", type=Path)
    args = parser.parse_args()
    if args.self_test:
        import runner_tests
        runner_tests.self_test()
        return 0
    require(args.app is not None and args.out is not None, "app and output required")
    repository = Path(__file__).resolve().parents[2]
    require(args.out.is_absolute() and not args.out.resolve().is_relative_to(repository),
            "private approval/evidence output must be absolute and outside the repository")
    if args.prepare:
        require(args.device_udid is not None, "selected device required")
        prepare(args.app.resolve(strict=True), args.device_udid, args.out)
        return 0
    require(args.approval is not None and args.state_root is not None, "approval and persistent state required")
    return run(args.app.resolve(strict=True), args.approval, args.out, args.state_root)


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (ValueError, OSError, subprocess.SubprocessError, KeyError, TypeError) as error:
        raise SystemExit("NON_PASS: " + str(error))
