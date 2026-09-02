#!/usr/bin/env python3
"""Build and validate the fixed G1 template/on-device/Luna comparison.

This tool never calls OpenAI or Apple Foundation Models. The physical-device test harness emits
the on-device transcript; this script extracts those records, applies the existing Luna safety
validator to every arm, and creates a deterministically blinded human-review packet.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
from pathlib import Path
from typing import Any

import g1_luna_eval as luna


ROOT = Path(__file__).resolve().parents[1]
LUNA_TRANSCRIPT = (
    ROOT / "Docs/Commercialization/G1_LUNA_EVAL_TRANSCRIPT_2026-09-02_ATTEMPT3.jsonl"
)
LUNA_RESULT = ROOT / "Docs/Commercialization/G1_LUNA_EVAL_RESULT_2026-09-02.json"
MARKER = "MINDBUDGET_G1_ON_DEVICE_EVAL "
SCHEMA_VERSION = 1
EXPECTED_DATASET_SHA256 = "d509c8fee36578e66fe361bf0dd635fb25fb947891aff2f1a5e7fc9c7747c014"
EXPECTED_LUNA_TRANSCRIPT_SHA256 = "4800cc6c8458fa39b0bd4419d90fbf7ee4bfa47bc3deffa73475b751e947999e"
EXPECTED_DEVICE_TRANSCRIPT_SHA256 = "d6236a29293e0c16068fb24b6b7a6392af9cfedc9dadb9c7cdc06b8fabb5a20b"
EXPECTED_PENDING_REVIEW_PACKET_SHA256 = "a4c2686ba448a0afaa67a2c82a1feb6bbe23c7780f29eb8d305e4bd35612f57f"
BLINDING_DOMAIN = "MindBudget-G1-three-way-v1"
ARM_IDS = ("deterministic_template", "apple_on_device", "openai_luna")
BLIND_LABELS = ("A", "B", "C")
EXPECTED_DEVICE_NAME = "拉沙的iPhone"
EXCLUDED_DEVICE_NAME = "Xiao li的 iPhone (2)"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise RuntimeError(message)


def sha256_file(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def canonical_json(value: Any) -> str:
    return json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":"))


def read_jsonl(path: Path) -> list[dict[str, Any]]:
    records: list[dict[str, Any]] = []
    for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        if not line.strip():
            continue
        try:
            value = json.loads(line)
        except json.JSONDecodeError as error:
            raise RuntimeError(f"invalid JSONL at {path}:{line_number}") from error
        require(isinstance(value, dict), f"JSONL record must be an object at {path}:{line_number}")
        records.append(value)
    return records


def write_jsonl(path: Path, records: list[dict[str, Any]]) -> None:
    if path.exists():
        raise RuntimeError(f"refusing to overwrite {path}")
    path.write_text(
        "".join(json.dumps(record, ensure_ascii=False, sort_keys=True) + "\n" for record in records),
        encoding="utf-8",
    )


def load_cases() -> list[dict[str, Any]]:
    dataset = luna.load_dataset()
    require(luna.sha256_json(dataset) == EXPECTED_DATASET_SHA256, "frozen dataset hash drifted")
    return luna.expanded_cases(dataset)


def extract_device_records(log_path: Path) -> list[dict[str, Any]]:
    log_text = log_path.read_text(encoding="utf-8", errors="replace")
    require(
        f"-destination platform=iOS,name={EXPECTED_DEVICE_NAME}" in log_text,
        "xcodebuild log does not prove the authorized physical destination",
    )
    require(
        f"-destination platform=iOS,name={EXCLUDED_DEVICE_NAME}" not in log_text,
        "xcodebuild log names the explicitly excluded destination",
    )
    records: list[dict[str, Any]] = []
    for line in log_text.splitlines():
        marker_index = line.find(MARKER)
        if marker_index < 0:
            continue
        payload = line[marker_index + len(MARKER) :]
        try:
            value = json.loads(payload)
        except json.JSONDecodeError as error:
            raise RuntimeError("on-device Eval marker contains invalid JSON") from error
        require(isinstance(value, dict), "on-device Eval marker must contain an object")
        records.append(value)
    require(records and records[0].get("record_type") == "metadata", "missing on-device metadata marker")
    records[0]["xcode_destination_name"] = EXPECTED_DEVICE_NAME
    validate_device_records(records, load_cases())
    return records


def validate_device_records(
    records: list[dict[str, Any]], cases: list[dict[str, Any]]
) -> dict[str, Any]:
    require(len(records) == len(cases) + 1, "on-device transcript must contain metadata plus 24 cases")
    metadata = records[0]
    require(
        set(metadata)
        == {
            "record_type",
            "schema_version",
            "dataset_sha256",
            "device_name",
            "device_model",
            "system_name",
            "system_version",
            "model_availability",
            "xcode_destination_name",
        },
        "on-device metadata shape drifted",
    )
    require(metadata["record_type"] == "metadata", "first on-device record must be metadata")
    require(metadata["schema_version"] == SCHEMA_VERSION, "on-device schema version drifted")
    require(metadata["dataset_sha256"] == EXPECTED_DATASET_SHA256, "device dataset hash drifted")
    require(metadata["model_availability"] == "available", "on-device model was not available")
    require(metadata["xcode_destination_name"] == EXPECTED_DEVICE_NAME, "Xcode destination drifted")
    for key in ("device_name", "device_model", "system_name", "system_version"):
        require(isinstance(metadata[key], str) and metadata[key], f"missing on-device {key}")
    require(
        metadata["device_name"] in {"iPhone", EXPECTED_DEVICE_NAME},
        "unexpected UIDevice name in physical evidence",
    )
    require(metadata["device_name"] != EXCLUDED_DEVICE_NAME, "excluded device must never produce G1 evidence")
    require(metadata["device_model"] == "iPhone", "on-device evidence must come from a physical iPhone")
    require(metadata["system_name"] == "iOS", "on-device evidence must run on iOS")

    case_map = {case["case_id"]: case for case in cases}
    seen: set[str] = set()
    for record in records[1:]:
        require(
            set(record)
            == {
                "record_type",
                "schema_version",
                "case_id",
                "latency_ms",
                "generation_error",
                "output",
            },
            "on-device case record shape drifted",
        )
        require(record["record_type"] == "case", "unexpected on-device record type")
        require(record["schema_version"] == SCHEMA_VERSION, "on-device case schema drifted")
        case_id = record["case_id"]
        require(case_id in case_map, f"unknown on-device case {case_id}")
        require(case_id not in seen, f"duplicate on-device case {case_id}")
        seen.add(case_id)
        require(type(record["latency_ms"]) is int and record["latency_ms"] >= 0, "invalid latency")
        require(
            record["generation_error"] is None
            or (
                isinstance(record["generation_error"], str)
                and re.fullmatch(r"[A-Za-z0-9_.]{1,120}", record["generation_error"])
            ),
            "unsafe on-device generation error",
        )
        require(record["output"] is None or isinstance(record["output"], dict), "invalid output")
    require(seen == set(case_map), "on-device transcript is missing cases")
    return metadata


def template_output(case: dict[str, Any]) -> dict[str, Any]:
    return {"case_id": case["case_id"], "status": "ok", **case["template"]}


def effective_on_device_output(
    case: dict[str, Any], record: dict[str, Any]
) -> tuple[dict[str, Any], str, list[str]]:
    if record["generation_error"] is not None or record["output"] is None:
        return template_output(case), "template_fallback_generation_error", ["generation error"]
    errors = luna.validate_output(case, record["output"])
    if errors:
        return template_output(case), "template_fallback_validation_error", errors
    return record["output"], "model", []


def load_luna_outputs(cases: list[dict[str, Any]]) -> dict[str, dict[str, Any]]:
    require(sha256_file(LUNA_TRANSCRIPT) == EXPECTED_LUNA_TRANSCRIPT_SHA256, "Luna transcript hash drifted")
    result = json.loads(LUNA_RESULT.read_text(encoding="utf-8"))
    require(result["productionAdmitted"] is False, "Luna evidence cannot admit production")
    require(result["datasetSHA256"] == EXPECTED_DATASET_SHA256, "Luna result dataset drifted")
    require(
        result["passingTranscript"]["sha256"] == EXPECTED_LUNA_TRANSCRIPT_SHA256,
        "Luna result no longer pins the passing transcript",
    )
    records = read_jsonl(LUNA_TRANSCRIPT)
    report = luna.score_transcript(records, cases)
    require(report["deterministic_result"] == "PASS", "reviewed Luna transcript no longer passes")
    outputs: dict[str, dict[str, Any]] = {}
    for record in records:
        require(record["attempt"] == 1, "three-way Eval requires the accepted first-pass Luna record")
        require(record["provider_error"] is None, "passing Luna arm contains a provider error")
        outputs[record["case_id"]] = record["output"]
    require(set(outputs) == {case["case_id"] for case in cases}, "Luna arm is incomplete")
    return outputs


def blinded_order(case_id: str) -> list[str]:
    decorated = []
    for arm_id in ARM_IDS:
        digest = hashlib.sha256(f"{BLINDING_DOMAIN}:{case_id}:{arm_id}".encode()).hexdigest()
        decorated.append((digest, arm_id))
    return [arm_id for _, arm_id in sorted(decorated)]


def build_review_packet(records: list[dict[str, Any]]) -> dict[str, Any]:
    cases = load_cases()
    metadata = validate_device_records(records, cases)
    device_by_case = {record["case_id"]: record for record in records[1:]}
    luna_outputs = load_luna_outputs(cases)
    review_cases: list[dict[str, Any]] = []
    fallback_counts = {
        "model": 0,
        "template_fallback_generation_error": 0,
        "template_fallback_validation_error": 0,
    }
    for case in cases:
        local_output, local_source, local_errors = effective_on_device_output(
            case, device_by_case[case["case_id"]]
        )
        fallback_counts[local_source] += 1
        outputs = {
            "deterministic_template": template_output(case),
            "apple_on_device": local_output,
            "openai_luna": luna_outputs[case["case_id"]],
        }
        for arm_id, output in outputs.items():
            require(
                not luna.validate_output(case, output),
                f"effective {arm_id} output failed safety validation for {case['case_id']}",
            )
        order = blinded_order(case["case_id"])
        review_cases.append(
            {
                "case_id": case["case_id"],
                "locale": case["locale"],
                "task": case["task"],
                "question": case["question"],
                "facts": case["facts"],
                "required_fact_ids": case["required_fact_ids"],
                "allowed_action_ids": case["allowed_action_ids"],
                "candidates": [
                    {"label": label, "headline": outputs[arm_id]["headline"], "explanation": outputs[arm_id]["explanation"], "fact_ids": outputs[arm_id]["fact_ids"], "action_ids": outputs[arm_id]["action_ids"]}
                    for label, arm_id in zip(BLIND_LABELS, order)
                ],
                "review": {
                    "preferred_label": None,
                    "clarity_best_labels": [],
                    "usefulness_best_labels": [],
                    "locale_naturalness_best_labels": [],
                    "material_incremental_value": None,
                    "review_notes": "",
                },
                "sealed_mapping_commitment": hashlib.sha256(canonical_json(order).encode()).hexdigest(),
                "on_device_effective_source": local_source,
                "on_device_raw_validation_errors": local_errors,
            }
        )
    return {
        "schema_version": SCHEMA_VERSION,
        "status": "PENDING_BLIND_REVIEW",
        "scope": "synthetic_three_way_comparison_only",
        "production_admitted": False,
        "dataset_sha256": EXPECTED_DATASET_SHA256,
        "luna_transcript_sha256": EXPECTED_LUNA_TRANSCRIPT_SHA256,
        "blinding_domain_sha256": hashlib.sha256(BLINDING_DOMAIN.encode()).hexdigest(),
        "case_count": len(review_cases),
        "arm_count": len(ARM_IDS),
        "device": metadata,
        "on_device_effective_sources": fallback_counts,
        "acceptance_rule": {
            "deterministic_safety": "ALL_EFFECTIVE_OUTPUTS_PASS_EXISTING_VALIDATOR",
            "incremental_value": "OWNER_MUST_ACCEPT_AT_LEAST_ONE_BILINGUAL_TASK_NEED_WHERE_LUNA_MATERIALLY_EXCEEDS_BOTH_LOCAL_ARMS",
            "no_self_approval": True,
        },
        "review_instructions": {
            "blind_first": "Score candidates without deriving or reading their arm mapping.",
            "preferred_label": "A, B, C, or TIE",
            "best_label_arrays": "One or more of A, B, C; an empty array is incomplete.",
            "material_incremental_value": "True only when the preferred output adds user value without new facts, advice, judgment, or unsafe actions.",
            "bilingual_task_gate": "A task qualifies only if an accepted need is supported in both English and Simplified Chinese cases.",
        },
        "independent_review": {
            "reviewer_kind": None,
            "reviewed_at_utc": None,
            "reviewed_head": None,
        },
        "cases": review_cases,
    }


def validate_review_packet(packet: dict[str, Any], *, require_complete: bool) -> None:
    require(
        set(packet)
        == {
            "schema_version",
            "status",
            "scope",
            "production_admitted",
            "dataset_sha256",
            "luna_transcript_sha256",
            "blinding_domain_sha256",
            "case_count",
            "arm_count",
            "device",
            "on_device_effective_sources",
            "acceptance_rule",
            "review_instructions",
            "independent_review",
            "cases",
        },
        "review packet shape drifted",
    )
    require(packet["schema_version"] == SCHEMA_VERSION, "review packet schema drifted")
    require(packet["scope"] == "synthetic_three_way_comparison_only", "review scope drifted")
    require(packet["production_admitted"] is False, "three-way Eval cannot admit production")
    require(packet["dataset_sha256"] == EXPECTED_DATASET_SHA256, "review dataset drifted")
    require(packet["luna_transcript_sha256"] == EXPECTED_LUNA_TRANSCRIPT_SHA256, "review Luna arm drifted")
    require(
        packet["blinding_domain_sha256"] == hashlib.sha256(BLINDING_DOMAIN.encode()).hexdigest(),
        "review blinding domain drifted",
    )
    require(packet["case_count"] == 24 and packet["arm_count"] == 3, "review cardinality drifted")
    require(len(packet["cases"]) == 24, "review case list is incomplete")
    source_counts = packet["on_device_effective_sources"]
    require(set(source_counts) == {"model", "template_fallback_generation_error", "template_fallback_validation_error"}, "on-device source counts drifted")
    require(all(type(value) is int and value >= 0 for value in source_counts.values()), "invalid on-device source count")
    require(sum(source_counts.values()) == 24, "on-device source counts must cover every case")
    review_record = packet["independent_review"]
    require(set(review_record) == {"reviewer_kind", "reviewed_at_utc", "reviewed_head"}, "independent-review record shape drifted")
    if require_complete:
        require(packet["status"] == "INDEPENDENT_REVIEW_COMPLETE", "complete review status is required")
        require(review_record["reviewer_kind"] == "independent_pr_reviewer", "independent reviewer kind is required")
        require(isinstance(review_record["reviewed_at_utc"], str) and re.fullmatch(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z", review_record["reviewed_at_utc"]), "invalid independent review timestamp")
        require(isinstance(review_record["reviewed_head"], str) and re.fullmatch(r"[0-9a-f]{7,40}", review_record["reviewed_head"]), "invalid reviewed head")
    else:
        require(packet["status"] in {"PENDING_BLIND_REVIEW", "INDEPENDENT_REVIEW_COMPLETE"}, "invalid review status")
    seen: set[str] = set()
    cases_by_id = {case["case_id"]: case for case in load_cases()}
    for case in packet["cases"]:
        require(
            set(case)
            == {
                "case_id",
                "locale",
                "task",
                "question",
                "facts",
                "required_fact_ids",
                "allowed_action_ids",
                "candidates",
                "review",
                "sealed_mapping_commitment",
                "on_device_effective_source",
                "on_device_raw_validation_errors",
            },
            "review case shape drifted",
        )
        case_id = case["case_id"]
        require(case_id not in seen, f"duplicate review case {case_id}")
        require(case_id in cases_by_id, f"unknown review case {case_id}")
        seen.add(case_id)
        source_case = cases_by_id[case_id]
        for key in ("locale", "task", "question", "facts", "required_fact_ids", "allowed_action_ids"):
            require(case[key] == source_case[key], f"review input drifted for {case_id}: {key}")
        require([candidate["label"] for candidate in case["candidates"]] == list(BLIND_LABELS), "candidate labels drifted")
        for candidate in case["candidates"]:
            require(set(candidate) == {"label", "headline", "explanation", "fact_ids", "action_ids"}, f"candidate shape drifted for {case_id}")
            output = {
                "case_id": case_id,
                "status": "ok",
                "headline": candidate["headline"],
                "explanation": candidate["explanation"],
                "fact_ids": candidate["fact_ids"],
                "action_ids": candidate["action_ids"],
            }
            require(not luna.validate_output(source_case, output), f"review candidate failed safety validation for {case_id}")
        require(case["sealed_mapping_commitment"] == hashlib.sha256(canonical_json(blinded_order(case_id)).encode()).hexdigest(), f"mapping commitment drifted for {case_id}")
        review = case["review"]
        require(
            set(review)
            == {
                "preferred_label",
                "clarity_best_labels",
                "usefulness_best_labels",
                "locale_naturalness_best_labels",
                "material_incremental_value",
                "review_notes",
            },
            f"review field shape drifted for {case_id}",
        )
        if require_complete:
            require(review["preferred_label"] in {*BLIND_LABELS, "TIE"}, f"missing preference for {case_id}")
            for field in ("clarity_best_labels", "usefulness_best_labels", "locale_naturalness_best_labels"):
                require(
                    isinstance(review[field], list)
                    and review[field]
                    and len(review[field]) == len(set(review[field]))
                    and set(review[field]).issubset(BLIND_LABELS),
                    f"incomplete {field} for {case_id}",
                )
            require(type(review["material_incremental_value"]) is bool, f"invalid value decision for {case_id}")
            require(
                review["preferred_label"] != "TIE" or not review["material_incremental_value"],
                f"a tied case cannot claim material incremental value: {case_id}",
            )
            require(
                isinstance(review["review_notes"], str) and review["review_notes"].strip(),
                f"missing review notes for {case_id}",
            )
        else:
            require(
                review["material_incremental_value"] is None
                or type(review["material_incremental_value"]) is bool,
                f"invalid pending value decision for {case_id}",
            )
    require(seen == set(cases_by_id), "review packet is missing cases")


def validate_review_derivation(packet: dict[str, Any], transcript_path: Path) -> None:
    expected = build_review_packet(read_jsonl(transcript_path))
    observed = json.loads(json.dumps(packet))
    observed["status"] = "PENDING_BLIND_REVIEW"
    observed["independent_review"] = expected["independent_review"]
    for case in observed["cases"]:
        case["review"] = {
            "preferred_label": None,
            "clarity_best_labels": [],
            "usefulness_best_labels": [],
            "locale_naturalness_best_labels": [],
            "material_incremental_value": None,
            "review_notes": "",
        }
    require(observed == expected, "review packet does not derive exactly from the frozen arms")


def summarize_complete_review(packet: dict[str, Any]) -> dict[str, Any]:
    validate_review_packet(packet, require_complete=True)
    case_results: list[dict[str, Any]] = []
    qualifying_locales_by_task: dict[str, set[str]] = {}
    for case in packet["cases"]:
        preferred_label = case["review"]["preferred_label"]
        preferred_arm = None
        if preferred_label != "TIE":
            label_to_arm = dict(zip(BLIND_LABELS, blinded_order(case["case_id"])))
            preferred_arm = label_to_arm[preferred_label]
        luna_materially_preferred = (
            preferred_arm == "openai_luna"
            and case["review"]["material_incremental_value"] is True
        )
        if luna_materially_preferred:
            qualifying_locales_by_task.setdefault(case["task"], set()).add(case["locale"])
        case_results.append(
            {
                "case_id": case["case_id"],
                "preferred_arm": preferred_arm or "tie",
                "luna_materially_preferred": luna_materially_preferred,
            }
        )
    qualifying_tasks = sorted(
        task
        for task, locales in qualifying_locales_by_task.items()
        if {"en", "zh"}.issubset(locales)
    )
    return {
        "schema_version": SCHEMA_VERSION,
        "result": "PASS" if qualifying_tasks else "NON_PASS",
        "scope": "synthetic_three_way_comparison_only",
        "production_admitted": False,
        "dataset_sha256": EXPECTED_DATASET_SHA256,
        "luna_transcript_sha256": EXPECTED_LUNA_TRANSCRIPT_SHA256,
        "reviewed_head": packet["independent_review"]["reviewed_head"],
        "qualifying_bilingual_tasks": qualifying_tasks,
        "luna_materially_preferred_case_count": sum(
            item["luna_materially_preferred"] for item in case_results
        ),
        "case_results": case_results,
    }


def self_test() -> None:
    cases = load_cases()
    luna_outputs = load_luna_outputs(cases)
    synthetic_records: list[dict[str, Any]] = [
        {
            "record_type": "metadata",
            "schema_version": 1,
            "dataset_sha256": EXPECTED_DATASET_SHA256,
            "device_name": EXPECTED_DEVICE_NAME,
            "device_model": "iPhone",
            "system_name": "iOS",
            "system_version": "26.6",
            "model_availability": "available",
            "xcode_destination_name": EXPECTED_DEVICE_NAME,
        }
    ]
    for case in cases:
        synthetic_records.append(
            {
                "record_type": "case",
                "schema_version": 1,
                "case_id": case["case_id"],
                "latency_ms": 1,
                "generation_error": None,
                "output": luna_outputs[case["case_id"]],
            }
        )
    packet = build_review_packet(synthetic_records)
    validate_review_packet(packet, require_complete=False)
    require(packet["case_count"] == 24, "self-test review count drifted")
    require(all(len(case["candidates"]) == 3 for case in packet["cases"]), "arm count drifted")

    missing = json.loads(json.dumps(synthetic_records))
    missing.pop()
    try:
        validate_device_records(missing, cases)
    except RuntimeError:
        pass
    else:
        raise RuntimeError("missing on-device case must fail closed")

    wrong_hash = json.loads(json.dumps(synthetic_records))
    wrong_hash[0]["dataset_sha256"] = "0" * 64
    try:
        validate_device_records(wrong_hash, cases)
    except RuntimeError:
        pass
    else:
        raise RuntimeError("wrong device dataset hash must fail closed")

    fallback = json.loads(json.dumps(synthetic_records))
    fallback[1]["output"]["fact_ids"].append("invented_fact")
    fallback_packet = build_review_packet(fallback)
    require(
        fallback_packet["on_device_effective_sources"]["template_fallback_validation_error"] == 1,
        "invalid on-device output must become the deterministic template",
    )

    complete = json.loads(json.dumps(packet))
    complete["status"] = "INDEPENDENT_REVIEW_COMPLETE"
    complete["independent_review"] = {
        "reviewer_kind": "independent_pr_reviewer",
        "reviewed_at_utc": "2026-09-02T12:00:00Z",
        "reviewed_head": "abcdef0",
    }
    task_counts = {
        task: sum(case["task"] == task for case in cases)
        for task in {case["task"] for case in cases}
    }
    selected_task = next(task for task, count in task_counts.items() if count == 2)
    selected_case_ids = {
        case["case_id"] for case in cases if case["task"] == selected_task
    }
    for case in complete["cases"]:
        label_to_arm = dict(zip(BLIND_LABELS, blinded_order(case["case_id"])))
        luna_label = next(label for label, arm in label_to_arm.items() if arm == "openai_luna")
        case["review"] = {
            "preferred_label": luna_label,
            "clarity_best_labels": [luna_label],
            "usefulness_best_labels": [luna_label],
            "locale_naturalness_best_labels": [luna_label],
            "material_incremental_value": case["case_id"] in selected_case_ids,
            "review_notes": "synthetic self-test decision",
        }
    summary = summarize_complete_review(complete)
    require(summary["result"] == "PASS", "bilingual Luna preference must pass")
    empty_notes = json.loads(json.dumps(complete))
    empty_notes["cases"][0]["review"]["review_notes"] = ""
    try:
        summarize_complete_review(empty_notes)
    except RuntimeError:
        pass
    else:
        raise RuntimeError("a complete review with empty notes must fail closed")
    selected_zh = next(
        case for case in complete["cases"]
        if case["task"] == selected_task and case["locale"] == "zh"
    )
    selected_zh["review"]["material_incremental_value"] = False
    require(
        summarize_complete_review(complete)["result"] == "NON_PASS",
        "a one-locale Luna preference must fail closed",
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--extract-on-device-log", type=Path)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--build-review-packet", type=Path, metavar="ON_DEVICE_JSONL")
    parser.add_argument("--check-review-packet", type=Path)
    parser.add_argument("--summarize-review", type=Path)
    parser.add_argument("--on-device-transcript", type=Path)
    parser.add_argument("--require-complete-review", action="store_true")
    args = parser.parse_args()

    selected = sum(
        bool(value)
        for value in (
            args.self_test,
            args.extract_on_device_log,
            args.build_review_packet,
            args.check_review_packet,
            args.summarize_review,
        )
    )
    require(selected == 1, "select exactly one operation")
    if args.self_test:
        self_test()
        return 0
    if args.extract_on_device_log is not None:
        require(args.output is not None, "log extraction requires --output")
        write_jsonl(args.output, extract_device_records(args.extract_on_device_log))
        return 0
    if args.build_review_packet is not None:
        require(args.output is not None, "review-packet generation requires --output")
        records = read_jsonl(args.build_review_packet)
        packet = build_review_packet(records)
        if args.output.exists():
            raise RuntimeError(f"refusing to overwrite {args.output}")
        args.output.write_text(json.dumps(packet, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        return 0
    if args.check_review_packet is not None:
        packet = json.loads(args.check_review_packet.read_text(encoding="utf-8"))
        validate_review_packet(packet, require_complete=args.require_complete_review)
        if args.on_device_transcript is not None:
            validate_review_derivation(packet, args.on_device_transcript)
        return 0
    if args.summarize_review is not None:
        require(args.output is not None, "review summary requires --output")
        packet = json.loads(args.summarize_review.read_text(encoding="utf-8"))
        summary = summarize_complete_review(packet)
        if args.output.exists():
            raise RuntimeError(f"refusing to overwrite {args.output}")
        args.output.write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        return 0
    raise RuntimeError("unreachable")


if __name__ == "__main__":
    raise SystemExit(main())
