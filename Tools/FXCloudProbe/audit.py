#!/usr/bin/env python3
"""Offline, fail-closed audit of the dedicated signed probe; never install or launch it."""
import argparse
import copy
import datetime as dt
import plistlib
from pathlib import Path
import subprocess
import tempfile
import hashlib

BUNDLE = "com.xdgf558.MindBudgetFXCloudProbe"
TEAM = "2AM5S7BM2N"
APP = TEAM + "." + BUNDLE
CONTAINER = "iCloud." + BUNDLE
CLOUD = "com.apple.developer.icloud-container-identifiers"
ENV = "com.apple.developer.icloud-container-environment"
SERVICES = "com.apple.developer.icloud-services"
EXPECTED = {
    "application-identifier": APP,
    "com.apple.developer.team-identifier": TEAM,
    "get-task-allow": True,
    "aps-environment": "development",
    CLOUD: [CONTAINER], ENV: "Development", SERVICES: ["CloudKit"],
}


def require(ok, message):
    if not ok:
        raise ValueError(message)


def validate(info, signed, profile, certificate, now):
    require(info.get("CFBundleIdentifier") == BUNDLE, "wrong app identity")
    require(info.get("CFBundleExecutable") == "MindBudgetFXCloudProbe", "wrong executable")
    require(info.get("CFBundleSupportedPlatforms") == ["iPhoneOS"], "not a physical iOS build")
    require(info.get("CFBundlePackageType") == "APPL", "not an application")
    require(set(signed) <= set(EXPECTED) | {"keychain-access-groups"}, "unexpected signed access")
    for key, value in EXPECTED.items():
        require(type(signed.get(key)) is type(value) and signed.get(key) == value,
                "signed entitlement mismatch: " + key)
    if "keychain-access-groups" in signed:
        require(signed["keychain-access-groups"] == [APP], "shared/wildcard keychain access")
    require(profile.get("TeamIdentifier") == [TEAM], "wrong profile team")
    require(profile.get("ApplicationIdentifierPrefix") == [TEAM], "wrong profile prefix")
    expiry = profile.get("ExpirationDate")
    require(isinstance(expiry, dt.datetime) and expiry > now, "missing/expired profile")
    created = profile.get("CreationDate")
    require(isinstance(created, dt.datetime) and created <= now, "missing/future profile creation")
    require(isinstance(profile.get("UUID"), str) and bool(profile["UUID"]), "missing profile UUID")
    devices = profile.get("ProvisionedDevices")
    require(isinstance(devices, list) and bool(devices) and
            all(isinstance(d, str) and d for d in devices), "no development devices")
    require(profile.get("ProvisionsAllDevices", False) is False, "enterprise profile rejected")
    grants = profile.get("Entitlements", {})
    for key, value in EXPECTED.items():
        if key == ENV:
            permitted = grants.get(key)
            require(permitted == "Development" or
                    (isinstance(permitted, list) and "Development" in permitted and
                     set(permitted) <= {"Development", "Production"}), "profile forbids Development")
        elif key == SERVICES:
            # Apple profiles may authorize all iCloud services. The signed app above
            # still MUST contain exactly ["CloudKit"], never this profile wildcard.
            require(grants.get(key) == "*" or grants.get(key) == value,
                    "profile forbids CloudKit")
        else:
            require(type(grants.get(key)) is type(value) and grants.get(key) == value,
                    "profile entitlement mismatch: " + key)
    require(not grants.get("com.apple.security.application-groups"), "profile shares App Groups")
    require(certificate in profile.get("DeveloperCertificates", []), "signer absent from profile")


def command(*args):
    return subprocess.run(args, check=True, stdout=subprocess.PIPE,
                          stderr=subprocess.PIPE, timeout=60).stdout


def audit(app):
    app = app.resolve(strict=True)
    require(app.suffix == ".app", "expected .app")
    require(not any(p.is_symlink() for p in app.rglob("*")), "symlink in app")
    require(not any((app / p).exists() for p in ("PlugIns", "Watch", "AppClips")), "unexpected nested target")
    command("/usr/bin/codesign", "--verify", "--deep", "--strict", str(app))
    signed = plistlib.loads(command("/usr/bin/codesign", "-d", "--entitlements", "-", "--xml", str(app)))
    profile = plistlib.loads(command("/usr/bin/security", "cms", "-D", "-i", str(app / "embedded.mobileprovision")))
    with tempfile.TemporaryDirectory(prefix="fx-probe-public-certificate-") as temporary:
        prefix = str(Path(temporary) / "signer")
        command("/usr/bin/codesign", "-d", "--extract-certificates=" + prefix, str(app))
        certificate = Path(prefix + "0").read_bytes()
    validate(plistlib.loads((app / "Info.plist").read_bytes()), signed, profile,
             certificate, dt.datetime.now(dt.timezone.utc).replace(tzinfo=None))
    print("PASS: signed dedicated iPhoneOS probe; Development; exact test container; no shared access.")
    print("Not installation permission, device eligibility, live CloudKit evidence or D completion.")
    return profile


def self_test():
    import source_contract
    source_contract.self_test()
    now = dt.datetime(2026, 9, 9)
    info = {"CFBundleIdentifier": BUNDLE, "CFBundleExecutable": "MindBudgetFXCloudProbe",
            "CFBundleSupportedPlatforms": ["iPhoneOS"], "CFBundlePackageType": "APPL"}
    signed = copy.deepcopy(EXPECTED)
    profile = {"UUID": "synthetic-profile", "TeamIdentifier": [TEAM],
               "ApplicationIdentifierPrefix": [TEAM], "CreationDate": now - dt.timedelta(days=1),
               "ExpirationDate": now + dt.timedelta(days=1), "ProvisionedDevices": ["synthetic-device"],
               "Entitlements": copy.deepcopy(EXPECTED), "DeveloperCertificates": [b"synthetic-cert"]}
    validate(info, signed, profile, b"synthetic-cert", now)
    multi_environment = copy.deepcopy(profile)
    multi_environment["Entitlements"][ENV] = ["Development", "Production"]
    validate(info, signed, multi_environment, b"synthetic-cert", now)
    apple_profile = copy.deepcopy(multi_environment)
    apple_profile["Entitlements"][SERVICES] = "*"
    validate(info, signed, apple_profile, b"synthetic-cert", now)
    failures = []
    for key in EXPECTED:
        value = copy.deepcopy(signed)
        del value[key]
        failures.append((info, value, profile, b"synthetic-cert"))
    for key, bad in [(CLOUD, [CONTAINER, "iCloud.com.xdgf558.MindBudget"]),
                     (ENV, "Production"), ("get-task-allow", 1),
                     (SERVICES, "*"), (SERVICES, ["CloudKit", "CloudDocuments"]),
                     ("keychain-access-groups", [TEAM + ".*"]),
                     ("com.apple.security.application-groups", ["group.test"]),
                     ("aps-environment", "production")]:
        value = copy.deepcopy(signed)
        value[key] = bad
        failures.append((info, value, profile, b"synthetic-cert"))
    for key, bad in [("TeamIdentifier", ["WRONG"]), ("ExpirationDate", now),
                     ("CreationDate", now + dt.timedelta(days=1)), ("ProvisionedDevices", []),
                     ("ProvisionsAllDevices", True), ("UUID", "")]:
        value = copy.deepcopy(profile)
        value[key] = bad
        failures.append((info, signed, value, b"synthetic-cert"))
    for key, bad in [(CLOUD, ["iCloud.com.xdgf558.MindBudget"]), (ENV, "Production"),
                     ("application-identifier", TEAM + ".*"), ("get-task-allow", False)]:
        value = copy.deepcopy(profile)
        value["Entitlements"][key] = bad
        failures.append((info, signed, value, b"synthetic-cert"))
    for key, bad in [("CFBundleIdentifier", "com.xdgf558.MindBudget"),
                     ("CFBundleSupportedPlatforms", ["iPhoneSimulator"]),
                     ("CFBundleExecutable", "MindBudget")]:
        value = copy.deepcopy(info)
        value[key] = bad
        failures.append((value, signed, profile, b"synthetic-cert"))
    failures.append((info, signed, profile, b"wrong-cert"))
    for bad in ("CloudKit", ["CloudDocuments"], [], None):
        value = copy.deepcopy(apple_profile)
        value["Entitlements"][SERVICES] = bad
        failures.append((info, signed, value, b"synthetic-cert"))
    for i, values in enumerate(failures):
        try:
            validate(*values, now)
        except ValueError:
            continue
        raise ValueError(f"negative {i} escaped")
    root = Path(__file__).resolve().parent
    require(plistlib.loads((root / "Probe.entitlements").read_bytes()) == {
        key: EXPECTED[key] for key in ("aps-environment", CLOUD, ENV, SERVICES)
    }, "source entitlement mismatch")
    print(f"PASS: 3 synthetic positive cases / {len(failures)} negative cases; no signing or cloud calls")


def protocol_tests():
    root = Path(__file__).resolve().parent
    # Only the pure protocol and its doubles enter this executable: no CloudKit/SwiftData/app.
    with tempfile.TemporaryDirectory(prefix="fx-probe-protocol-build-") as directory:
        executable = str(Path(directory) / "protocol-tests")
        result = subprocess.run([
            "xcrun", "swiftc", "-swift-version", "6", "-module-cache-path",
            str(Path(directory) / "ModuleCache"), str(root / "ProbeProtocol.swift"),
            str(root / "ProtocolTests.swift"), "-o", executable,
        ], check=True, capture_output=True, timeout=120)
        result = subprocess.run([executable], check=True, capture_output=True, timeout=30)
        print(result.stdout.decode(), end="")
        blocked = subprocess.run([executable, "--blocked-main-watchdog-child"],
                                 capture_output=True, timeout=5)
        require(blocked.returncode == 124, "independent watchdog failed to exit blocked-main child")
        print("PASS: actual local child blocked main thread; independent hard timer exited 124.")
        fixture = Path(directory) / "package"
        fixture.mkdir()
        (fixture / "nested").mkdir()
        (fixture / "z.txt").write_bytes(b"synthetic signature")
        (fixture / "nested/a.txt").write_bytes(b"synthetic profile")
        inventory = {str(p.relative_to(fixture)): hashlib.sha256(p.read_bytes()).hexdigest()
                     for p in fixture.rglob("*") if p.is_file()}
        expected = hashlib.sha256("".join(n + "\0" + inventory[n] + "\n"
                                          for n in sorted(inventory)).encode()).hexdigest()
        actual = subprocess.run([executable, "--artifact-hash", str(fixture)], check=True,
                                capture_output=True, timeout=5).stdout.decode().strip()
        require(actual == expected, "Swift/controller package hash mismatch")
        (fixture / "link").symlink_to(fixture / "z.txt")
        bad = subprocess.run([executable, "--artifact-hash", str(fixture)], capture_output=True, timeout=5)
        require(bad.returncode == 2, "linked package file accepted")
        print("PASS: Swift/controller package inventory hashes agree; linked file refused.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--self-test", action="store_true")
    mode.add_argument("--protocol-tests", action="store_true")
    mode.add_argument("--app", type=Path)
    args = parser.parse_args()
    try:
        if args.self_test:
            self_test()
        elif args.protocol_tests:
            protocol_tests()
        else:
            audit(args.app)
    except (ValueError, OSError, subprocess.SubprocessError, plistlib.InvalidFileException) as error:
        raise SystemExit("FAIL: " + str(error))
