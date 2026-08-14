#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/.." && pwd)"
cd "${PROJECT_ROOT}"

CATALOG="Config/StoreKit/MindBudgetPro.storekit"
DEFAULT_SCHEME="MindBudget.xcodeproj/xcshareddata/xcschemes/MindBudget.xcscheme"
LOCAL_SCHEME="MindBudget.xcodeproj/xcshareddata/xcschemes/MindBudget-StoreKit-Local.xcscheme"
PROJECT_FILE="MindBudget.xcodeproj/project.pbxproj"
CONTRACT="${SCRIPT_DIRECTORY}/storekit_catalog_contract.py"
CONTRACT_TESTS="${SCRIPT_DIRECTORY}/tests/test_storekit_catalog_contract.py"
PAYWALL_SOURCE="MindBudget/Features/Commerce/ProSubscriptionView.swift"
SETTINGS_SOURCE="MindBudget/Features/Settings/SettingsView.swift"
LOCALIZATIONS="MindBudget/Resources/Localizable.xcstrings"

for file in \
  "${CATALOG}" \
  "${DEFAULT_SCHEME}" \
  "${LOCAL_SCHEME}" \
  "${PROJECT_FILE}" \
  "${CONTRACT}" \
  "${CONTRACT_TESTS}" \
  "${PAYWALL_SOURCE}" \
  "${SETTINGS_SOURCE}" \
  "${LOCALIZATIONS}"; do
  if [[ ! -s "${file}" ]]; then
    echo "Missing StoreKit catalog control: ${file}" >&2
    exit 1
  fi
done

python3 -B "${CONTRACT_TESTS}"
python3 -B "${CONTRACT}" \
  "${CATALOG}" \
  "${DEFAULT_SCHEME}" \
  "${LOCAL_SCHEME}" \
  "${PROJECT_FILE}"

PRICE_LITERAL_PATTERN='(^|[^[:digit:]])(US\$|HK\$|S\$|NT\$|\$)?(1[.]99|19[.]99)([^[:digit:]]|$)'
RAW_STOREKIT_ACTION_PATTERN='Product[.]products|[.]purchase[(]|AppStore[.]sync|EntitlementStore[(]'

if ! grep -Eq "${PRICE_LITERAL_PATTERN}" <<< 'Text("US$19.99")'; then
  echo "StoreKit presentation price-literal guard self-test failed" >&2
  exit 1
fi
if ! grep -Eq "${RAW_STOREKIT_ACTION_PATTERN}" <<< 'try await product.purchase()'; then
  echo "StoreKit presentation action-boundary guard self-test failed" >&2
  exit 1
fi

if grep -En "${PRICE_LITERAL_PATTERN}" "${PAYWALL_SOURCE}" "${LOCALIZATIONS}"; then
  echo "Customer subscription presentation must not hardcode provisional prices" >&2
  exit 1
fi
if grep -En "${RAW_STOREKIT_ACTION_PATTERN}" "${PAYWALL_SOURCE}"; then
  echo "The paywall must use typed AppSession seams rather than raw StoreKit actions" >&2
  exit 1
fi

for contract in \
  'product.displayPrice' \
  'product.isEligibleForIntroductoryOffer' \
  'StoreCatalogContract.expectedIntroductoryOffer' \
  'session.purchasePro' \
  'session.restoreProPurchases' \
  '.manageSubscriptionsSheet'; do
  if ! grep -Fq "${contract}" "${PAYWALL_SOURCE}"; then
    echo "Missing C3-01 customer-presentation contract: ${contract}" >&2
    exit 1
  fi
done

paywall_entry_sites="$({ find MindBudget -type f -name '*.swift' ! -path "${PAYWALL_SOURCE}" \
  -exec grep -nH 'ProSubscriptionView' {} + || true; })"
if [[ "$(wc -l <<< "${paywall_entry_sites}" | tr -d ' ')" != "2" ]] \
  || grep -Fvq "${SETTINGS_SOURCE}:" <<< "${paywall_entry_sites}"; then
  echo "C3-01 paywall entry points must remain the two explicit Settings value triggers" >&2
  printf '%s\n' "${paywall_entry_sites}" >&2
  exit 1
fi

echo "StoreKit local catalog and environment isolation passed"
