#!/usr/bin/env python3
"""Validate the bounded C6-02 acceptance matrix and its runtime test evidence."""

from __future__ import annotations

import argparse
import copy
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Any


ROOT_KEYS = frozenset(
    {"schemaVersion", "phase", "ownerInstructionDate", "blockedActions", "rows"}
)
ROW_KEYS = frozenset(
    {"id", "disposition", "requiredTests", "acceptedEvidence", "nonPassBoundary"}
)
TEST_KEYS = frozenset({"source", "type", "method"})
EXPECTED_ROWS = (
    ("storekit-transaction-errors", "deterministic-pass"),
    ("receipt-acquisition", "bounded-mixed-evidence"),
    ("signed-phone-accessibility", "owner-accepted-non-pass"),
    ("instruments-data-protection", "owner-accepted-non-pass"),
    ("system-integration", "deterministic-pass-with-physical-deferral"),
)
EXPECTED_BLOCKED_ACTIONS = (
    "archive",
    "upload",
    "deploy-staging",
    "deploy-production",
    "app-store-connect-write",
    "tester-assignment",
    "g1-decision",
    "distribution",
    "release",
)
EXPECTED_BINDINGS_BY_ROW = {
    "storekit-transaction-errors": (
        "StoreLifecycleDomainTests/nonSuccessfulPurchaseResultsNeverFinishOrGrantAccess",
        "StoreLifecycleDomainTests/restoreDistinguishesRestoredNoPurchaseAndSourceFailure",
        "StoreLifecycleDomainTests/unavailableAuthorityBlocksPurchaseBeforeTheSourceCanPresentStoreKit",
        "StoreLifecycleDomainTests/subscriptionStateMatrixGrantsOnlySubscribedAndVerifiedGrace",
        "StoreRuntimeTests/eligiblePayAsYouGoOfferRetainsItsPriceAndPausesPurchase",
        "StoreRuntimeTests/eligiblePayUpFrontOfferRetainsItsPriceAndPausesPurchase",
        "StoreRuntimeTests/ineligibleOrUnknownIntroductoryOffersCannotBeMisrepresented",
        "StoreRuntimeTests/subscriptionSoftLandingCoversEveryVerifiedExceptionalStateBilingually",
    ),
    "receipt-acquisition": (
        "ReceiptImageLifecycleTests/twentySequentialRealImagesStayBoundedAndLeaveNoTemporaryArtifact",
        "ReceiptImportIntegrationTests/cancellingARecognizingGenerationCannotApplyItsLateResult",
        "ReceiptImportIntegrationTests/recognizedFieldsRemainEphemeralUntilTheExistingSaveAction",
        "ReceiptImportIntegrationTests/editedFieldsStayUserOwnedEvenWhenChangedBackToTheirStartingValues",
        "ReceiptImportIntegrationTests/acquisitionGateFailuresRemainTruthfulAndRecoverySpecific",
    ),
    "signed-phone-accessibility": (
        "MindBudgetPhase3UITests/testProSubscriptionKeepsAX5ControlsReachableAcrossEveryAppearance",
        "MindBudgetPhase3UITests/testAccessibilityExtraLargeKeepsPrimaryActionsAndNavigationReachable",
    ),
    "instruments-data-protection": (),
    "system-integration": (
        "Phase9FeatureTests/notificationSchedulerCarriesAGatedEntityAssociationToTheSDKBoundary",
        "Phase8AFeatureTests/unavailableSiriReturnsNoPassiveEntitiesAndRejectsActiveWrites",
        "Phase8AFeatureTests/spotlightReconciliationEnforcesTheMerchantTripleGateEndToEnd",
        "SettingsStoreTests/appLockNeverUnlocksAfterCancelledAuthentication",
        "SettingsStoreTests/enablingAppLockRequiresAvailableFaceIDAndSuccessfulAuthentication",
        "Phase11FreeTierTests/unifiedCSVExportsIncomeExactlyAndNeutralizesSpreadsheetFormulas",
        "Phase6FeatureTests/deleteAllDataRunsPrivacyStagesThenResetsEveryLocalModelAndPreference",
        "Phase6FeatureTests/telemetryDeletionFailureNeverBlocksLocalFinancialDeletion",
    ),
}
IDENTIFIER = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")
TEST_NODE_IDENTIFIER = re.compile(
    r"^(?:[A-Za-z_][A-Za-z0-9_]*/)?"
    r"(?P<type>[A-Za-z_][A-Za-z0-9_]*)/"
    r"(?P<method>[A-Za-z_][A-Za-z0-9_]*)\(.*\)$"
)
# Xcode 26.6 and Xcode 27 both expose this stable test-results schema. Do not use 0.4.0 here:
# hosted Xcode 26.6 does not recognize it.
RESULT_SCHEMA_VERSION = "0.3.0"


def exact_keys(value: Any, expected: frozenset[str]) -> bool:
    return isinstance(value, dict) and frozenset(value) == expected


def load_json(path: Path) -> Any:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeDecodeError, json.JSONDecodeError) as error:
        raise ValueError(f"unable to read strict C6-02 acceptance JSON: {error}") from error


def validate_manifest(data: Any, project_root: Path) -> list[str]:
    if not exact_keys(data, ROOT_KEYS):
        return ["root object must contain exactly the reviewed C6-02 acceptance keys"]

    errors: list[str] = []
    if data["schemaVersion"] != 1:
        errors.append("schemaVersion must be exactly 1")
    if data["phase"] != "C6-02":
        errors.append("phase must be exactly C6-02")
    if data["ownerInstructionDate"] != "2026-08-31":
        errors.append("owner instruction date must remain the accepted 2026-08-31 decision")
    if tuple(data["blockedActions"]) != EXPECTED_BLOCKED_ACTIONS:
        errors.append("C6-02 must retain every archive, remote, G1, distribution, and release block")

    rows = data["rows"]
    if not isinstance(rows, list):
        return errors + ["rows must be a list"]

    observed_rows: list[tuple[str, str]] = []
    observed_bindings: set[str] = set()
    for row_index, row in enumerate(rows):
        label = f"rows[{row_index}]"
        if not exact_keys(row, ROW_KEYS):
            errors.append(f"{label} must contain exactly the reviewed row keys")
            continue
        observed_rows.append((row["id"], row["disposition"]))
        if not isinstance(row["acceptedEvidence"], str) or not row["acceptedEvidence"].strip():
            errors.append(f"{label}.acceptedEvidence must be explicit")
        boundary = row["nonPassBoundary"]
        if not isinstance(boundary, str) or "not" not in boundary.lower() or "pass" not in boundary.lower():
            errors.append(f"{label}.nonPassBoundary must explicitly deny a broadened pass")

        tests = row["requiredTests"]
        if not isinstance(tests, list):
            errors.append(f"{label}.requiredTests must be a list")
            continue
        if row["id"] != "instruments-data-protection" and not tests:
            errors.append(f"{label}.requiredTests must bind deterministic evidence")
        if row["id"] == "instruments-data-protection" and tests:
            errors.append("Instruments/data protection must not invent a test substitute")

        row_bindings: list[str] = []
        for test_index, test in enumerate(tests):
            test_label = f"{label}.requiredTests[{test_index}]"
            if not exact_keys(test, TEST_KEYS):
                errors.append(f"{test_label} must contain exactly source/type/method")
                continue
            source = test["source"]
            type_name = test["type"]
            method = test["method"]
            path = Path(source) if isinstance(source, str) else Path("/")
            if (
                not isinstance(source, str)
                or path.is_absolute()
                or ".." in path.parts
                or path.parts[0] not in {"MindBudgetTests", "MindBudgetUITests"}
                or path.suffix != ".swift"
            ):
                errors.append(f"{test_label}.source must be a safe test-target Swift path")
                continue
            if not isinstance(type_name, str) or not IDENTIFIER.fullmatch(type_name):
                errors.append(f"{test_label}.type must be a Swift identifier")
                continue
            if not isinstance(method, str) or not IDENTIFIER.fullmatch(method):
                errors.append(f"{test_label}.method must be a Swift identifier")
                continue
            binding = f"{type_name}/{method}"
            row_bindings.append(binding)
            if binding in observed_bindings:
                errors.append(f"duplicate required-test binding: {binding}")
            observed_bindings.add(binding)
            source_path = project_root / source
            if not source_path.is_file():
                errors.append(f"{test_label} references missing source: {source}")
                continue
            text = source_path.read_text(encoding="utf-8")
            if not re.search(rf"\b(?:struct|class|final\s+class)\s+{re.escape(type_name)}\b", text):
                errors.append(f"{test_label} cannot find type {type_name}")
            if not re.search(rf"\bfunc\s+{re.escape(method)}\s*\(", text):
                errors.append(f"{test_label} cannot find method {method}")

        expected_bindings = EXPECTED_BINDINGS_BY_ROW.get(row["id"])
        if expected_bindings is not None and tuple(row_bindings) != expected_bindings:
            errors.append(f"{label}.requiredTests must retain its exact reviewed bindings in order")

    if tuple(observed_rows) != EXPECTED_ROWS:
        errors.append("rows must retain every reviewed C6-02 disposition exactly once and in order")
    return errors


def required_bindings(data: dict[str, Any]) -> list[str]:
    return [
        f"{test['type']}/{test['method']}"
        for row in data["rows"]
        for test in row["requiredTests"]
    ]


def result_bindings(result_data: Any) -> dict[str, list[str]]:
    observed: dict[str, list[str]] = {}

    def visit(value: Any) -> None:
        if isinstance(value, dict):
            if value.get("nodeType") == "Test Case":
                identifier = value.get("nodeIdentifier")
                result = value.get("result")
                if isinstance(identifier, str) and isinstance(result, str):
                    match = TEST_NODE_IDENTIFIER.fullmatch(identifier)
                    if match:
                        binding = f"{match.group('type')}/{match.group('method')}"
                        observed.setdefault(binding, []).append(result)
            for child in value.get("children", []):
                visit(child)
        elif isinstance(value, list):
            for child in value:
                visit(child)

    if isinstance(result_data, dict):
        visit(result_data.get("testNodes", []))
    return observed


def validate_results(data: dict[str, Any], result_data: Any) -> list[str]:
    errors: list[str] = []
    observed = result_bindings(result_data)
    for binding in required_bindings(data):
        results = observed.get(binding, [])
        if len(results) != 1:
            errors.append(f"required C6-02 test {binding} must execute exactly once; observed={results}")
        elif results[0] != "Passed":
            errors.append(f"required C6-02 test {binding} cannot fail or skip; result={results[0]}")
    return errors


def load_result_bundle(path: Path) -> Any:
    if not path.is_dir() or path.suffix != ".xcresult":
        raise ValueError(f"C6-02 runtime evidence is not an xcresult directory: {path}")
    command = [
        "xcrun",
        "xcresulttool",
        "get",
        "test-results",
        "tests",
        "--schema-version",
        RESULT_SCHEMA_VERSION,
        "--path",
        str(path),
        "--compact",
    ]
    completed = subprocess.run(command, capture_output=True, text=True, check=False)
    if completed.returncode != 0:
        detail = completed.stderr.strip() or "xcresulttool returned no diagnostic"
        raise ValueError(f"unable to read C6-02 runtime evidence: {detail}")
    try:
        return json.loads(completed.stdout)
    except json.JSONDecodeError as error:
        raise ValueError(f"xcresulttool returned invalid JSON: {error}") from error


def self_test(data: dict[str, Any], project_root: Path) -> None:
    if errors := validate_manifest(data, project_root):
        raise AssertionError("\n".join(errors))

    mutations: list[tuple[str, Any]] = []
    removed_row = copy.deepcopy(data)
    removed_row["rows"].pop()
    mutations.append(("removed disposition", removed_row))
    removed_binding = copy.deepcopy(data)
    removed_binding["rows"][0]["requiredTests"].pop()
    mutations.append(("removed runtime binding", removed_binding))
    broadened = copy.deepcopy(data)
    broadened["rows"][2]["nonPassBoundary"] = "Complete physical accessibility passed."
    mutations.append(("broadened physical pass", broadened))
    archive = copy.deepcopy(data)
    archive["blockedActions"].remove("archive")
    mutations.append(("removed archive block", archive))
    traversal = copy.deepcopy(data)
    traversal["rows"][0]["requiredTests"][0]["source"] = "MindBudgetTests/../unsafe.swift"
    mutations.append(("test source traversal", traversal))
    missing_method = copy.deepcopy(data)
    missing_method["rows"][0]["requiredTests"][0]["method"] = "notARealTest"
    mutations.append(("missing method", missing_method))
    for description, mutation in mutations:
        if not validate_manifest(mutation, project_root):
            raise AssertionError(f"self-test failed to reject {description}")

    passing = {
        "testNodes": [
            {
                "children": [
                    {
                        "nodeType": "Test Case",
                        "nodeIdentifier": f"{binding}()",
                        "result": "Passed",
                    }
                    for binding in required_bindings(data)
                ]
            }
        ]
    }
    if errors := validate_results(data, passing):
        raise AssertionError("\n".join(errors))
    bundle_prefixed = copy.deepcopy(passing)
    for node in bundle_prefixed["testNodes"][0]["children"]:
        node["nodeIdentifier"] = f"MindBudgetTests/{node['nodeIdentifier']}"
    if errors := validate_results(data, bundle_prefixed):
        raise AssertionError("\n".join(errors))
    skipped = copy.deepcopy(passing)
    skipped["testNodes"][0]["children"][0]["result"] = "Skipped"
    if not validate_results(data, skipped):
        raise AssertionError("self-test failed to reject skipped evidence")
    duplicate = copy.deepcopy(passing)
    duplicate["testNodes"][0]["children"].append(
        copy.deepcopy(duplicate["testNodes"][0]["children"][0])
    )
    if not validate_results(data, duplicate):
        raise AssertionError("self-test failed to reject duplicate evidence")
    failed_then_passed = copy.deepcopy(passing)
    failed_then_passed["testNodes"][0]["children"][0]["result"] = "Failed"
    retry_pass = copy.deepcopy(passing["testNodes"][0]["children"][0])
    failed_then_passed["testNodes"][0]["children"].append(retry_pass)
    if not validate_results(data, failed_then_passed):
        raise AssertionError("self-test failed to reject a failed-then-passed retry")


def arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--manifest",
        default="Docs/Commercialization/C6_02_ACCEPTANCE_MATRIX.json",
    )
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--verify-result-bundle")
    return parser.parse_args()


def main() -> int:
    options = arguments()
    project_root = Path(__file__).resolve().parent.parent
    try:
        data = load_json(project_root / options.manifest)
        if errors := validate_manifest(data, project_root):
            raise ValueError("\n".join(errors))
        if options.self_test:
            self_test(data, project_root)
        if options.verify_result_bundle:
            result_data = load_result_bundle(Path(options.verify_result_bundle))
            if errors := validate_results(data, result_data):
                raise ValueError("\n".join(errors))
            print(
                "C6-02 deterministic evidence passed: "
                f"{len(required_bindings(data))} exact runtime bindings"
            )
        else:
            print("C6-02 bounded acceptance contract passed")
        return 0
    except (AssertionError, OSError, ValueError) as error:
        print(str(error), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
