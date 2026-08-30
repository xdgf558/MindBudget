#!/usr/bin/env python3
"""Fail closed when App-target required-reason API use and PrivacyInfo.xcprivacy drift."""

from __future__ import annotations

import argparse
import plistlib
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path
from typing import Any


API_TYPE_KEY = "NSPrivacyAccessedAPIType"
API_REASONS_KEY = "NSPrivacyAccessedAPITypeReasons"
USER_DEFAULTS = "NSPrivacyAccessedAPICategoryUserDefaults"
FILE_TIMESTAMP = "NSPrivacyAccessedAPICategoryFileTimestamp"
SYSTEM_BOOT_TIME = "NSPrivacyAccessedAPICategorySystemBootTime"
DISK_SPACE = "NSPrivacyAccessedAPICategoryDiskSpace"
ACTIVE_KEYBOARDS = "NSPrivacyAccessedAPICategoryActiveKeyboards"

# Apple documents these five categories at
# https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/
# nsprivacyaccessedapitypes/nsprivacyaccessedapitype
# Keep this inventory explicit: an Apple list change must be reviewed instead of silently being
# treated as covered by an old scanner.
REVIEWED_CATEGORY_SYMBOLS = {
    USER_DEFAULTS: frozenset({"UserDefaults", "NSUserDefaults", "AppStorage"}),
    FILE_TIMESTAMP: frozenset(
        {
            "creationDate",
            "modificationDate",
            "fileModificationDate",
            "contentModificationDateKey",
            "creationDateKey",
            "NSFileCreationDate",
            "NSFileModificationDate",
            "NSURLContentModificationDateKey",
            "NSURLCreationDateKey",
            "stat",
            "fstat",
            "fstatat",
            "lstat",
        }
    ),
    SYSTEM_BOOT_TIME: frozenset({"systemUptime", "mach_absolute_time"}),
    DISK_SPACE: frozenset(
        {
            "volumeAvailableCapacityKey",
            "volumeAvailableCapacityForImportantUsageKey",
            "volumeAvailableCapacityForOpportunisticUsageKey",
            "volumeTotalCapacityKey",
            "NSURLVolumeAvailableCapacityKey",
            "NSURLVolumeAvailableCapacityForImportantUsageKey",
            "NSURLVolumeAvailableCapacityForOpportunisticUsageKey",
            "NSURLVolumeTotalCapacityKey",
            "systemFreeSize",
            "systemSize",
            "NSFileSystemFreeSize",
            "NSFileSystemSize",
            "statfs",
            "statvfs",
            "fstatfs",
            "fstatvfs",
        }
    ),
    ACTIVE_KEYBOARDS: frozenset({"activeInputModes"}),
}

# These functions can access timestamps, disk metadata, or both depending on their attribute list.
# A token-only gate cannot infer that list safely, so any use requires a new explicit classifier.
AMBIGUOUS_FILE_METADATA_SYMBOLS = frozenset(
    {"getattrlist", "getattrlistbulk", "fgetattrlist", "getattrlistat"}
)
SOURCE_SUFFIXES = frozenset({".swift", ".m", ".mm", ".c", ".cc", ".cpp", ".h", ".hpp"})


@dataclass(frozen=True)
class CodeToken:
    value: str
    offset: int


@dataclass(frozen=True)
class SourceOccurrence:
    category: str
    symbol: str
    path: Path
    line: int


def _string_opener(source: str, start: int) -> tuple[int, int, str] | None:
    """Return raw-hash count, quote count, and quote scalar for a string opener."""

    if source[start] in {'"', "'"}:
        quote = source[start]
        return (0, 3 if quote == '"' and source.startswith('"""', start) else 1, quote)
    if source[start] != "#":
        return None

    hashes = 0
    cursor = start
    while cursor < len(source) and source[cursor] == "#":
        hashes += 1
        cursor += 1
    if cursor >= len(source) or source[cursor] != '"':
        return None
    return (hashes, 3 if source.startswith('"""', cursor) else 1, '"')


def _skip_block_comment(source: str, start: int) -> int:
    depth = 1
    cursor = start + 2
    while cursor < len(source) and depth:
        if source.startswith("/*", cursor):
            depth += 1
            cursor += 2
        elif source.startswith("*/", cursor):
            depth -= 1
            cursor += 2
        else:
            cursor += 1
    return cursor


def _matching_parenthesis(source: str, opening: int) -> int | None:
    depth = 1
    cursor = opening + 1
    while cursor < len(source):
        if source.startswith("//", cursor):
            newline = source.find("\n", cursor + 2)
            cursor = len(source) if newline == -1 else newline + 1
            continue
        if source.startswith("/*", cursor):
            cursor = _skip_block_comment(source, cursor)
            continue
        if _string_opener(source, cursor) is not None:
            cursor, _ = _skip_string(source, cursor, collect_interpolations=False, base_offset=0)
            continue
        if source[cursor] == "(":
            depth += 1
        elif source[cursor] == ")":
            depth -= 1
            if depth == 0:
                return cursor
        cursor += 1
    return None


def _skip_string(
    source: str,
    start: int,
    *,
    collect_interpolations: bool,
    base_offset: int,
) -> tuple[int, list[CodeToken]]:
    opener = _string_opener(source, start)
    if opener is None:
        raise ValueError("string skip requested at a non-string token")
    hashes, quote_count, quote = opener
    quote_start = start + hashes
    cursor = quote_start + quote_count
    closing = quote * quote_count + "#" * hashes
    interpolation = "\\" + "#" * hashes + "("
    tokens: list[CodeToken] = []

    while cursor < len(source):
        if quote == '"' and source.startswith(interpolation, cursor):
            expression_start = cursor + len(interpolation)
            expression_end = _matching_parenthesis(source, expression_start - 1)
            if expression_end is None:
                return (len(source), tokens)
            if collect_interpolations:
                tokens.extend(
                    _code_tokens(
                        source[expression_start:expression_end],
                        base_offset + expression_start,
                    )
                )
            cursor = expression_end + 1
            continue
        if source.startswith(closing, cursor):
            return (cursor + len(closing), tokens)
        if source[cursor] == "\\":
            if hashes == 0:
                cursor = min(len(source), cursor + 2)
                continue
            raw_escape = "\\" + "#" * hashes
            if source.startswith(raw_escape, cursor):
                cursor += len(raw_escape)
                if cursor < len(source):
                    cursor += 1
            else:
                cursor += 1
            continue
        cursor += 1
    return (len(source), tokens)


def _code_tokens(source: str, base_offset: int = 0) -> list[CodeToken]:
    """Return identifier tokens after removing nested comments and literal string content."""

    tokens: list[CodeToken] = []
    cursor = 0
    while cursor < len(source):
        if source.startswith("//", cursor):
            newline = source.find("\n", cursor + 2)
            cursor = len(source) if newline == -1 else newline + 1
            continue
        if source.startswith("/*", cursor):
            cursor = _skip_block_comment(source, cursor)
            continue
        if _string_opener(source, cursor) is not None:
            cursor, interpolation_tokens = _skip_string(
                source,
                cursor,
                collect_interpolations=True,
                base_offset=base_offset,
            )
            tokens.extend(interpolation_tokens)
            continue
        character = source[cursor]
        if character == "`":
            closing = source.find("`", cursor + 1)
            if closing != -1:
                identifier = source[cursor + 1 : closing]
                if identifier:
                    tokens.append(CodeToken(identifier, base_offset + cursor))
                cursor = closing + 1
                continue
        if character.isascii() and (character.isalpha() or character == "_"):
            end = cursor + 1
            while end < len(source) and source[end].isascii() and (
                source[end].isalnum() or source[end] == "_"
            ):
                end += 1
            tokens.append(CodeToken(source[cursor:end], base_offset + cursor))
            cursor = end
            continue
        cursor += 1
    return tokens


def declared_api_categories(manifest: Any) -> tuple[set[str], list[str]]:
    errors: list[str] = []
    if not isinstance(manifest, dict):
        return set(), ["privacy manifest root must be a dictionary"]
    declarations = manifest.get("NSPrivacyAccessedAPITypes")
    if not isinstance(declarations, list):
        return set(), ["NSPrivacyAccessedAPITypes must be an array"]

    categories: list[str] = []
    for index, declaration in enumerate(declarations):
        label = f"NSPrivacyAccessedAPITypes[{index}]"
        if not isinstance(declaration, dict) or frozenset(declaration) != {
            API_TYPE_KEY,
            API_REASONS_KEY,
        }:
            errors.append(f"{label} must contain exactly type and reasons")
            continue
        category = declaration.get(API_TYPE_KEY)
        reasons = declaration.get(API_REASONS_KEY)
        if not isinstance(category, str) or not category:
            errors.append(f"{label} has an invalid category")
            continue
        if not isinstance(reasons, list) or not reasons or not all(
            isinstance(reason, str) and reason for reason in reasons
        ):
            errors.append(f"{label} must contain nonempty reason strings")
        categories.append(category)

    if len(categories) != len(set(categories)):
        errors.append("required-reason API categories must be unique")
    return set(categories), errors


def scan_source_tree(source_root: Path) -> tuple[list[SourceOccurrence], list[str]]:
    errors: list[str] = []
    occurrences: list[SourceOccurrence] = []
    if not source_root.is_dir():
        return [], [f"App source root does not exist: {source_root}"]

    source_paths = sorted(
        path
        for path in source_root.rglob("*")
        if path.is_file() and path.suffix.lower() in SOURCE_SUFFIXES
    )
    if not source_paths:
        return [], [f"App source root contains no reviewed source files: {source_root}"]

    symbol_categories = {
        symbol: category
        for category, symbols in REVIEWED_CATEGORY_SYMBOLS.items()
        for symbol in symbols
    }
    for path in source_paths:
        try:
            source = path.read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError) as error:
            errors.append(f"Unable to read App source {path}: {error}")
            continue
        for token in _code_tokens(source):
            line = source.count("\n", 0, token.offset) + 1
            if token.value in AMBIGUOUS_FILE_METADATA_SYMBOLS:
                errors.append(
                    f"{path}:{line}: {token.value} is an ambiguous timestamp/disk-space "
                    "required-reason API; add an explicit reviewed classifier before use"
                )
                continue
            category = symbol_categories.get(token.value)
            if category is not None:
                occurrences.append(SourceOccurrence(category, token.value, path, line))
    return occurrences, errors


def validate_contract(source_root: Path, manifest_path: Path) -> list[str]:
    try:
        with manifest_path.open("rb") as stream:
            manifest = plistlib.load(stream)
    except (OSError, plistlib.InvalidFileException) as error:
        return [f"Unable to read privacy manifest {manifest_path}: {error}"]

    declared, errors = declared_api_categories(manifest)
    occurrences, scan_errors = scan_source_tree(source_root)
    errors.extend(scan_errors)
    observed = {occurrence.category for occurrence in occurrences}

    missing = sorted(observed - declared)
    extra = sorted(declared - observed)
    if missing:
        errors.append(f"App source uses undeclared required-reason API categories: {missing}")
        for occurrence in occurrences:
            if occurrence.category in missing:
                errors.append(
                    f"  {occurrence.path}:{occurrence.line}: "
                    f"{occurrence.symbol} -> {occurrence.category}"
                )
    if extra:
        errors.append(f"Privacy manifest declares unobserved required-reason categories: {extra}")

    if declared == {USER_DEFAULTS}:
        declarations = manifest["NSPrivacyAccessedAPITypes"]
        user_defaults_declaration = next(
            item for item in declarations if item[API_TYPE_KEY] == USER_DEFAULTS
        )
        if user_defaults_declaration[API_REASONS_KEY] != ["CA92.1"]:
            errors.append("App-only UserDefaults use must remain exactly CA92.1")
    return errors


def _manifest(categories: list[tuple[str, list[str]]]) -> dict[str, Any]:
    return {
        "NSPrivacyAccessedAPITypes": [
            {API_TYPE_KEY: category, API_REASONS_KEY: reasons}
            for category, reasons in categories
        ]
    }


def self_test() -> None:
    with tempfile.TemporaryDirectory() as temporary:
        root = Path(temporary)
        source_root = root / "MindBudget"
        source_root.mkdir()
        source_path = source_root / "App.swift"
        manifest_path = root / "PrivacyInfo.xcprivacy"

        def write_case(source: str, categories: list[tuple[str, list[str]]]) -> list[str]:
            source_path.write_text(source, encoding="utf-8")
            with manifest_path.open("wb") as stream:
                plistlib.dump(_manifest(categories), stream)
            return validate_contract(source_root, manifest_path)

        accepted = write_case(
            "@AppStorage(\"accepted\") var accepted = false\n"
            "let defaults = UserDefaults.standard\n",
            [(USER_DEFAULTS, ["CA92.1"])],
        )
        if accepted:
            raise AssertionError(f"accepted UserDefaults contract was rejected: {accepted}")

        ignored_literal = r'''
// ProcessInfo.processInfo.systemUptime
/* nested /* URLResourceKey.volumeTotalCapacityKey */ activeInputModes */
let ordinary = "creationDate statfs activeInputModes"
let multiline = """mach_absolute_time() modificationDate"""
let raw = #"ends with backslash\\"#
let defaults = UserDefaults.standard
'''
        if write_case(ignored_literal, [(USER_DEFAULTS, ["CA92.1"])]):
            raise AssertionError("comment/string-only symbols were treated as API use")

        missing_cases = (
            ("File Timestamp", "let key = URLResourceKey.creationDateKey", FILE_TIMESTAMP),
            ("System Boot Time", "let elapsed = ProcessInfo.processInfo.systemUptime", SYSTEM_BOOT_TIME),
            ("Disk Space", "let key = URLResourceKey.volumeAvailableCapacityKey", DISK_SPACE),
            ("Active Keyboards", "let modes = UITextInputMode.activeInputModes", ACTIVE_KEYBOARDS),
            ("C stat", "struct stat value; stat(path, &value);", FILE_TIMESTAMP),
        )
        for label, source, expected_category in missing_cases:
            errors = write_case(source, [])
            if not any(expected_category in error for error in errors):
                raise AssertionError(f"self-test failed to reject undeclared {label}: {errors}")

        interpolation_errors = write_case(
            'let value = "\\(ProcessInfo.processInfo.systemUptime)"',
            [],
        )
        if not any(SYSTEM_BOOT_TIME in error for error in interpolation_errors):
            raise AssertionError("string interpolation hid real systemUptime use")

        raw_tail_errors = write_case(
            'let marker = #"ends with backslash\\\\"#\n'
            "let elapsed = ProcessInfo.processInfo.systemUptime\n",
            [],
        )
        if not any(SYSTEM_BOOT_TIME in error for error in raw_tail_errors):
            raise AssertionError("raw-string trailing backslash hid following API use")

        ambiguous = write_case("getattrlist(path, &list, size, options)", [])
        if not any("ambiguous timestamp/disk-space" in error for error in ambiguous):
            raise AssertionError("ambiguous file metadata API was not rejected")

        extra = write_case(
            "let defaults = UserDefaults.standard",
            [
                (USER_DEFAULTS, ["CA92.1"]),
                (SYSTEM_BOOT_TIME, ["35F9.1"]),
            ],
        )
        if not any("unobserved" in error for error in extra):
            raise AssertionError("unobserved manifest category was not rejected")

        wrong_reason = write_case(
            "let defaults = UserDefaults.standard",
            [(USER_DEFAULTS, ["1C8F.1"])],
        )
        if not any("CA92.1" in error for error in wrong_reason):
            raise AssertionError("wrong UserDefaults reason was not rejected")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--source-root", default="MindBudget")
    parser.add_argument(
        "--manifest",
        default="MindBudget/Resources/PrivacyInfo.xcprivacy",
    )
    arguments = parser.parse_args()
    project_root = Path(__file__).resolve().parent.parent
    try:
        if arguments.self_test:
            self_test()
        errors = validate_contract(
            project_root / arguments.source_root,
            project_root / arguments.manifest,
        )
        if errors:
            raise ValueError("\n".join(errors))
        print("Required-reason API source/manifest contract passed")
        return 0
    except (AssertionError, ValueError) as error:
        print(str(error), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
