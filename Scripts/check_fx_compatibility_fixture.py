#!/usr/bin/env python3
"""Pin pre-D codec provenance and keep both compatibility files test-only."""
from __future__ import annotations

import argparse
import hashlib
from pathlib import Path
import re

BASE = "7e9d69389d88dabb5bfcc5e77709b282801d3df0"
SOURCE = "MindBudget/Services/CloudSyncDomain.swift"
SHA256 = "707e153d9fd0973778e9eca722047530de4c7b915e0028e19b461ea6825b0425"
FROZEN = "MindBudgetTests/PreDFrozenCloudSyncDomain.swift"
TESTS = "MindBudgetTests/ForeignCurrencyCompatibilityTests.swift"


def original_source(frozen: str) -> str:
    # Exactly invert the three mechanical symbol substitutions, including Date helpers.
    # No Git history, network, current codec import or source regeneration is used by CI.
    return (frozen.replace("preDFrozenCloudSyncBits", "cloudSyncBits")
            .replace("PreDFrozenRecurringOccurrenceKey", "RecurringOccurrenceKey")
            .replace("PreDFrozenCloudSync", "CloudSync"))


def errors(root: Path, *, frozen: str | None = None, project: str | None = None) -> list[str]:
    frozen = (root / FROZEN).read_text() if frozen is None else frozen
    project = (root / "MindBudget.xcodeproj/project.pbxproj").read_text() if project is None else project
    result = []
    if hashlib.sha256(original_source(frozen).encode()).hexdigest() != SHA256:
        result.append(f"Frozen codec must recover {BASE}:{SOURCE} byte-for-byte")
    if "@testable import MindBudget" in frozen:
        result.append("Frozen codec must not delegate to current application code")
    for index, path in enumerate((TESTS, FROZEN), start=1):
        build_id = f"AF01D000000000000000000{index}"
        file_id = f"BF01D000000000000000000{index}"
        if not (root / path).is_file():
            result.append(f"Missing test fixture: {path}")
        if len(re.findall(rf"{build_id} /\*.*?\*/ = \{{isa = PBXBuildFile; fileRef = {file_id}", project)) != 1:
            result.append(f"Missing/duplicate test build binding: {path}")
        if len(re.findall(rf"{file_id} /\*.*?\*/ = \{{isa = PBXFileReference;.*?path = {re.escape(path)};", project)) != 1:
            result.append(f"Wrong file reference: {path}")
        phases = re.findall(r"(\w+) /\* [^\n]*? \*/ = \{isa = PBX\w+BuildPhase;([^\n]+)", project)
        owners = [phase for phase, body in phases if re.search(rf"\b{build_id}\b", body)]
        if owners != ["F10000000000000000000004"]:
            result.append(f"Fixture must compile only in MindBudgetTests: {path}")
        # Also forbid alternate build IDs for this file reference.
        if len(re.findall(rf"isa = PBXBuildFile; fileRef = {file_id}\b", project)) != 1:
            result.append(f"Alternate target binding: {path}")
    return result


def self_test(root: Path) -> None:
    frozen = (root / FROZEN).read_text()
    project = (root / "MindBudget.xcodeproj/project.pbxproj").read_text()
    negatives = [
        {"frozen": frozen.replace("case expense\n", "case expense\n    case expenseForeignCurrencyMetadata\n", 1)},
        {"frozen": frozen.replace("case expense\n", "", 1)},
        {"frozen": frozen + "\n@testable import MindBudget\n"},
        {"project": project.replace("files = (", "files = (AF01D0000000000000000002 /* duplicate */, ", 1)},
        {"project": project.replace("path = " + FROZEN, "path = " + SOURCE)},
    ]
    for index, values in enumerate(negatives):
        if not errors(root, **values):
            raise RuntimeError(f"Mutation {index} was accepted")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    failures = errors(root)
    if failures:
        raise SystemExit("\n".join(failures))
    if args.self_test:
        self_test(root)
    print("FX compatibility fixture provenance/test-target isolation passed")


if __name__ == "__main__":
    main()
