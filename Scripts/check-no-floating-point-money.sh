#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/.." && pwd)"

cd "${PROJECT_ROOT}"

violations=""
approved_non_money_violations=""

# SPEC-015 permits floating point only for the future Vision observation boundary. These exact
# paths may hold normalized geometry/confidence, never parsed or calculated money. Keeping the
# list closed before C4C-02/03 means a similarly named file cannot silently widen the exception.
is_approved_non_money_vision_path() {
  case "$1" in
    MindBudget/Services/ReceiptRecognition/ReceiptGeometry.swift | \
    MindBudget/Services/ReceiptRecognition/ReceiptVisionObservation.swift)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

if ! is_approved_non_money_vision_path \
    'MindBudget/Services/ReceiptRecognition/ReceiptGeometry.swift'; then
  echo "Floating-point gate no longer accepts the exact reviewed Vision geometry boundary" >&2
  exit 1
fi
if is_approved_non_money_vision_path \
    'MindBudget/Services/ReceiptRecognition/ReceiptGeometryBypass.swift'; then
  echo "Floating-point gate accepts an unreviewed lookalike path" >&2
  exit 1
fi

while IFS= read -r -d '' swift_file; do
  set +e
  file_violations="$(
    grep -nEH \
      '(^|[^[:alnum:]_])(Double|Float)([^[:alnum:]_]|$)' \
      "${swift_file}"
  )"
  grep_status=$?
  set -e

  if (( grep_status > 1 )); then
    echo "Failed to inspect ${swift_file}." >&2
    exit "${grep_status}"
  fi

  if [[ -z "${file_violations}" ]]; then
    continue
  fi

  if is_approved_non_money_vision_path "${swift_file}"; then
    set +e
    money_terms="$({
      grep -nEH \
        '(^|[^[:alnum:]_])(Money|minorUnits|majorUnits|amount|currency|price|subtotal|tax|tip|total)([^[:alnum:]_]|$)' \
        "${swift_file}"
    } 2>/dev/null)"
    money_status=$?
    set -e
    if (( money_status > 1 )); then
      echo "Failed to inspect approved non-money boundary ${swift_file}." >&2
      exit "${money_status}"
    fi
    if [[ -n "${money_terms}" ]]; then
      approved_non_money_violations+="${money_terms}"$'\n'
    fi
  else
    violations+="${file_violations}"$'\n'
  fi
done < <(
  find MindBudget -type f -name '*.swift' \
    ! -path 'MindBudget/AppIntents/IntentMoneyTransport.swift' \
    -print0
)

if [[ -n "${violations}" ]]; then
  echo "Floating-point types are forbidden in deterministic money paths:"
  echo "${violations%$'\n'}"
  echo "Exceptions are limited to the App Intents transport adapter and exact reviewed Vision geometry/confidence paths."
  exit 1
fi

if [[ -n "${approved_non_money_violations}" ]]; then
  echo "Approved Vision floating-point files must not contain money vocabulary:" >&2
  echo "${approved_non_money_violations%$'\n'}" >&2
  exit 1
fi
