#!/usr/bin/env python3
"""Validate commercialization phase-state records structurally.

The phase map is durable project state, not incidental prose.  This parser deliberately
checks its headings and nearby ``Status:`` records rather than making each later phase add
another collection of one-off grep strings to the shell gate.
"""

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


HEADING = re.compile(
    r"^(?P<level>#{2,4})\s+(?P<identifier>(?:(?:COM-)?C(?:\d+(?:\.\d+)?[A-Z]?)(?:-\d+[A-Z]?)?|G\d+))(?=\s+—|\s*$)"
)
ANY_HEADING = re.compile(r"^(?P<level>#{2,6})\s+")
STATUS_START = re.compile(r"^Status:\s+\*\*(?P<text>.*)$")
PENDING_REVIEW = re.compile(r"pending (?:independent )?review", re.IGNORECASE)
DONE = re.compile(r"\bdone\b", re.IGNORECASE)
BLOCKED = re.compile(r"\bblocked\b", re.IGNORECASE)
IN_PROGRESS = re.compile(r"\bin progress\b", re.IGNORECASE)
PARALLEL = re.compile(r"\bparallel development\b", re.IGNORECASE)
PR_NUMBER = re.compile(r"\bPR\s*#\d+\b", re.IGNORECASE)
MERGE_SHA = re.compile(r"`[0-9a-f]{7,40}`", re.IGNORECASE)
TASK_ITEM = re.compile(r"^- \[(?P<marker>[xB~ ])\]\s+")

STATE_PATTERNS = {
    "done": DONE,
    "blocked": BLOCKED,
    "in_progress": IN_PROGRESS,
    "pending_review": PENDING_REVIEW,
    "parallel": PARALLEL,
}

# C0A/C0B were documentation/bootstrap gates whose original completion records predate the
# status-line merge-evidence contract. Keep these exceptions explicit and narrow; every later
# Done phase must carry both PR number and merge SHA in its own status record.
LEGACY_DONE_EVIDENCE_EXCEPTIONS = {
    "COM-C0A",
    "COM-C0B",
}


@dataclass(frozen=True)
class PhaseStatus:
    identifier: str
    text: str
    source: Path
    line: int


@dataclass(frozen=True)
class SectionExpectation:
    source: Path
    identifier: str
    state: str
    task_marker: str


def parse_statuses(
    source: Path,
    require_all_statuses: bool = False,
    expected_identifiers: frozenset[str] = frozenset(),
) -> tuple[list[PhaseStatus], list[str]]:
    lines = source.read_text(encoding="utf-8").splitlines()
    statuses: list[PhaseStatus] = []
    errors: list[str] = []
    discovered_top_level_identifiers: set[str] = set()

    for index, line in enumerate(lines):
        heading = HEADING.match(line)
        if heading is None:
            continue

        identifier = heading.group("identifier")
        if heading.group("level") == "##":
            discovered_top_level_identifiers.add(identifier)
        candidates: list[tuple[int, str]] = []
        for candidate_index in range(index + 1, len(lines)):
            candidate = lines[candidate_index]
            if ANY_HEADING.match(candidate) is not None:
                break
            status = STATUS_START.match(candidate)
            if status is not None:
                text = status.group("text")
                continuation = candidate_index
                while "**" not in text and continuation + 1 < len(lines):
                    continuation += 1
                    if ANY_HEADING.match(lines[continuation]) is not None:
                        break
                    text = f"{text} {lines[continuation].strip()}"
                if "**" not in text:
                    errors.append(
                        f"{source}:{candidate_index + 1} ({identifier}): Status line is missing closing **"
                    )
                else:
                    candidates.append((candidate_index, text.replace("**", "").strip()))

        # Every durable top-level phase has one unambiguous Status record. Sources that opt into
        # require-all extend the same rule to every recognized subphase without maintaining a
        # per-identifier registration list. Historical packet sources may remain prose-only by
        # deliberately not selecting require-all.
        is_top_level_phase = heading.group("level") == "##" and identifier.startswith("COM-")
        requires_status = is_top_level_phase or require_all_statuses
        if requires_status and len(candidates) != 1:
            errors.append(
                f"{source}:{index + 1} ({identifier}): expected exactly one direct Status line, "
                f"found {len(candidates)}"
            )
        if candidates:
            candidate_index, text = candidates[0]
            statuses.append(PhaseStatus(identifier, text, source, candidate_index + 1))

    # require-all detects a missing Status only while its heading remains. The authoritative map
    # therefore also supplies a stable approved top-level ID set so deletion of a whole phase is
    # loud. Nested subphases remain automatic: adding one does not require editing this set.
    for identifier in sorted(expected_identifiers - discovered_top_level_identifiers):
        errors.append(f"{source} ({identifier}): expected phase heading is missing")
    unexpected_identifiers = (
        discovered_top_level_identifiers - expected_identifiers if expected_identifiers else set()
    )
    for identifier in sorted(unexpected_identifiers):
        errors.append(f"{source} ({identifier}): phase heading is not in the approved ID set")
    return statuses, errors


def validate(statuses: Iterable[PhaseStatus]) -> list[str]:
    errors: list[str] = []
    for status in statuses:
        text = status.text
        location = f"{status.source}:{status.line} ({status.identifier})"
        is_done = DONE.search(text) is not None
        is_pending_review = PENDING_REVIEW.search(text) is not None
        is_blocked = BLOCKED.search(text) is not None
        is_in_progress = IN_PROGRESS.search(text) is not None
        is_parallel = PARALLEL.search(text) is not None
        classifications = sum((is_done, is_pending_review, is_blocked, is_in_progress, is_parallel))

        if classifications == 0:
            errors.append(f"{location}: Status does not declare a recognized phase state")
        elif classifications > 1:
            errors.append(f"{location}: Status declares conflicting phase states")
        if is_done and is_pending_review:
            errors.append(f"{location}: Done phase cannot remain pending review")
        if is_blocked and (is_done or is_in_progress):
            errors.append(f"{location}: blocked phase cannot also be Done or In Progress")
        if is_done and status.identifier not in LEGACY_DONE_EVIDENCE_EXCEPTIONS:
            if PR_NUMBER.search(text) is None or MERGE_SHA.search(text) is None:
                errors.append(
                    f"{location}: Done phase must record its PR number and merge SHA "
                    "in the Status line"
                )
    return errors


def validate_section_expectations(
    expectations: Iterable[SectionExpectation],
) -> list[str]:
    """Bind an expected state and task marker to one exact phase section.

    A repository-wide string search cannot prove phase authorization: summary prose can satisfy
    it while the durable section silently changes. These expectations resolve one unique heading,
    use only that heading's direct Status record, and inspect only task items owned by that section.
    """

    errors: list[str] = []
    lines_by_source: dict[Path, list[str]] = {}
    statuses_by_source: dict[Path, list[PhaseStatus]] = {}

    for expectation in expectations:
        lines = lines_by_source.setdefault(
            expectation.source,
            expectation.source.read_text(encoding="utf-8").splitlines(),
        )
        statuses = statuses_by_source.setdefault(
            expectation.source,
            parse_statuses(expectation.source)[0],
        )
        headings = [
            (index, match)
            for index, line in enumerate(lines)
            if (match := HEADING.match(line)) is not None
            and match.group("identifier") == expectation.identifier
        ]
        if len(headings) != 1:
            errors.append(
                f"{expectation.source} ({expectation.identifier}): expected exactly one phase "
                f"heading, found {len(headings)}"
            )
            continue

        heading_index, heading = headings[0]
        heading_level = len(heading.group("level"))
        section_end = len(lines)
        for candidate_index in range(heading_index + 1, len(lines)):
            candidate = ANY_HEADING.match(lines[candidate_index])
            if candidate is not None and len(candidate.group("level")) <= heading_level:
                section_end = candidate_index
                break

        phase_statuses = [
            status for status in statuses if status.identifier == expectation.identifier
        ]
        if len(phase_statuses) != 1:
            errors.append(
                f"{expectation.source} ({expectation.identifier}): expected exactly one parsed "
                f"Status record, found {len(phase_statuses)}"
            )
        else:
            status = phase_statuses[0]
            matched_states = [
                state
                for state, pattern in STATE_PATTERNS.items()
                if pattern.search(status.text) is not None
            ]
            if matched_states != [expectation.state]:
                errors.append(
                    f"{expectation.source}:{status.line} ({expectation.identifier}): expected "
                    f"state {expectation.state}, found {matched_states or ['unrecognized']}"
                )

        task_markers = [
            match.group("marker")
            for line in lines[heading_index + 1 : section_end]
            if (match := TASK_ITEM.match(line)) is not None
        ]
        if task_markers != [expectation.task_marker]:
            errors.append(
                f"{expectation.source}:{heading_index + 1} ({expectation.identifier}): expected "
                f"one [{expectation.task_marker}] task, found "
                f"{[f'[{marker}]' for marker in task_markers] or ['none']}"
            )

    return errors


def self_test() -> None:
    source = Path("self-test.md")
    valid = [
        PhaseStatus("C3-04", "Done after independent review; PR #40 merged as `9448ca9`.", source, 1),
        PhaseStatus("C4A-01", "Implementation complete pending independent review.", source, 2),
        PhaseStatus("C4A-02", "Blocked by C4A-01.", source, 3),
        PhaseStatus("COM-C0A", "Done.", source, 4),
        PhaseStatus("C5-03", "Done through PR #80 (`a587f42`).", source, 5),
        PhaseStatus("C5-04", "Implementation complete pending independent review.", source, 6),
    ]
    if validate(valid):
        raise AssertionError("valid structural phase states were rejected")

    cases = (
        (
            PhaseStatus("C4A-01", "Done pending independent review; PR #51 merged as `16dddf8`.", source, 5),
            "pending review",
        ),
        (PhaseStatus("C4A-01", "Done.", source, 6), "PR number and merge SHA"),
        (PhaseStatus("C4A-02", "Blocked and In Progress.", source, 7), "blocked phase"),
        (PhaseStatus("C4A-02", "Deferred until later.", source, 8), "recognized phase state"),
        (PhaseStatus("C4A-02", "Pending review and Blocked.", source, 9), "conflicting phase states"),
    )
    for status, expected in cases:
        errors = validate([status])
        if not any(expected in error for error in errors):
            raise AssertionError(f"self-test did not reject {status.text!r}: {errors!r}")

    with_temp_map = (
        "## COM-C4A — Money migration delta\n"
        "Status: **In Progress.**\n\n"
        "### C4A-01 — Delta\n"
        "Status: **Implementation complete pending independent review.**\n\n"
        "### C4A-02 — Required migration\n"
        "Status: **Blocked by C4A-01 review, CI, and merge.**\n\n"
        "### C4A-03 — Matrix\n"
        "Status: **Blocked by C4A-02 review, CI, and merge.**\n"
    )
    import subprocess
    import tempfile

    with tempfile.TemporaryDirectory() as directory:
        map_path = Path(directory) / "map.md"
        map_path.write_text(with_temp_map, encoding="utf-8")
        expected = frozenset({"COM-C4A"})
        parsed, parse_errors = parse_statuses(map_path, True, expected)
        if parse_errors or validate(parsed):
            raise AssertionError("valid C4A pending/blocked phase map was rejected")
        if {status.identifier for status in parsed} != {"COM-C4A", "C4A-01", "C4A-02", "C4A-03"}:
            raise AssertionError("heading parser missed a C4A phase status")

        missing_path = Path(directory) / "missing.md"
        missing_path.write_text("## COM-C4A — Missing\n", encoding="utf-8")
        _, missing_errors = parse_statuses(missing_path)
        if not any("exactly one direct Status" in error for error in missing_errors):
            raise AssertionError("self-test did not reject a missing top-level Status")

        duplicate_path = Path(directory) / "duplicate.md"
        duplicate_path.write_text(
            "## COM-C4A — Duplicate\nStatus: **In Progress.**\nStatus: **Blocked.**\n",
            encoding="utf-8",
        )
        _, duplicate_errors = parse_statuses(duplicate_path)
        if not any("found 2" in error for error in duplicate_errors):
            raise AssertionError("self-test did not reject duplicate top-level Status records")

        missing_nested_path = Path(directory) / "missing-nested.md"
        missing_nested_path.write_text(
            with_temp_map.replace(
                "Status: **Blocked by C4A-01 review, CI, and merge.**\n\n"
                "### C4A-03",
                "### C4A-03",
            ),
            encoding="utf-8",
        )
        _, missing_nested_errors = parse_statuses(missing_nested_path, True)
        if not any("(C4A-02): expected exactly one direct Status line, found 0" in error
                   for error in missing_nested_errors):
            raise AssertionError("self-test did not reject a missing C4A-02 Status")

        duplicate_nested_path = Path(directory) / "duplicate-nested.md"
        duplicate_nested_path.write_text(
            with_temp_map.replace(
                "Status: **Blocked by C4A-01 review, CI, and merge.**",
                "Status: **Blocked by C4A-01 review, CI, and merge.**\n"
                "Status: **Done through PR #99 (`abcdef0`).**",
            ),
            encoding="utf-8",
        )
        _, duplicate_nested_errors = parse_statuses(duplicate_nested_path, True)
        if not any("(C4A-02): expected exactly one direct Status line, found 2" in error
                   for error in duplicate_nested_errors):
            raise AssertionError("self-test did not reject duplicate C4A-02 Status records")

        c3_missing_status_path = Path(directory) / "c3-missing-status.md"
        c3_missing_status_path.write_text(
            "## C3-01 — Paywall\n"
            "Customer terms remain truthful.\n\n"
            "## C3-02 — Trial lifecycle\n"
            "Status: **Done through PR #34 (`12d9217`).**\n",
            encoding="utf-8",
        )
        _, c3_missing_status_errors = parse_statuses(c3_missing_status_path, True)
        if not any("(C3-01): expected exactly one direct Status line, found 0" in error
                   for error in c3_missing_status_errors):
            raise AssertionError("require-all did not reject a deleted C3-style Status")

        missing_heading_path = Path(directory) / "missing-heading.md"
        missing_heading_path.write_text(
            with_temp_map.replace(
                "## COM-C4A — Money migration delta",
                "Money migration delta",
            ),
            encoding="utf-8",
        )
        _, missing_heading_errors = parse_statuses(missing_heading_path, True, expected)
        if not any("expected phase heading is missing" in error
                   for error in missing_heading_errors):
            raise AssertionError("stable phase-ID set did not reject a deleted heading")

        unexpected_heading_path = Path(directory) / "unexpected-heading.md"
        unexpected_heading_path.write_text(
            with_temp_map + "\n## COM-C4B — Unapproved\nStatus: **Blocked by COM-C4A.**\n",
            encoding="utf-8",
        )
        _, unexpected_heading_errors = parse_statuses(unexpected_heading_path, True, expected)
        if not any("not in the approved ID set" in error
                   for error in unexpected_heading_errors):
            raise AssertionError("stable phase-ID set did not reject an unapproved heading")

        c6_map = (
            "## COM-C6 — Release preflight\n"
            "Status: **In Progress.**\n\n"
            "### C6-01 — Matrix\n"
            "Status: **Done through PR #86 (`015d00e`).**\n\n"
            "- [x] Run the matrix.\n\n"
            "### C6-02 — Signed-device review\n"
            "Status: **Blocked pending owner entry.**\n\n"
            "- [B] Review signed-device evidence.\n\n"
            "### C6-03 — TestFlight\n"
            "Status: **Blocked by C6-02.**\n\n"
            "- [B] Upload after approval.\n"
        )
        c6_path = Path(directory) / "c6.md"
        c6_path.write_text(c6_map, encoding="utf-8")
        c6_expectations = (
            SectionExpectation(c6_path, "C6-01", "done", "x"),
            SectionExpectation(c6_path, "C6-02", "blocked", "B"),
            SectionExpectation(c6_path, "C6-03", "blocked", "B"),
        )

        def run_c6_cli() -> subprocess.CompletedProcess[str]:
            return subprocess.run(
                [
                    sys.executable,
                    "-B",
                    str(Path(__file__).resolve()),
                    "--expect-section",
                    f"{c6_path}:C6-01:done:x",
                    "--expect-section",
                    f"{c6_path}:C6-02:blocked:B",
                    "--expect-section",
                    f"{c6_path}:C6-03:blocked:B",
                    str(c6_path),
                ],
                check=False,
                capture_output=True,
                text=True,
            )

        if validate_section_expectations(c6_expectations):
            raise AssertionError("valid C6 section-state/task bindings were rejected")
        valid_c6_cli = run_c6_cli()
        if valid_c6_cli.returncode != 0:
            raise AssertionError(
                f"valid C6 CLI fixture was rejected: {valid_c6_cli.stderr!r}"
            )

        mutations = (
            (
                "C6-01 Done to In Progress",
                c6_map.replace(
                    "Status: **Done through PR #86 (`015d00e`).**",
                    "Status: **In Progress.**",
                    1,
                ),
                "(C6-01): expected state done",
            ),
            (
                "C6-02 Blocked to next-line In Progress",
                c6_map.replace(
                    "Status: **Blocked pending owner entry.**",
                    "Status: **In Progress.**",
                    1,
                ),
                "(C6-02): expected state blocked",
            ),
            (
                "C6-03 Blocked to In Progress",
                c6_map.replace(
                    "Status: **Blocked by C6-02.**",
                    "Status: **In Progress.**",
                    1,
                ),
                "(C6-03): expected state blocked",
            ),
            (
                "C6-01 completed task to blocked marker",
                c6_map.replace("- [x] Run the matrix.", "- [B] Run the matrix.", 1),
                "(C6-01): expected one [x] task",
            ),
            (
                "C6-02 blocked task to completed marker",
                c6_map.replace(
                    "- [B] Review signed-device evidence.",
                    "- [x] Review signed-device evidence.",
                    1,
                ),
                "(C6-02): expected one [B] task",
            ),
            (
                "C6-03 blocked task to completed marker",
                c6_map.replace(
                    "- [B] Upload after approval.",
                    "- [x] Upload after approval.",
                    1,
                ),
                "(C6-03): expected one [B] task",
            ),
        )
        for label, mutated_map, expected_error in mutations:
            c6_path.write_text(mutated_map, encoding="utf-8")
            errors = validate_section_expectations(c6_expectations)
            if not any(expected_error in error for error in errors):
                raise AssertionError(f"self-test did not reject {label}: {errors!r}")
            cli_result = run_c6_cli()
            if cli_result.returncode == 0 or expected_error not in cli_result.stderr:
                raise AssertionError(
                    f"CLI self-test did not fail closed for {label}: "
                    f"returncode={cli_result.returncode}, stderr={cli_result.stderr!r}"
                )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("sources", type=Path, nargs="*")
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument(
        "--require-all-status",
        action="append",
        default=[],
        type=Path,
        metavar="SOURCE",
        help="require exactly one direct Status for every recognized heading in SOURCE",
    )
    parser.add_argument(
        "--expect-identifiers",
        action="append",
        default=[],
        metavar="SOURCE:IDENTIFIER[,IDENTIFIER...]",
        help="require the stable approved top-level phase-heading ID set in SOURCE",
    )
    parser.add_argument(
        "--expect-section",
        action="append",
        default=[],
        metavar="SOURCE:IDENTIFIER:STATE:TASK_MARKER",
        help="bind one phase section to its exact state and sole task marker",
    )
    args = parser.parse_args()

    if args.self_test:
        self_test()
        return 0
    if not args.sources:
        parser.error("provide at least one Markdown source")

    sources = set(args.sources)
    require_all_sources = set(args.require_all_status)
    unknown_require_all = require_all_sources - sources
    if unknown_require_all:
        parser.error(f"require-all source is not an input source: {sorted(unknown_require_all)[0]}")

    expected_by_source: dict[Path, set[str]] = {source: set() for source in args.sources}
    for expectation in args.expect_identifiers:
        source_text, separator, identifier_text = expectation.rpartition(":")
        source = Path(source_text)
        identifiers = {identifier for identifier in identifier_text.split(",") if identifier}
        if not separator or not source_text or not identifiers:
            parser.error(f"invalid --expect-identifiers value: {expectation!r}")
        if source not in sources:
            parser.error(f"expected-identifiers source is not an input source: {source}")
        expected_by_source[source].update(identifiers)

    section_expectations: list[SectionExpectation] = []
    for expectation in args.expect_section:
        try:
            source_text, identifier, state, task_marker = expectation.rsplit(":", 3)
        except ValueError:
            parser.error(f"invalid --expect-section value: {expectation!r}")
        source = Path(source_text)
        if source not in sources:
            parser.error(f"expect-section source is not an input source: {source}")
        if state not in STATE_PATTERNS:
            parser.error(f"unknown expect-section state: {state!r}")
        if task_marker not in {"x", "B", "~"}:
            parser.error(f"unknown expect-section task marker: {task_marker!r}")
        section_expectations.append(
            SectionExpectation(source, identifier, state, task_marker)
        )

    parsed = [
        parse_statuses(
            source,
            source in require_all_sources,
            frozenset(expected_by_source[source]),
        )
        for source in args.sources
    ]
    errors = [error for _, parse_errors in parsed for error in parse_errors]
    errors.extend(validate(status for statuses, _ in parsed for status in statuses))
    errors.extend(validate_section_expectations(section_expectations))
    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
