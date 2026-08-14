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
CATALOG_SOURCE="MindBudget/Commerce/StoreCatalog.swift"
ENTITLEMENT_SOURCE="MindBudget/Commerce/EntitlementStore.swift"
SETTINGS_SOURCE="MindBudget/Features/Settings/SettingsView.swift"
DASHBOARD_SOURCE="MindBudget/Features/Dashboard/DashboardView.swift"
TRIAL_SOURCE="MindBudget/Commerce/TrialLifecycle.swift"
LOCALIZATIONS="MindBudget/Resources/Localizable.xcstrings"

for file in \
  "${CATALOG}" \
  "${DEFAULT_SCHEME}" \
  "${LOCAL_SCHEME}" \
  "${PROJECT_FILE}" \
  "${CONTRACT}" \
  "${CONTRACT_TESTS}" \
  "${PAYWALL_SOURCE}" \
  "${CATALOG_SOURCE}" \
  "${ENTITLEMENT_SOURCE}" \
  "${SETTINGS_SOURCE}" \
  "${DASHBOARD_SOURCE}" \
  "${TRIAL_SOURCE}" \
  "${LOCALIZATIONS}"; do
  if [[ ! -s "${file}" ]]; then
    echo "Missing StoreKit catalog control: ${file}" >&2
    exit 1
  fi
done

for contract in \
  'transaction.offer?.type == .introductory' \
  'verifiedRenewalInfo.renewalDate' \
  'verifiedRenewalInfo.willAutoRenew' \
  'verifiedRenewalInfo.autoRenewPreference' \
  'TrialLifecycleProjection'; do
  if ! grep -Fq "${contract}" "${ENTITLEMENT_SOURCE}"; then
    echo "Missing C3-02 verified trial projection contract: ${contract}" >&2
    exit 1
  fi
done

for contract in \
  'mindbudget.commerce.trial-renewal' \
  'advanceDayCount = 5' \
  'calendar.date(' \
  'byAdding: .day' \
  'currentTrialProductID' \
  'renewalProductID' \
  'trial.renewalProductID' \
  'removePendingRequest' \
  'notification.trialRenewal.title' \
  'notification.trialRenewal.body'; do
  if ! grep -Fq "${contract}" "${TRIAL_SOURCE}"; then
    echo "Missing C3-02 local trial-reminder contract: ${contract}" >&2
    exit 1
  fi
done

for copy in \
  'Your Pro trial ends soon. Open MindBudget to review its current status.' \
  '你的 Pro 试用即将结束。打开花有数查看当前状态。'; do
  if ! grep -Fq "${copy}" "${LOCALIZATIONS}"; then
    echo "Missing state-safe C3-02 trial reminder copy: ${copy}" >&2
    exit 1
  fi
done

if grep -Eq 'Your Pro trial will renew soon|你的 Pro 试用即将续订' "${LOCALIZATIONS}"; then
  echo "A pending local reminder must not promise that auto-renew is still enabled" >&2
  exit 1
fi

if grep -En 'requestAuthorization|86400|timeIntervalSince' "${TRIAL_SOURCE}"; then
  echo "Trial lifecycle must not prompt implicitly or use fixed-second day arithmetic" >&2
  exit 1
fi

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
  'ProCommercePurchaseGate.supportsIntroductoryOffer' \
  'commerce.pro.offer.unsupported' \
  '@Environment(\.locale)' \
  'renewalDisclosure(for: selectedProduct, locale: locale)' \
  'commerce.pro.status.recheck' \
  'session.purchasePro' \
  'session.restoreProPurchases' \
  '.manageSubscriptionsSheet'; do
  if ! grep -Fq "${contract}" "${PAYWALL_SOURCE}"; then
    echo "Missing C3-01 customer-presentation contract: ${contract}" >&2
    exit 1
  fi
done

for contract in \
  'offer.displayPrice' \
  'offer.paymentMode.rawValue' \
  'StoreIntroductoryOfferPurchasePolicy.permitsPurchase(requestedRecord)' \
  'StoreCommerceSourceError.unsupportedIntroductoryOffer'; do
  if ! grep -Fq "${contract}" "${CATALOG_SOURCE}" "${ENTITLEMENT_SOURCE}"; then
    echo "Missing paid introductory-offer fail-closed contract: ${contract}" >&2
    exit 1
  fi
done

if grep -En 'record[.]introductoryOffer[[:space:]]*==' "${CATALOG_SOURCE}"; then
  echo "Optional introductory offers must not enter the production catalog authority contract" >&2
  exit 1
fi

paywall_entry_sites="$({ find MindBudget -type f -name '*.swift' ! -path "${PAYWALL_SOURCE}" \
  -exec grep -nH 'ProSubscriptionView' {} + || true; })"
settings_entry_count="$(grep -Fc "${SETTINGS_SOURCE}:" <<< "${paywall_entry_sites}" || true)"
dashboard_entry_count="$(grep -Fc "${DASHBOARD_SOURCE}:" <<< "${paywall_entry_sites}" || true)"
if [[ "$(wc -l <<< "${paywall_entry_sites}" | tr -d ' ')" != "3" ]] \
  || [[ "${settings_entry_count}" != "2" ]] \
  || [[ "${dashboard_entry_count}" != "1" ]]; then
  echo "Pro presentation must remain at two explicit Settings triggers plus one verified-trial Dashboard card" >&2
  printf '%s\n' "${paywall_entry_sites}" >&2
  exit 1
fi

grep -Fq 'if let trial = session.trialLifecycle' "${DASHBOARD_SOURCE}" || {
  echo "The Dashboard Pro entry must remain conditional on a verified trial lifecycle" >&2
  exit 1
}

echo "StoreKit local catalog and environment isolation passed"
