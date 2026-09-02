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
DEVICE_TRANSCRIPT = (
    ROOT / "Docs/Commercialization/G1_APPLE_ON_DEVICE_EVAL_TRANSCRIPT_2026-09-02.jsonl"
)
MARKER = "MINDBUDGET_G1_ON_DEVICE_EVAL "
SCHEMA_VERSION = 1
EXPECTED_DATASET_SHA256 = "d509c8fee36578e66fe361bf0dd635fb25fb947891aff2f1a5e7fc9c7747c014"
EXPECTED_LUNA_TRANSCRIPT_SHA256 = "4800cc6c8458fa39b0bd4419d90fbf7ee4bfa47bc3deffa73475b751e947999e"
EXPECTED_DEVICE_TRANSCRIPT_SHA256 = "d6236a29293e0c16068fb24b6b7a6392af9cfedc9dadb9c7cdc06b8fabb5a20b"
EXPECTED_PENDING_REVIEW_PACKET_SHA256 = "bcbf943ba7d6a1a9d18442efc38e760cc798c30e8674c8d877f9e0cb751ab2a5"
EXPECTED_REVIEW_SIDECAR_SHA256 = "d29fca8246df5641d876be19ea56a936edd975616d2b3101bc18cca9d7bff507"
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


def rendered_json(value: Any) -> str:
    return json.dumps(value, ensure_ascii=False, indent=2) + "\n"


def rendered_json_sha256(value: Any) -> str:
    return hashlib.sha256(rendered_json(value).encode()).hexdigest()


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


def candidate_payload(candidate: dict[str, Any]) -> dict[str, Any]:
    return {
        "headline": candidate["headline"],
        "explanation": candidate["explanation"],
        "fact_ids": candidate["fact_ids"],
        "action_ids": candidate["action_ids"],
    }


def build_review_artifacts(
    records: list[dict[str, Any]],
) -> tuple[dict[str, Any], dict[str, Any]]:
    cases = load_cases()
    metadata = validate_device_records(records, cases)
    device_by_case = {record["case_id"]: record for record in records[1:]}
    luna_outputs = load_luna_outputs(cases)
    review_cases: list[dict[str, Any]] = []
    sidecar_cases: list[dict[str, Any]] = []
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
        mapping_commitment = hashlib.sha256(canonical_json(order).encode()).hexdigest()
        candidates = [
            {
                "label": label,
                "headline": outputs[arm_id]["headline"],
                "explanation": outputs[arm_id]["explanation"],
                "fact_ids": outputs[arm_id]["fact_ids"],
                "action_ids": outputs[arm_id]["action_ids"],
            }
            for label, arm_id in zip(BLIND_LABELS, order)
        ]
        all_candidates_distinct = len(
            {canonical_json(candidate_payload(candidate)) for candidate in candidates}
        ) == len(BLIND_LABELS)
        review_cases.append(
            {
                "case_id": case["case_id"],
                "locale": case["locale"],
                "task": case["task"],
                "question": case["question"],
                "facts": case["facts"],
                "required_fact_ids": case["required_fact_ids"],
                "allowed_action_ids": case["allowed_action_ids"],
                "candidates": candidates,
                "review": {
                    "preferred_label": None,
                    "clarity_best_labels": [],
                    "usefulness_best_labels": [],
                    "locale_naturalness_best_labels": [],
                    "material_incremental_value": None,
                    "review_notes": "",
                },
                "sealed_mapping_commitment": mapping_commitment,
            }
        )
        sidecar_cases.append(
            {
                "case_id": case["case_id"],
                "label_to_arm": dict(zip(BLIND_LABELS, order)),
                "sealed_mapping_commitment": mapping_commitment,
                "on_device_effective_source": local_source,
                "on_device_raw_validation_errors": local_errors,
                "all_candidates_distinct": all_candidates_distinct,
                "comparative_value_eligible": all_candidates_distinct,
            }
        )
    packet = {
        "schema_version": SCHEMA_VERSION,
        "status": "PENDING_BLIND_REVIEW",
        "scope": "synthetic_three_way_comparison_only",
        "production_admitted": False,
        "dataset_sha256": EXPECTED_DATASET_SHA256,
        "case_count": len(review_cases),
        "arm_count": len(ARM_IDS),
        "acceptance_rule": {
            "deterministic_safety": "ALL_EFFECTIVE_OUTPUTS_PASS_EXISTING_VALIDATOR",
            "incremental_value": "OWNER_MUST_ACCEPT_AT_LEAST_ONE_BILINGUAL_TASK_NEED_WHERE_LUNA_MATERIALLY_EXCEEDS_BOTH_LOCAL_ARMS",
            "no_self_approval": True,
        },
        "review_instructions": {
            "blind_first": "Score and lock every review field before opening the transcript, sidecar, mapping code, or diagnostic prose.",
            "preferred_label": "A, B, C, or TIE",
            "best_label_arrays": "One or more of A, B, C; an empty array is incomplete.",
            "material_incremental_value": "True only when the preferred output adds user value without new facts, advice, judgment, or unsafe actions.",
            "bilingual_task_gate": "A task qualifies only if an accepted need is supported in both English and Simplified Chinese cases.",
            "duplicate_candidates": "Protocol residue may make candidate bodies identical. Score identical bodies equally and set material_incremental_value false for that case; do not infer arm identity.",
        },
        "independent_review": {
            "reviewer_kind": None,
            "reviewed_at_utc": None,
            "reviewed_head": None,
        },
        "cases": review_cases,
    }
    sidecar = {
        "schema_version": SCHEMA_VERSION,
        "status": "SEALED_UNTIL_REVIEW_FIELDS_LOCKED",
        "scope": "post_score_mapping_and_diagnostics_only",
        "production_admitted": False,
        "dataset_sha256": EXPECTED_DATASET_SHA256,
        "luna_transcript_sha256": EXPECTED_LUNA_TRANSCRIPT_SHA256,
        "device_transcript_sha256": EXPECTED_DEVICE_TRANSCRIPT_SHA256,
        "pending_review_packet_sha256": rendered_json_sha256(packet),
        "blinding_domain_sha256": hashlib.sha256(BLINDING_DOMAIN.encode()).hexdigest(),
        "case_count": len(sidecar_cases),
        "device": metadata,
        "on_device_effective_sources": fallback_counts,
        "protocol_residue": {
            "duplicate_effective_candidates_are_value_ineligible": True,
            "open_only_after": "ALL_BLIND_REVIEW_FIELDS_LOCKED",
        },
        "cases": sidecar_cases,
    }
    return packet, sidecar


def validate_review_packet(packet: dict[str, Any], *, require_complete: bool) -> None:
    require(
        set(packet)
        == {
            "schema_version",
            "status",
            "scope",
            "production_admitted",
            "dataset_sha256",
            "case_count",
            "arm_count",
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
    require(packet["case_count"] == 24 and packet["arm_count"] == 3, "review cardinality drifted")
    require(len(packet["cases"]) == 24, "review case list is incomplete")
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
                review
                == {
                    "preferred_label": None,
                    "clarity_best_labels": [],
                    "usefulness_best_labels": [],
                    "locale_naturalness_best_labels": [],
                    "material_incremental_value": None,
                    "review_notes": "",
                },
                f"pending review fields must remain empty for {case_id}",
            )
    require(seen == set(cases_by_id), "review packet is missing cases")


def validate_review_sidecar(sidecar: dict[str, Any]) -> None:
    require(
        set(sidecar)
        == {
            "schema_version",
            "status",
            "scope",
            "production_admitted",
            "dataset_sha256",
            "luna_transcript_sha256",
            "device_transcript_sha256",
            "pending_review_packet_sha256",
            "blinding_domain_sha256",
            "case_count",
            "device",
            "on_device_effective_sources",
            "protocol_residue",
            "cases",
        },
        "review sidecar shape drifted",
    )
    require(sidecar["schema_version"] == SCHEMA_VERSION, "review sidecar schema drifted")
    require(sidecar["status"] == "SEALED_UNTIL_REVIEW_FIELDS_LOCKED", "sidecar seal drifted")
    require(sidecar["scope"] == "post_score_mapping_and_diagnostics_only", "sidecar scope drifted")
    require(sidecar["production_admitted"] is False, "sidecar cannot admit production")
    require(sidecar["dataset_sha256"] == EXPECTED_DATASET_SHA256, "sidecar dataset drifted")
    require(sidecar["luna_transcript_sha256"] == EXPECTED_LUNA_TRANSCRIPT_SHA256, "sidecar Luna arm drifted")
    require(sidecar["device_transcript_sha256"] == EXPECTED_DEVICE_TRANSCRIPT_SHA256, "sidecar device transcript drifted")
    require(sidecar["pending_review_packet_sha256"] == EXPECTED_PENDING_REVIEW_PACKET_SHA256, "sidecar blind packet drifted")
    require(sidecar["blinding_domain_sha256"] == hashlib.sha256(BLINDING_DOMAIN.encode()).hexdigest(), "sidecar blinding domain drifted")
    require(sidecar["case_count"] == 24 and len(sidecar["cases"]) == 24, "sidecar cardinality drifted")
    source_counts = sidecar["on_device_effective_sources"]
    require(set(source_counts) == {"model", "template_fallback_generation_error", "template_fallback_validation_error"}, "on-device source counts drifted")
    require(all(type(value) is int and value >= 0 for value in source_counts.values()), "invalid on-device source count")
    require(sum(source_counts.values()) == 24, "on-device source counts must cover every case")
    require(
        sidecar["protocol_residue"]
        == {
            "duplicate_effective_candidates_are_value_ineligible": True,
            "open_only_after": "ALL_BLIND_REVIEW_FIELDS_LOCKED",
        },
        "sidecar protocol residue rule drifted",
    )
    seen: set[str] = set()
    for case in sidecar["cases"]:
        require(
            set(case)
            == {
                "case_id",
                "label_to_arm",
                "sealed_mapping_commitment",
                "on_device_effective_source",
                "on_device_raw_validation_errors",
                "all_candidates_distinct",
                "comparative_value_eligible",
            },
            "sidecar case shape drifted",
        )
        case_id = case["case_id"]
        require(case_id not in seen, f"duplicate sidecar case {case_id}")
        seen.add(case_id)
        mapping = case["label_to_arm"]
        require(set(mapping) == set(BLIND_LABELS), f"sidecar labels drifted for {case_id}")
        require(set(mapping.values()) == set(ARM_IDS), f"sidecar arms drifted for {case_id}")
        order = [mapping[label] for label in BLIND_LABELS]
        require(
            case["sealed_mapping_commitment"]
            == hashlib.sha256(canonical_json(order).encode()).hexdigest(),
            f"sidecar mapping commitment drifted for {case_id}",
        )
        require(
            case["on_device_effective_source"]
            in {"model", "template_fallback_generation_error", "template_fallback_validation_error"},
            f"invalid sidecar source for {case_id}",
        )
        require(isinstance(case["on_device_raw_validation_errors"], list), f"invalid sidecar errors for {case_id}")
        require(type(case["all_candidates_distinct"]) is bool, f"invalid distinctness for {case_id}")
        require(
            case["comparative_value_eligible"] is case["all_candidates_distinct"],
            f"duplicate-candidate eligibility drifted for {case_id}",
        )
    require(seen == {case["case_id"] for case in load_cases()}, "review sidecar is missing cases")


def pending_copy(packet: dict[str, Any]) -> dict[str, Any]:
    observed = json.loads(json.dumps(packet))
    observed["status"] = "PENDING_BLIND_REVIEW"
    observed["independent_review"] = {
        "reviewer_kind": None,
        "reviewed_at_utc": None,
        "reviewed_head": None,
    }
    for case in observed["cases"]:
        case["review"] = {
            "preferred_label": None,
            "clarity_best_labels": [],
            "usefulness_best_labels": [],
            "locale_naturalness_best_labels": [],
            "material_incremental_value": None,
            "review_notes": "",
        }
    return observed


def validate_review_derivation(
    packet: dict[str, Any], sidecar: dict[str, Any], transcript_path: Path
) -> None:
    require(
        sha256_file(transcript_path) == EXPECTED_DEVICE_TRANSCRIPT_SHA256,
        "frozen device transcript hash drifted",
    )
    expected_packet, expected_sidecar = build_review_artifacts(read_jsonl(transcript_path))
    observed = pending_copy(packet)
    require(observed == expected_packet, "review packet does not derive exactly from the frozen arms")
    require(sidecar == expected_sidecar, "review sidecar does not derive exactly from the frozen arms")
    require(rendered_json_sha256(observed) == EXPECTED_PENDING_REVIEW_PACKET_SHA256, "pending review packet hash drifted")
    require(rendered_json_sha256(sidecar) == EXPECTED_REVIEW_SIDECAR_SHA256, "review sidecar hash drifted")


def summarize_complete_review(
    packet: dict[str, Any], sidecar: dict[str, Any]
) -> dict[str, Any]:
    validate_review_packet(packet, require_complete=True)
    validate_review_sidecar(sidecar)
    sidecar_by_case = {case["case_id"]: case for case in sidecar["cases"]}
    case_results: list[dict[str, Any]] = []
    qualifying_locales_by_task: dict[str, set[str]] = {}
    for case in packet["cases"]:
        sealed = sidecar_by_case[case["case_id"]]
        all_candidates_distinct = len(
            {canonical_json(candidate_payload(candidate)) for candidate in case["candidates"]}
        ) == len(BLIND_LABELS)
        require(
            all_candidates_distinct is sealed["all_candidates_distinct"],
            f"candidate distinctness no longer matches sidecar for {case['case_id']}",
        )
        require(
            sealed["comparative_value_eligible"]
            or case["review"]["material_incremental_value"] is False,
            f"duplicate candidates cannot establish incremental value: {case['case_id']}",
        )
        preferred_label = case["review"]["preferred_label"]
        preferred_arm = None
        if preferred_label != "TIE":
            preferred_arm = sealed["label_to_arm"][preferred_label]
        luna_materially_preferred = (
            sealed["comparative_value_eligible"]
            and
            preferred_arm == "openai_luna"
            and case["review"]["material_incremental_value"] is True
        )
        if luna_materially_preferred:
            qualifying_locales_by_task.setdefault(case["task"], set()).add(case["locale"])
        case_results.append(
            {
                "case_id": case["case_id"],
                "preferred_arm": preferred_arm or "tie",
                "comparative_value_eligible": sealed["comparative_value_eligible"],
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
    require(
        sha256_file(DEVICE_TRANSCRIPT) == EXPECTED_DEVICE_TRANSCRIPT_SHA256,
        "self-test device transcript hash drifted",
    )
    device_records = read_jsonl(DEVICE_TRANSCRIPT)
    packet, sidecar = build_review_artifacts(device_records)
    validate_review_packet(packet, require_complete=False)
    validate_review_sidecar(sidecar)
    validate_review_derivation(packet, sidecar, DEVICE_TRANSCRIPT)
    require(packet["case_count"] == 24, "self-test review count drifted")
    require(all(len(case["candidates"]) == 3 for case in packet["cases"]), "arm count drifted")
    require("device" not in packet, "blind review packet must not expose device metadata")
    require("on_device_effective_sources" not in packet, "blind review packet must not expose source counts")
    for case in packet["cases"]:
        require("on_device_effective_source" not in case, "blind review case leaked effective source")
        require("on_device_raw_validation_errors" not in case, "blind review case leaked validation errors")

    missing = json.loads(json.dumps(device_records))
    missing.pop()
    try:
        validate_device_records(missing, cases)
    except RuntimeError:
        pass
    else:
        raise RuntimeError("missing on-device case must fail closed")

    wrong_hash = json.loads(json.dumps(device_records))
    wrong_hash[0]["dataset_sha256"] = "0" * 64
    try:
        validate_device_records(wrong_hash, cases)
    except RuntimeError:
        pass
    else:
        raise RuntimeError("wrong device dataset hash must fail closed")

    fallback = json.loads(json.dumps(device_records))
    model_case_id = next(
        case["case_id"] for case in sidecar["cases"]
        if case["on_device_effective_source"] == "model"
    )
    source_record = next(record for record in fallback[1:] if record["case_id"] == model_case_id)
    source_record["output"]["fact_ids"].append("invented_fact")
    _, fallback_sidecar = build_review_artifacts(fallback)
    require(
        fallback_sidecar["on_device_effective_sources"]["template_fallback_validation_error"]
        == sidecar["on_device_effective_sources"]["template_fallback_validation_error"] + 1,
        "invalid on-device output must become the deterministic template",
    )

    complete = json.loads(json.dumps(packet))
    complete["status"] = "INDEPENDENT_REVIEW_COMPLETE"
    complete["independent_review"] = {
        "reviewer_kind": "independent_pr_reviewer",
        "reviewed_at_utc": "2026-09-02T12:00:00Z",
        "reviewed_head": "abcdef0",
    }
    sealed_by_case = {case["case_id"]: case for case in sidecar["cases"]}
    eligible_locales_by_task: dict[str, set[str]] = {}
    for case in cases:
        if sealed_by_case[case["case_id"]]["comparative_value_eligible"]:
            eligible_locales_by_task.setdefault(case["task"], set()).add(case["locale"])
    selected_task = next(
        task for task, locales in eligible_locales_by_task.items()
        if {"en", "zh"}.issubset(locales)
    )
    selected_case_ids = {
        case["case_id"] for case in cases if case["task"] == selected_task
    }
    for case in complete["cases"]:
        sealed = sealed_by_case[case["case_id"]]
        label_to_arm = sealed["label_to_arm"]
        luna_label = next(label for label, arm in label_to_arm.items() if arm == "openai_luna")
        case["review"] = {
            "preferred_label": luna_label,
            "clarity_best_labels": [luna_label],
            "usefulness_best_labels": [luna_label],
            "locale_naturalness_best_labels": [luna_label],
            "material_incremental_value": (
                sealed["comparative_value_eligible"]
                and case["case_id"] in selected_case_ids
            ),
            "review_notes": "synthetic self-test decision",
        }
    summary = summarize_complete_review(complete, sidecar)
    require(summary["result"] == "PASS", "bilingual Luna preference must pass")
    empty_notes = json.loads(json.dumps(complete))
    empty_notes["cases"][0]["review"]["review_notes"] = ""
    try:
        summarize_complete_review(empty_notes, sidecar)
    except RuntimeError:
        pass
    else:
        raise RuntimeError("a complete review with empty notes must fail closed")
    for case in complete["cases"]:
        if case["task"] == selected_task and case["locale"] == "zh":
            case["review"]["material_incremental_value"] = False
    require(
        summarize_complete_review(complete, sidecar)["result"] == "NON_PASS",
        "a one-locale Luna preference must fail closed",
    )
    duplicate_claim = json.loads(json.dumps(packet))
    duplicate_claim["status"] = "INDEPENDENT_REVIEW_COMPLETE"
    duplicate_claim["independent_review"] = complete["independent_review"]
    for case in duplicate_claim["cases"]:
        case["review"] = {
            "preferred_label": "A",
            "clarity_best_labels": ["A"],
            "usefulness_best_labels": ["A"],
            "locale_naturalness_best_labels": ["A"],
            "material_incremental_value": False,
            "review_notes": "synthetic self-test decision",
        }
    ineligible_case = next(
        case for case in duplicate_claim["cases"]
        if not sealed_by_case[case["case_id"]]["comparative_value_eligible"]
    )
    ineligible_case["review"]["material_incremental_value"] = True
    try:
        summarize_complete_review(duplicate_claim, sidecar)
    except RuntimeError:
        pass
    else:
        raise RuntimeError("duplicate candidate bodies must be value-ineligible")

    tampered_sidecar = json.loads(json.dumps(sidecar))
    first_mapping = tampered_sidecar["cases"][0]["label_to_arm"]
    first_mapping["A"], first_mapping["B"] = first_mapping["B"], first_mapping["A"]
    try:
        validate_review_sidecar(tampered_sidecar)
    except RuntimeError:
        pass
    else:
        raise RuntimeError("tampered sidecar mapping must fail closed")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--extract-on-device-log", type=Path)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--build-review-packet", type=Path, metavar="ON_DEVICE_JSONL")
    parser.add_argument("--sidecar-output", type=Path)
    parser.add_argument("--check-review-packet", type=Path)
    parser.add_argument("--summarize-review", type=Path)
    parser.add_argument("--on-device-transcript", type=Path)
    parser.add_argument("--review-sidecar", type=Path)
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
        require(
            args.output is not None and args.sidecar_output is not None,
            "review-packet generation requires --output and --sidecar-output",
        )
        records = read_jsonl(args.build_review_packet)
        packet, sidecar = build_review_artifacts(records)
        for path in (args.output, args.sidecar_output):
            if path.exists():
                raise RuntimeError(f"refusing to overwrite {path}")
        args.output.write_text(rendered_json(packet), encoding="utf-8")
        args.sidecar_output.write_text(rendered_json(sidecar), encoding="utf-8")
        return 0
    if args.check_review_packet is not None:
        packet = json.loads(args.check_review_packet.read_text(encoding="utf-8"))
        validate_review_packet(packet, require_complete=args.require_complete_review)
        if packet["status"] == "PENDING_BLIND_REVIEW":
            require(
                sha256_file(args.check_review_packet) == EXPECTED_PENDING_REVIEW_PACKET_SHA256,
                "pending blind-review packet hash drifted",
            )
        require(
            (args.on_device_transcript is None) == (args.review_sidecar is None),
            "derivation check requires both --on-device-transcript and --review-sidecar",
        )
        if args.on_device_transcript is not None and args.review_sidecar is not None:
            sidecar = json.loads(args.review_sidecar.read_text(encoding="utf-8"))
            validate_review_sidecar(sidecar)
            validate_review_derivation(packet, sidecar, args.on_device_transcript)
        return 0
    if args.summarize_review is not None:
        require(
            args.output is not None
            and args.review_sidecar is not None
            and args.on_device_transcript is not None,
            "review summary requires --output, --review-sidecar, and --on-device-transcript",
        )
        packet = json.loads(args.summarize_review.read_text(encoding="utf-8"))
        sidecar = json.loads(args.review_sidecar.read_text(encoding="utf-8"))
        validate_review_derivation(packet, sidecar, args.on_device_transcript)
        summary = summarize_complete_review(packet, sidecar)
        if args.output.exists():
            raise RuntimeError(f"refusing to overwrite {args.output}")
        args.output.write_text(rendered_json(summary), encoding="utf-8")
        return 0
    raise RuntimeError("unreachable")


if __name__ == "__main__":
    raise SystemExit(main())
