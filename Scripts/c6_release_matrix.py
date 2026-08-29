#!/usr/bin/env python3
"""Validate and expose the closed COM-C6 automated release matrix."""

from __future__ import annotations

import argparse
import copy
import json
import re
import sys
from pathlib import Path
from typing import Any


REQUIRED_ROW_IDS = (
    "storekit-entitlement-lifecycle",
    "signed-public-configuration-and-r1-network",
    "migration-and-rollback",
    "free-private-icloud",
    "receipt-local-privacy-accuracy-memory",
    "telemetry-deletion-ttl-and-local-delete",
    "offline-local-pro",
)

ALLOWED_STATIC_CHECKS = frozenset(
    {
        "Scripts/check-commercialization-docs.sh",
        "Scripts/check-feature-access-boundary.sh",
        "Scripts/check-network-egress.sh",
        "Scripts/check-no-floating-point-money.sh",
        "Scripts/check-public-configuration-contract.sh",
        "Scripts/check-public-configuration-transport.sh",
        "Scripts/check-release-readiness.sh",
        "Scripts/check-storekit-test-catalog.sh",
        "Scripts/check-telemetry-contract.sh",
        "Scripts/check-telemetry-metrics-contract.sh",
        "Scripts/check-telemetry-worker-contract.sh",
        "Scripts/check_icloud_sync_contract.py",
    }
)

EXPECTED_WORKER_CHECKS = (
    ("Services/PublicConfigurationWorker", "check"),
    ("Services/TelemetryWorker", "check"),
)

EXPECTED_BLOCKED_ACTIONS = (
    "archive",
    "upload",
    "deploy-staging",
    "deploy-production",
    "app-store-connect-write",
)

ROOT_KEYS = frozenset(
    {
        "schemaVersion",
        "phase",
        "remoteMutationAllowed",
        "workerChecks",
        "blockedActions",
        "rows",
    }
)
ROW_KEYS = frozenset(
    {
        "id",
        "title",
        "requirements",
        "swiftTests",
        "staticChecks",
        "nonAutomatedBoundary",
    }
)
TEST_KEYS = frozenset({"source", "type", "requiredMethods"})
WORKER_KEYS = frozenset({"directory", "script"})
IDENTIFIER = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")


def _is_safe_relative_path(raw_path: Any, prefix: str) -> bool:
    if not isinstance(raw_path, str) or not raw_path.startswith(prefix):
        return False
    path = Path(raw_path)
    return not path.is_absolute() and ".." not in path.parts


def _exact_keys(value: Any, expected: frozenset[str]) -> bool:
    return isinstance(value, dict) and frozenset(value.keys()) == expected


def _nonempty_strings(value: Any) -> bool:
    return (
        isinstance(value, list)
        and bool(value)
        and all(isinstance(item, str) and bool(item.strip()) for item in value)
    )


def validate_manifest_data(data: Any, project_root: Path) -> list[str]:
    errors: list[str] = []
    if not _exact_keys(data, ROOT_KEYS):
        return ["root object must contain exactly the reviewed C6 matrix keys"]

    if data["schemaVersion"] != 1:
        errors.append("schemaVersion must be exactly 1")
    if data["phase"] != "C6-01":
        errors.append("phase must be exactly C6-01")
    if data["remoteMutationAllowed"] is not False:
        errors.append("C6-01 must keep every remote mutation disabled")

    worker_checks = data["workerChecks"]
    observed_worker_checks: list[tuple[str, str]] = []
    if not isinstance(worker_checks, list):
        errors.append("workerChecks must be a list")
    else:
        for index, worker in enumerate(worker_checks):
            if not _exact_keys(worker, WORKER_KEYS):
                errors.append(f"workerChecks[{index}] must use only directory/script")
                continue
            observed_worker_checks.append((worker["directory"], worker["script"]))
        if tuple(observed_worker_checks) != EXPECTED_WORKER_CHECKS:
            errors.append("workerChecks must remain the two exact local dry-run check commands")

    if tuple(data["blockedActions"]) != EXPECTED_BLOCKED_ACTIONS:
        errors.append("blockedActions must retain every C6-01 archive/upload/deployment boundary")

    rows = data["rows"]
    if not isinstance(rows, list):
        return errors + ["rows must be a list"]

    observed_row_ids: list[str] = []
    observed_static_checks: set[str] = set()
    for row_index, row in enumerate(rows):
        label = f"rows[{row_index}]"
        if not _exact_keys(row, ROW_KEYS):
            errors.append(f"{label} must contain exactly the reviewed row keys")
            continue

        row_id = row["id"]
        observed_row_ids.append(row_id)
        if not isinstance(row["title"], str) or not row["title"].strip():
            errors.append(f"{label}.title must be nonempty")
        if not _nonempty_strings(row["requirements"]) or not all(
            requirement.startswith("REQ-") for requirement in row["requirements"]
        ):
            errors.append(f"{label}.requirements must contain closed REQ identifiers")
        if not isinstance(row["nonAutomatedBoundary"], str) or not row[
            "nonAutomatedBoundary"
        ].strip():
            errors.append(f"{label}.nonAutomatedBoundary must be explicit")

        static_checks = row["staticChecks"]
        if not _nonempty_strings(static_checks):
            errors.append(f"{label}.staticChecks must be nonempty")
        else:
            for check in static_checks:
                observed_static_checks.add(check)
                if check not in ALLOWED_STATIC_CHECKS:
                    errors.append(f"{label} uses unreviewed static check: {check}")
                    continue
                check_path = project_root / check
                if not check_path.is_file():
                    errors.append(f"{label} references missing static check: {check}")

        swift_tests = row["swiftTests"]
        if not isinstance(swift_tests, list) or not swift_tests:
            errors.append(f"{label}.swiftTests must be nonempty")
            continue
        for test_index, test in enumerate(swift_tests):
            test_label = f"{label}.swiftTests[{test_index}]"
            if not _exact_keys(test, TEST_KEYS):
                errors.append(f"{test_label} must contain exactly source/type/requiredMethods")
                continue
            source = test["source"]
            test_type = test["type"]
            methods = test["requiredMethods"]
            if not _is_safe_relative_path(source, "MindBudgetTests/") or not source.endswith(
                ".swift"
            ):
                errors.append(f"{test_label}.source must be a safe MindBudgetTests Swift path")
                continue
            if not isinstance(test_type, str) or not IDENTIFIER.fullmatch(test_type):
                errors.append(f"{test_label}.type must be a Swift identifier")
                continue
            if not _nonempty_strings(methods) or not all(
                IDENTIFIER.fullmatch(method) for method in methods
            ):
                errors.append(f"{test_label}.requiredMethods must be Swift identifiers")
                continue

            source_path = project_root / source
            if not source_path.is_file():
                errors.append(f"{test_label} references missing source: {source}")
                continue
            source_text = source_path.read_text(encoding="utf-8")
            if not re.search(rf"\bstruct\s+{re.escape(test_type)}\b", source_text):
                errors.append(f"{test_label} cannot find test type {test_type} in {source}")
            for method in methods:
                if not re.search(rf"\bfunc\s+{re.escape(method)}\s*\(", source_text):
                    errors.append(f"{test_label} cannot find required method {method}")

    if tuple(observed_row_ids) != REQUIRED_ROW_IDS:
        errors.append("rows must contain every required C6-01 row exactly once and in review order")
    if observed_static_checks != ALLOWED_STATIC_CHECKS:
        missing = sorted(ALLOWED_STATIC_CHECKS - observed_static_checks)
        extra = sorted(observed_static_checks - ALLOWED_STATIC_CHECKS)
        errors.append(f"matrix static-check coverage drifted; missing={missing}, extra={extra}")

    return errors


def load_manifest(path: Path) -> Any:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeDecodeError, json.JSONDecodeError) as error:
        raise ValueError(f"unable to read strict C6 matrix JSON: {error}") from error


def fail_if_invalid(data: Any, project_root: Path) -> None:
    errors = validate_manifest_data(data, project_root)
    if errors:
        raise ValueError("\n".join(errors))


def run_self_test(data: Any, project_root: Path) -> None:
    fail_if_invalid(data, project_root)

    mutations: list[tuple[str, Any]] = []

    remote = copy.deepcopy(data)
    remote["remoteMutationAllowed"] = True
    mutations.append(("remote mutation", remote))

    missing_row = copy.deepcopy(data)
    missing_row["rows"].pop()
    mutations.append(("missing required row", missing_row))

    traversal = copy.deepcopy(data)
    traversal["rows"][0]["swiftTests"][0]["source"] = "MindBudgetTests/../unsafe.swift"
    mutations.append(("source traversal", traversal))

    missing_method = copy.deepcopy(data)
    missing_method["rows"][0]["swiftTests"][0]["requiredMethods"] = ["notARealTest"]
    mutations.append(("missing test method", missing_method))

    unknown_check = copy.deepcopy(data)
    unknown_check["rows"][0]["staticChecks"].append("Scripts/unreviewed.sh")
    mutations.append(("unreviewed static check", unknown_check))

    deploy_worker = copy.deepcopy(data)
    deploy_worker["workerChecks"][0]["script"] = "deploy:production"
    mutations.append(("remote Worker command", deploy_worker))

    for description, mutation in mutations:
        if not validate_manifest_data(mutation, project_root):
            raise AssertionError(f"self-test failed to reject {description}")


def unique_test_filters(data: dict[str, Any]) -> list[str]:
    values: list[str] = []
    seen: set[str] = set()
    for row in data["rows"]:
        for test in row["swiftTests"]:
            value = f"MindBudgetTests/{test['type']}"
            if value not in seen:
                seen.add(value)
                values.append(value)
    return values


def unique_static_checks(data: dict[str, Any]) -> list[str]:
    return sorted({check for row in data["rows"] for check in row["staticChecks"]})


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--manifest",
        default="Docs/Commercialization/C6_RELEASE_MATRIX.json",
    )
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--list-test-filters", action="store_true")
    parser.add_argument("--list-static-checks", action="store_true")
    parser.add_argument("--list-worker-checks", action="store_true")
    return parser.parse_args()


def main() -> int:
    arguments = parse_arguments()
    project_root = Path(__file__).resolve().parent.parent
    manifest_path = project_root / arguments.manifest
    try:
        data = load_manifest(manifest_path)
        fail_if_invalid(data, project_root)
        if arguments.self_test:
            run_self_test(data, project_root)
        if arguments.list_test_filters:
            print("\n".join(unique_test_filters(data)))
        if arguments.list_static_checks:
            print("\n".join(unique_static_checks(data)))
        if arguments.list_worker_checks:
            print(
                "\n".join(
                    f"{worker['directory']}|{worker['script']}"
                    for worker in data["workerChecks"]
                )
            )
        if not any(
            (
                arguments.list_test_filters,
                arguments.list_static_checks,
                arguments.list_worker_checks,
            )
        ):
            print("C6-01 release matrix contract passed")
        return 0
    except (AssertionError, ValueError) as error:
        print(str(error), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
