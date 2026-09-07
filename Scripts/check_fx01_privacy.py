#!/usr/bin/env python3
"""FX source egress regression; runtime fixtures remain separately mandatory.

This is a deliberately narrow symbol/field barrier, not final-binary network proof.
It rejects references (including literals/comments) on the existing private sinks;
it cannot prove safety of arbitrary reflection, renamed aliases or a new unlisted sink.
The whole-app network, telemetry, AI and receipt contracts remain additional gates.
"""
from pathlib import Path
import argparse
import re
import tempfile

SINKS = (
    "MindBudget/Services/PrivacyRedactor.swift",
    "MindBudget/Services/AskMindBudgetService.swift",
    "MindBudget/Services/CycleSummaryService.swift",
    "MindBudget/Services/AIAdviceGenerator.swift",
    "MindBudget/Services/ReminderEngine.swift",
    "MindBudget/Services/NotificationScheduler.swift",
    "MindBudget/Services/SpotlightIndexingService.swift",
    "MindBudget/Services/OnscreenAwareness.swift",
    "MindBudget/Services/TelemetryDomain.swift",
    "MindBudget/Services/TelemetryClient.swift",
    "MindBudget/Services/TelemetryTransport.swift",
    "MindBudget/AppIntents/Entities/MindBudgetEntities.swift",
    "MindBudget/AppIntents/Intents/MindBudgetIntents.swift",
    "MindBudget/AppIntents/IntentSupport.swift",
    "MindBudget/Models/Projections.swift",
)
PRIVATE_SYMBOLS = (
    "ExpenseForeignCurrencyMetadata", "ExpenseForeignCurrency", "foreignCurrency",
    "originalAmountMinorUnits", "originalCurrencyCode", "rateNumerator", "rateDenominator",
    "rateTimeZoneIdentifier", "rateSourceRaw", "exchange_rate_source", "original_amount_minor_units",
)


def inspect(relative: str, text: str) -> list[str]:
    if relative.endswith("Projections.swift"):
        # Detail/export legitimately carry FX. The shared summary is the consumer boundary.
        match = re.search(r"struct ExpenseSummary\b.*?(?=\nstruct |\Z)", text, re.S)
        if not match:
            return ["missing ExpenseSummary privacy projection"]
        text = match[0]
    return [f"{relative}: FX field/type cannot enter this private sink: {symbol}"
            for symbol in PRIVATE_SYMBOLS if re.search(r"\b" + re.escape(symbol) + r"\b", text)]


def validate(root: Path) -> list[str]:
    errors = []
    for relative in SINKS:
        path = root / relative
        if not path.is_file():
            errors.append(f"missing FX privacy sink: {relative}")
        else:
            errors.extend(inspect(relative, path.read_text(encoding="utf-8")))
    return errors


def self_test(root: Path) -> None:
    if validate(root):
        raise ValueError("authoritative FX privacy sources failed")
    count = 0
    with tempfile.TemporaryDirectory(prefix="fx01-privacy-") as temporary:
        fixture = Path(temporary)
        for relative in SINKS:
            original = (root / relative).read_text(encoding="utf-8")
            path = fixture / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            for symbol in PRIVATE_SYMBOLS:
                injected = f'\nlet forbiddenFXProbe = "{symbol}"\n'
                changed = original + injected
                if relative.endswith("Projections.swift"):
                    match = re.search(r"struct ExpenseSummary[^\{]*\{", original)
                    if not match:
                        raise ValueError("summary mutation target missing")
                    changed = original[:match.end()] + injected + original[match.end():]
                path.write_text(changed, encoding="utf-8")
                if not inspect(relative, path.read_text(encoding="utf-8")):
                    raise ValueError(f"FX privacy mutation escaped: {relative}/{symbol}")
                count += 1
    print(f"FX privacy self-test passed: {count} private-sink mutations rejected")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    if args.self_test:
        self_test(root)
    errors = validate(root)
    if errors:
        raise SystemExit("\n".join(errors))


if __name__ == "__main__":
    main()
