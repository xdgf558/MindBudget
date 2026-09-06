#!/usr/bin/env python3
"""Run only the FX host on a new, non-cloned simulator; preserve all result evidence."""
from __future__ import annotations

import copy
import json
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import uuid


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def device_uuid(value: str) -> str:
    require(isinstance(value, str) and re.fullmatch(r"[A-Fa-f0-9-]{36}", value) is not None,
            "simulator identity must be a UUID, never booted/all/a name")
    return str(uuid.UUID(value)).upper()


def select_source(destination: str, catalog: dict) -> tuple[dict, str]:
    fields = {}
    for item in destination.split(","):
        key, separator, value = item.partition("=")
        require(bool(separator and value) and key not in fields, "invalid/duplicate destination field")
        fields[key] = value
    require(fields.get("platform") == "iOS Simulator", "FX permits simulators only")
    require(set(fields) in ({"platform", "id"}, {"platform", "name", "OS"}),
            "use an exact simulator ID or exact name and OS version")
    identifier = device_uuid(fields["id"]) if "id" in fields else None
    runtimes = {r["identifier"]: r for r in catalog["runtimes"]
                if r.get("isAvailable") is True and
                re.fullmatch(r"com\.apple\.CoreSimulator\.SimRuntime\.iOS-\d+(?:-\d+)*", r["identifier"]) and
                r.get("platform", "iOS") == "iOS"}
    matches = []
    for runtime, devices in catalog["devices"].items():
        if runtime not in runtimes:
            continue
        for device in devices:
            if device.get("isAvailable") is not True:
                continue
            match = (device_uuid(device["udid"]) == identifier if identifier else
                     device.get("name") == fields["name"] and runtimes[runtime].get("version") == fields["OS"])
            if match:
                matches.append((device, runtime))
    require(len(matches) == 1, "source simulator must resolve uniquely; no newest-runtime fallback")
    device, runtime = matches[0]
    require(isinstance(device.get("deviceTypeIdentifier"), str) and
            device["deviceTypeIdentifier"].startswith("com.apple.CoreSimulator.SimDeviceType.iPhone-"),
            "FX host requires the exact source iPhone device type")
    return device, runtime


def invoke(command: list[str], *, capture: bool = False, timeout: int = 120) -> str:
    print("FX runner:", " ".join(command), flush=True)
    result = subprocess.run(command, check=True, text=True, stdout=subprocess.PIPE if capture else None,
                            timeout=timeout)
    return result.stdout.strip() if capture else ""


def arguments(identifier: str, derived: Path) -> list[str]:
    return ["-project", "MindBudget.xcodeproj", "-scheme", "MindBudget-FX-UI", "-configuration", "Debug",
            "-sdk", "iphonesimulator", "-destination", f"platform=iOS Simulator,id={identifier}",
            "-derivedDataPath", str(derived), "-parallel-testing-enabled", "NO",
            "-test-timeouts-enabled", "YES", "-maximum-test-execution-time-allowance", "240",
            "-enableCodeCoverage", "YES", "SWIFT_ACTIVE_COMPILATION_CONDITIONS=DEBUG MINDBUDGET_FX_UI_TEST_HOST"]


def run(destination: str, bundle: Path, call=invoke, report=print) -> None:
    require(bundle.suffix == ".xcresult", "result path must end in .xcresult")
    derived = bundle.with_suffix(".DerivedData")
    provenance = bundle.with_suffix(".simulator.json")
    require(not any(p.exists() for p in (bundle, derived, provenance)), "FX evidence/DerivedData paths must be fresh")
    bundle.parent.mkdir(parents=True, exist_ok=True)
    catalog = json.loads(call(["xcrun", "simctl", "list", "-j"], capture=True))
    source, runtime = select_source(destination, catalog)
    existing = {device_uuid(d["udid"]) for devices in catalog["devices"].values() for d in devices}
    name = "MindBudget FX isolated " + str(uuid.uuid4())
    identifier = device_uuid(call(["xcrun", "simctl", "create", name, source["deviceTypeIdentifier"], runtime], capture=True))
    # Never allow a buggy command/stub to authorize erasing the caller's existing simulator.
    require(identifier not in existing, f"create returned an existing UUID; refusing to use/delete {identifier}")
    ownership = {"sourceDestination": destination, "sourceDevice": device_uuid(source["udid"]),
                 "createdDevice": identifier, "name": name, "runtime": runtime,
                 "deviceType": source["deviceTypeIdentifier"], "cloned": False}
    def owned_device() -> dict:
        current = json.loads(call(["xcrun", "simctl", "list", "-j"], capture=True))
        matches = [(r, d) for r, ds in current["devices"].items() for d in ds
                   if device_uuid(d["udid"]) == identifier]
        require(len(matches) == 1, "created simulator identity is missing/ambiguous")
        r, d = matches[0]
        require(r == runtime and d.get("name") == name and
                d.get("deviceTypeIdentifier") == source["deviceTypeIdentifier"],
                "created simulator ownership changed; refusing destructive cleanup")
        return d
    failure = None
    try:
        require(owned_device().get("state") == "Shutdown", "fresh simulator was not initially shut down")
        # Persist identity before boot so an interrupted run leaves a recoverable exact target.
        # A write failure still reaches ownership-checked cleanup.
        with provenance.open("x") as stream:
            json.dump(ownership, stream, indent=2)
            stream.write("\n")
        call(["xcrun", "simctl", "bootstatus", identifier, "-b"], timeout=600)
        args = arguments(identifier, derived)
        call(["xcodebuild", *args, "build-for-testing"], timeout=3600)
        call(["xcodebuild", *args, "-resultBundlePath", str(bundle), "test-without-building"], timeout=1800)
        call([sys.executable, "-B", "Scripts/fx01_ui_contract.py", "--verify-ui-bundle", str(bundle),
              "--expected-device-id", identifier], timeout=180)
    except Exception as error:
        failure = error
    finally:
        try:
            state = owned_device().get("state")
            if state != "Shutdown":
                call(["xcrun", "simctl", "shutdown", identifier])
            call(["xcrun", "simctl", "delete", identifier])
            report(f"FX runner removed only its temporary simulator {identifier}; evidence retained", flush=True)
        except Exception as error:
            raise RuntimeError(f"FX cleanup failed for {identifier}: {error}; primary failure: {failure}") from error
    if failure is not None:
        raise failure


def self_test() -> None:
    """Execute the production lifecycle with strict fake commands; no simulator is touched."""
    source_id, fresh_id = "11111111-1111-4111-8111-111111111111", "22222222-2222-4222-8222-222222222222"
    runtime, device_type = "com.apple.CoreSimulator.SimRuntime.iOS-26-5", "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro"
    source = {"udid": source_id, "name": "Source", "isAvailable": True,
              "deviceTypeIdentifier": device_type, "state": "Booted"}
    catalog = {"runtimes": [{"identifier": runtime, "version": "26.5", "platform": "iOS", "isAvailable": True}],
               "devices": {runtime: [source]}}
    destination = f"platform=iOS Simulator,id={source_id}"
    require(select_source(destination, catalog)[0] == source, "exact-ID selection failed")
    require(select_source("platform=iOS Simulator,name=Source,OS=26.5", catalog)[0] == source, "name/OS selection failed")
    older_shape = copy.deepcopy(catalog)
    del older_shape["runtimes"][0]["platform"]
    require(select_source(destination, older_shape)[0] == source, "runtime ID must identify iOS without redundant platform")
    negatives = ["platform=iOS,id=" + source_id, "platform=iOS Simulator,id=booted",
                 destination + ",id=" + source_id, destination + ",OS=26.5",
                 "platform=iOS Simulator,name=Source,OS=latest", "platform=iOS Simulator,name=Source,OS=99"]
    for candidate in negatives:
        try:
            select_source(candidate, catalog)
        except (ValueError, KeyError):
            continue
        raise ValueError(f"unsafe destination accepted: {candidate}")
    duplicate = copy.deepcopy(catalog)
    duplicate["devices"][runtime].append(copy.deepcopy(source))
    try:
        select_source(destination, duplicate)
    except ValueError:
        pass
    else:
        raise ValueError("ambiguous source accepted")
    stages = ("success", "create", "existing-id", "bootstatus", "build-for-testing",
              "test-without-building", "verify", "shutdown", "delete", "ownership")
    for fault in stages:
        state, events, created = copy.deepcopy(catalog), [], False
        def fake(command, **kwargs):
            nonlocal created
            events.append(command)
            if command[:3] == ["xcrun", "simctl", "list"]:
                return json.dumps(state)
            if command[:3] == ["xcrun", "simctl", "create"]:
                if fault == "create": raise RuntimeError("injected create failure")
                if fault == "existing-id": return source_id
                created = True
                state["devices"][runtime].append(dict(source, udid=fresh_id, name=command[3], state="Shutdown"))
                return fresh_id
            if command[0] == "xcrun":
                require(command[3] == fresh_id, "lifecycle command touched the source simulator")
                operation = command[2]
                if operation == fault: raise RuntimeError("injected " + fault)
                if operation == "bootstatus": state["devices"][runtime][1]["state"] = "Booted"
                return ""
            if command[0] == "xcodebuild":
                require(command[command.index("-destination") + 1] == f"platform=iOS Simulator,id={fresh_id}", "build/test reused source")
                require(command[command.index("-maximum-test-execution-time-allowance") + 1] == "240", "allowance changed")
                require(not any("retry" in item or "iterations" in item for item in command), "runner retry enabled")
                require(any("bootstatus" in event for event in events), "build/test ran before fresh boot")
                if command[-1] == fault: raise RuntimeError("injected " + fault)
                return ""
            require("--expected-device-id" in command and command[-1] == fresh_id, "verifier lost fresh device binding")
            if fault == "verify": raise RuntimeError("injected native verification failure")
            if fault == "ownership": state["devices"][runtime][1]["name"] = "not owned"
            return ""
        with tempfile.TemporaryDirectory(prefix="fx-runner-test-") as directory:
            failed = False
            try:
                run(destination, Path(directory) / "Run.xcresult", fake, report=lambda *args, **kwargs: None)
            except (ValueError, RuntimeError):
                failed = True
            require(failed == (fault != "success"), "lifecycle accepted a fault or rejected success: " + fault)
            deletes = [e for e in events if e[:3] == ["xcrun", "simctl", "delete"]]
            require(len(deletes) == int(created and fault not in {"shutdown", "ownership"}), "cleanup ownership/failure path drifted: " + fault)
            tests = [e for e in events if e[-1] == "test-without-building"]
            require(len(tests) <= 1, "hidden second test attempt")
            if fault == "success":
                prior_count = len(events)
                try:
                    run(destination, Path(directory) / "Run.xcresult", fake, report=lambda *args, **kwargs: None)
                except ValueError:
                    pass
                else:
                    raise ValueError("existing provenance/evidence path reused")
                require(len(events) == prior_count, "non-fresh evidence touched a simulator")
    print("FX isolated-runner self-test passed: exact destinations, ownership, 1 lifecycle success / 9 failure paths; no real simulator")


def main() -> int:
    try:
        if sys.argv[1:] == ["--self-test"]:
            self_test()
        else:
            require(len(sys.argv) == 3, "usage: fx01_ui_runner.py DESTINATION FRESH.xcresult")
            run(sys.argv[1], Path(sys.argv[2]))
    except (OSError, ValueError, KeyError, RuntimeError, subprocess.SubprocessError) as error:
        print(f"FX isolated runner failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
