#!/usr/bin/env python3
"""FX-owned UI-host isolation and exact native xcresult bindings (not C6 evidence)."""
from __future__ import annotations

import argparse
import copy
from collections import Counter
from concurrent.futures import ThreadPoolExecutor
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET

FLAG = "MINDBUDGET_FX_UI_TEST_HOST"
GUARD = f"#if DEBUG && targetEnvironment(simulator) && {FLAG}"
HOST = "MindBudget/App/FXUITestHost.swift"
MAIN = "MindBudget/App/MindBudgetApp.swift"
ACCESS = "MindBudget/Commerce/FeatureAccessService.swift"
SCHEME = "MindBudget.xcodeproj/xcshareddata/xcschemes/MindBudget-FX-UI.xcscheme"
PROJECT = "MindBudget.xcodeproj/project.pbxproj"
FIXTURE_FILES = (HOST, MAIN, ACCESS, SCHEME, PROJECT,
                 "MindBudget.xcodeproj/xcshareddata/xcschemes/MindBudget.xcscheme",
                 "Scripts/fx01_ui_contract.py")
FIXED_COMMERCE_FIXTURE = """enum FXUIFixtureAccess {
    static func allow(_ authority: LiveFeatureAccessAuthority) {
        authority.replaceEntitlements(.proSubscription)
    }

    static func revoke(_ authority: LiveFeatureAccessAuthority) {
        authority.replaceEntitlements(.free)
    }
}
"""
UNIT_BINDINGS = (
    "ForeignCurrencyMigrationTests/v1ThroughV6PreserveEverySeededFieldAcrossMigrationAndRestartWithoutInventingFX",
    "ForeignCurrencyMigrationTests/v7ForeignTupleSurvivesDiskReopenAndDeleteAll",
    "ForeignCurrencyMigrationTests/knownLegacyJournalsRestoreBeforeV7AndUnknownTargetsRemainClosed",
    "ForeignCurrencyTests/decimalInputNormalizesBeforeReductionAndRoundTrips",
    "ForeignCurrencyTests/malformedOrOutOfBoundRateTextFailsClosed",
    "ForeignCurrencyTests/exponentsOrientationAndEvenOddTiesAreExact",
    "ForeignCurrencyTests/wideProductsLimitsAndUnderflowDoNotTrapOrLosePrecision",
    "ForeignCurrencyTests/smallIntegerOracleChecksThousandsOfHalfEvenCases",
    "ForeignCurrencyTests/overridesAreExactAndApproximationIsDisplayOnly",
    "ForeignCurrencyPersistenceTests/createEditOverrideAndDeleteAreAtomicAndRetainTheSavedCurrency",
    "ForeignCurrencyPersistenceTests/formEntryUsesSettingsForNewRowsButTheSavedCurrencyForEdits",
    "ForeignCurrencyPersistenceTests/failedCreatesUnsupportedSourcesAndDuplicateIDsLeaveNoPartialRows",
    "ForeignCurrencyPersistenceTests/legacySyncAndForeignWritesCannotCoexistBeforeD",
    "ForeignCurrencyPersistenceTests/downstreamFailureRollsBackBothTheExpenseAndCompanion",
    "ForeignCurrencyPersistenceTests/recoveryCannotReuploadFXAndCloudErasureNeverBlocksLocalRecording",
    "ForeignCurrencyPersistenceTests/pendingLegacyParentReplayCannotOverwriteFXButTombstoneCascades",
    "ForeignCurrencyPersistenceTests/unreadableTupleIsRejectedButStewardshipDeletionStillWorks",
    "ForeignCurrencyFormTests/explicitCurrencySelectionIsRequiredAndSameCurrencyIsRejected",
    "ForeignCurrencyFormTests/rateTextNormalizesWithHalfEvenWithoutRewritingUserInput",
    "ForeignCurrencyFormTests/overrideKeepsExactNonterminatingFractionAcrossReopenAndLocale",
    "ForeignCurrencyFormTests/explicitRateEditExitsOverrideAndOriginalEditPreservesChosenMode",
    "ForeignCurrencyFormTests/invalidInputNeverReturnsPriorPreviewAndPreservesAllFields",
    "ForeignCurrencyFormTests/savedRateDayAndZoneDoNotFollowCurrentDeviceCalendar",
    "ForeignCurrencyFormTests/zeroTwoAndThreeDigitAmountsUseTheirOwnCurrencyExponents",
    "ForeignCurrencyFormTests/freeDeniesNewAndConversionButAllowsOrdinaryRecording",
    "ForeignCurrencyFormTests/proCreatesAndConvertsButExpiredAccessCannotDuplicateExistingFX",
    "ForeignCurrencyFormTests/expiredStewardshipUsesPersistedCompanionNotCallerClaimAndCannotRevalueCurrency",
    "ForeignCurrencyFormTests/invalidFormDoesNotSaveStaleAmountAndKeepsOriginalUserInput",
    "ForeignCurrencyFormTests/liveRevocationAfterAdvisoryAwaitDeniesNewFXWithoutDiscardingInput",
    "ForeignCurrencyFormTests/togglingNewModeOffRestoresOrdinaryAmountAndFreeCannotEnableIt",
    "ForeignCurrencyFormTests/recurringAndWishlistCannotEnterForeignModeAndForgedRecurringFailsSave",
    "ForeignCurrencyFormTests/localizedAmountPresentationAlwaysKeepsBothCurrencyIdentities",
)
UI_BINDINGS = (
    "MindBudgetPhase3UITests/testManualForeignCurrencyEnglishProCreateAndDetail",
    "MindBudgetPhase3UITests/testManualForeignCurrencyChineseAX5ProCreateAndDetail",
)


def isolation_errors(root: Path) -> list[str]:
    errors: list[str] = []
    if missing := [path for path in FIXTURE_FILES if not (root / path).is_file()]:
        return [f"missing FX isolation input: {path}" for path in missing]
    host = (root / HOST).read_text()
    main = (root / MAIN).read_text()
    access = (root / ACCESS).read_text()
    if not host.startswith(GUARD + "\n") or not host.rstrip().endswith("\n#endif"):
        errors.append("FX UI host must be wholly Debug AND simulator AND dedicated-flag compiled")
    if len(re.findall(r"^\s*#(?:if|else|elseif|endif)\b", host, re.M)) != 2:
        errors.append("FX UI host may not add conditional escape branches")
    if not main.startswith(f"#if !{FLAG}\n") or not main.rstrip().endswith("\n#endif"):
        errors.append("normal AppBootstrap must be excluded before initialization in the host build")
    if len(re.findall(r"^\s*#(?:if|else|elseif|endif)\b", main, re.M)) != 2:
        errors.append("normal app entry may not add conditional escape branches")
    fixture = access.split(GUARD + "\n")
    if len(fixture) != 2 or not fixture[1].rstrip().endswith("\n#endif"):
        errors.append("Commerce fixture must have the same three compile-time requirements")
    elif re.search(r"#(?:if|else|elseif|endif)\b", fixture[1].rstrip()[:-len("#endif")]):
        errors.append("Commerce fixture may not add an escape branch")
    elif re.sub(r"\s+", "", re.sub(r"//[^\n]*", "", fixture[1].rstrip()[:-len("#endif")])) != re.sub(r"\s+", "", FIXED_COMMERCE_FIXTURE):
        errors.append("Commerce fixture must retain fixed unconditional allow/revoke bodies, with no external input")
    for marker in ("FXUIFixtureAccess",):
        if marker in fixture[0]:
            errors.append("fixture authority escaped its compile-time guard")
    code = re.sub(r"//[^\n]*", "", host)
    for forbidden in (r"\bAppEnvironment\b", r"\bAppBootstrap\b", r"\bProcessInfo\b",
                      r"\bregister\s*\(", r"\.prepare\s*\(", r"\bstart\w*Lifecycle\s*\(",
                      r"\bStoreKit\b", r"\bURLSession\b", r"\.standard\b"):
        if re.search(forbidden, code):
            errors.append(f"FX host must not start live bootstrap/services or select rights via arguments: {forbidden}")
    for anchor in ("DataController(isStoredInMemoryOnly: true)",
                   'let suite = "MindBudget.FXUI.IsolatedPreferences"',
                   "SettingsStore(defaults: defaults)", "AddExpenseView(", "ExpenseDetailView(",
                   "notificationScheduler: FXUINotificationStub()",
                   '.accessibilityIdentifier("fx.testHost")'):
        if anchor not in code:
            errors.append(f"FX host lost isolated-store / real-view contract: {anchor}")
    for path in (root / "MindBudget").rglob("*.swift"):
        if FLAG in path.read_text() and path.relative_to(root).as_posix() not in {MAIN, HOST, ACCESS}:
            errors.append(f"unexpected FX host compile-flag consumer: {path.name}")
    for path in [root / PROJECT, *root.rglob("*.xcconfig")]:
        if FLAG in path.read_text():
            errors.append("ordinary project configurations must never enable the FX test host")
    for path in (root / "MindBudget.xcodeproj/xcshareddata/xcschemes").glob("*.xcscheme"):
        tree = ET.fromstring(path.read_text())
        if path.relative_to(root).as_posix() != SCHEME:
            if "MINDBUDGET_FX_UI" in path.read_text():
                errors.append("default/other schemes must not enable FX test-only fixtures")
            continue
        if any(tree.find(action) is not None for action in ("ArchiveAction", "LaunchAction", "ProfileAction")):
            errors.append("FX UI scheme is test-only, with no Launch/Profile/Archive action")
        test = tree.find("TestAction")
        if test is None or test.get("buildConfiguration") != "Debug":
            errors.append("FX UI scheme tests only Debug")
        entries = tree.findall("BuildAction/BuildActionEntries/BuildActionEntry")
        if len(entries) != 2 or any(entry.get(key) != "NO" for entry in entries
                                   for key in ("buildForRunning", "buildForProfiling", "buildForArchiving")):
            errors.append("FX UI scheme must disable non-test build actions")
        selected = tuple(node.get("Identifier", "").removesuffix("()")
                         for node in tree.findall(".//SelectedTests/Test"))
        if selected != UI_BINDINGS:
            errors.append("FX UI scheme must retain its two exact runtime methods")
    return errors


def execution_children(children: object) -> list[dict]:
    """Native diagnostic leaves are not attempts; never erase identities/results/children."""
    if not isinstance(children, list) or any(not isinstance(child, dict) for child in children):
        raise ValueError("malformed native execution/diagnostic children")
    executions = []
    for child in children:
        if child.get("nodeType") == "Runtime Warning":
            if set(child) != {"nodeType", "name"} or not isinstance(child["name"], str) or not child["name"].strip():
                raise ValueError("runtime warning must be an exact non-execution diagnostic leaf")
        else:
            executions.append(child)
    return executions


def required_cases(data: object, *, ui: bool) -> dict[str, dict]:
    bindings = UI_BINDINGS if ui else UNIT_BINDINGS
    observed: dict[str, dict] = {}
    if not isinstance(data, dict) or not isinstance(data.get("testNodes"), list):
        raise ValueError("FX evidence lacks a native testNodes array")

    def visit(node: object) -> None:
        if not isinstance(node, dict) or not isinstance(node.get("children", []), list):
            raise ValueError("malformed native test node/children")
        identifier = node.get("nodeIdentifier", "")
        match = re.fullmatch(r"(?:[A-Za-z_][A-Za-z0-9_]*/)?([A-Za-z_][A-Za-z0-9_]*/[A-Za-z_][A-Za-z0-9_]*)\(\)", identifier) if isinstance(identifier, str) else None
        if match and match[1] in bindings:
            binding = match[1]
            if binding in observed or node.get("nodeType") != "Test Case" or node.get("result") != "Passed":
                raise ValueError(f"{binding}: duplicate, non-test, or non-Passed aggregate")
            if not isinstance(node.get("nodeIdentifierURL"), str) or not node["nodeIdentifierURL"]:
                raise ValueError(f"{binding}: missing concrete identity URL")
            children = execution_children(node.get("children", []))
            if children:
                if len(children) != 1 or not isinstance(children[0], dict) or children[0].get("nodeType") != "Repetition" or children[0].get("result") != "Passed" or children[0].get("children"):
                    raise ValueError(f"{binding}: parameters, extra/unknown attempts, or nested attempts are not a single unparameterized pass")
            observed[binding] = node
            return
        for child in node.get("children", []):
            visit(child)

    for node in data["testNodes"]:
        visit(node)
    if missing := set(bindings) - observed.keys():
        raise ValueError(f"missing required FX executions: {sorted(missing)}")
    return observed


def runtime_errors(data: object, *, ui: bool) -> list[str]:
    try:
        required_cases(data, ui=ui)
    except ValueError as error:
        return [str(error)]
    return []


def validate_detail(detail: object, case: dict) -> None:
    """Close the tree over one native device/configuration execution, never an aggregate alone."""
    identifier, url = case["nodeIdentifier"], case["nodeIdentifierURL"]
    if not isinstance(detail, dict) or detail.get("testIdentifier") != identifier or detail.get("testIdentifierURL") != url or detail.get("testResult") != "Passed":
        raise ValueError(f"{identifier}: detail identity/result drift")
    if detail.get("testDescription") not in {"Test case with 1 run", "Test case with 1 runs"}:
        raise ValueError(f"{identifier}: missing, unknown, or extra concrete run count")
    devices, configurations, runs = (detail.get(key) for key in ("devices", "testPlanConfigurations", "testRuns"))
    if any(not isinstance(value, list) or len(value) != 1 or not isinstance(value[0], dict) for value in (devices, configurations, runs)):
        raise ValueError(f"{identifier}: exactly one device, configuration and concrete run required")
    device = runs[0]
    if device.get("nodeType") != "Device" or device.get("result") != "Passed" or not device.get("nodeIdentifier") or device["nodeIdentifier"] != devices[0].get("deviceId"):
        raise ValueError(f"{identifier}: concrete device/result mismatch")
    children = device.get("children")
    if not isinstance(children, list) or len(children) != 1 or not isinstance(children[0], dict):
        raise ValueError(f"{identifier}: extra/missing device executions")
    configuration = children[0]
    if configuration.get("nodeType") != "Test Plan Configuration" or configuration.get("result") != "Passed" or not configuration.get("nodeIdentifier") or configuration["nodeIdentifier"] != configurations[0].get("configurationId") or configuration.get("nodeIdentifierURL") != url:
        raise ValueError(f"{identifier}: concrete configuration identity/result mismatch")
    attempts = execution_children(configuration.get("children", []))
    tree_warnings = Counter(child["name"] for child in case.get("children", [])
                            if child.get("nodeType") == "Runtime Warning")
    detail_warnings = Counter(child["name"] for child in configuration.get("children", [])
                              if child.get("nodeType") == "Runtime Warning")
    if tree_warnings != detail_warnings:
        raise ValueError(f"{identifier}: diagnostic tree/detail mismatch")
    if attempts:
        if not isinstance(attempts, list) or len(attempts) != 1 or not isinstance(attempts[0], dict) or attempts[0].get("nodeType") != "Repetition" or attempts[0].get("result") != "Passed" or attempts[0].get("children"):
            raise ValueError(f"{identifier}: unexpected/extra/failed concrete attempts")
    elif not isinstance(attempts, list):
        raise ValueError(f"{identifier}: malformed concrete attempt list")


def native_result(bundle: Path, command: str, *extra: str) -> object:
    if not bundle.is_dir() or bundle.suffix != ".xcresult":
        raise ValueError("FX evidence must be an xcresult directory")
    completed = subprocess.run(["xcrun", "xcresulttool", "get", "test-results", command,
                                "--path", str(bundle), "--compact", *extra],
                               capture_output=True, text=True, timeout=30, check=False)
    if completed.returncode:
        raise ValueError(f"unable to read FX {command}: {completed.stderr.strip()}")
    return json.loads(completed.stdout)


def verify_bundle(bundle: Path, *, ui: bool) -> None:
    cases = required_cases(native_result(bundle, "tests"), ui=ui)

    def verify(case: dict) -> None:
        validate_detail(native_result(bundle, "test-details", "--test-id", case["nodeIdentifier"]), case)

    with ThreadPoolExecutor(max_workers=4) as executor:
        list(executor.map(verify, cases.values()))
    warnings = [(case["nodeIdentifier"], child["name"]) for case in cases.values()
                for child in case.get("children", []) if child.get("nodeType") == "Runtime Warning"]
    for identifier, message in warnings:
        print(f"FX retained runtime diagnostic (not an execution): {identifier}: {message}")


def diagnostic_self_test(tree: dict, *, ui: bool) -> None:
    warning = {"nodeType": "Runtime Warning", "name": "Invalid frame dimension (negative or non-finite)."}
    valid = copy.deepcopy(tree)
    for case in valid["testNodes"]:
        case["children"] = [copy.deepcopy(warning)]
        detail = detail_fixture(case)
        detail["testRuns"][0]["children"][0]["children"] = [copy.deepcopy(warning)]
        validate_detail(detail, case)
        for tree_only in (True, False):
            changed_case, changed_detail = copy.deepcopy(case), copy.deepcopy(detail)
            if tree_only:
                changed_detail["testRuns"][0]["children"][0]["children"] = []
            else:
                changed_case["children"] = []
            try:
                validate_detail(changed_detail, changed_case)
            except ValueError:
                continue
            raise ValueError("tree/detail diagnostic mismatch must not silently drop a warning")
        for fake in (
            dict(warning, result="Failed"), dict(warning, result="Passed"),
            dict(warning, nodeIdentifier="hidden()"), dict(warning, nodeIdentifierURL="test://hidden"),
            dict(warning, children=[]), dict(warning, children=[{"nodeType": "Repetition", "result": "Failed"}]),
            dict(warning, name=""), dict(warning, name=None), dict(warning, unknown="extra"),
        ):
            changed = copy.deepcopy(valid)
            changed["testNodes"][0]["children"] = [fake]
            if not runtime_errors(changed, ui=ui):
                raise ValueError("diagnostic-shaped execution bypassed aggregate validation")
            changed_detail = copy.deepcopy(detail)
            changed_detail["testRuns"][0]["children"][0]["children"] = [fake]
            try:
                validate_detail(changed_detail, case)
            except ValueError:
                continue
            raise ValueError("diagnostic-shaped execution bypassed concrete-detail validation")
    if runtime_errors(valid, ui=ui):
        raise ValueError("native pure diagnostic leaves must not be counted as retries")


def detail_fixture(case: dict) -> dict:
    return {"testIdentifier": case["nodeIdentifier"], "testIdentifierURL": case["nodeIdentifierURL"],
            "testResult": "Passed", "testDescription": "Test case with 1 run",
            "devices": [{"deviceId": "device"}],
            "testPlanConfigurations": [{"configurationId": "1"}],
            "testRuns": [{"nodeType": "Device", "nodeIdentifier": "device", "result": "Passed",
                          "children": [{"nodeType": "Test Plan Configuration", "nodeIdentifier": "1",
                                        "nodeIdentifierURL": case["nodeIdentifierURL"], "result": "Passed"}]}]}


def detail_self_test(tree: dict) -> None:
    for case in tree["testNodes"]:
        valid = detail_fixture(case)
        validate_detail(valid, case)
        mutations = []
        for kind in ("extra-run", "missing-run", "hidden-failed", "unknown-repetition", "wrong-id", "wrong-url",
                     "wrong-device", "wrong-config", "extra-config", "count", "arguments", "null-children"):
            changed = copy.deepcopy(valid)
            configuration = changed["testRuns"][0]["children"][0]
            if kind == "extra-run": changed["testRuns"] *= 2
            elif kind == "missing-run": changed["testRuns"] = []
            elif kind == "hidden-failed": configuration["result"] = "Failed"
            elif kind == "unknown-repetition": configuration["children"] = [{"nodeType": "Repetition"}]
            elif kind == "wrong-id": changed["testIdentifier"] = "Other/test()"
            elif kind == "wrong-url": configuration["nodeIdentifierURL"] = "test://other"
            elif kind == "wrong-device": changed["devices"][0]["deviceId"] = "other"
            elif kind == "wrong-config": changed["testPlanConfigurations"][0]["configurationId"] = "other"
            elif kind == "extra-config": changed["testRuns"][0]["children"] *= 2
            elif kind == "count": changed["testDescription"] = "Test case with 2 runs"
            elif kind == "arguments": configuration["children"] = [{"nodeType": "Arguments", "result": "Passed"}] * 2
            else: configuration["children"] = None
            mutations.append((kind, changed))
        for kind, changed in mutations:
            try:
                validate_detail(changed, case)
            except ValueError:
                continue
            raise ValueError(f"FX detail self-test accepted {kind}: {case['nodeIdentifier']}")


def native_cli_self_test(root: Path, tree: dict, *, ui: bool) -> None:
    """Cross the real CLI/native-reader boundary with finite fake xcresulttool responses."""
    with tempfile.TemporaryDirectory(prefix="fx-native-cli-") as directory:
        base = Path(directory)
        bundle = base / "Evidence.xcresult"
        bundle.mkdir()
        command = base / "xcrun"
        command.write_text(f"#!{sys.executable}\n" + '''import json, pathlib, sys
args = sys.argv[1:]
bundle = pathlib.Path(args[args.index('--path') + 1])
payload = json.loads((bundle / 'native.json').read_text())
if args[:4] == ['xcresulttool', 'get', 'test-results', 'tests']:
    print(json.dumps(payload['tree']))
elif args[:4] == ['xcresulttool', 'get', 'test-results', 'test-details']:
    print(json.dumps(payload['details'][args[args.index('--test-id') + 1]]))
else:
    raise SystemExit(72)
''')
        command.chmod(0o700)
        valid = {"tree": tree, "details": {case["nodeIdentifier"]: detail_fixture(case) for case in tree["testNodes"]}}
        identifier = tree["testNodes"][0]["nodeIdentifier"]
        for kind in ("valid", "warning", "warning-execution", "warning-nested", "extra-detail", "failed-detail", "unknown-detail", "arguments-tree", "failed-parent", "unknown-tree"):
            payload = copy.deepcopy(valid)
            case = payload["tree"]["testNodes"][0]
            detail = payload["details"][identifier]
            configuration = detail["testRuns"][0]["children"][0]
            if kind.startswith("warning"):
                diagnostic = {"nodeType": "Runtime Warning", "name": "Native layout diagnostic"}
                if kind == "warning-execution": diagnostic["result"] = "Failed"
                if kind == "warning-nested": diagnostic["children"] = [{"nodeType": "Repetition", "result": "Failed"}]
                case["children"] = [copy.deepcopy(diagnostic)]
                configuration["children"] = [copy.deepcopy(diagnostic)]
            elif kind == "extra-detail": detail["testRuns"] *= 2
            elif kind == "failed-detail": configuration["result"] = "Failed"
            elif kind == "unknown-detail": configuration["children"] = [{"nodeType": "Repetition"}]
            elif kind == "arguments-tree": case["children"] = [{"nodeType": "Arguments", "result": "Passed"}] * 2
            elif kind == "failed-parent":
                case.update(result="Failed", children=[{"nodeType": "Repetition", "result": "Passed"}])
            elif kind == "unknown-tree": case["children"] = [{"nodeType": "Repetition"}, {"nodeType": "Repetition", "result": "Passed"}]
            (bundle / "native.json").write_text(json.dumps(payload))
            completed = subprocess.run([sys.executable, "-B", str(root / "Scripts/fx01_ui_contract.py"),
                                        "--verify-ui-bundle" if ui else "--verify-unit-bundle", str(bundle)],
                                       env={"PATH": str(base) + os.pathsep + "/usr/bin:/bin"},
                                       capture_output=True, text=True, timeout=30, check=False)
            expected = 0 if kind in {"valid", "warning"} else 1
            if completed.returncode != expected or (expected == 0 and "passed exactly once" not in completed.stdout) or (expected == 1 and "validation failed" not in completed.stderr) or (kind == "warning" and "retained runtime diagnostic" not in completed.stdout):
                raise ValueError(f"FX native CLI self-test {ui}/{kind}: unexpected verdict {completed.returncode}")


def self_test(root: Path) -> None:
    if errors := isolation_errors(root):
        raise ValueError("\n".join(errors))
    mutations = (
        (HOST, GUARD, f"#if DEBUG || targetEnvironment(simulator) || {FLAG}"),
        (HOST, GUARD, f"#if DEBUG && {FLAG}"),
        (HOST, GUARD, f"#if targetEnvironment(simulator) && {FLAG}"),
        (HOST, GUARD, "#if DEBUG && targetEnvironment(simulator)"),
        (HOST, GUARD, "#if DEBUG"),
        (HOST, "DataController(isStoredInMemoryOnly: true)", "DataController()"),
        (HOST, "SettingsStore(defaults: defaults)", "SettingsStore()"),
        (HOST, "notificationScheduler: FXUINotificationStub(),", ""),
        (HOST, "FXUIFixtureAccess.allow(authority)", "if ProcessInfo.processInfo.arguments.contains(\"pro\") { FXUIFixtureAccess.allow(authority) }"),
        (MAIN, f"#if !{FLAG}", "#if DEBUG"),
        (ACCESS, GUARD, "#if DEBUG"),
        (ACCESS, GUARD, f"#if DEBUG || targetEnvironment(simulator) || {FLAG}"),
        (ACCESS, "authority.replaceEntitlements(.proSubscription)", 'if ProcessInfo.processInfo.environment["FX_FAKE_PAID"] == "1" { authority.replaceEntitlements(.proSubscription) }'),
        (ACCESS, "authority.replaceEntitlements(.proSubscription)", 'if UserDefaults.standard.bool(forKey: "paid") { authority.replaceEntitlements(.proSubscription) }'),
        (ACCESS, "authority.replaceEntitlements(.free)", "authority.replaceEntitlements(.proSubscription)"),
        (SCHEME, 'buildForArchiving="NO"', 'buildForArchiving="YES"'),
        (SCHEME, 'buildConfiguration="Debug"', 'buildConfiguration="Release"'),
        (SCHEME, "</Scheme>", "<ArchiveAction buildConfiguration=\"Release\"/></Scheme>"),
        (SCHEME, UI_BINDINGS[0] + "()", "MindBudgetPhase3UITests/unrelated()"),
        (PROJECT, "// !$*UTF8*$!", "// !$*UTF8*$!\n// " + FLAG),
        ("MindBudget.xcodeproj/xcshareddata/xcschemes/MindBudget.xcscheme",
         "</Scheme>", "<!-- MINDBUDGET_FX_UI_TESTS --></Scheme>"),
    )
    with tempfile.TemporaryDirectory(prefix="fx-ui-isolation-") as directory:
        fixture = Path(directory)
        for name in FIXTURE_FILES:
            target = fixture / name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text((root / name).read_text())
        if isolation_errors(fixture):
            raise ValueError("valid copied host isolation fixture rejected")
        for name, original, replacement in mutations:
            path = fixture / name
            text = path.read_text()
            if original not in text:
                raise ValueError(f"isolation mutation no longer exercises source: {name}:{original}")
            try:
                path.write_text(text.replace(original, replacement))
                if not isolation_errors(fixture):
                    raise ValueError(f"isolation self-test failed open: {name}:{original}")
            finally:
                path.write_text(text)
        # Missing scheme must not silently remove the loop that would inspect it.
        (fixture / SCHEME).unlink()
        if not isolation_errors(fixture):
            raise ValueError("missing test-only scheme accepted")
    for ui, bindings in ((False, UNIT_BINDINGS), (True, UI_BINDINGS)):
        if not bindings:
            raise ValueError("empty runtime binding inventory")
        valid = {"testNodes": [{"nodeType": "Test Case", "nodeIdentifier": name + "()",
                                "nodeIdentifierURL": "test://bundle/" + name + "()",
                                "result": "Passed"} for name in bindings]}
        if runtime_errors(valid, ui=ui):
            raise ValueError("valid runtime fixture rejected")
        detail_self_test(valid)
        diagnostic_self_test(valid, ui=ui)
        native_cli_self_test(root, valid, ui=ui)
        for index in range(len(bindings)):
            for mutation in ("missing", "skipped", "failed", "duplicate", "not-test", "retry", "wrong-type", "arguments", "unknown-attempt", "failed-parent", "missing-url"):
                changed = copy.deepcopy(valid)
                node = changed["testNodes"][index]
                if mutation == "missing":
                    changed["testNodes"].pop(index)
                elif mutation in {"skipped", "failed"}:
                    node["result"] = mutation.title()
                elif mutation == "duplicate":
                    changed["testNodes"].append(copy.deepcopy(node))
                elif mutation == "not-test":
                    node["nodeType"] = "Test Suite"
                elif mutation == "wrong-type":
                    node["nodeIdentifier"] = "Unrelated/" + node["nodeIdentifier"].split("/")[1]
                elif mutation == "arguments":
                    node["children"] = [{"nodeType": "Arguments", "result": "Passed"}] * 2
                elif mutation == "unknown-attempt":
                    node["children"] = [{"nodeType": "Repetition"}, {"nodeType": "Repetition", "result": "Passed"}]
                elif mutation == "failed-parent":
                    node["result"] = "Failed"
                    node["children"] = [{"nodeType": "Repetition", "result": "Passed"}]
                elif mutation == "missing-url":
                    del node["nodeIdentifierURL"]
                else:
                    node["children"] = [{"nodeType": "Repetition", "result": "Failed"},
                                        {"nodeType": "Repetition", "result": "Passed"}]
                if not runtime_errors(changed, ui=ui):
                    raise ValueError(f"FX runtime self-test accepted {mutation}: {bindings[index]}")
        repeated = copy.deepcopy(valid)
        for node in repeated["testNodes"]:
            node["children"] = [{"nodeType": "Repetition", "result": "Passed"}]
        if runtime_errors(repeated, ui=ui):
            raise ValueError("one concrete Passed repetition must be accepted")
    print(f"FX isolation self-test passed: {len(mutations) + 1} copied-source negatives")
    print(f"FX runtime self-test passed: {11 * (len(UNIT_BINDINGS) + len(UI_BINDINGS))} negative bindings")
    print(f"FX concrete-detail self-test passed: {12 * (len(UNIT_BINDINGS) + len(UI_BINDINGS))} negative details; 4 CLI positives / 16 CLI negatives")
    print(f"FX diagnostic self-test passed: {18 * (len(UNIT_BINDINGS) + len(UI_BINDINGS))} disguised-execution negatives")
    print(f"FX diagnostic closure self-test passed: {2 * (len(UNIT_BINDINGS) + len(UI_BINDINGS))} missing-diagnostic negatives")


def main() -> int:
    parser = argparse.ArgumentParser()
    action = parser.add_mutually_exclusive_group(required=True)
    action.add_argument("--self-test", action="store_true")
    action.add_argument("--verify-unit-bundle", type=Path)
    action.add_argument("--verify-ui-bundle", type=Path)
    args = parser.parse_args()
    try:
        if args.self_test:
            self_test(Path(__file__).resolve().parent.parent)
        else:
            ui = args.verify_ui_bundle is not None
            verify_bundle(args.verify_ui_bundle if ui else args.verify_unit_bundle, ui=ui)
            print(f"FX {'UI host' if ui else 'unit'} runtime bindings passed exactly once: "
                  f"{len(UI_BINDINGS if ui else UNIT_BINDINGS)}; no skipped/retried binding accepted")
    except (OSError, ValueError, ET.ParseError, subprocess.TimeoutExpired) as error:
        print(f"FX runtime/isolation validation failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
