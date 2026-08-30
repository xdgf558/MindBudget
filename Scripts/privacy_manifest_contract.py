#!/usr/bin/env python3
"""Validate MindBudget's exact first-party privacy-manifest contract."""

from __future__ import annotations

import argparse
import copy
import plistlib
import sys
from pathlib import Path
from typing import Any


COLLECTED_KEYS = frozenset(
    {
        "NSPrivacyCollectedDataType",
        "NSPrivacyCollectedDataTypeLinked",
        "NSPrivacyCollectedDataTypeTracking",
        "NSPrivacyCollectedDataTypePurposes",
    }
)
EXPECTED_COLLECTED_TYPES = frozenset(
    {
        "NSPrivacyCollectedDataTypeProductInteraction",
        "NSPrivacyCollectedDataTypeDeviceID",
        # subscription_action includes the outcome of an explicit purchase. Apple defines
        # Purchase History as an account's or individual's purchases or purchase tendencies;
        # omitting this row would understate the closed telemetry vocabulary.
        "NSPrivacyCollectedDataTypePurchaseHistory",
    }
)
EXPECTED_PURPOSE = ["NSPrivacyCollectedDataTypePurposeAnalytics"]
EXPECTED_ACCESSED_API = {
    "NSPrivacyAccessedAPIType": "NSPrivacyAccessedAPICategoryUserDefaults",
    "NSPrivacyAccessedAPITypeReasons": ["CA92.1"],
}
ROOT_KEYS = frozenset(
    {
        "NSPrivacyAccessedAPITypes",
        "NSPrivacyCollectedDataTypes",
        "NSPrivacyTracking",
        "NSPrivacyTrackingDomains",
    }
)


def validate_manifest(data: Any) -> list[str]:
    if not isinstance(data, dict) or frozenset(data) != ROOT_KEYS:
        return ["privacy manifest must contain exactly the reviewed root keys"]

    errors: list[str] = []
    if data["NSPrivacyTracking"] is not False:
        errors.append("tracking must remain false")
    if data["NSPrivacyTrackingDomains"] != []:
        errors.append("tracking domains must remain empty")
    if data["NSPrivacyAccessedAPITypes"] != [EXPECTED_ACCESSED_API]:
        errors.append("required-reason API declaration must remain UserDefaults CA92.1 only")

    collected = data["NSPrivacyCollectedDataTypes"]
    if not isinstance(collected, list):
        return errors + ["collected data types must be an array"]

    observed_types: list[str] = []
    for index, declaration in enumerate(collected):
        label = f"NSPrivacyCollectedDataTypes[{index}]"
        if not isinstance(declaration, dict) or frozenset(declaration) != COLLECTED_KEYS:
            errors.append(f"{label} must contain exactly the reviewed declaration keys")
            continue
        observed_types.append(declaration["NSPrivacyCollectedDataType"])
        if declaration["NSPrivacyCollectedDataTypeLinked"] is not False:
            errors.append(f"{label} must remain unlinked")
        if declaration["NSPrivacyCollectedDataTypeTracking"] is not False:
            errors.append(f"{label} must remain non-tracking")
        if declaration["NSPrivacyCollectedDataTypePurposes"] != EXPECTED_PURPOSE:
            errors.append(f"{label} must be used only for Analytics")

    if len(observed_types) != len(set(observed_types)):
        errors.append("collected data type declarations must be unique")
    if frozenset(observed_types) != EXPECTED_COLLECTED_TYPES:
        errors.append(
            "collected data types must be exactly Product Interaction, Device ID, "
            "and Purchase History"
        )
    return errors


def load_manifest(path: Path) -> Any:
    try:
        with path.open("rb") as stream:
            return plistlib.load(stream)
    except (OSError, plistlib.InvalidFileException) as error:
        raise ValueError(f"unable to read privacy manifest: {error}") from error


def validate_source_contract(project_root: Path) -> list[str]:
    sources = {
        "domain": project_root / "MindBudget/Services/TelemetryDomain.swift",
        "router": project_root / "MindBudget/App/AppRouter.swift",
        "audit": project_root / "Docs/Commercialization/C5_TELEMETRY_CAPTURE_AUDIT.md",
        "privacy": project_root / "Docs/PRIVACY_AND_REVIEW_NOTES.md",
        "egress": project_root / "Docs/Commercialization/NETWORK_EGRESS_POLICY.md",
    }
    errors: list[str] = []
    texts: dict[str, str] = {}
    for label, path in sources.items():
        try:
            texts[label] = path.read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError) as error:
            errors.append(f"unable to read {path}: {error}")
    if errors:
        return errors

    required_fragments = {
        "domain": (
            "case subscription(TelemetryPurchaseAction, TelemetryOutcome)",
            'case subscription = "subscription_action"',
        ),
        "router": (
            "recordTelemetry(.subscription(.purchase, telemetryOutcome(for: outcome)))",
            "recordTelemetry(.subscription(.restore, telemetryOutcome(for: outcome)))",
            "recordTelemetry(.subscription(.manage, .completed))",
        ),
        "audit": ("Purchase History",),
        "privacy": ("Purchase History",),
        "egress": ("Purchase History",),
    }
    for label, fragments in required_fragments.items():
        for fragment in fragments:
            if fragment not in texts[label]:
                errors.append(f"{sources[label]} is missing privacy contract: {fragment}")
    return errors


def self_test() -> None:
    accepted = {
        "NSPrivacyAccessedAPITypes": [copy.deepcopy(EXPECTED_ACCESSED_API)],
        "NSPrivacyCollectedDataTypes": [
            {
                "NSPrivacyCollectedDataType": data_type,
                "NSPrivacyCollectedDataTypeLinked": False,
                "NSPrivacyCollectedDataTypeTracking": False,
                "NSPrivacyCollectedDataTypePurposes": list(EXPECTED_PURPOSE),
            }
            for data_type in sorted(EXPECTED_COLLECTED_TYPES)
        ],
        "NSPrivacyTracking": False,
        "NSPrivacyTrackingDomains": [],
    }
    if validate_manifest(accepted):
        raise AssertionError("accepted privacy manifest was rejected")

    mutations: list[tuple[str, dict[str, Any]]] = []

    missing_purchase = copy.deepcopy(accepted)
    missing_purchase["NSPrivacyCollectedDataTypes"] = [
        item
        for item in missing_purchase["NSPrivacyCollectedDataTypes"]
        if item["NSPrivacyCollectedDataType"]
        != "NSPrivacyCollectedDataTypePurchaseHistory"
    ]
    mutations.append(("missing Purchase History", missing_purchase))

    linked = copy.deepcopy(accepted)
    linked["NSPrivacyCollectedDataTypes"][0]["NSPrivacyCollectedDataTypeLinked"] = True
    mutations.append(("linked data", linked))

    tracking = copy.deepcopy(accepted)
    tracking["NSPrivacyTracking"] = True
    mutations.append(("tracking enabled", tracking))

    tracking_domain = copy.deepcopy(accepted)
    tracking_domain["NSPrivacyTrackingDomains"] = ["example.com"]
    mutations.append(("tracking domain", tracking_domain))

    wrong_purpose = copy.deepcopy(accepted)
    wrong_purpose["NSPrivacyCollectedDataTypes"][0][
        "NSPrivacyCollectedDataTypePurposes"
    ] = ["NSPrivacyCollectedDataTypePurposeAdvertisingOrMarketing"]
    mutations.append(("wrong purpose", wrong_purpose))

    wrong_reason = copy.deepcopy(accepted)
    wrong_reason["NSPrivacyAccessedAPITypes"][0]["NSPrivacyAccessedAPITypeReasons"] = [
        "UNKNOWN"
    ]
    mutations.append(("wrong required reason", wrong_reason))

    extra_type = copy.deepcopy(accepted)
    extra_type["NSPrivacyCollectedDataTypes"].append(
        {
            "NSPrivacyCollectedDataType": "NSPrivacyCollectedDataTypeOtherDataTypes",
            "NSPrivacyCollectedDataTypeLinked": False,
            "NSPrivacyCollectedDataTypeTracking": False,
            "NSPrivacyCollectedDataTypePurposes": list(EXPECTED_PURPOSE),
        }
    )
    mutations.append(("unreviewed data type", extra_type))

    for label, mutation in mutations:
        if not validate_manifest(mutation):
            raise AssertionError(f"self-test failed to reject {label}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument(
        "--manifest",
        default="MindBudget/Resources/PrivacyInfo.xcprivacy",
    )
    arguments = parser.parse_args()
    project_root = Path(__file__).resolve().parent.parent
    try:
        if arguments.self_test:
            self_test()
        errors = validate_manifest(load_manifest(project_root / arguments.manifest))
        errors.extend(validate_source_contract(project_root))
        if errors:
            raise ValueError("\n".join(errors))
        print("First-party privacy manifest contract passed")
        return 0
    except (AssertionError, ValueError) as error:
        print(str(error), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
