#!/usr/bin/env python3
"""Check the structural C4B design contract and prevent accidental managed SwiftData sync."""

from __future__ import annotations

import argparse
from dataclasses import dataclass
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


@dataclass(frozen=True)
class SwiftToken:
    """One code token from a deliberately small, comment/string-free Swift lexer."""

    value: str
    offset: int


def _string_opener(source: str, start: int) -> tuple[int, int] | None:
    """Return (raw-hash-count, quote-count) for a Swift string opening at ``start``."""

    if source[start] == '"':
        return (0, 3 if source.startswith('\"\"\"', start) else 1)
    if source[start] != '#':
        return None

    hashes = 0
    cursor = start
    while cursor < len(source) and source[cursor] == '#':
        hashes += 1
        cursor += 1
    if cursor >= len(source) or source[cursor] != '"':
        return None
    return (hashes, 3 if source.startswith('\"\"\"', cursor) else 1)


def _skip_block_comment(source: str, start: int) -> int:
    """Skip Swift's nestable block comments, failing closed by consuming an unclosed tail."""

    depth = 1
    cursor = start + 2
    while cursor < len(source) and depth:
        if source.startswith('/*', cursor):
            depth += 1
            cursor += 2
        elif source.startswith('*/', cursor):
            depth -= 1
            cursor += 2
        else:
            cursor += 1
    return cursor


def _skip_string(
    source: str,
    start: int,
    *,
    collect_interpolations: bool,
    base_offset: int,
) -> tuple[int, list[SwiftToken]]:
    """Skip one Swift normal/raw and single/multiline string.

    Literal text never becomes a token, while code inside a Swift interpolation remains code and
    is lexed recursively. This keeps a comment or a documentation/example string from satisfying
    the `.none` contract without letting a real construction hidden in interpolation evade it.
    """

    opener = _string_opener(source, start)
    if opener is None:
        raise ValueError("string skip requested at a non-string token")
    hashes, quote_count = opener
    quote_start = start + hashes
    cursor = quote_start + quote_count
    closing = '"' * quote_count + '#' * hashes
    interpolation = '\\' + '#' * hashes + '('
    tokens: list[SwiftToken] = []

    while cursor < len(source):
        if source.startswith(interpolation, cursor):
            expression_start = cursor + len(interpolation)
            expression_end = _matching_parenthesis(source, expression_start - 1)
            if expression_end is None:
                return (len(source), tokens)
            if collect_interpolations:
                tokens.extend(_swift_code_tokens(source[expression_start:expression_end], base_offset + expression_start))
            cursor = expression_end + 1
            continue
        if source.startswith(closing, cursor):
            return (cursor + len(closing), tokens)
        if source[cursor] == '\\':
            # A quote only terminates a string when it is not escaped. Raw-string escapes carry
            # exactly the opening number of hashes; accepting an ordinary escaped next character
            # as well is conservative and prevents literal text from becoming code tokens.
            cursor += 1
            if hashes and source.startswith('#' * hashes, cursor):
                cursor += hashes
            if cursor < len(source):
                cursor += 1
            continue
        cursor += 1
    return (len(source), tokens)


def _matching_parenthesis(source: str, opening_parenthesis: int) -> int | None:
    """Find the closing parenthesis while honoring Swift comments and strings."""

    depth = 1
    cursor = opening_parenthesis + 1
    while cursor < len(source):
        if source.startswith('//', cursor):
            newline = source.find('\n', cursor + 2)
            cursor = len(source) if newline == -1 else newline + 1
            continue
        if source.startswith('/*', cursor):
            cursor = _skip_block_comment(source, cursor)
            continue
        if _string_opener(source, cursor) is not None:
            cursor, _ = _skip_string(
                source,
                cursor,
                collect_interpolations=False,
                base_offset=0,
            )
            continue
        if source[cursor] == '(':
            depth += 1
        elif source[cursor] == ')':
            depth -= 1
            if depth == 0:
                return cursor
        cursor += 1
    return None


def _swift_code_tokens(source: str, base_offset: int = 0) -> list[SwiftToken]:
    """Tokenize enough Swift syntax to enforce the closed SwiftData construction boundary.

    This is intentionally not a general Swift parser. It preserves code identifiers and
    punctuation, removes nested comments and all normal/raw/single/multiline string literal text,
    and recurses into interpolation expressions. The rule is deliberately conservative: a new
    construction spelling must be centralized and made explicit rather than guessed from prose.
    """

    tokens: list[SwiftToken] = []
    cursor = 0
    while cursor < len(source):
        if source.startswith('//', cursor):
            newline = source.find('\n', cursor + 2)
            cursor = len(source) if newline == -1 else newline + 1
            continue
        if source.startswith('/*', cursor):
            cursor = _skip_block_comment(source, cursor)
            continue
        if _string_opener(source, cursor) is not None:
            cursor, nested_tokens = _skip_string(
                source,
                cursor,
                collect_interpolations=True,
                base_offset=base_offset,
            )
            tokens.extend(nested_tokens)
            continue
        character = source[cursor]
        if character == '`':
            closing = source.find('`', cursor + 1)
            if closing != -1:
                identifier = source[cursor + 1:closing]
                if identifier:
                    tokens.append(SwiftToken(identifier, base_offset + cursor))
                cursor = closing + 1
                continue
        if character.isascii() and (character.isalpha() or character == '_'):
            end = cursor + 1
            while end < len(source) and source[end].isascii() and (source[end].isalnum() or source[end] == '_'):
                end += 1
            tokens.append(SwiftToken(source[cursor:end], base_offset + cursor))
            cursor = end
            continue
        if character in '.():={}[],;':
            tokens.append(SwiftToken(character, base_offset + cursor))
        cursor += 1
    return tokens


def _has_sequence(tokens: list[SwiftToken], values: tuple[str, ...]) -> bool:
    width = len(values)
    return any(
        tuple(token.value for token in tokens[index:index + width]) == values
        for index in range(len(tokens) - width + 1)
    )


def _matching_token_parenthesis(tokens: list[SwiftToken], opening: int) -> int | None:
    depth = 1
    for index in range(opening + 1, len(tokens)):
        if tokens[index].value == '(':
            depth += 1
        elif tokens[index].value == ')':
            depth -= 1
            if depth == 0:
                return index
    return None


def _typealias_mentions_swiftdata_type(tokens: list[SwiftToken]) -> bool:
    targets = {'ModelConfiguration', 'ModelContainer'}
    for index, token in enumerate(tokens):
        if token.value != 'typealias':
            continue
        # A typealias declaration is deliberately short in the accepted coding style. Looking
        # through its statement catches qualified aliases too and fails closed if the spelling
        # grows into a form this structural gate does not own.
        for candidate in tokens[index + 1:index + 16]:
            if candidate.value in {';', '{', '}'}:
                break
            if candidate.value in targets:
                return True
    return False


def _has_contextual_initializer(tokens: list[SwiftToken]) -> bool:
    """Return whether a real-code contextual `.init(...)` appears in a protected file."""

    return _has_sequence(tokens, ('.', 'init', '('))


def _direct_construction_indices(tokens: list[SwiftToken], type_name: str) -> list[int]:
    return [
        index
        for index in range(len(tokens) - 1)
        if tokens[index].value == type_name and tokens[index + 1].value == '('
    ]


def _configuration_explicitly_disables_cloudkit(tokens: list[SwiftToken], opening: int) -> bool:
    closing = _matching_token_parenthesis(tokens, opening)
    if closing is None:
        return False
    arguments = tokens[opening + 1:closing]
    depth = 0
    for index in range(len(arguments) - 3):
        token = arguments[index].value
        if token in {'(', '[', '{'}:
            depth += 1
            continue
        if token in {')', ']', '}'}:
            depth = max(0, depth - 1)
            continue
        if depth == 0 and tuple(item.value for item in arguments[index:index + 4]) == (
            'cloudKitDatabase', ':', '.', 'none'
        ):
            return True
    return False


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
    tokenized_sources = [_swift_code_tokens(text) for text in swift_sources.values()]
    has_cloudkit_source = any(
        _has_sequence(tokens, ('import', 'CloudKit'))
        or any(token.value == 'CKContainer' for token in tokens)
        for tokens in tokenized_sources
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
    tokenized_sources = {
        file: _swift_code_tokens(text)
        for file, text in swift_sources.items()
    }

    for file, tokens in tokenized_sources.items():
        if (
            _has_sequence(tokens, ('cloudKitDatabase', ':', '.', 'automatic'))
            or _has_sequence(tokens, ('cloudKitDatabase', ':', '.', 'private'))
            or _has_sequence(tokens, ('CloudKitDatabase', '.', 'private'))
        ):
            errors.append(
                f"{file}: primary local SwiftData must never opt into managed CloudKit sync"
            )

    if not requires_cloudkit_hardening(project_root, swift_sources):
        return errors

    total_configurations = 0
    for file, tokens in tokenized_sources.items():
        protected_types_present = {
            token.value
            for token in tokens
            if token.value in {'ModelConfiguration', 'ModelContainer'}
        }
        if _typealias_mentions_swiftdata_type(tokens):
            errors.append(
                f"{file}: typealiases for ModelConfiguration/ModelContainer bypass the centralized construction boundary"
            )

        configuration_calls = _direct_construction_indices(tokens, 'ModelConfiguration')
        container_calls = _direct_construction_indices(tokens, 'ModelContainer')
        total_configurations += len(configuration_calls)

        # Direct `.init`, metatype `.self`, and contextual `.init` spellings are intentionally
        # rejected. The centralized owner has stable direct constructor calls; accepting aliases,
        # metatypes, or inference would make a static requirement on each configuration
        # unverifiable. A contextual initializer is rejected anywhere in a file mentioning either
        # protected type so a return-style `-> ModelConfiguration { .init(...) }` cannot cross a
        # scope boundary undetected.
        for type_name in ('ModelConfiguration', 'ModelContainer'):
            for index, token in enumerate(tokens):
                if token.value != type_name:
                    continue
                if index + 2 < len(tokens) and tokens[index + 1].value == '.' and tokens[index + 2].value == 'init':
                    errors.append(
                        f"{file}: {type_name}.init bypasses the explicit SwiftData construction form"
                    )
                if index + 2 < len(tokens) and tokens[index + 1].value == '.' and tokens[index + 2].value == 'self':
                    errors.append(
                        f"{file}: {type_name}.self bypasses the explicit SwiftData construction form"
                    )
        if protected_types_present and _has_contextual_initializer(tokens):
            errors.append(
                f"{file}: contextual .init bypasses the explicit SwiftData construction form"
            )

        if file != data_controller:
            if configuration_calls:
                errors.append(
                    f"{file}: production ModelConfiguration construction must remain centralized in DataController"
                )
            if container_calls:
                errors.append(
                    f"{file}: production ModelContainer construction must remain centralized in DataController"
                )
            continue

        for configuration in configuration_calls:
            if not _configuration_explicitly_disables_cloudkit(tokens, configuration + 1):
                errors.append(
                    f"{file}: CloudKit capability/import requires every ModelConfiguration "
                    "to explicitly use cloudKitDatabase: .none"
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

        data_controller.write_text(
            "ModelConfiguration.init(cloudKitDatabase: .none)\nModelContainer(for: Schema.self)\n",
            encoding="utf-8",
        )
        if not validate_swiftdata_boundary(root):
            raise AssertionError("ModelConfiguration.init fixture accepted")

        data_controller.write_text(
            "ModelConfiguration(cloudKitDatabase: .none)\nModelContainer.init(for: Schema.self)\n",
            encoding="utf-8",
        )
        if not validate_swiftdata_boundary(root):
            raise AssertionError("ModelContainer.init fixture accepted")

        data_controller.write_text(
            "let configuration: ModelConfiguration = .init(cloudKitDatabase: .none)\n"
            "ModelContainer(for: Schema.self)\n",
            encoding="utf-8",
        )
        if not validate_swiftdata_boundary(root):
            raise AssertionError("contextual ModelConfiguration .init fixture accepted")

        data_controller.write_text(
            "ModelConfiguration(cloudKitDatabase: .none)\n"
            "let container: ModelContainer = .init(for: Schema.self)\n",
            encoding="utf-8",
        )
        if not validate_swiftdata_boundary(root):
            raise AssertionError("contextual ModelContainer .init fixture accepted")

        data_controller.write_text(
            "typealias LocalConfiguration = ModelConfiguration\n"
            "let configuration = LocalConfiguration(cloudKitDatabase: .none)\n"
            "ModelContainer(for: Schema.self)\n",
            encoding="utf-8",
        )
        if not validate_swiftdata_boundary(root):
            raise AssertionError("ModelConfiguration typealias fixture accepted")

        data_controller.write_text(
            "ModelConfiguration() // cloudKitDatabase: .none\n"
            "let example = \"cloudKitDatabase: .none\"\n"
            "let raw = #\"cloudKitDatabase: .none\"#\n"
            "let multiline = \"\"\"\ncloudKitDatabase: .none\n\"\"\"\n"
            "let rawMultiline = ##\"\"\"\ncloudKitDatabase: .none\n\"\"\"##\n"
            "ModelContainer(for: Schema.self)\n",
            encoding="utf-8",
        )
        if not validate_swiftdata_boundary(root):
            raise AssertionError("comment/string .none fixture accepted")

        data_controller.write_text(
            "ModelConfiguration(\n"
            "  schema: makeSchema(cloudKitDatabase: .none)\n"
            ")\n"
            "ModelContainer(for: Schema.self)\n",
            encoding="utf-8",
        )
        if not validate_swiftdata_boundary(root):
            raise AssertionError("nested .none fixture accepted")

        data_controller.write_text(
            "ModelConfiguration(cloudKitDatabase: .none)\n"
            "// ModelConfiguration.init(cloudKitDatabase: .none)\n"
            "let example = #\"ModelContainer.init(for: Schema.self)\"#\n"
            "ModelContainer(for: Schema.self)\n",
            encoding="utf-8",
        )
        if validate_swiftdata_boundary(root):
            raise AssertionError("comment/string construction fixture rejected")

        data_controller.write_text(
            "ModelConfiguration(cloudKitDatabase: .none)\n"
            "let interpolation = \"\\(ModelConfiguration())\"\n"
            "ModelContainer(for: Schema.self)\n",
            encoding="utf-8",
        )
        if not validate_swiftdata_boundary(root):
            raise AssertionError("construction inside string interpolation fixture accepted")

        data_controller.write_text(
            "func makeConfiguration() -> ModelConfiguration { .init(cloudKitDatabase: .none) }\n"
            "ModelContainer(for: Schema.self)\n",
            encoding="utf-8",
        )
        if not validate_swiftdata_boundary(root):
            raise AssertionError("return-style contextual .init fixture accepted")

        data_controller.write_text(
            "let configurationType = ModelConfiguration.self\n"
            "let configuration = configurationType.init(cloudKitDatabase: .none)\n"
            "ModelContainer(for: Schema.self)\n",
            encoding="utf-8",
        )
        if not validate_swiftdata_boundary(root):
            raise AssertionError("ModelConfiguration metatype fixture accepted")

        (root / "MindBudget/AlternateStore.swift").write_text(
            "typealias AlternateConfiguration = ModelConfiguration\n"
            "typealias AlternateContainer = ModelContainer\n"
            "let configuration = AlternateConfiguration(cloudKitDatabase: .none)\n"
            "let container = AlternateContainer(for: AlternateSchema.self, configurations: [configuration])\n",
            encoding="utf-8",
        )
        if not validate_swiftdata_boundary(root):
            raise AssertionError("alternate typealias construction fixture accepted")
        (root / "MindBudget/AlternateStore.swift").unlink()

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
