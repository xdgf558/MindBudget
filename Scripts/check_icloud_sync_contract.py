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
    "C4B-02 prerequisite decisions",
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
    "Record identity": ("uuid", "<type>/<uuid>", "signed base-10 calendar year", "caller strings are rejected"),
    "Envelope": ("schemaversion", "encrypted", "revision 1", "absent parent digest"),
    "Ordering": ("change tag", "semantic digest", "last accepted semantic digest"),
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


def requires_cloudkit_hardening(
    project_root: Path,
    swift_sources: dict[Path, str] | None = None,
) -> bool:
    if swift_sources is None:
        source = project_root / "MindBudget"
        swift_sources = {
            file: file.read_text(encoding="utf-8")
            for file in source.rglob("*.swift")
        }
    has_cloudkit_source = any(
        "import CloudKit" in text or "CKContainer" in text
        for text in swift_sources.values()
    )
    has_icloud_entitlement = any(
        "icloud" in file.read_text(encoding="utf-8").lower()
        for file in project_root.rglob("*.entitlements")
    )
    return has_cloudkit_source or has_icloud_entitlement


def validate_swiftdata_boundary(project_root: Path) -> list[str]:
    data_controller = project_root / "MindBudget/Data/DataController.swift"
    errors: list[str] = []
    if not data_controller.is_file():
        return [f"{data_controller}: missing primary SwiftData construction owner"]

    source = project_root / "MindBudget"
    swift_sources = {
        file: file.read_text(encoding="utf-8")
        for file in source.rglob("*.swift")
    }
    normalized_sources = {
        file: re.sub(r"\s+", "", text)
        for file, text in swift_sources.items()
    }

    for file, normalized in normalized_sources.items():
        if (
            "cloudKitDatabase:.automatic" in normalized
            or "cloudKitDatabase:.private" in normalized
            or "CloudKitDatabase.private" in normalized
        ):
            errors.append(
                f"{file}: primary local SwiftData must never opt into managed CloudKit sync"
            )

    if not requires_cloudkit_hardening(project_root, swift_sources):
        return errors

    total_configurations = 0
    for file, normalized in normalized_sources.items():
        configurations = normalized.count("ModelConfiguration(")
        explicit_none = normalized.count("cloudKitDatabase:.none")
        total_configurations += configurations
        if configurations != explicit_none:
            errors.append(
                f"{file}: CloudKit capability/import requires every ModelConfiguration "
                "to explicitly use cloudKitDatabase: .none"
            )

        if file != data_controller and "ModelContainer(" in normalized:
            errors.append(
                f"{file}: production ModelContainer construction must remain centralized in DataController"
            )

    if total_configurations == 0:
        errors.append("CloudKit capability/import found no explicit primary ModelConfiguration")
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
        data_controller = data / "DataController.swift"
        data_controller.write_text(
            "ModelConfiguration(\n cloudKitDatabase:.none\n)\nModelContainer(for: Schema.self)\n",
            encoding="utf-8",
        )
        (root / "MindBudget/Sync.swift").write_text("import CloudKit\n", encoding="utf-8")
        if validate_swiftdata_boundary(root):
            raise AssertionError("explicit .none fixture rejected")
        data_controller.write_text("ModelConfiguration()\n", encoding="utf-8")
        if not validate_swiftdata_boundary(root):
            raise AssertionError("implicit managed-sync fixture accepted")
        data_controller.write_text(
            "ModelConfiguration(\n cloudKitDatabase: .none\n)\nModelConfiguration()\n",
            encoding="utf-8",
        )
        if not validate_swiftdata_boundary(root):
            raise AssertionError("partial explicit-.none fixture accepted")

        data_controller.write_text(
            "ModelConfiguration(cloudKitDatabase: .automatic)\n",
            encoding="utf-8",
        )
        if not validate_swiftdata_boundary(root):
            raise AssertionError("managed .automatic fixture accepted")

        data_controller.write_text(
            "ModelConfiguration(cloudKitDatabase: CloudKitDatabase.private(\"unsafe\"))\n",
            encoding="utf-8",
        )
        if not validate_swiftdata_boundary(root):
            raise AssertionError("managed private-database fixture accepted")

        data_controller.write_text(
            "ModelConfiguration(cloudKitDatabase:.none)\nModelContainer(for: Schema.self)\n",
            encoding="utf-8",
        )
        (root / "MindBudget/AlternateStore.swift").write_text(
            "ModelConfiguration()\nModelContainer(for: AlternateSchema.self)\n",
            encoding="utf-8",
        )
        if not validate_swiftdata_boundary(root):
            raise AssertionError("alternate production SwiftData construction fixture accepted")
        (root / "MindBudget/AlternateStore.swift").unlink()

        (root / "MindBudget/Sync.swift").unlink()
        (root / "MindBudget/App.entitlements").write_text(
            "<key>com.apple.developer.icloud-container-identifiers</key>\n",
            encoding="utf-8",
        )
        data_controller.write_text(
            "ModelConfiguration(\n cloudKitDatabase: .none\n)\nModelContainer(for: Schema.self)\n",
            encoding="utf-8",
        )
        if validate_swiftdata_boundary(root):
            raise AssertionError("iCloud-entitlement explicit-.none fixture rejected")

        data_controller.unlink()
        missing_errors = validate_swiftdata_boundary(root)
        if not missing_errors or "missing primary SwiftData construction owner" not in missing_errors[0]:
            raise AssertionError("missing DataController did not fail with a closed diagnostic")


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
