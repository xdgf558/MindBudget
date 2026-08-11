#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/.." && pwd)"
cd "${PROJECT_ROOT}"

CATALOG="Config/StoreKit/MindBudgetPro.storekit"
DEFAULT_SCHEME="MindBudget.xcodeproj/xcshareddata/xcschemes/MindBudget.xcscheme"
LOCAL_SCHEME="MindBudget.xcodeproj/xcshareddata/xcschemes/MindBudget-StoreKit-Local.xcscheme"
PROJECT_FILE="MindBudget.xcodeproj/project.pbxproj"

for file in "${CATALOG}" "${DEFAULT_SCHEME}" "${LOCAL_SCHEME}" "${PROJECT_FILE}"; do
  if [[ ! -s "${file}" ]]; then
    echo "Missing StoreKit catalog control: ${file}" >&2
    exit 1
  fi
done

python3 - "${CATALOG}" <<'PY'
import copy
import json
import sys

MONTHLY = "com.xdgf558.mindbudget.pro.monthly"
ANNUAL = "com.xdgf558.mindbudget.pro.annual"
EXPECTED = {
    MONTHLY: ("MindBudget Pro Monthly", "P1M"),
    ANNUAL: ("MindBudget Pro Annual", "P1Y"),
}


def validate(catalog):
    errors = []
    if catalog.get("products") != []:
        errors.append("one-time products must remain absent")
    if catalog.get("nonRenewingSubscriptions") != []:
        errors.append("non-renewing subscriptions must remain absent")

    groups = catalog.get("subscriptionGroups")
    if not isinstance(groups, list) or len(groups) != 1:
        return errors + ["catalog must contain exactly one subscription group"]

    group = groups[0]
    if group.get("name") != "MindBudget Pro":
        errors.append("subscription group must be MindBudget Pro")

    subscriptions = group.get("subscriptions")
    if not isinstance(subscriptions, list) or len(subscriptions) != 2:
        return errors + ["catalog must contain exactly two subscriptions"]

    ids = [item.get("productID") for item in subscriptions]
    if set(ids) != set(EXPECTED) or len(ids) != len(set(ids)):
        errors.append("catalog must contain each accepted Product ID exactly once")

    if "lifetime" in json.dumps(catalog, ensure_ascii=False).lower():
        errors.append("Lifetime must remain absent")

    for item in subscriptions:
        product_id = item.get("productID")
        expected = EXPECTED.get(product_id)
        if expected is None:
            continue
        reference_name, duration = expected
        if item.get("referenceName") != reference_name:
            errors.append(f"{product_id} has the wrong reference name")
        if item.get("recurringSubscriptionPeriod") != duration:
            errors.append(f"{product_id} has the wrong duration")
        if item.get("type") != "RecurringSubscription":
            errors.append(f"{product_id} must be auto-renewable")
        if item.get("subscriptionGroupID") != group.get("id"):
            errors.append(f"{product_id} is outside the accepted group")
        if item.get("groupNumber") != 1:
            errors.append(f"{product_id} must remain at the one shared service level")
        if item.get("familyShareable") is not False:
            errors.append(f"{product_id} must not enable Family Sharing")
        for offers_key in (
            "introductoryOffers",
            "codeOffers",
            "adHocOffers",
            "winbackOffers",
        ):
            if item.get(offers_key) != []:
                errors.append(f"{product_id} must not define {offers_key}")
        locales = {entry.get("locale") for entry in item.get("localizations", [])}
        if locales != {"en_US", "zh_CN"}:
            errors.append(f"{product_id} must have only local en_US/zh_CN fixtures")
    return errors


def fixture():
    def subscription(product_id, reference_name, duration):
        return {
            "adHocOffers": [],
            "codeOffers": [],
            "familyShareable": False,
            "groupNumber": 1,
            "introductoryOffers": [],
            "localizations": [{"locale": "en_US"}, {"locale": "zh_CN"}],
            "productID": product_id,
            "recurringSubscriptionPeriod": duration,
            "referenceName": reference_name,
            "subscriptionGroupID": "GROUP",
            "type": "RecurringSubscription",
            "winbackOffers": [],
        }

    return {
        "products": [],
        "nonRenewingSubscriptions": [],
        "subscriptionGroups": [{
            "id": "GROUP",
            "name": "MindBudget Pro",
            "subscriptions": [
                subscription(MONTHLY, "MindBudget Pro Monthly", "P1M"),
                subscription(ANNUAL, "MindBudget Pro Annual", "P1Y"),
            ],
        }],
    }


positive = fixture()
if validate(positive):
    raise SystemExit("StoreKit catalog validator rejected its accepted self-test")

negative_lifetime = copy.deepcopy(positive)
negative_lifetime["subscriptionGroups"][0]["subscriptions"][1]["productID"] = (
    "com.xdgf558.mindbudget.pro.lifetime"
)
if not validate(negative_lifetime):
    raise SystemExit("StoreKit catalog validator accepted a Lifetime self-test")

negative_environment = copy.deepcopy(positive)
negative_environment["subscriptionGroups"][0]["subscriptions"][0]["familyShareable"] = True
if not validate(negative_environment):
    raise SystemExit("StoreKit catalog validator accepted a Family Sharing self-test")

with open(sys.argv[1], "r", encoding="utf-8") as handle:
    actual = json.load(handle)
actual_errors = validate(actual)
if actual_errors:
    raise SystemExit("StoreKit catalog contract failed:\n- " + "\n- ".join(actual_errors))
PY

if grep -Fq 'StoreKitConfigurationFileReference' "${DEFAULT_SCHEME}"; then
  echo "The default MindBudget scheme must not activate a local StoreKit configuration" >&2
  exit 1
fi

grep -Fq \
  '<StoreKitConfigurationFileReference identifier="../../Config/StoreKit/MindBudgetPro.storekit"/>' \
  "${LOCAL_SCHEME}" || {
  echo "The dedicated local scheme must activate only MindBudgetPro.storekit" >&2
  exit 1
}

grep -Fq 'buildForArchiving="NO"' "${LOCAL_SCHEME}" || {
  echo "The local StoreKit scheme must not be an Archive scheme" >&2
  exit 1
}

app_resources="$(
  grep -F 'F10000000000000000000003 /* Resources */ = {isa = PBXResourcesBuildPhase' \
    "${PROJECT_FILE}"
)"
test_resources="$(
  grep -F 'F10000000000000000000006 /* Resources */ = {isa = PBXResourcesBuildPhase' \
    "${PROJECT_FILE}"
)"

if grep -Fq 'MindBudgetPro.storekit' <<< "${app_resources}"; then
  echo "The StoreKit fixture must never enter the MindBudget app resource phase" >&2
  exit 1
fi

if ! grep -Fq 'MindBudgetPro.storekit in Resources' <<< "${test_resources}"; then
  echo "The StoreKit fixture must be copied only into the unit-test bundle" >&2
  exit 1
fi

echo "StoreKit local catalog and environment isolation passed"
