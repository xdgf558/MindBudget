#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: Scripts/check-coverage.sh <result.xcresult>" >&2
  exit 2
fi

RESULT_BUNDLE="$1"
if [[ ! -d "${RESULT_BUNDLE}" ]]; then
  echo "Coverage result bundle does not exist: ${RESULT_BUNDLE}" >&2
  exit 2
fi

python3 - "${RESULT_BUNDLE}" <<'PY'
import json
import subprocess
import sys

result_bundle = sys.argv[1]
report = json.loads(
    subprocess.check_output(
        ["xcrun", "xccov", "view", "--report", "--json", result_bundle],
        text=True,
    )
)
app_target = next(
    (target for target in report["targets"] if target["name"] == "MindBudget.app"),
    None,
)
if app_target is None:
    raise SystemExit("MindBudget.app coverage target was not found")

# Phase 10's release gate applies to deterministic money, budget, rule, privacy,
# formatting, and answer-safety services. Views remain covered by UI/manual smoke tests.
minimum = 0.85
required_files = [
    "Money.swift",
    "BudgetEngine.swift",
    "BudgetCycleCalculator.swift",
    "SpendingPatternDetector.swift",
    "ReminderThrottle.swift",
    "ReminderEngine.swift",
    "AdviceSafetyValidator.swift",
    "PrivacyRedactor.swift",
    "CycleSummaryService.swift",
    "IntentClassifier.swift",
    "CSVExporter.swift",
    "CurrencyFormatterService.swift",
]
coverage_by_name = {file["name"]: file for file in app_target["files"]}
failures = []
for name in required_files:
    file = coverage_by_name.get(name)
    if file is None:
        failures.append(f"{name}: missing from coverage report")
        continue
    coverage = file["lineCoverage"]
    print(
        f"{name}: {coverage * 100:.2f}% "
        f"({file['coveredLines']}/{file['executableLines']})"
    )
    if coverage + 1e-12 < minimum:
        failures.append(f"{name}: {coverage * 100:.2f}% is below 85.00%")

if failures:
    print("\nCore service coverage gate failed:", file=sys.stderr)
    for failure in failures:
        print(f"- {failure}", file=sys.stderr)
    raise SystemExit(1)

print("Core service coverage gate passed (all selected files >= 85.00%).")
PY
