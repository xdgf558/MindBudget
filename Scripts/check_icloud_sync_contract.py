#!/usr/bin/env python3
"""Check the structural C4B design contract and prevent accidental managed SwiftData sync."""

from __future__ import annotations

import argparse
from collections import Counter
from dataclasses import dataclass
import plistlib
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


# Before CloudKit hardening can activate, every real `.init(...)` spelling is repository-managed.
# The allowance is intentionally exact and count-bounded: adding even another otherwise harmless
# contextual initializer requires a review of this gate rather than silently expanding the surface
# through which ModelConfiguration or ModelContainer could be inferred across files.
ALLOWED_INITIALIZER_CALLS: dict[str, Counter[tuple[str | None, tuple[str, ...]]]] = {
    "MindBudget/AppIntents/Entities/MindBudgetEntities.swift": Counter({
        (None, ("systemName",)): 7,
    }),
    "MindBudget/Commerce/EntitlementStore.swift": Counter({
        ("StoreProductRecord", ("product",)): 1,
    }),
    "MindBudget/Commerce/StoreCatalog.swift": Counter({
        ("self", ("product", "isEligibleForIntroductoryOffer")): 1,
        (
            "self",
            (
                "id",
                "displayName",
                "description",
                "displayPrice",
                "isAutoRenewable",
                "isFamilyShareable",
                "subscriptionGroupID",
                "subscriptionPeriod",
                "introductoryOffer",
                "isEligibleForIntroductoryOffer",
            ),
        ): 1,
    }),
    "MindBudget/Data/CloudSyncDataActor.swift": Counter({
        ("CloudSyncReasonCode", ("rawValue",)): 1,
    }),
    "MindBudget/Services/CloudSyncDomain.swift": Counter({
        ("self", ("timeIntervalSinceReferenceDate",)): 1,
    }),
    "MindBudget/Services/CloudSyncRuntime.swift": Counter({
        ("super", ()): 1,
    }),
    "MindBudget/Services/ReceiptRecognition/ReceiptSystemImageAcquisition.swift": Counter({
        ("super", ("nibName", "bundle")): 1,
    }),
    "MindBudget/Services/PrivacyRedactor.swift": Counter({
        ("Locale", ("identifier",)): 1,
    }),
}

ALLOWED_INITIALIZER_REFERENCES: dict[str, Counter[str | None]] = {
    "MindBudget/AppIntents/IntentSupport.swift": Counter({"Set": 6}),
    "MindBudget/Commerce/PublicConfigurationTransport.swift": Counter({"Date": 1}),
    "MindBudget/Data/DataController.swift": Counter({
        "StoreMigrationRecoveryArtifactDeleter": 1,
    }),
    "MindBudget/Services/PrivacyRedactor.swift": Counter({"String": 7}),
}

# SwiftUI's unlabeled overload attaches an already-created container. The `for:` overload creates
# a new one and is therefore forbidden outside the DataController boundary. Keeping even the safe
# attachment call path- and count-bound prevents another View or Scene from silently becoming a
# second construction owner.
ALLOWED_MODEL_CONTAINER_MODIFIER_CALLS: dict[str, Counter[tuple[str, ...]]] = {
    "MindBudget/App/MindBudgetApp.swift": Counter({
        (): 1,
    }),
}

SWIFT_IMPORT_KINDS = {
    "class",
    "enum",
    "func",
    "let",
    "macro",
    "protocol",
    "struct",
    "typealias",
    "var",
}

EXPECTED_SYNC_ENTITY_CASES = {
    "expense",
    "income",
    "incomeAllocation",
    "savingsGoal",
    "recurringRule",
    "recurringOccurrence",
    "budgetPlan",
    "budgetPlanSemantics",
    "categoryBudget",
    "wishItem",
    "coolingOffPlan",
    "reflectionLog",
}

REQUIRED_RUNTIME_ANCHORS = {
    "MindBudget/Services/CloudSyncRuntime.swift": (
        'containerIdentifier = "iCloud.com.xdgf558.MindBudget"',
        'zoneName = "MindBudget.Sync.v1"',
        'recordType = "MindBudgetEnvelopeV1"',
        "container.privateCloudDatabase",
        "configuration.automaticallySync = Self.automaticallySync",
        "nonisolated static let automaticallySync = true",
        "Task.detached(operation: operation)",
        "clearEngine(ifMatching: engine)",
        "requiresGenesisZoneCreation(hasSerializedState: serialization != nil)",
        "privateCloudDatabase.save(CKRecordZone(zoneID: zoneID))",
        "record.encryptedValues[Self.encryptedEnvelopeKey]",
        "deleteRecordZone(withID: zoneID)",
        "recoverFromTrustBoundary",
        "refreshAfterLocalDataDeletion",
    ),
    "MindBudget/App/AppRouter.swift": (
        "await cloudSyncService.refreshAfterLocalDataDeletion()",
    ),
    "MindBudget/Data/DataController.swift": (
        "Schema(versionedSchema: SchemaV6.self)",
        "cloudKitDatabase: .none",
    ),
    "MindBudget/Data/CloudSyncDataActor.swift": (
        "stageAllCurrentFacts",
        "CloudSyncOutboxItem",
        "CloudSyncRecordMetadata",
    ),
    "MindBudget/Data/CloudSyncRemoteApply.swift": (
        "applyPendingCloudSyncInbox",
        "resolveCloudSyncConflict",
        "CloudSyncInboxStatus.quarantined",
        "CloudSyncOperation.tombstone",
    ),
    "MindBudget/Features/Settings/SettingsView.swift": (
        "CloudSyncConflictListView",
        "deleteCloudSyncData",
        "recoverCloudSyncFromLocalData",
        "CloudSyncSettingsPresentation.requiresReimportConfirmation",
        "CloudSyncSettingsPresentation.cloudDeletionGuidance",
    ),
    "MindBudgetTests/CloudSyncTests.swift": (
        "@Test(.enabled(if: Self.runsPhysicalCloudKitRuntimeTests))",
        "physicalDevelopmentCloudKitRoundTripPreservesLocalFactsAndDeletesTheZone",
        "#elseif MINDBUDGET_PHYSICAL_CLOUDKIT_TESTS",
        "let deletion = await service.deleteCloudData()",
        "serverSaveConflictLeavesTheOutboxBlockedAndTheRemoteCandidateQuarantined",
    ),
    "MindBudgetTests/Phase6FeatureTests.swift": (
        "CloudSyncSettingsPresentation.showsCloudDeletionAction",
        "await session.setCloudSyncEnabled(true, reimportConfirmed: true)",
    ),
}

EXPECTED_CLOUDKIT_ENTITLEMENTS = {
    "MindBudget/MindBudgetDebug.entitlements": ("development", "Development"),
    "MindBudget/MindBudgetRelease.entitlements": ("production", "Production"),
}
EXPECTED_CLOUDKIT_CONTAINER = "iCloud.com.xdgf558.MindBudget"
EXPECTED_INFO_PLIST = "MindBudget/Resources/MindBudgetInfo.plist"
EXPECTED_INFO_PLIST_BUILD_SETTING = f"INFOPLIST_FILE = {EXPECTED_INFO_PLIST};"


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
            if hashes == 0:
                # In an ordinary Swift string every backslash introduces an escape. Skipping the
                # escaped scalar prevents an escaped quote from looking like the closing quote.
                cursor = min(len(source), cursor + 2)
                continue

            # In a raw string an ordinary backslash is literal content. It becomes an escape only
            # when immediately followed by exactly the opening delimiter's hashes. In particular,
            # a literal trailing backslash must not consume the quote that closes `#"...\\"#`.
            raw_escape = '\\' + '#' * hashes
            if source.startswith(raw_escape, cursor):
                cursor += len(raw_escape)
                if cursor < len(source):
                    cursor += 1
            else:
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


def _matching_token_brace(tokens: list[SwiftToken], opening: int) -> int | None:
    depth = 1
    for index in range(opening + 1, len(tokens)):
        if tokens[index].value == '{':
            depth += 1
        elif tokens[index].value == '}':
            depth -= 1
            if depth == 0:
                return index
    return None


def _enum_cases(tokens: list[SwiftToken], enum_name: str) -> set[str] | None:
    for index in range(len(tokens) - 2):
        if tokens[index].value != 'enum' or tokens[index + 1].value != enum_name:
            continue
        opening = next(
            (candidate for candidate in range(index + 2, len(tokens)) if tokens[candidate].value == '{'),
            None,
        )
        if opening is None:
            return None
        closing = _matching_token_brace(tokens, opening)
        if closing is None:
            return None
        return {
            tokens[candidate + 1].value
            for candidate in range(opening + 1, closing - 1)
            if tokens[candidate].value == 'case'
        }
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


def _top_level_argument_labels(tokens: list[SwiftToken], opening: int) -> tuple[str, ...]:
    """Return the labels of one initializer call without considering nested expressions."""

    closing = _matching_token_parenthesis(tokens, opening)
    if closing is None:
        return ("<unclosed>",)
    labels: list[str] = []
    depth = 0
    at_argument_start = True
    for index in range(opening + 1, closing):
        value = tokens[index].value
        if value in {'(', '[', '{'}:
            depth += 1
            continue
        if value in {')', ']', '}'}:
            depth = max(0, depth - 1)
            continue
        if depth != 0:
            continue
        if value == ',':
            at_argument_start = True
            continue
        if at_argument_start:
            if index + 1 < closing and tokens[index + 1].value == ':':
                labels.append(value)
            at_argument_start = False
    return tuple(labels)


def _initializer_call_shapes(tokens: list[SwiftToken]) -> Counter[tuple[str | None, tuple[str, ...]]]:
    """Inventory every real `.init(...)` call for the repository-wide closed allowance."""

    allowed_receivers = {
        receiver
        for allowed in ALLOWED_INITIALIZER_CALLS.values()
        for receiver, _ in allowed
        if receiver is not None
    }
    calls: Counter[tuple[str | None, tuple[str, ...]]] = Counter()
    for dot in range(len(tokens) - 2):
        if tuple(token.value for token in tokens[dot:dot + 3]) != ('.', 'init', '('):
            continue
        receiver = tokens[dot - 1].value if dot > 0 and tokens[dot - 1].value in allowed_receivers else None
        calls[(receiver, _top_level_argument_labels(tokens, dot + 2))] += 1
    return calls


def _initializer_reference_receivers(tokens: list[SwiftToken]) -> Counter[str | None]:
    """Inventory `.init` function values that are not immediately applied or label-specialized."""

    references: Counter[str | None] = Counter()
    for dot in range(len(tokens) - 1):
        if tokens[dot].value != '.' or tokens[dot + 1].value != 'init':
            continue
        if dot + 2 < len(tokens) and tokens[dot + 2].value == '(':
            continue
        references[tokens[dot - 1].value if dot > 0 else None] += 1
    return references


def _member_call_shapes(tokens: list[SwiftToken], member: str) -> Counter[tuple[str, ...]]:
    """Inventory qualified or implicit-self calls by top-level argument-label shape."""

    calls: Counter[tuple[str, ...]] = Counter()
    for index in range(len(tokens) - 1):
        if tokens[index].value != member or tokens[index + 1].value != '(':
            continue
        calls[_top_level_argument_labels(tokens, index + 1)] += 1
    return calls


def _unapplied_member_reference_count(tokens: list[SwiftToken], member: str) -> int:
    """Count unapplied references to a protected member such as SwiftUI's modelContainer."""

    return sum(
        1
        for index, token in enumerate(tokens)
        if token.value == member
        and (index + 1 >= len(tokens) or tokens[index + 1].value not in {'(', ':'})
    )


def _imports_swift_module(tokens: list[SwiftToken], module: str) -> bool:
    """Recognize direct and selective Swift imports such as `import class CloudKit.CKSyncEngine`."""

    for index, token in enumerate(tokens):
        if token.value != 'import' or index + 1 >= len(tokens):
            continue
        module_index = index + 1
        if tokens[module_index].value in SWIFT_IMPORT_KINDS:
            module_index += 1
        if module_index < len(tokens) and tokens[module_index].value == module:
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
        _imports_swift_module(tokens, 'CloudKit')
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

        relative_file = file.relative_to(project_root).as_posix()
        initializer_calls = _initializer_call_shapes(tokens)
        initializer_allowance = ALLOWED_INITIALIZER_CALLS.get(relative_file, Counter())
        for shape, count in initializer_calls.items():
            allowed_count = initializer_allowance[shape]
            if count > allowed_count:
                receiver, labels = shape
                call = f"{receiver + '.' if receiver else '.'}init({', '.join(labels)})"
                errors.append(
                    f"{file}: unapproved initializer call {call} appears {count} time(s); "
                    f"the repository allowance permits {allowed_count}"
                )

        initializer_references = _initializer_reference_receivers(tokens)
        initializer_reference_allowance = ALLOWED_INITIALIZER_REFERENCES.get(
            relative_file,
            Counter(),
        )
        for receiver, count in initializer_references.items():
            allowed_count = initializer_reference_allowance[receiver]
            if count > allowed_count:
                reference = f"{receiver + '.' if receiver else '.'}init"
                errors.append(
                    f"{file}: unapproved initializer function reference {reference} appears "
                    f"{count} time(s); the repository allowance permits {allowed_count}"
                )

        modifier_calls = _member_call_shapes(tokens, 'modelContainer')
        modifier_allowance = ALLOWED_MODEL_CONTAINER_MODIFIER_CALLS.get(relative_file, Counter())
        for labels, count in modifier_calls.items():
            allowed_count = modifier_allowance[labels]
            if count > allowed_count:
                call = f".modelContainer({', '.join(labels)})"
                errors.append(
                    f"{file}: unapproved SwiftUI container modifier {call} appears {count} "
                    f"time(s); the repository allowance permits {allowed_count}"
                )

        unapplied_modifiers = _unapplied_member_reference_count(tokens, 'modelContainer')
        if unapplied_modifiers:
            errors.append(
                f"{file}: unapplied .modelContainer function reference appears "
                f"{unapplied_modifiers} time(s); only the reviewed existing-container call is allowed"
            )

    if not requires_cloudkit_hardening(project_root, swift_sources):
        return errors

    total_configurations = 0
    for file, tokens in tokenized_sources.items():
        if _typealias_mentions_swiftdata_type(tokens):
            errors.append(
                f"{file}: typealiases for ModelConfiguration/ModelContainer bypass the centralized construction boundary"
            )

        configuration_calls = _direct_construction_indices(tokens, 'ModelConfiguration')
        container_calls = _direct_construction_indices(tokens, 'ModelContainer')
        total_configurations += len(configuration_calls)

        # Type-specific aliases and metatypes are rejected in addition to the global `.init`
        # allowance. The latter is global because Swift can infer a contextual initializer from a
        # declaration in a different file, where no ModelContainer token is present at the call.
        for type_name in ('ModelConfiguration', 'ModelContainer'):
            for index, token in enumerate(tokens):
                if token.value != type_name:
                    continue
                if index + 2 < len(tokens) and tokens[index + 1].value == '.' and tokens[index + 2].value == 'self':
                    errors.append(
                        f"{file}: {type_name}.self bypasses the explicit SwiftData construction form"
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

    # The app target's CloudKit entitlement is also present while hosted unit tests construct
    # legacy-schema stores. Those fixtures must opt out explicitly or SwiftData's `.automatic`
    # default can activate managed mirroring and invalidate the migration evidence itself.
    tests_root = project_root / "MindBudgetTests"
    if tests_root.is_dir():
        for file in tests_root.rglob("*.swift"):
            tokens = _swift_code_tokens(file.read_text(encoding="utf-8"))
            for configuration in _direct_construction_indices(tokens, "ModelConfiguration"):
                if not _configuration_explicitly_disables_cloudkit(tokens, configuration + 1):
                    errors.append(
                        f"{file}: entitled test-host ModelConfiguration fixtures must explicitly "
                        "use cloudKitDatabase: .none"
                    )
    return errors


def validate_custom_sync_runtime(project_root: Path) -> list[str]:
    """Keep the accepted custom-record runtime and C4B-03 capability boundary fail closed."""

    errors: list[str] = []
    source_text: dict[str, str] = {}
    for relative, anchors in REQUIRED_RUNTIME_ANCHORS.items():
        path = project_root / relative
        if not path.is_file():
            errors.append(f"{path}: missing accepted C4B-02 runtime owner")
            continue
        text = path.read_text(encoding="utf-8")
        source_text[relative] = text
        for anchor in anchors:
            if anchor not in text:
                errors.append(f"{path}: missing C4B-02 runtime contract anchor {anchor!r}")

    domain_path = project_root / "MindBudget/Services/CloudSyncDomain.swift"
    if not domain_path.is_file():
        errors.append(f"{domain_path}: missing versioned sync envelope domain")
    else:
        domain_text = domain_path.read_text(encoding="utf-8")
        source_text["MindBudget/Services/CloudSyncDomain.swift"] = domain_text
        cases = _enum_cases(_swift_code_tokens(domain_text), "CloudSyncEntityType")
        if cases != EXPECTED_SYNC_ENTITY_CASES:
            errors.append(
                f"{domain_path}: CloudSyncEntityType must be exactly the 12 accepted facts; "
                f"found {sorted(cases or set())}"
            )

    combined_runtime = "\n".join(source_text.values())
    for forbidden in (
        "publicCloudDatabase",
        "sharedCloudDatabase",
        "CKAsset(",
        ".deleteRecord(",
        # CKSyncEngine delegate callbacks are serialized. Awaiting an engine operation through the
        # callback parameter can synchronously re-enter the delegate and is a CloudKit client bug;
        # sticky-pause cancellation must use the reviewed detached-operation seam instead.
        "syncEngine.cancelOperations()",
        "pendingDatabaseChanges: [.saveZone",
    ):
        if forbidden in combined_runtime:
            errors.append(f"custom sync runtime contains forbidden transport shape {forbidden!r}")

    errors.extend(validate_cloudkit_entitlements(project_root))
    return errors


def validate_cloudkit_entitlements(project_root: Path) -> list[str]:
    """Require exact environment-separated CloudKit and push capabilities for the app target."""

    errors: list[str] = []
    expected_paths = {project_root / relative for relative in EXPECTED_CLOUDKIT_ENTITLEMENTS}
    for relative, (push_environment, cloud_environment) in EXPECTED_CLOUDKIT_ENTITLEMENTS.items():
        path = project_root / relative
        if not path.is_file():
            errors.append(f"{path}: missing exact C4B-03 entitlement file")
            continue
        try:
            with path.open("rb") as stream:
                values = plistlib.load(stream)
        except (OSError, plistlib.InvalidFileException) as error:
            errors.append(f"{path}: invalid entitlement plist: {error}")
            continue

        expected = {
            "aps-environment": push_environment,
            "com.apple.developer.icloud-container-environment": cloud_environment,
            "com.apple.developer.icloud-container-identifiers": [EXPECTED_CLOUDKIT_CONTAINER],
            "com.apple.developer.icloud-services": ["CloudKit"],
        }
        if values != expected:
            errors.append(
                f"{path}: entitlements must be exactly the reviewed {cloud_environment} "
                "private-CloudKit and push capability set"
            )

    for path in project_root.rglob("*.entitlements"):
        if path in expected_paths:
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except OSError as error:
            errors.append(f"{path}: cannot inspect entitlement file: {error}")
            continue
        if "com.apple.developer.icloud-container-identifiers" in text:
            errors.append(f"{path}: unapproved additional iCloud container entitlement owner")

    project = project_root / "MindBudget.xcodeproj/project.pbxproj"
    if not project.is_file():
        errors.append(f"{project}: missing project capability wiring")
    else:
        project_text = project.read_text(encoding="utf-8")
        for relative in EXPECTED_CLOUDKIT_ENTITLEMENTS:
            anchor = f"CODE_SIGN_ENTITLEMENTS = {relative};"
            if project_text.count(anchor) != 1:
                errors.append(f"{project}: expected exactly one build setting {anchor!r}")
        if project_text.count(EXPECTED_INFO_PLIST_BUILD_SETTING) != 2:
            errors.append(
                f"{project}: Debug and Release must each reference the exact source plist "
                f"{EXPECTED_INFO_PLIST_BUILD_SETTING!r}"
            )

    info_plist = project_root / EXPECTED_INFO_PLIST
    if not info_plist.is_file():
        errors.append(f"{info_plist}: missing app background-mode source plist")
    else:
        try:
            with info_plist.open("rb") as stream:
                values = plistlib.load(stream)
        except (OSError, plistlib.InvalidFileException) as error:
            errors.append(f"{info_plist}: invalid source plist: {error}")
        else:
            if values != {"UIBackgroundModes": ["remote-notification"]}:
                errors.append(
                    f"{info_plist}: must contain exactly the reviewed remote-notification "
                    "background mode"
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

        (root / "MindBudget").mkdir()
        project = root / "MindBudget.xcodeproj"
        project.mkdir()
        project.joinpath("project.pbxproj").write_text(
            "\n".join(
                f"CODE_SIGN_ENTITLEMENTS = {relative};\n"
                f"{EXPECTED_INFO_PLIST_BUILD_SETTING}"
                for relative in EXPECTED_CLOUDKIT_ENTITLEMENTS
            ),
            encoding="utf-8",
        )
        info_plist = root / EXPECTED_INFO_PLIST
        info_plist.parent.mkdir(parents=True)
        info_plist.write_bytes(
            plistlib.dumps({"UIBackgroundModes": ["remote-notification"]})
        )
        for relative, (push_environment, cloud_environment) in EXPECTED_CLOUDKIT_ENTITLEMENTS.items():
            path = root / relative
            path.write_bytes(
                plistlib.dumps({
                    "aps-environment": push_environment,
                    "com.apple.developer.icloud-container-environment": cloud_environment,
                    "com.apple.developer.icloud-container-identifiers": [EXPECTED_CLOUDKIT_CONTAINER],
                    "com.apple.developer.icloud-services": ["CloudKit"],
                })
            )
        if validate_cloudkit_entitlements(root):
            raise AssertionError("exact environment-separated entitlement fixture rejected")
        release_path = root / "MindBudget/MindBudgetRelease.entitlements"
        release_values = plistlib.loads(release_path.read_bytes())
        release_values["com.apple.developer.icloud-container-environment"] = "Development"
        release_path.write_bytes(plistlib.dumps(release_values))
        if not validate_cloudkit_entitlements(root):
            raise AssertionError("Release entitlement with Development environment accepted")
        release_values["com.apple.developer.icloud-container-environment"] = "Production"
        release_path.write_bytes(plistlib.dumps(release_values))
        project_fixture = project / "project.pbxproj"
        info_plist.write_bytes(plistlib.dumps({"UIBackgroundModes": ["audio"]}))
        if not validate_cloudkit_entitlements(root):
            raise AssertionError("incorrect remote-notification background mode accepted")
        info_plist.write_bytes(
            plistlib.dumps({"UIBackgroundModes": ["remote-notification"]})
        )

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

        tests = root / "MindBudgetTests"
        tests.mkdir()
        fixture = tests / "LegacyMigrationTests.swift"
        fixture.write_text("ModelConfiguration()\n", encoding="utf-8")
        if not validate_swiftdata_boundary(root):
            raise AssertionError("entitled test-host automatic ModelConfiguration fixture accepted")
        fixture.write_text("ModelConfiguration(cloudKitDatabase: .none)\n", encoding="utf-8")
        if validate_swiftdata_boundary(root):
            raise AssertionError("entitled test-host explicit-.none fixture rejected")

        for import_kind in sorted(SWIFT_IMPORT_KINDS):
            (root / "MindBudget/Sync.swift").write_text(
                f"import {import_kind} CloudKit.ImportedSymbol\n",
                encoding="utf-8",
            )
            data_controller.write_text("ModelConfiguration()\n", encoding="utf-8")
            if not validate_swiftdata_boundary(root):
                raise AssertionError(f"selective CloudKit {import_kind} import did not trigger hardening")
        (root / "MindBudget/Sync.swift").write_text("import CloudKit\n", encoding="utf-8")

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

        (root / "MindBudget/AlternateStore.swift").write_text(
            r'let marker = #"ends with backslash\"#' + "\n"
            "let configuration = ModelConfiguration()\n"
            "let container = ModelContainer(\n"
            "  for: AlternateSchema.self,\n"
            "  configurations: [configuration]\n"
            ")\n",
            encoding="utf-8",
        )
        if not validate_swiftdata_boundary(root):
            raise AssertionError("raw-string trailing-backslash fixture swallowed later construction")
        (root / "MindBudget/AlternateStore.swift").unlink()

        (root / "MindBudget/ContainerSink.swift").write_text(
            "func publish(_ value: ModelContainer) {}\n",
            encoding="utf-8",
        )
        (root / "MindBudget/AlternateStore.swift").write_text(
            "func constructAlternateStore() throws {\n"
            "  publish(try .init(for: AlternateSchema.self))\n"
            "}\n",
            encoding="utf-8",
        )
        if not validate_swiftdata_boundary(root):
            raise AssertionError("cross-file contextual ModelContainer .init fixture accepted")
        (root / "MindBudget/ContainerSink.swift").unlink()
        (root / "MindBudget/AlternateStore.swift").unlink()

        (root / "MindBudget/AlternateStore.swift").write_text(
            "let factory: (\n"
            "  String?, Schema?, Bool, Bool,\n"
            "  ModelConfiguration.GroupContainer,\n"
            "  ModelConfiguration.CloudKitDatabase\n"
            ") -> ModelConfiguration = ModelConfiguration.init\n",
            encoding="utf-8",
        )
        if not validate_swiftdata_boundary(root):
            raise AssertionError("ModelConfiguration initializer function-value fixture accepted")
        (root / "MindBudget/AlternateStore.swift").unlink()

        (root / "MindBudget/AlternateStore.swift").write_text(
            "let factory = ModelContainer.init\n",
            encoding="utf-8",
        )
        if not validate_swiftdata_boundary(root):
            raise AssertionError("ModelContainer initializer function-value fixture accepted")
        (root / "MindBudget/AlternateStore.swift").unlink()

        app = root / "MindBudget/App"
        app.mkdir(parents=True)
        (app / "MindBudgetApp.swift").write_text(
            "WindowGroup { EmptyView() }\n"
            "  .modelContainer(environment.dataController.container)\n",
            encoding="utf-8",
        )
        if validate_swiftdata_boundary(root):
            raise AssertionError("reviewed existing-container SwiftUI modifier fixture rejected")

        (root / "MindBudget/AlternateView.swift").write_text(
            "EmptyView().modelContainer(for: AlternateModel.self)\n",
            encoding="utf-8",
        )
        if not validate_swiftdata_boundary(root):
            raise AssertionError("SwiftUI View modelContainer(for:) fixture accepted")
        (root / "MindBudget/AlternateView.swift").unlink()

        (root / "MindBudget/AlternateView.swift").write_text(
            "extension View {\n"
            "  func alternateStorage() -> some View {\n"
            "    modelContainer(for: AlternateModel.self)\n"
            "  }\n"
            "}\n",
            encoding="utf-8",
        )
        if not validate_swiftdata_boundary(root):
            raise AssertionError("implicit-self SwiftUI modelContainer(for:) fixture accepted")
        (root / "MindBudget/AlternateView.swift").unlink()

        (root / "MindBudget/AlternateScene.swift").write_text(
            "WindowGroup { EmptyView() }\n"
            "  .modelContainer(for: AlternateModel.self)\n",
            encoding="utf-8",
        )
        if not validate_swiftdata_boundary(root):
            raise AssertionError("SwiftUI Scene modelContainer(for:) fixture accepted")
        (root / "MindBudget/AlternateScene.swift").unlink()

        (root / "MindBudget/AlternateView.swift").write_text(
            "let attachContainer = EmptyView().modelContainer\n",
            encoding="utf-8",
        )
        if not validate_swiftdata_boundary(root):
            raise AssertionError("SwiftUI modelContainer function-value fixture accepted")
        (root / "MindBudget/AlternateView.swift").unlink()

        (root / "MindBudget/AlternateView.swift").write_text(
            "extension View {\n"
            "  func captureStorageModifier() {\n"
            "    let attachContainer = modelContainer\n"
            "    _ = attachContainer\n"
            "  }\n"
            "}\n",
            encoding="utf-8",
        )
        if not validate_swiftdata_boundary(root):
            raise AssertionError("implicit-self modelContainer function-value fixture accepted")
        (root / "MindBudget/AlternateView.swift").unlink()

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
    errors.extend(validate_custom_sync_runtime(args.project_root))
    if errors:
        raise SystemExit("\n".join(errors))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
