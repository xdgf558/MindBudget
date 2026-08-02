#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/.." && pwd)"

cd "${PROJECT_ROOT}"

SEARCH_PATHS=(
  MindBudget/Models
  MindBudget/Data
  MindBudget/Services
  MindBudget/Features
)

violations="$(rg --line-number --glob '*.swift' '\b(Double|Float)\b' "${SEARCH_PATHS[@]}" || true)"

if [[ -n "${violations}" ]]; then
  echo "Floating-point types are forbidden in deterministic money paths:"
  echo "${violations}"
  echo "The sole transport-only exception belongs in AppIntents/IntentMoneyTransport.swift."
  exit 1
fi
