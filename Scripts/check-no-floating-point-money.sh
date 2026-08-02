#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/.." && pwd)"

cd "${PROJECT_ROOT}"

violations=""

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

  if [[ -n "${file_violations}" ]]; then
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
  echo "The sole transport-only exception belongs in AppIntents/IntentMoneyTransport.swift."
  exit 1
fi
