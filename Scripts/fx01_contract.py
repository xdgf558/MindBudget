#!/usr/bin/env python3
"""Validate the fail-closed FX-01 phase and source-boundary contract."""

from __future__ import annotations

import argparse
import copy
import json
import re
import tempfile
from pathlib import Path
from typing import Any


ROOT_KEYS = frozenset(
    {
        "schemaVersion",
        "phase",
        "accountingAuthority",
        "manualBoundary",
        "moneyBoundary",
        "sourceBoundary",
        "evidenceBoundary",
    }
)
PHASE_KEYS = frozenset(
    {
        "id",
        "status",
        "activeSubphase",
        "nextSubphase",
        "nextSubphaseEntered",
        "deferredPhases",
    }
)
ACCOUNTING_KEYS = frozenset(
    {
        "model",
        "persistedFields",
        "foreignMetadataStorage",
        "historyRevaluationAllowed",
    }
)
MANUAL_KEYS = frozenset(
    {
        "rateMode",
        "automaticRateProviderAllowed",
        "locationOrCountryInferenceAllowed",
        "newNetworkDomains",
    }
)
MONEY_KEYS = frozenset(
    {
        "storageType",
        "rateRepresentation",
        "rounding",
        "floatingPointTypesAllowed",
    }
)
SOURCE_KEYS = frozenset(
    {
        "expenseModel",
        "writeAuthority",
        "floatingPointExceptions",
        "networkExceptions",
    }
)
EVIDENCE_KEYS = frozenset(
    {
        "kind",
        "runtimeEvidenceClaimed",
        "schemaV7EvidenceClaimed",
    }
)

EXPECTED_PHASE = {
    "id": "FX-01",
    "status": "IN_PROGRESS",
    "activeSubphase": "FX-01A",
    "nextSubphase": "FX-01B",
    "nextSubphaseEntered": False,
    "deferredPhases": ["FX-02", "COM-C12"],
}
EXPECTED_ACCOUNTING_AUTHORITY = {
    "model": "Expense",
    "persistedFields": ["amountMinorUnits", "currencyCode"],
    "foreignMetadataStorage": "separateCompanion",
    "historyRevaluationAllowed": False,
}
EXPECTED_MANUAL_BOUNDARY = {
    "rateMode": "manualOnly",
    "automaticRateProviderAllowed": False,
    "locationOrCountryInferenceAllowed": False,
    "newNetworkDomains": [],
}
EXPECTED_MONEY_BOUNDARY = {
    "storageType": "Int64",
    "rateRepresentation": "reducedPositiveRational",
    "rounding": "roundHalfToEven",
    "floatingPointTypesAllowed": [],
}
EXPECTED_SOURCE_BOUNDARY = {
    "expenseModel": "MindBudget/Models/Expense.swift",
    "writeAuthority": "MindBudget/Data/DataActor.swift",
    "floatingPointExceptions": [
        "MindBudget/AppIntents/IntentMoneyTransport.swift",
        "MindBudget/Services/ReceiptRecognition/ReceiptGeometry.swift",
        "MindBudget/Services/ReceiptRecognition/ReceiptVisionObservation.swift",
    ],
    "networkExceptions": [
        "MindBudget/Commerce/PublicConfigurationTransport.swift",
        "MindBudget/Services/TelemetryTransport.swift",
    ],
}
EXPECTED_EVIDENCE_BOUNDARY = {
    "kind": "staticContractOnly",
    "runtimeEvidenceClaimed": False,
    "schemaV7EvidenceClaimed": False,
}

EXPECTED_PLAN_STATUS = (
    "FX-01A contract gate implemented; FX-01B remains unentered pending independent review, "
    "exact-head hosted CI, and merge."
)
EXPECTED_PLAN_STATUS_MARKDOWN = (
    "Status: **FX-01A contract gate implemented; FX-01B remains unentered pending independent "
    "review,\nexact-head hosted CI, and merge.**"
)
EXPECTED_TASK_STATUS = (
    "In Progress — FX-01A contract gate implemented; FX-01B unentered pending review/CI/merge"
)
PLAN_HEADING = "# FX-01 Manual Foreign-Currency Expense Plan"
TASK_HEADING = "## FX-01 — Manual foreign-currency expense recording"

EXPECTED_EXPENSE_PROPERTIES = (
    ("id", "UUID"),
    ("amountMinorUnits", "Int64"),
    ("currencyCode", "String"),
    ("categoryRaw", "String"),
    ("bucketRaw", "String"),
    ("merchantName", "String?"),
    ("normalizedMerchantName", "String?"),
    ("note", "String?"),
    ("spentAt", "Date"),
    ("spentTimeZoneIdentifier", "String"),
    ("createdAt", "Date"),
    ("updatedAt", "Date"),
    ("paymentMethodRaw", "String?"),
    ("emotionTagRaw", "String?"),
    ("purchaseReasonRaw", "String?"),
    ("isPlanned", "Bool"),
    ("isRecurring", "Bool"),
    ("sourceRaw", "String"),
    ("allowMerchantIndexing", "Bool"),
)
REQUIRED_WRITE_AUTHORITY_ANCHORS = {
    "func updateExpense(id: UUID, with draft: ExpenseDraft)": (
        "try validateAccountingCurrency(draft.amount.currencyCode)",
        "expense.amountMinorUnits = draft.amount.minorUnits",
        "expense.currencyCode = draft.amount.currencyCode",
    ),
    "private func insertExpense(_ draft: ExpenseDraft)": (
        "try validateAccountingCurrency(draft.amount.currencyCode)",
        "amountMinorUnits: draft.amount.minorUnits",
        "currencyCode: draft.amount.currencyCode",
        "modelContext.insert(expense)",
    ),
}
FX_IDENTIFIERS = (
    "ExpenseForeignCurrencyMetadata",
    "originalAmountMinorUnits",
    "originalCurrencyCode",
    "rateNumerator",
    "rateDenominator",
    "manualHomeAmountOverride",
    "ForeignCurrencyRateProvider",
)
FLOAT_PATTERN = re.compile(r"(^|[^A-Za-z0-9_])(Double|Float)([^A-Za-z0-9_]|$)")
NETWORK_PATTERN = re.compile(
    r"(^|[^A-Za-z0-9_])"
    r"(URLSession|URLRequest|NSURLConnection|NWConnection|NWListener|NWBrowser|"
    r"CFHTTPMessage|CFHost|CFSocket|WKWebView)"
    r"([^A-Za-z0-9_]|$)|^[ \t]*import[ \t]+(Network|CFNetwork|WebKit)([ \t]|$)|"
    r"\"[^\"\n]*https?://",
    re.MULTILINE,
)
LOCATION_PATTERN = re.compile(
    r"(^|[^A-Za-z0-9_])(CoreLocation|CLLocation|CLGeocoder|CLLocationManager)"
    r"([^A-Za-z0-9_]|$)|NSLocation[A-Za-z]+UsageDescription|com\.apple\.developer\.location"
)
AUTOMATIC_RATE_PATTERN = re.compile(
    r"(^|[^A-Za-z0-9_])"
    r"(Automatic[A-Za-z0-9_]*(Exchange|Currency|FX)Rate|"
    r"(Exchange|Currency|FX)Rate(Provider|Service|Client|Transport|API))"
    r"([^A-Za-z0-9_]|$)"
)
PROPERTY_PATTERN = re.compile(
    r"^[ \t]+(?:@Attribute\([^)]*\)[ \t]+)?var[ \t]+"
    r"([A-Za-z_][A-Za-z0-9_]*)[ \t]*:[ \t]*([^\n={]+?)"
    r"[ \t]*(?:=|\{|$)",
    re.MULTILINE,
)


def _exact_keys(value: Any, expected: frozenset[str]) -> bool:
    return isinstance(value, dict) and frozenset(value.keys()) == expected


def _normalize_space(value: str) -> str:
    return " ".join(value.split())


def _status_after_heading(text: str, heading: str, *, bold: bool) -> str | None:
    marker = f"{heading}\n"
    if text.count(marker) != 1:
        return None
    remainder = text.split(marker, 1)[1]
    lines = remainder.splitlines()
    status_lines: list[str] = []
    for index, line in enumerate(lines):
        if line.startswith("Status:"):
            status_lines.append(line.removeprefix("Status:").strip())
            for continuation in lines[index + 1 :]:
                stripped = continuation.strip()
                if not stripped or stripped.startswith("#") or stripped.startswith("- "):
                    break
                status_lines.append(stripped)
            break
        if line.startswith("#"):
            break
    if not status_lines:
        return None
    status = _normalize_space(" ".join(status_lines))
    if bold:
        if not status.startswith("**") or not status.endswith("**"):
            return None
        status = status[2:-2]
    return status


def _section(text: str, heading: str, next_heading_prefix: str) -> str | None:
    marker = f"{heading}\n"
    if text.count(marker) != 1:
        return None
    remainder = text.split(marker, 1)[1]
    lines: list[str] = []
    for line in remainder.splitlines():
        if line.startswith(next_heading_prefix):
            break
        lines.append(line)
    return "\n".join(lines)


def _noncomment_source(text: str) -> str:
    return "\n".join(
        line for line in text.splitlines() if not line.lstrip().startswith("//")
    )


def _function_region(text: str, declaration: str) -> str | None:
    marker = f"    {declaration}"
    if text.count(marker) != 1:
        return None
    start = text.index(marker)
    later_function = re.search(r"^    (?:private )?func\s", text[start + len(marker) :], re.MULTILINE)
    if later_function is None:
        return text[start:]
    end = start + len(marker) + later_function.start()
    return text[start:end]


def load_contract(path: Path) -> Any:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeDecodeError, json.JSONDecodeError) as error:
        raise ValueError(f"unable to read strict FX-01 contract JSON: {error}") from error


def validate_contract_data(data: Any) -> list[str]:
    if not _exact_keys(data, ROOT_KEYS):
        return ["root object must contain exactly the reviewed FX-01 contract keys"]

    errors: list[str] = []
    nested_contracts = (
        ("phase", PHASE_KEYS, EXPECTED_PHASE),
        ("accountingAuthority", ACCOUNTING_KEYS, EXPECTED_ACCOUNTING_AUTHORITY),
        ("manualBoundary", MANUAL_KEYS, EXPECTED_MANUAL_BOUNDARY),
        ("moneyBoundary", MONEY_KEYS, EXPECTED_MONEY_BOUNDARY),
        ("sourceBoundary", SOURCE_KEYS, EXPECTED_SOURCE_BOUNDARY),
        ("evidenceBoundary", EVIDENCE_KEYS, EXPECTED_EVIDENCE_BOUNDARY),
    )
    if data["schemaVersion"] != 1:
        errors.append("schemaVersion must be exactly 1")
    for key, expected_keys, expected_value in nested_contracts:
        if not _exact_keys(data[key], expected_keys):
            errors.append(f"{key} must contain exactly the reviewed keys")
        elif data[key] != expected_value:
            errors.append(f"{key} drifted from the reviewed FX-01A boundary")
    return errors


def validate_project(data: Any, project_root: Path) -> list[str]:
    errors = validate_contract_data(data)
    if errors:
        return errors

    plan_path = project_root / "Docs/FX_01_MANUAL_CURRENCY_PLAN.md"
    tasks_path = project_root / "Docs/TASKS.md"
    for path in (plan_path, tasks_path):
        if not path.is_file():
            errors.append(f"missing FX-01 phase artifact: {path.relative_to(project_root)}")
    if errors:
        return errors

    plan_text = plan_path.read_text(encoding="utf-8")
    tasks_text = tasks_path.read_text(encoding="utf-8")
    if _status_after_heading(plan_text, PLAN_HEADING, bold=True) != EXPECTED_PLAN_STATUS:
        errors.append("FX-01 plan Status must identify the exact FX-01A candidate boundary")
    if _status_after_heading(tasks_text, TASK_HEADING, bold=False) != EXPECTED_TASK_STATUS:
        errors.append("TASKS FX-01 Status must identify the exact FX-01A candidate boundary")

    fx01a = _section(plan_text, "### FX-01A — Entry and contract lock", "### ")
    if fx01a is None:
        errors.append("FX-01A checklist section is missing or duplicated")
    else:
        normalized = _normalize_space(fx01a)
        required_task = _normalize_space(
            "- [x] At implementation start, add a fail-closed FX-01 contract gate that protects "
            "the active phase, accounting-authority fields, manual-only/no-domain boundary, and "
            "no-`Double` rule without claiming runtime evidence from prose."
        )
        if normalized.count(required_task) != 1:
            errors.append("FX-01A contract-gate task must be checked exactly once")

    fx01b = _section(plan_text, "### FX-01B — Integer conversion and Schema V7", "### ")
    if fx01b is None:
        errors.append("FX-01B checklist section is missing or duplicated")
    elif re.search(r"^- \[[xX]\]", fx01b, re.MULTILINE):
        errors.append("FX-01B must remain unentered while the FX-01A candidate is under review")

    source_boundary = data["sourceBoundary"]
    expense_path = project_root / source_boundary["expenseModel"]
    data_actor_path = project_root / source_boundary["writeAuthority"]
    for path in (expense_path, data_actor_path):
        if not path.is_file():
            errors.append(f"missing FX-01 source authority: {path.relative_to(project_root)}")
    if errors:
        return errors

    expense_text = expense_path.read_text(encoding="utf-8")
    if not re.search(r"@Model\s+final class Expense\s*\{", expense_text):
        errors.append("Expense must remain the reviewed SwiftData accounting model")
    observed_properties = tuple(
        (name, _normalize_space(type_name))
        for name, type_name in PROPERTY_PATTERN.findall(expense_text)
    )
    if observed_properties != EXPECTED_EXPENSE_PROPERTIES:
        errors.append(
            "Expense stored-property inventory drifted; FX metadata must use a separate companion"
        )

    data_actor_text = data_actor_path.read_text(encoding="utf-8")
    for declaration, anchors in REQUIRED_WRITE_AUTHORITY_ANCHORS.items():
        region = _function_region(data_actor_text, declaration)
        if region is None:
            errors.append(f"DataActor accounting-authority function drifted: {declaration}")
            continue
        for anchor in anchors:
            if region.count(anchor) != 1:
                errors.append(
                    f"DataActor accounting-authority anchor drifted in {declaration}: {anchor}"
                )

    floating_exceptions = set(source_boundary["floatingPointExceptions"])
    network_exceptions = set(source_boundary["networkExceptions"])
    for source_path in sorted((project_root / "MindBudget").rglob("*.swift")):
        relative = source_path.relative_to(project_root).as_posix()
        text = source_path.read_text(encoding="utf-8")
        code = _noncomment_source(text)
        if relative not in floating_exceptions and FLOAT_PATTERN.search(code):
            errors.append(f"floating-point type is forbidden outside reviewed exceptions: {relative}")
        if relative not in network_exceptions and NETWORK_PATTERN.search(code):
            errors.append(f"app-owned network primitive is forbidden outside reviewed exceptions: {relative}")
        if LOCATION_PATTERN.search(code):
            errors.append(f"location access is forbidden by the FX-01 contract: {relative}")
        if AUTOMATIC_RATE_PATTERN.search(code):
            errors.append(f"automatic rate-provider source is forbidden by the FX-01 contract: {relative}")
        if relative in floating_exceptions or relative in network_exceptions:
            for identifier in FX_IDENTIFIERS:
                if re.search(rf"\b{re.escape(identifier)}\b", code):
                    errors.append(
                        f"FX-01 code cannot hide in a pre-existing source exception: {relative}:{identifier}"
                    )

    configuration_patterns = ("*.plist", "*.entitlements", "*.xcconfig")
    configuration_paths = {
        path
        for pattern in configuration_patterns
        for path in project_root.rglob(pattern)
        if ".git" not in path.parts and "Docs" not in path.parts
    }
    project_file = project_root / "MindBudget.xcodeproj/project.pbxproj"
    if project_file.is_file():
        configuration_paths.add(project_file)
    for configuration_path in sorted(configuration_paths):
        text = configuration_path.read_text(encoding="utf-8")
        if LOCATION_PATTERN.search(text):
            relative = configuration_path.relative_to(project_root).as_posix()
            errors.append(f"location configuration is forbidden by the FX-01 contract: {relative}")
    return errors


def fail_if_invalid(data: Any, project_root: Path) -> None:
    errors = validate_project(data, project_root)
    if errors:
        raise ValueError("\n".join(errors))


def _write_fixture(project_root: Path, source_root: Path, data: Any) -> None:
    required = (
        "Docs/FX_01_MANUAL_CURRENCY_PLAN.md",
        "Docs/TASKS.md",
        "MindBudget/Models/Expense.swift",
        "MindBudget/Data/DataActor.swift",
    )
    for relative in required:
        destination = project_root / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_text((source_root / relative).read_text(encoding="utf-8"), encoding="utf-8")
    contract_path = project_root / "Docs/FX_01_CONTRACT.json"
    contract_path.write_text(json.dumps(data), encoding="utf-8")


def _require_rejection(description: str, data: Any, project_root: Path) -> None:
    if not validate_project(data, project_root):
        raise RuntimeError(f"FX-01 self-test failed to reject {description}")


def run_self_test(data: Any, project_root: Path) -> None:
    fail_if_invalid(data, project_root)

    mutations: list[tuple[str, Any]] = []
    entered_b = copy.deepcopy(data)
    entered_b["phase"]["nextSubphaseEntered"] = True
    mutations.append(("premature FX-01B entry", entered_b))

    new_domain = copy.deepcopy(data)
    new_domain["manualBoundary"]["newNetworkDomains"] = ["rates.example.invalid"]
    mutations.append(("an FX network domain", new_domain))

    revalue_history = copy.deepcopy(data)
    revalue_history["accountingAuthority"]["historyRevaluationAllowed"] = True
    mutations.append(("historical revaluation", revalue_history))

    runtime_claim = copy.deepcopy(data)
    runtime_claim["evidenceBoundary"]["runtimeEvidenceClaimed"] = True
    mutations.append(("a prose-backed runtime claim", runtime_claim))

    unknown_key = copy.deepcopy(data)
    unknown_key["manualBoundary"]["fallbackProvider"] = "silent"
    mutations.append(("an unknown contract key", unknown_key))

    for description, mutation in mutations:
        if not validate_contract_data(mutation):
            raise RuntimeError(f"FX-01 self-test failed to reject {description}")

    with tempfile.TemporaryDirectory(prefix="mindbudget-fx01-contract-") as temporary:
        fixture_root = Path(temporary)
        _write_fixture(fixture_root, project_root, data)

        tasks_path = fixture_root / "Docs/TASKS.md"
        tasks_text = tasks_path.read_text(encoding="utf-8")
        tasks_path.write_text(
            "Summary: In Progress — FX-01A contract gate implemented; FX-01B unentered pending "
            "review/CI/merge\n\n"
            + tasks_text.replace(EXPECTED_TASK_STATUS, "Done", 1),
            encoding="utf-8",
        )
        _require_rejection("summary prose masking a wrong FX-01 section", data, fixture_root)
        _write_fixture(fixture_root, project_root, data)

        plan_path = fixture_root / "Docs/FX_01_MANUAL_CURRENCY_PLAN.md"
        plan_text = plan_path.read_text(encoding="utf-8")
        plan_path.write_text(
            f"Summary: {EXPECTED_PLAN_STATUS}\n\n"
            + plan_text.replace(EXPECTED_PLAN_STATUS_MARKDOWN, "Status: **Done**", 1),
            encoding="utf-8",
        )
        _require_rejection("summary prose masking a wrong FX-01 plan status", data, fixture_root)
        _write_fixture(fixture_root, project_root, data)

        plan_path = fixture_root / "Docs/FX_01_MANUAL_CURRENCY_PLAN.md"
        plan_path.write_text(
            plan_path.read_text(encoding="utf-8").replace(
                "### FX-01B — Integer conversion and Schema V7\n\n- [ ]",
                "### FX-01B — Integer conversion and Schema V7\n\n- [x]",
                1,
            ),
            encoding="utf-8",
        )
        _require_rejection("a checked FX-01B implementation task", data, fixture_root)
        _write_fixture(fixture_root, project_root, data)

        expense_path = fixture_root / EXPECTED_SOURCE_BOUNDARY["expenseModel"]
        expense_path.write_text(
            expense_path.read_text(encoding="utf-8").replace(
                "    var categoryRaw: String",
                "    var originalAmountMinorUnits: Int64\n    var categoryRaw: String",
                1,
            ),
            encoding="utf-8",
        )
        _require_rejection("FX metadata embedded in Expense", data, fixture_root)
        _write_fixture(fixture_root, project_root, data)

        data_actor_path = fixture_root / EXPECTED_SOURCE_BOUNDARY["writeAuthority"]
        data_actor_path.write_text(
            data_actor_path.read_text(encoding="utf-8").replace(
                "currencyCode: draft.amount.currencyCode,",
                "currencyCode: settings.currencyCode,",
                1,
            ),
            encoding="utf-8",
        )
        _require_rejection("the create accounting-currency authority drifting", data, fixture_root)
        _write_fixture(fixture_root, project_root, data)

        bad_math = fixture_root / "MindBudget/Domain/ForeignCurrency/BadMath.swift"
        bad_math.parent.mkdir(parents=True, exist_ok=True)
        bad_math.write_text("struct BadRate { let value: Double }\n", encoding="utf-8")
        _require_rejection("floating-point FX arithmetic", data, fixture_root)
        bad_math.unlink()

        bad_network = fixture_root / "MindBudget/Domain/ForeignCurrency/RemoteRate.swift"
        bad_network.write_text(
            'let endpoint = "https://rates.example.invalid/latest"\nlet session = URLSession.shared\n',
            encoding="utf-8",
        )
        _require_rejection("automatic FX network code", data, fixture_root)
        bad_network.unlink()

        bad_location = fixture_root / "MindBudget/Domain/ForeignCurrency/LocationCurrency.swift"
        bad_location.write_text(
            "import CoreLocation\nlet manager = CLLocationManager()\n",
            encoding="utf-8",
        )
        _require_rejection("location-derived currency source", data, fixture_root)
        bad_location.unlink()

        bad_provider = fixture_root / "MindBudget/Domain/ForeignCurrency/AutomaticRate.swift"
        bad_provider.write_text("struct ExchangeRateProvider {}\n", encoding="utf-8")
        _require_rejection("an automatic rate provider", data, fixture_root)
        bad_provider.unlink()

        exception_path = fixture_root / EXPECTED_SOURCE_BOUNDARY["floatingPointExceptions"][0]
        exception_path.parent.mkdir(parents=True, exist_ok=True)
        exception_path.write_text(
            "struct ExpenseForeignCurrencyMetadata { let rateNumerator: Double }\n",
            encoding="utf-8",
        )
        _require_rejection("FX code hidden in a floating-point exception", data, fixture_root)


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--contract", default="Docs/FX_01_CONTRACT.json")
    parser.add_argument("--self-test", action="store_true")
    return parser.parse_args()


def main() -> int:
    arguments = parse_arguments()
    project_root = Path(__file__).resolve().parent.parent
    try:
        data = load_contract(project_root / arguments.contract)
        if arguments.self_test:
            run_self_test(data, project_root)
            print("FX-01 contract self-test passed")
        else:
            fail_if_invalid(data, project_root)
            print("FX-01 static contract passed; no runtime or Schema V7 evidence is claimed")
    except (OSError, UnicodeDecodeError, ValueError, RuntimeError) as error:
        print(f"FX-01 contract validation failed: {error}")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
