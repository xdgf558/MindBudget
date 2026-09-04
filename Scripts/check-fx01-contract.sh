#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/.." && pwd)"
cd "${PROJECT_ROOT}"

python3 -B Scripts/fx01_contract.py --self-test
python3 -B Scripts/fx01_contract.py

# These existing whole-app gates are part of the FX-01A boundary: a future FX source cannot gain
# floating-point money or a third app-owned network path merely by satisfying the JSON contract.
Scripts/check-no-floating-point-money.sh
Scripts/check-network-egress.sh
