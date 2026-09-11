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
CONTINUATION_KEYS = {"mode", "priorApprovalSHA256", "priorControllerResultSHA256",
                     "priorControllerSHA256", "retainedReservationSHA256"}
PRIOR_RESULT_KEYS = {"status", "reason", "processStopped", "run", "resumed",
                     "liveDeletionTested", "failureType", "privateFailure", "collectionAttempted"}
CONTINUATION_MODE = "SAME_RUN_AFTER_PRE_RESUME_LAUNCH_PARSER_NON_PASS"


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


def reservation_path(state_root, device):
    key = sha((device + ":" + BUNDLE).encode())
    return state_root / (key + ".json")


def validate_state_root(state_root, must_exist):
    require(state_root.is_absolute() and not state_root.is_symlink(),
            "reservation root must be an absolute real directory")
    if must_exist:
        require(state_root.is_dir(), "retained reservation root missing")
    elif state_root.exists():
        require(state_root.is_dir(), "reservation root is not a directory")


def continuation_claim_path(state_root, approval):
    key = sha((approval["deviceUDID"] + ":" + BUNDLE + ":" + approval["run"] + ":" +
               approval["controllerSHA256"]).encode())
    return state_root / (key + ".continuation.json")


def validate_prior_continuation(prior, result, reservation, exe, package, device):
    require(isinstance(prior, dict) and set(prior) == APPROVAL_KEYS and
            type(prior.get("version")) is int and prior["version"] == 2,
            "prior approval schema mismatch")
    require(prior["ownerApproval"] == "APPROVED_FOR_THIS_ONE_RUN" and
            isinstance(prior["independentReview"], str) and
            prior["independentReview"].strip() not in ("", "PENDING"),
            "prior run was not explicitly approved/reviewed")
    require(prior["run"] == str(uuid.UUID(prior["run"])) and
            prior["deviceUDID"] == device and prior["bundle"] == BUNDLE and
            prior["container"] == audit.CONTAINER,
            "prior approval identity mismatch")
    require(prior["executableSHA256"] == exe and prior["artifactSHA256"] == package,
            "prior approval used a different signed package")
    require(isinstance(prior["controllerSHA256"], str) and
            re.fullmatch(r"[a-f0-9]{64}", prior["controllerSHA256"]) and
            prior["controllerSHA256"] != controller_hash(),
            "prior controller is invalid or was not replaced")
    require(prior["deletionAllowed"] is False and
            prior["operation"] == "SIX_STAGE_SYNTHETIC_ROUND_TRIP",
            "prior operation mismatch")
    prior_expiry = dt.datetime.fromisoformat(prior["expiresAt"])
    require(prior_expiry.tzinfo is not None, "prior approval expiry is invalid")

    require(isinstance(result, dict) and set(result) == PRIOR_RESULT_KEYS,
            "prior controller result schema mismatch")
    require(result["status"] == "NON_PASS" and
            result["reason"] == "SUSPENDED_LAUNCH_UNCONFIRMED_NO_RESUME_SENT" and
            result["run"] == prior["run"] and result["resumed"] is False and
            result["processStopped"] is False and result["collectionAttempted"] is False and
            result["liveDeletionTested"] is False and result["failureType"] == "ValueError" and
            isinstance(result["privateFailure"], str) and result["privateFailure"],
            "prior result is not the single accepted pre-resume parser failure")

    require(isinstance(reservation, dict) and set(reservation) == {"run", "status"} and
            reservation == {"run": prior["run"], "status": "RESERVED"},
            "retained reservation does not match the prior run")


def continuation_metadata(prior_path, result_path, state_root, exe, package, device):
    validate_state_root(state_root, must_exist=True)
    prior = read_json(prior_path)
    result = read_json(result_path)
    retained = reservation_path(state_root, device)
    reservation = read_json(retained)
    validate_prior_continuation(prior, result, reservation, exe, package, device)
    return prior, {
        "mode": CONTINUATION_MODE,
        "priorApprovalSHA256": sha(prior_path.read_bytes()),
        "priorControllerResultSHA256": sha(result_path.read_bytes()),
        "priorControllerSHA256": prior["controllerSHA256"],
        "retainedReservationSHA256": sha(retained.read_bytes()),
    }


def bind_continuation(approval, prior, metadata):
    require(approval["version"] == 3 and prior["run"] == approval["run"] and
            metadata == approval["continuation"], "continuation evidence drift")


def prepare_continuation(app, device, prior_path, result_path, state_root, out):
    exe, package = artifact(app, device)
    prior, continuation = continuation_metadata(
        prior_path, result_path, state_root, exe, package, device)
    save_new(out, dict(version=3, ownerApproval="PENDING", independentReview="PENDING",
                       run=prior["run"], deviceUDID=device, bundle=BUNDLE,
                       container=audit.CONTAINER, executableSHA256=exe,
                       artifactSHA256=package, controllerSHA256=controller_hash(),
                       expiresAt=(dt.datetime.now(dt.timezone.utc) + dt.timedelta(hours=24)).isoformat(),
                       operation="SIX_STAGE_SYNTHETIC_ROUND_TRIP", deletionAllowed=False,
                       continuation=continuation))
    print("Prepared same-run continuation request. NOT approved; no device command executed.")


def validate_approval(value, exe, package, now):
    require(isinstance(value, dict), "approval schema mismatch")
    version = value.get("version")
    expected_keys = APPROVAL_KEYS if version == 2 else APPROVAL_KEYS | {"continuation"}
    require(type(version) is int and version in (2, 3) and set(value) == expected_keys,
            "approval schema mismatch/wrong protocol")
    require(value["ownerApproval"] == "APPROVED_FOR_THIS_ONE_RUN", "separate owner approval required")
    require(isinstance(value["independentReview"], str) and
            value["independentReview"].strip() not in ("", "PENDING"), "independent review required")
    require(value["run"] == str(uuid.UUID(value["run"])), "noncanonical run")
    require(value["bundle"] == BUNDLE and value["container"] == audit.CONTAINER, "wrong isolation")
    require(value["executableSHA256"] == exe and value["artifactSHA256"] == package and
            value["controllerSHA256"] == controller_hash(), "approval artifact/controller drift")
    require(value["deletionAllowed"] is False and value["operation"] == "SIX_STAGE_SYNTHETIC_ROUND_TRIP",
            "unapproved operation")
    if version == 3:
        continuation = value["continuation"]
        require(isinstance(continuation, dict) and set(continuation) == CONTINUATION_KEYS and
                continuation["mode"] == CONTINUATION_MODE,
                "continuation schema/mode mismatch")
        for key in CONTINUATION_KEYS - {"mode"}:
            require(isinstance(continuation[key], str) and
                    re.fullmatch(r"[a-f0-9]{64}", continuation[key]),
                    "invalid continuation digest")
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

    def command(self, args, seconds, positional_tail=()):
        self.count += 1
        stem = self.out / f"native-{self.count:02d}"
        destination = stem.with_suffix(".json")
        require(not destination.exists(), "native output path already used")
        require(isinstance(args, (list, tuple)) and all(isinstance(value, str) for value in args),
                "invalid native option arguments")
        require(isinstance(positional_tail, (list, tuple)) and
                all(isinstance(value, str) for value in positional_tail),
                "invalid native positional arguments")
        # `device process launch` treats every token after its Bundle ID positional as an
        # application argument. Keep devicectl's common options ahead of all positional tail
        # values so --device/--timeout/--json-output cannot be swallowed by the launched app.
        command = ["/usr/bin/xcrun", "devicectl", "device", *args, "--device", self.device,
                   "--timeout", str(max(1, math.ceil(seconds))), "--json-output", str(destination),
                   *positional_tail]
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
                              json.dumps(env)], 15, [BUNDLE])
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


def reserve_run(state_root, approval):
    destination = reservation_path(state_root, approval["deviceUDID"])
    if approval["version"] == 2:
        save_new(destination, {"run": approval["run"], "status": "RESERVED"})
        return
    retained = read_json(destination)
    require(retained == {"run": approval["run"], "status": "RESERVED"} and
            sha(destination.read_bytes()) == approval["continuation"]["retainedReservationSHA256"],
            "same-run retained reservation changed; continuation refused")
    save_new(continuation_claim_path(state_root, approval), {
        "run": approval["run"],
        "status": "CONTINUATION_RESERVED",
        "controllerSHA256": approval["controllerSHA256"],
        "priorApprovalSHA256": approval["continuation"]["priorApprovalSHA256"],
        "priorControllerResultSHA256": approval["continuation"]["priorControllerResultSHA256"],
        "retainedReservationSHA256": approval["continuation"]["retainedReservationSHA256"],
    })


def run(app, approval_path, out, state_root, prior_path=None, result_path=None):
    approval = read_json(approval_path)
    exe, package = artifact(app, approval.get("deviceUDID", ""))
    validate_approval(approval, exe, package, dt.datetime.now(dt.timezone.utc))
    validate_state_root(state_root, must_exist=approval["version"] == 3)
    if approval["version"] == 3:
        require(prior_path is not None and result_path is not None,
                "continuation requires retained prior approval/result")
        prior, continuation = continuation_metadata(
            prior_path, result_path, state_root, exe, package, approval["deviceUDID"])
        bind_continuation(approval, prior, continuation)
    else:
        require(prior_path is None and result_path is None,
                "fresh run cannot accept continuation evidence")
    # A fresh run creates the once-only marker. A reviewed v3 continuation can only reuse the
    # exact unchanged marker for the same UUID and the one accepted pre-resume parser NON_PASS.
    # Never remove these markers or change state roots to obtain another attempt.
    state_root.mkdir(parents=True, exist_ok=True, mode=0o700)
    reserve_run(state_root, approval)
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
    parser.add_argument("--prior-approval", type=Path)
    parser.add_argument("--prior-controller-result", type=Path)
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
        continuation_inputs = (args.prior_approval, args.prior_controller_result, args.state_root)
        if any(value is not None for value in continuation_inputs):
            require(all(value is not None for value in continuation_inputs),
                    "continuation preparation requires prior approval/result and persistent state")
            private_paths = [args.prior_approval, args.prior_controller_result, args.state_root]
            require(all(path.is_absolute() and not path.resolve().is_relative_to(repository)
                        for path in private_paths),
                    "private continuation inputs/state must be absolute and outside repository")
            prepare_continuation(args.app.resolve(strict=True), args.device_udid,
                                 args.prior_approval.resolve(strict=True),
                                 args.prior_controller_result.resolve(strict=True),
                                 args.state_root.resolve(strict=True), args.out)
        else:
            prepare(args.app.resolve(strict=True), args.device_udid, args.out)
        return 0
    require(args.approval is not None and args.state_root is not None, "approval and persistent state required")
    private_paths = [args.approval, args.state_root]
    private_paths += [value for value in (args.prior_approval, args.prior_controller_result)
                      if value is not None]
    require(all(path.is_absolute() and not path.resolve().is_relative_to(repository)
                for path in private_paths), "private inputs/state must be absolute and outside repository")
    return run(args.app.resolve(strict=True), args.approval.resolve(strict=True), args.out,
               args.state_root.resolve(),
               args.prior_approval.resolve(strict=True) if args.prior_approval else None,
               args.prior_controller_result.resolve(strict=True)
               if args.prior_controller_result else None)


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (ValueError, OSError, subprocess.SubprocessError, KeyError, TypeError) as error:
        raise SystemExit("NON_PASS: " + str(error))
