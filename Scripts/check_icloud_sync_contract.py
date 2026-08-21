#!/usr/bin/env python3
"""Check the structural C4B design contract and prevent accidental managed SwiftData sync."""

from __future__ import annotations

import argparse
import re
import tempfile
from pathlib import Path


REQUIRED_SECTIONS = {
    "Status",
    "Scope and authority",
    "Contract declarations",
    "Why this architecture",
    "Current-store inventory and mapping",
    "Envelope, mutation, and conflict rules",
    "Account, offline, quota, and lifecycle behavior",
    "Environment and deployment boundary",
    "C4B-02 and C4B-03 handoff",
    "Unknowns and required evidence",
}
REQUIRED_DECLARATIONS = {
    "Access",
    "Local authority",
    "Cloud database",
    "Record identity",
    "Envelope",
    "Ordering",
    "Deletion",
    "Environment",
    "Encryption",
    "Attachments",
    "Managed SwiftData sync",
    "Disable/delete",
}
REQUIRED_DECLARATION_TOKENS = {
    "Access": ("free", "default-off"),
    "Local authority": ("never wait", "nonblocking"),
    "Cloud database": ("private", "mindbudget.sync.v1"),
    "Record identity": ("uuid", "<type>/<uuid>"),
    "Envelope": ("schemaversion", "encrypted"),
    "Ordering": ("change tag", "semantic digest"),
    "Deletion": ("tombstone",),
    "Environment": ("icloud.com.xdgf558.mindbudget", "development", "production"),
    "Encryption": ("encrypted", "no content"),
    "Attachments": ("never",),
    "Managed SwiftData sync": ("cloudkitdatabase: .none",),
    "Disable/delete": ("retains local", "separately"),
}
HEADING = re.compile(r"^##\s+(.+?)\s*$", re.MULTILINE)
TABLE_ROW = re.compile(r"^\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|\s*$", re.MULTILINE)


def validate_contract(path: Path) -> list[str]:
    text = path.read_text(encoding="utf-8")
    headings = set(HEADING.findall(text))
    errors = [f"{path}: missing section {section!r}" for section in sorted(REQUIRED_SECTIONS - headings)]
    declarations = {
        key.strip(): value.strip()
        for key, value in TABLE_ROW.findall(text)
        if key.strip() in REQUIRED_DECLARATIONS and value.strip()
    }
    errors.extend(
        f"{path}: missing contract declaration {key!r}"
        for key in sorted(REQUIRED_DECLARATIONS - set(declarations))
    )
    for key, tokens in REQUIRED_DECLARATION_TOKENS.items():
        value = declarations.get(key, "").lower()
        missing = [token for token in tokens if token not in value]
        if missing:
            errors.append(f"{path}: declaration {key!r} is missing required token(s): {', '.join(missing)}")
    return errors


def requires_cloudkit_hardening(project_root: Path) -> bool:
    source = project_root / "MindBudget"
    has_cloudkit_source = any(
        "import CloudKit" in file.read_text(encoding="utf-8") or "CKContainer" in file.read_text(encoding="utf-8")
        for file in source.rglob("*.swift")
    )
    has_icloud_entitlement = any(
        "icloud" in file.read_text(encoding="utf-8").lower()
        for file in project_root.rglob("*.entitlements")
    )
    return has_cloudkit_source or has_icloud_entitlement


def validate_swiftdata_boundary(project_root: Path) -> list[str]:
    data_controller = project_root / "MindBudget/Data/DataController.swift"
    text = data_controller.read_text(encoding="utf-8")
    errors: list[str] = []
    if ".automatic" in text or "CloudKitDatabase.private" in text:
        errors.append("DataController must never opt the primary local store into managed CloudKit sync")
    if requires_cloudkit_hardening(project_root):
        configurations = text.count("ModelConfiguration(")
        explicit_none = text.count("cloudKitDatabase: .none")
        if configurations == 0 or explicit_none != configurations:
            errors.append(
                "CloudKit capability/import requires every DataController ModelConfiguration to explicitly use cloudKitDatabase: .none"
            )
    return errors


def self_test() -> None:
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        contract = root / "contract.md"
        contract.write_text(
            "\n".join(f"## {section}" for section in sorted(REQUIRED_SECTIONS))
            + "\n"
            + "\n".join(
                f"| {key} | {' '.join(REQUIRED_DECLARATION_TOKENS[key])} |"
                for key in sorted(REQUIRED_DECLARATIONS)
            ),
            encoding="utf-8",
        )
        if validate_contract(contract):
            raise AssertionError("valid contract fixture rejected")
        contract.write_text("## Status\n", encoding="utf-8")
        if not validate_contract(contract):
            raise AssertionError("missing contract sections were accepted")

        data = root / "MindBudget/Data"
        data.mkdir(parents=True)
        (data / "DataController.swift").write_text(
            "ModelConfiguration(\n cloudKitDatabase: .none\n)\n",
            encoding="utf-8",
        )
        (root / "MindBudget/Sync.swift").write_text("import CloudKit\n", encoding="utf-8")
        if validate_swiftdata_boundary(root):
            raise AssertionError("explicit .none fixture rejected")
        (data / "DataController.swift").write_text("ModelConfiguration()\n", encoding="utf-8")
        if not validate_swiftdata_boundary(root):
            raise AssertionError("implicit managed-sync fixture accepted")
        (data / "DataController.swift").write_text(
            "ModelConfiguration(\n cloudKitDatabase: .none\n)\nModelConfiguration()\n",
            encoding="utf-8",
        )
        if not validate_swiftdata_boundary(root):
            raise AssertionError("partial explicit-.none fixture accepted")
        (root / "MindBudget/Sync.swift").unlink()
        (root / "MindBudget/App.entitlements").write_text(
            "<key>com.apple.developer.icloud-container-identifiers</key>\n",
            encoding="utf-8",
        )
        (data / "DataController.swift").write_text(
            "ModelConfiguration(\n cloudKitDatabase: .none\n)\n",
            encoding="utf-8",
        )
        if validate_swiftdata_boundary(root):
            raise AssertionError("iCloud-entitlement explicit-.none fixture rejected")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--contract", type=Path, default=Path("Docs/Commercialization/ICLOUD_SYNC_CONTRACT.md"))
    parser.add_argument("--project-root", type=Path, default=Path("."))
    args = parser.parse_args()
    if args.self_test:
        self_test()
        return 0
    errors = validate_contract(args.contract)
    errors.extend(validate_swiftdata_boundary(args.project_root))
    if errors:
        raise SystemExit("\n".join(errors))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
