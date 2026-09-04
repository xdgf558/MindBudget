#!/usr/bin/env python3
"""Validate the fail-closed FX-01 phase and source-boundary contract."""

from __future__ import annotations

import argparse
import copy
import json
import re
import subprocess
import sys
import tempfile
import time
from pathlib import Path
from typing import Any


ROOT_KEYS = frozenset(
    {
        "schemaVersion",
        "phase",
        "deliveryEvidence",
        "implementationEvidence",
        "accountingAuthority",
        "manualBoundary",
        "moneyBoundary",
        "sourceBoundary",
        "evidenceBoundary",
        "decimalRateContract",
        "syncCompanionContract",
    }
)
PHASE_KEYS = frozenset(
    {
        "id",
        "status",
        "activeSubphase",
        "activeSubphaseStatus",
        "closeoutStatus",
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
    "activeSubphase": "FX-01B",
    "activeSubphaseStatus": "DONE",
    "closeoutStatus": "PENDING_REVIEW_CI_MERGE",
    "nextSubphase": "FX-01C",
    "nextSubphaseEntered": False,
    "deferredPhases": ["FX-02", "COM-C12"],
}
EXPECTED_DELIVERY_EVIDENCE = {
    "pullRequest": 110,
    "reviewedHead": "4554d0e21c714e44d2e5dec91d6026ae3cf7a7bf",
    "hostedRun": "33823593637",
    "mergeCommit": "9322e3bc8da59d5ea5b6d067d66fae879404b642",
    "retainedNonPassRun": "33772144343",
    "acceptedRunFailedToPassedObserved": False,
}
EXPECTED_ACCOUNTING_AUTHORITY = {
    "model": "Expense",
    "persistedFields": ["amountMinorUnits", "currencyCode"],
    "foreignMetadataStorage": "separateCompanion",
    "historyRevaluationAllowed": False,
}
EXPECTED_IMPLEMENTATION_EVIDENCE = {
    "pullRequest": 112,
    "reviewKind": "ownerAuthorizedIndependentAgent",
    "reviewedHead": "a24cfa1f296defd1fb17f4a815bd8caa10039117",
    "hostedRun": "33841868078",
    "hostedAttempt": 1,
    "testedSyntheticMerge": "ea6a17f91ccc50cd135537a22d47f15dc54c4d42",
    "reviewedAndTestedTree": "1ac571400f2241c2f987b2fdab2ea71e318cf9f4",
    "mergeCommit": "2e49acdc62bef9aac89b12b4c483f3d12008f5ac",
    "casePassed": 575,
    "caseSkipped": 14,
    "concretePassed": 584,
    "concreteSkipped": 14,
    "requiredFXMethodsPassedExactlyOnce": 17,
    "acceptedRunExtraAttempts": 0,
    "acceptedRunFailedToPassedObserved": False,
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
EXPECTED_DECIMAL_RATE = {
    "maximumIntegerDigits": 10,
    "maximumFractionalInputDigits": 12,
    "storedDecimalPlaces": 8,
    "normalization": "roundHalfToEvenThenReduce",
    "orientation": "accountingMajorPerOriginalMajor",
}
EXPECTED_SYNC_COMPANION = {
    "implementationPhase": "FX-01D",
    "entityType": "expenseForeignCurrencyMetadata",
    "futureEntityCount": 13,
    "positionAfter": "expense",
    "expensePayloadUnchanged": True,
    "coordinatedContract": "Docs/Commercialization/ICLOUD_SYNC_CONTRACT.md",
}

EXPECTED_PLAN_STATUS = (
    "FX-01 In Progress; FX-01A and FX-01B Done; B closeout pending review/CI/merge; FX-01C unentered."
)
EXPECTED_PLAN_STATUS_MARKDOWN = (
    f"Status: **{EXPECTED_PLAN_STATUS}**"
)
EXPECTED_TASK_STATUS = (
    "In Progress — FX-01B Done; B closeout pending review/CI/merge; FX-01C unentered"
)
PLAN_HEADING = "# FX-01 Manual Foreign-Currency Expense Plan"
TASK_HEADING = "## FX-01 — Manual foreign-currency expense recording"
SUBPHASE_HEADINGS = (
    "### FX-01A — Entry and contract lock",
    "### FX-01B — Integer conversion and Schema V7",
    "### FX-01C — Pro entry, form, detail, and edit behavior",
    "### FX-01D — Consumers, CSV, optional sync, and privacy",
    "### FX-01E — Release evidence and closeout",
)
SUBPHASE_TASK_COUNTS = (3, 4, 4, 4, 3)
DONE_STATUS = "Done — merged static contract-gate delivery only."
BLOCKED_STATUS = "Blocked — unentered."
IMPLEMENTATION_DONE_STATUS = "Done — reviewed, hosted-green, merged integer conversion and Schema V7 only."
CLOSEOUT_STATUS = "Owner merged with hosted non-pass retained; no independent rereview claimed."
CLOSEOUT_TASK = (
    "- [ ] Independently review, pass exact-head hosted CI, and merge this separate FX-01A closeout."
)
BEFORE_B_TASK = (
    "- [x] Before FX-01B implementation, extend the JSON and negative gate for eight-place decimal "
    "normalization and the thirteenth iCloud companion contract, preserving the `.expense` payload "
    "and requiring `ICLOUD_SYNC_CONTRACT.md` to change with implementation."
)
OWNER_ENTRY_BOUNDARY = (
    "FX-01B has a separate owner entry; FX-01C remains unentered."
)
CLOSEOUT_SECTIONS = {
    relative: "## 2026-09-04 — FX-01B owner entry"
    for relative in (
        "Docs/FX_01_MANUAL_CURRENCY_PLAN.md", "Docs/TASKS.md", "Docs/PROJECT_MEMORY.md",
        "Docs/DECISIONS.md", "Docs/SESSION_LOG.md", "Docs/TEST_PLAN.md",
    )
}
CLOSEOUT_ANCHORS = (
    "PR #111", "`33b8009`", "`33834027746`", "`34ac3f3`",
    "Hosted failure is retained as non-pass, not a green result or independent rereview.", OWNER_ENTRY_BOUNDARY,
)
B_CLOSEOUT_HEADING = "## 2026-09-04 — FX-01B post-merge closeout"
B_CLOSEOUT_DOCUMENTS = (*CLOSEOUT_SECTIONS, "Docs/FX_01B_IMPLEMENTATION_EVIDENCE.md")
B_PACKET_STATUS = "FX-01B delivery accepted; separate closeout pending independent review, hosted CI and merge."
B_CLOSEOUT_TASK = "- [ ] Independently review, pass exact-head hosted CI, and merge this separate FX-01B closeout before FX-01C entry."
B_CLOSEOUT_ANCHORS = (
    "PR #112", "`a24cfa1`", "`33841868078`", "`2e49acd`",
    "owner-authorized independent agent review", "second parent",
    "FX-01B is Done; FX-01 remains In Progress; FX-01C remains unentered.",
    "The 14 skips remain non-pass.", B_CLOSEOUT_TASK,
)
EXPECTED_TASKS_CHECKLIST = """
- [x] Record the owner-approved manual-only product contract in
  `Docs/FX_01_MANUAL_CURRENCY_PLAN.md`: explicit currency/rate entry, editable accounting result,
  save-time lock, no historical revaluation, detail/CSV dual amounts, no location, and no network.
- [x] Independently review, pass exact-head hosted CI, and merge the FX-01 planning package before
  changing product code or Schema V7. Exact head `0619d5e` passed run `33758966855`; PR #108
  merged it as `f2f57b4` with that head as second parent. The separate closeout head `8de85e6`
  passed run `33763718952`, and PR #109 merged it as `69050da` with that head as second parent.
- [x] Add the machine-readable, self-testing FX-01A contract gate for the active phase, frozen
  `Expense` accounting authority, manual-only/no-domain boundary, whole-app no-floating-point
  rule, and static-evidence limitation. PR #110 completed the gate's review/CI/merge requirement.
- [ ] Independently review, pass exact-head hosted CI, and merge this separate FX-01A closeout.
- [x] Before FX-01B implementation, extend the JSON and negative gate for eight-place decimal
  normalization and the thirteenth iCloud companion contract, preserving the `.expense` payload
  and requiring `ICLOUD_SYNC_CONTRACT.md` to change with implementation.
- [ ] Keep the FX gate's C6 registry placement and the existing AX5 `boundBy: 0` Back selector as
  maintenance follow-ups in the plan, not reasons to enter C6 or claim new physical evidence.
- [x] Implement the pure checked integer-rational converter and deterministic bankers rounding;
  close rate text through an eight-fractional-place half-even normalization before reduction,
  prohibit `Double`/`Float`, and test ISO exponent, tie, overflow, direction, and invalid inputs.
- [x] Add Schema V7's optional one-to-one foreign-currency companion while preserving
  `Expense.amountMinorUnits`/`currencyCode` as the sole accounting authority; migrate V1–V6 with no
  inferred metadata and keep create/update/delete atomic. New rows use the current Settings
  currency; edits use only the row's persisted accounting currency.
- [ ] Add the local-Pro/manual-entry UI and central feature-access gate. The active 30-day local
  trial may create FX expenses; after access ends, existing FX records remain editable/exportable
  while new, converted, or duplicated FX records are denied. Consume the existing Pro snapshot;
  do not implement or mutate the trial clock in FX-01.
- [ ] Update detail, CSV, optional enabled-iCloud compatibility, deletion, localization, VoiceOver,
  AX5, and privacy boundaries. CSV exports the exact rate-date/time-zone tuple and blank FX fields
  for ordinary expenses and incomes. Enabled iCloud adds a separate thirteenth companion type
  without changing `.expense`; budgets, reminders, insights, Ask, and reports use only the locked
  accounting amount.
- [ ] Pass the dedicated negative gates and complete validation, independent review, hosted CI,
  merge, and a separate closeout before marking FX-01 Done. Do not enter COM-C12 or FX-02 from an
  FX-01 merge.
- [ ] Keep FX-02 automatic reference rates deferred behind a new owner entry and separate provider,
  privacy, cache/failure, network-egress, and release review.
"""

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
    # Only the heading's introduction may supply its Status; summary prose or a
    # nested section cannot. Also reject a second Status anywhere in that introduction.
    lines: list[str] = []
    for line in remainder.splitlines():
        if line.startswith("#"):
            break
        lines.append(line)
    if sum(line.startswith("Status:") for line in lines) != 1:
        return None
    status_lines: list[str] = []
    for index, line in enumerate(lines):
        if line.startswith("Status:"):
            status_lines.append(line.removeprefix("Status:").strip())
            for continuation in lines[index + 1 :]:
                stripped = continuation.strip()
                if not stripped or stripped.startswith(("#", "- ", "Status:")):
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
        # A higher-level heading also ends this section (not only a sibling).
        match = re.match(r"^(#+) ", line)
        if line.startswith(next_heading_prefix) or (
            match and len(match.group(1)) <= len(heading.split(" ", 1)[0])
        ):
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


def _unique_json_object(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"duplicate JSON key: {key}")
        result[key] = value
    return result


def _reject_json_constant(value: str) -> Any:
    raise ValueError(f"non-standard JSON constant: {value}")


def _checklist_items(section: str) -> list[str]:
    items: list[str] = []
    in_item = False
    for line in section.splitlines():
        # Canonical repo checklist only. Do not silently discard alternative
        # CommonMark list markers, indentation, blockquotes or inline checkboxes.
        task_like = re.match(r"^\s*(?:>\s*)*(?:[-+*]|[0-9]+[.)])\s*\[[^\]\r\n]*\]", line)
        checkbox_tokens = re.findall(r"\[\s*[xX]?\s*\]", line)
        canonical = re.match(r"^- \[(?:x| )\] \S", line)
        if (task_like or checkbox_tokens) and (canonical is None or len(checkbox_tokens) != 1):
            raise ValueError("non-canonical checkbox/list syntax in an authoritative FX checklist")
        if canonical:
            items.append(line)
            in_item = True
        elif in_item and line.startswith("  "):
            items[-1] += " " + line.strip()
        else:
            in_item = False
    return [_normalize_space(item) for item in items]


def load_contract(path: Path) -> Any:
    try:
        return json.loads(
            path.read_text(encoding="utf-8"), object_pairs_hook=_unique_json_object,
            parse_constant=_reject_json_constant,
        )
    except (OSError, UnicodeDecodeError, json.JSONDecodeError) as error:
        raise ValueError(f"unable to read strict FX-01 contract JSON: {error}") from error


def validate_contract_data(data: Any) -> list[str]:
    if not _exact_keys(data, ROOT_KEYS):
        return ["root object must contain exactly the reviewed FX-01 contract keys"]

    errors: list[str] = []
    nested_contracts = (
        ("phase", PHASE_KEYS, EXPECTED_PHASE),
        ("deliveryEvidence", frozenset(EXPECTED_DELIVERY_EVIDENCE), EXPECTED_DELIVERY_EVIDENCE),
        ("accountingAuthority", ACCOUNTING_KEYS, EXPECTED_ACCOUNTING_AUTHORITY),
        ("manualBoundary", MANUAL_KEYS, EXPECTED_MANUAL_BOUNDARY),
        ("moneyBoundary", MONEY_KEYS, EXPECTED_MONEY_BOUNDARY),
        ("sourceBoundary", SOURCE_KEYS, EXPECTED_SOURCE_BOUNDARY),
        ("evidenceBoundary", EVIDENCE_KEYS, EXPECTED_EVIDENCE_BOUNDARY),
        ("decimalRateContract", frozenset(EXPECTED_DECIMAL_RATE), EXPECTED_DECIMAL_RATE),
        ("syncCompanionContract", frozenset(EXPECTED_SYNC_COMPANION), EXPECTED_SYNC_COMPANION),
        ("implementationEvidence", frozenset(EXPECTED_IMPLEMENTATION_EVIDENCE), EXPECTED_IMPLEMENTATION_EVIDENCE),
    )
    if type(data["schemaVersion"]) is not int or data["schemaVersion"] != 4:
        errors.append("schemaVersion must be exactly 4")
    for key, expected_keys, expected_value in nested_contracts:
        if not _exact_keys(data[key], expected_keys):
            errors.append(f"{key} must contain exactly the reviewed keys")
        elif json.dumps(data[key], sort_keys=True) != json.dumps(expected_value, sort_keys=True):
            errors.append(f"{key} drifted from the active FX-01 boundary")
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
        errors.append("FX-01 plan must have one exact closeout Status before the next heading")
    if _status_after_heading(tasks_text, TASK_HEADING, bold=False) != EXPECTED_TASK_STATUS:
        errors.append("TASKS FX-01 must have one exact closeout Status in its own section")
    tasks_section = _section(tasks_text, TASK_HEADING, "## ") or ""
    try:
        if _checklist_items(tasks_section) != _checklist_items(EXPECTED_TASKS_CHECKLIST):
            errors.append("TASKS FX-01 must retain its complete ordered task text and reviewed checkbox states")
    except ValueError as error:
        errors.append(f"TASKS FX-01: {error}")

    for relative, heading in CLOSEOUT_SECTIONS.items():
        path = project_root / relative
        if not path.is_file():
            errors.append(f"missing closeout document: {relative}")
            continue
        section = _section(path.read_text(encoding="utf-8"), heading, "## ")
        if section is None:
            errors.append(f"missing or duplicate closeout section: {relative}:{heading}")
            continue
        for anchor in CLOSEOUT_ANCHORS:
            if anchor not in _normalize_space(section):
                errors.append(f"missing scoped closeout anchor: {relative}:{anchor}")

    for relative in B_CLOSEOUT_DOCUMENTS:
        path = project_root / relative
        if not path.is_file():
            errors.append(f"missing B closeout document: {relative}")
            continue
        b_section = _section(path.read_text(encoding="utf-8"), B_CLOSEOUT_HEADING, "## ")
        if b_section is None:
            errors.append(f"missing or duplicate B closeout section: {relative}")
        else:
            normalized_b = _normalize_space(b_section)
            for anchor in B_CLOSEOUT_ANCHORS:
                if normalized_b.count(anchor) != 1:
                    errors.append(f"missing/duplicate scoped B closeout anchor: {relative}:{anchor}")
            try:
                if _checklist_items(b_section) != [B_CLOSEOUT_TASK]:
                    errors.append(f"this separate B closeout must retain exactly one pending task: {relative}")
            except ValueError as error:
                errors.append(f"{relative} B closeout: {error}")
    packet_path = project_root / "Docs/FX_01B_IMPLEMENTATION_EVIDENCE.md"
    if packet_path.is_file():
        packet_status = _status_after_heading(
            packet_path.read_text(encoding="utf-8"), "# FX-01B implementation evidence", bold=True,
        )
        if packet_status != B_PACKET_STATUS:
            errors.append("B packet must have one exact current Status, not a pending implementation checkpoint")

    closeout_heading = "## FX-01A post-merge closeout"
    closeout = _section(plan_text, closeout_heading, "## ") or ""
    if _status_after_heading(plan_text, closeout_heading, bold=True) != CLOSEOUT_STATUS:
        errors.append("FX-01A closeout must retain the explicit owner exception and hosted non-pass")
    try:
        closeout_items = _checklist_items(closeout)
        if len(closeout_items) != 3 or any(not item.startswith("- [ ] ") for item in closeout_items):
            errors.append("the historical A closeout and its two maintenance follow-ups must remain unchecked")
    except ValueError as error:
        errors.append(f"A closeout: {error}")
    for relative, section in (
        ("plan closeout", closeout),
        ("TASKS FX-01", _section(tasks_text, TASK_HEADING, "## ") or ""),
    ):
        if _normalize_space(section).count(CLOSEOUT_TASK) != 1:
            errors.append(f"pending closeout task must occur exactly once: {relative}")
    for anchor in ("migration-and-rollback", "navigationBars.buttons.element(boundBy: 0)"):
        if anchor not in closeout:
            errors.append(f"retained PR #110 maintenance follow-up missing: {anchor}")

    for index, heading in enumerate(SUBPHASE_HEADINGS):
        expected_status = DONE_STATUS if index == 0 else IMPLEMENTATION_DONE_STATUS if index == 1 else BLOCKED_STATUS
        if _status_after_heading(plan_text, heading, bold=True) != expected_status:
            errors.append(f"subphase must have one exact scoped Status: {heading}")
        section = _section(plan_text, heading, "### ") or ""
        try:
            items = _checklist_items(section)
        except ValueError as error:
            errors.append(f"{heading}: {error}")
            continue
        markers = [item[3] for item in items]
        expected_markers = ["x" if index <= 1 else " "] * len(markers)
        if len(markers) != SUBPHASE_TASK_COUNTS[index] or markers != expected_markers:
            errors.append(f"subphase task inventory must be complete and {'checked' if index <= 1 else 'unchecked'}: {heading}")

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

    for relative, section in (
        ("plan FX-01B", _section(plan_text, SUBPHASE_HEADINGS[1], "### ") or ""),
        ("TASKS FX-01", _section(tasks_text, TASK_HEADING, "## ") or ""),
    ):
        if _normalize_space(section).count(BEFORE_B_TASK) != 1:
            errors.append(f"the completed pre-B machine-contract task must occur exactly once: {relative}")

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
        *B_CLOSEOUT_DOCUMENTS,
        "Scripts/fx01_contract.py",
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


CLI_TIMEOUT_SECONDS = 30


def _require_fixture_cli(project_root: Path, *, valid: bool, description: str) -> None:
    started = time.monotonic()
    try:
        result = subprocess.run(
            [sys.executable, "-B", str(project_root / "Scripts/fx01_contract.py")],
            cwd=project_root, capture_output=True, text=True,
            timeout=CLI_TIMEOUT_SECONDS, check=False,
        )
    except subprocess.TimeoutExpired as error:
        raise RuntimeError(
            f"FX-01 CLI self-test timed out: {description}; "
            f"deadline={CLI_TIMEOUT_SECONDS}s, elapsed={time.monotonic() - started:.2f}s; "
            "no validation verdict; timeout is non-pass"
        ) from error
    expected_code = 0 if valid else 1
    expected_message = "FX-01 static contract passed" if valid else "FX-01 contract validation failed:"
    if result.returncode != expected_code or expected_message not in result.stdout or result.stderr:
        raise RuntimeError(
            f"FX-01 CLI self-test did not {'accept' if valid else 'reject'} {description}; "
            f"exit={result.returncode}, expected={expected_code}, "
            f"verdict_present={expected_message in result.stdout}, stderr_present={bool(result.stderr)}"
        )


def run_cli_failure_self_test(project_root: Path) -> None:
    """Inject process failures, never replace the real mutation executions."""
    from unittest.mock import patch

    verdict = "FX-01 contract validation failed: injected invalid contract"
    for valid in (False, True):
        with patch.object(subprocess, "run", side_effect=subprocess.TimeoutExpired("fixture", 30)) as run:
            try:
                _require_fixture_cli(project_root, valid=valid, description="injected timeout")
            except RuntimeError as error:
                if "injected timeout" not in str(error) or "timeout is non-pass" not in str(error):
                    raise RuntimeError("FX-01 timeout diagnostic lost its mutation context") from error
            else:
                raise RuntimeError("FX-01 self-test accepted a process timeout")
            if run.call_count != 1 or run.call_args.kwargs.get("timeout") != 30:
                raise RuntimeError("FX-01 child deadline/retry policy drifted")

    for code, stdout, stderr in (
        (0, verdict, ""),                 # A negative test must not succeed.
        (-9, verdict, ""),                # A crash is not a contract rejection.
        (2, verdict, ""),                 # An unrelated CLI error is not a rejection.
        (1, "", ""),                     # Nonzero alone is insufficient.
        (1, verdict, "unexpected error"), # A stderr diagnostic invalidates the verdict.
    ):
        with patch.object(subprocess, "run", return_value=subprocess.CompletedProcess([], code, stdout, stderr)):
            try:
                _require_fixture_cli(project_root, valid=False, description="injected invalid verdict")
            except RuntimeError:
                pass
            else:
                raise RuntimeError("FX-01 self-test accepted an invalid process verdict")
    print("FX-01 CLI fault self-test rejected 7 timeout/invalid-verdict outcomes")


def run_closeout_self_test(data: Any, project_root: Path) -> None:
    """Mutate copied authoritative sections, then exercise the production CLI."""
    with tempfile.TemporaryDirectory(prefix="mindbudget-fx01-closeout-") as temporary:
        fixture = Path(temporary)
        _write_fixture(fixture, project_root, data)
        _require_fixture_cli(fixture, valid=True, description="the clean copied contract")
        mutation_count = 0

        def reject_section_change(relative: str, heading: str, old: str, new: str) -> None:
            nonlocal mutation_count
            path = fixture / relative
            original = (project_root / relative).read_text(encoding="utf-8")
            section = _section(original, heading, "### " if heading.startswith("### ") else "## ")
            if not section:
                raise RuntimeError(f"missing self-test source section: {relative}:{heading}")
            pattern = r"\s+".join(re.escape(part) for part in old.split())
            changed, count = re.subn(pattern, lambda _: new, section)
            if count < 1 or (old not in CLOSEOUT_ANCHORS and count != 1):
                raise RuntimeError(f"self-test mutation has an unexpected target count: {relative}:{old}")
            path.write_text(original.replace(section, changed, 1), encoding="utf-8")
            try:
                _require_fixture_cli(
                    fixture, valid=False,
                    description=f"mutation {mutation_count + 1}: {relative}:{heading}: {old} -> {new}",
                )
                mutation_count += 1
            finally:
                path.write_text(original, encoding="utf-8")

        # Another file or an older historical section must not satisfy a removed anchor.
        for relative, heading in CLOSEOUT_SECTIONS.items():
            for anchor in CLOSEOUT_ANCHORS:
                reject_section_change(relative, heading, anchor, "removed closeout obligation")
        for relative in B_CLOSEOUT_DOCUMENTS:
            for anchor in B_CLOSEOUT_ANCHORS:
                reject_section_change(relative, B_CLOSEOUT_HEADING, anchor, "removed B closeout obligation")
            reject_section_change(relative, B_CLOSEOUT_HEADING, B_CLOSEOUT_TASK, B_CLOSEOUT_TASK.replace("[ ]", "[x]"))
            reject_section_change(relative, B_CLOSEOUT_HEADING, B_CLOSEOUT_TASK, B_CLOSEOUT_TASK + "\n" + B_CLOSEOUT_TASK)
            reject_section_change(relative, B_CLOSEOUT_HEADING, B_CLOSEOUT_TASK,
                                  B_CLOSEOUT_TASK + "\n\n* [x] Premature closeout completion.")
        reject_section_change("Docs/FX_01B_IMPLEMENTATION_EVIDENCE.md", "# FX-01B implementation evidence",
                             f"Status: **{B_PACKET_STATUS}**", "Status: **Implementation pending.**")
        reject_section_change("Docs/FX_01B_IMPLEMENTATION_EVIDENCE.md", "# FX-01B implementation evidence",
                             f"Status: **{B_PACKET_STATUS}**", f"Status: **{B_PACKET_STATUS}**\n\nStatus: **{B_PACKET_STATUS}**")

        plan = "Docs/FX_01_MANUAL_CURRENCY_PLAN.md"
        for index, heading in enumerate(SUBPHASE_HEADINGS):
            status = DONE_STATUS if index == 0 else IMPLEMENTATION_DONE_STATUS if index == 1 else BLOCKED_STATUS
            reject_section_change(plan, heading, f"Status: **{status}**", "Status: **In Progress.**")
            reject_section_change(
                plan, heading, f"Status: **{status}**",
                f"Status: **{status}**\n\nStatus: **{status}**",
            )
        reject_section_change(
            plan, SUBPHASE_HEADINGS[0], "- [x] At implementation start, add", "- [ ] At implementation start, add",
        )
        for heading, first_task in (
            (SUBPHASE_HEADINGS[1], "- [x] Add the closed rate/source domain"),
            (SUBPHASE_HEADINGS[2], "- [ ] Add one exhaustive"),
            (SUBPHASE_HEADINGS[3], "- [ ] Prove budget, reminder, insight, Ask, Dashboard"),
            (SUBPHASE_HEADINGS[4], "- [ ] Pass money, network, commercialization-document"),
        ):
            changed_task = first_task.replace("[x]", "[ ]") if "[x]" in first_task else first_task.replace("[ ]", "[x]")
            reject_section_change(plan, heading, first_task, changed_task)
            reject_section_change(plan, heading, first_task, "removed task marker")
        closeout_heading = "## FX-01A post-merge closeout"
        reject_section_change(plan, closeout_heading, f"Status: **{CLOSEOUT_STATUS}**", "Status: **Done.**")
        reject_section_change(plan, closeout_heading, CLOSEOUT_TASK,
                              CLOSEOUT_TASK + "\n\n* [x] Relabel the historical non-pass as complete.")
        for relative, heading in ((plan, closeout_heading), ("Docs/TASKS.md", TASK_HEADING)):
            reject_section_change(relative, heading, CLOSEOUT_TASK, CLOSEOUT_TASK.replace("[ ]", "[x]"))
        for relative, heading in ((plan, SUBPHASE_HEADINGS[1]), ("Docs/TASKS.md", TASK_HEADING)):
            reject_section_change(relative, heading, BEFORE_B_TASK, "")
            reject_section_change(relative, heading, BEFORE_B_TASK, BEFORE_B_TASK.replace("[x]", "[ ]"))
        for relative, heading, status in (
            (plan, PLAN_HEADING, f"Status: **{EXPECTED_PLAN_STATUS}**"),
            ("Docs/TASKS.md", TASK_HEADING, f"Status: {EXPECTED_TASK_STATUS}"),
        ):
            reject_section_change(relative, heading, status, f"{status}\n\n{status}")

        # The main TASKS checklist is a separate authoritative state surface, not
        # implied by the plan's valid A–E status/marker inventory.
        for item in _checklist_items(EXPECTED_TASKS_CHECKLIST):
            flipped = item.replace("[x]", "[ ]", 1) if item.startswith("- [x]") else item.replace("[ ]", "[x]", 1)
            for changed in (flipped, "", item + "\n" + item, item + " altered obligation"):
                reject_section_change("Docs/TASKS.md", TASK_HEADING, item, changed)
        reject_section_change(
            "Docs/TASKS.md", TASK_HEADING,
            "- [x] Implement the pure checked integer-rational converter", "Implement the pure checked integer-rational converter",
        )
        for relative, heading, anchor in (
            ("Docs/TASKS.md", TASK_HEADING, _checklist_items(EXPECTED_TASKS_CHECKLIST)[-1]),
            *((plan, heading, f"Status: **{DONE_STATUS if index == 0 else IMPLEMENTATION_DONE_STATUS if index == 1 else BLOCKED_STATUS}**")
              for index, heading in enumerate(SUBPHASE_HEADINGS)),
        ):
            for extra in (
                "* [x] Premature later-stage completion.",
                "+ [x] Premature later-stage completion.",
                " - [x] Premature later-stage completion.",
                "-\t[x] Premature later-stage completion.",
                "1. [x] Premature later-stage completion.",
                "1) [x] Premature later-stage completion.",
                "> - [x] Premature later-stage completion.",
                "    - [x] Premature later-stage completion.",
                "- [X] Premature later-stage completion.",
                "- [B] Noncanonical stage marker.",
                "- [ ] Canonical item with another [x] hidden inline.",
            ):
                reject_section_change(relative, heading, anchor, anchor + "\n\n" + extra)

        contract_path = fixture / "Docs/FX_01_CONTRACT.json"
        raw_contract = json.dumps(data)
        for old, new in (
            ('"schemaVersion": 4', '"schemaVersion": 999, "schemaVersion": 4'),
            ('"casePassed": 575', '"casePassed": 999, "casePassed": 575'),
            ('"casePassed": 575', '"casePassed": 575, "casePassed": 575'),
            ('"casePassed": 575', '"case\\u0050assed": 999, "casePassed": 575'),
            ('"nextSubphaseEntered": false', '"nextSubphaseEntered": true, "nextSubphaseEntered": false'),
            ('"schemaVersion": 4', '"schemaVersion": NaN'),
            ('"schemaVersion": 4', '"schemaVersion": Infinity'),
        ):
            if raw_contract.count(old) != 1:
                raise RuntimeError(f"ambiguous raw JSON self-test target: {old}")
            contract_path.write_text(raw_contract.replace(old, new, 1), encoding="utf-8")
            _require_fixture_cli(fixture, valid=False, description=f"raw JSON mutation: {new}")
            mutation_count += 1
        contract_path.write_text(raw_contract, encoding="utf-8")
        for section, key, value in (
            ("phase", "activeSubphaseStatus", "IN_PROGRESS"),
            ("phase", "closeoutStatus", "DONE"),
            ("phase", "nextSubphaseEntered", 0),
            ("deliveryEvidence", "reviewedHead", "b2b45f1155e6b393c17cac6c77f5208fb3792c41"),
            ("deliveryEvidence", "hostedRun", "33772144343"),
            ("deliveryEvidence", "acceptedRunFailedToPassedObserved", True),
            ("evidenceBoundary", "schemaV7EvidenceClaimed", True),
        ):
            mutation = copy.deepcopy(data)
            mutation[section][key] = value
            contract_path.write_text(json.dumps(mutation), encoding="utf-8")
            _require_fixture_cli(fixture, valid=False, description=f"{section}:{key}")
            mutation_count += 1
        for section in ("decimalRateContract", "syncCompanionContract", "implementationEvidence"):
            for key in data[section]:
                mutation = copy.deepcopy(data)
                mutation[section].pop(key)
                contract_path.write_text(json.dumps(mutation), encoding="utf-8")
                _require_fixture_cli(fixture, valid=False, description=f"missing {section}:{key}")
                mutation_count += 1
                mutation[section][key] = "unreviewed value"
                contract_path.write_text(json.dumps(mutation), encoding="utf-8")
                _require_fixture_cli(fixture, valid=False, description=f"drifted {section}:{key}")
                mutation_count += 1
        contract_path.write_text(json.dumps(data), encoding="utf-8")
        _require_fixture_cli(fixture, valid=True, description="the restored copied contract")
        print(f"FX-01 closeout self-test rejected {mutation_count} CLI mutations")


def run_self_test(data: Any, project_root: Path) -> None:
    fail_if_invalid(data, project_root)
    run_cli_failure_self_test(project_root)
    run_closeout_self_test(data, project_root)
    from validation_order_self_test import run_validation_order_self_test
    run_validation_order_self_test(project_root)

    mutations: list[tuple[str, Any]] = []
    entered_next = copy.deepcopy(data)
    entered_next["phase"]["nextSubphaseEntered"] = True
    mutations.append(("premature FX-01C entry", entered_next))

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

    ambiguous_run_scope = copy.deepcopy(data)
    ambiguous_run_scope["deliveryEvidence"]["failedToPassedObserved"] = ambiguous_run_scope[
        "deliveryEvidence"
    ].pop("acceptedRunFailedToPassedObserved")
    mutations.append(("the obsolete unscoped Failed-to-Passed key", ambiguous_run_scope))

    for description, mutation in mutations:
        if not validate_contract_data(mutation):
            raise RuntimeError(f"FX-01 self-test failed to reject {description}")

    with tempfile.TemporaryDirectory(prefix="mindbudget-fx01-contract-") as temporary:
        fixture_root = Path(temporary)
        _write_fixture(fixture_root, project_root, data)

        tasks_path = fixture_root / "Docs/TASKS.md"
        tasks_text = tasks_path.read_text(encoding="utf-8")
        tasks_path.write_text(
            f"Summary: {EXPECTED_TASK_STATUS}\n\n"
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
                "- [x] Add the closed rate/source domain",
                "- [ ] Add the closed rate/source domain",
                1,
            ),
            encoding="utf-8",
        )
        _require_rejection("a rolled-back FX-01B implementation task", data, fixture_root)
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
