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

python3 - "${CATALOG}" "${DEFAULT_SCHEME}" "${LOCAL_SCHEME}" "${PROJECT_FILE}" <<'PY'
import copy
import json
import re
import sys
import xml.etree.ElementTree as ET

MONTHLY = "com.xdgf558.mindbudget.pro.monthly"
ANNUAL = "com.xdgf558.mindbudget.pro.annual"
APP_RESOURCES_ID = "F10000000000000000000003"
TEST_RESOURCES_ID = "F10000000000000000000006"
LOCAL_CONFIGURATION_PATH = "../../Config/StoreKit/MindBudgetPro.storekit"
EXPECTED = {
    MONTHLY: {
        "referenceName": "MindBudget Pro Monthly",
        "duration": "P1M",
        "displayPrice": "0.99",
        "localizations": {
            "en_US": (
                "MindBudget Pro Monthly (Local Test)",
                "Local StoreKit test configuration fixture only. Not a customer offer.",
            ),
            "zh_CN": (
                "花有数 Pro 月付（本地测试）",
                "仅用于本地 StoreKit 配置测试，不是对用户的售价。",
            ),
        },
    },
    ANNUAL: {
        "referenceName": "MindBudget Pro Annual",
        "duration": "P1Y",
        "displayPrice": "9.99",
        "localizations": {
            "en_US": (
                "MindBudget Pro Annual (Local Test)",
                "Local StoreKit test configuration fixture only. Not a customer offer.",
            ),
            "zh_CN": (
                "花有数 Pro 年付（本地测试）",
                "仅用于本地 StoreKit 配置测试，不是对用户的售价。",
            ),
        },
    },
}


def validate(catalog):
    errors = []
    settings = catalog.get("settings")
    if not isinstance(settings, dict):
        errors.append("catalog settings are missing")
    else:
        if settings.get("_storefront") != "CHN":
            errors.append("the local default storefront must be CHN")
        if settings.get("_locale") != "zh_CN":
            errors.append("the local default locale must be zh_CN")

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
        if item.get("referenceName") != expected["referenceName"]:
            errors.append(f"{product_id} has the wrong reference name")
        if item.get("recurringSubscriptionPeriod") != expected["duration"]:
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
        if item.get("displayPrice") != expected["displayPrice"]:
            errors.append(f"{product_id} changed its synthetic local test price")
        billing_plans = item.get("billingPlans")
        if not isinstance(billing_plans, list) or len(billing_plans) != 1:
            errors.append(f"{product_id} must have one synthetic local billing plan")
        else:
            billing_plan = billing_plans[0]
            if billing_plan.get("billingPlanType") != "BILLED_UPFRONT":
                errors.append(f"{product_id} has the wrong local billing plan type")
            if billing_plan.get("displayPrice") != expected["displayPrice"]:
                errors.append(f"{product_id} billing display price changed")
            if billing_plan.get("commitmentDisplayPrice") != expected["displayPrice"]:
                errors.append(f"{product_id} commitment display price changed")
            if billing_plan.get("isEnabled") is not True:
                errors.append(f"{product_id} local billing plan must remain enabled")

        localizations = item.get("localizations")
        if not isinstance(localizations, list):
            errors.append(f"{product_id} localizations are missing")
        else:
            localizations_by_locale = {
                entry.get("locale"): (
                    entry.get("displayName"),
                    entry.get("description"),
                )
                for entry in localizations
            }
            if localizations_by_locale != expected["localizations"]:
                errors.append(
                    f"{product_id} must retain exact bilingual local-test disclaimers"
                )
    return errors


def fixture():
    def subscription(product_id, expected):
        return {
            "adHocOffers": [],
            "codeOffers": [],
            "familyShareable": False,
            "groupNumber": 1,
            "introductoryOffers": [],
            "billingPlans": [{
                "billingPlanType": "BILLED_UPFRONT",
                "commitmentDisplayPrice": expected["displayPrice"],
                "displayPrice": expected["displayPrice"],
                "isEnabled": True,
            }],
            "displayPrice": expected["displayPrice"],
            "localizations": [
                {
                    "locale": locale,
                    "displayName": localized_copy[0],
                    "description": localized_copy[1],
                }
                for locale, localized_copy in expected["localizations"].items()
            ],
            "productID": product_id,
            "recurringSubscriptionPeriod": expected["duration"],
            "referenceName": expected["referenceName"],
            "subscriptionGroupID": "GROUP",
            "type": "RecurringSubscription",
            "winbackOffers": [],
        }

    return {
        "settings": {"_storefront": "CHN", "_locale": "zh_CN"},
        "products": [],
        "nonRenewingSubscriptions": [],
        "subscriptionGroups": [{
            "id": "GROUP",
            "name": "MindBudget Pro",
            "subscriptions": [
                subscription(MONTHLY, EXPECTED[MONTHLY]),
                subscription(ANNUAL, EXPECTED[ANNUAL]),
            ],
        }],
    }


def object_body(project, object_id):
    header = re.search(
        rf"(?m)^\s*{re.escape(object_id)}\s+/\*[^\n]*\*/\s*=\s*\{{",
        project,
    )
    if header is None:
        return None

    start = project.find("{", header.start())
    depth = 0
    for index in range(start, len(project)):
        character = project[index]
        if character == "{":
            depth += 1
        elif character == "}":
            depth -= 1
            if depth == 0:
                return project[start:index + 1]
    return None


def validate_project_resources(project):
    errors = []
    build_file_ids = []
    header_pattern = re.compile(
        r"(?m)^\s*([A-Za-z0-9]+)\s+"
        r"/\*\s*MindBudgetPro\.storekit in Resources\s*\*/\s*=\s*\{"
    )
    for match in header_pattern.finditer(project):
        body = object_body(project, match.group(1))
        if body is not None and re.search(r"\bisa\s*=\s*PBXBuildFile\s*;", body):
            build_file_ids.append(match.group(1))

    if len(build_file_ids) != 1:
        return ["MindBudgetPro.storekit must have exactly one PBXBuildFile resource entry"]

    build_file_id = build_file_ids[0]
    app_resources = object_body(project, APP_RESOURCES_ID)
    test_resources = object_body(project, TEST_RESOURCES_ID)
    if app_resources is None or test_resources is None:
        return ["app/test PBXResourcesBuildPhase objects are missing"]

    token = re.compile(rf"(?<![A-Za-z0-9]){re.escape(build_file_id)}(?![A-Za-z0-9])")
    if token.search(app_resources) or "MindBudgetPro.storekit" in app_resources:
        errors.append("the StoreKit fixture entered the MindBudget app resource phase")
    if len(token.findall(test_resources)) != 1:
        errors.append("the StoreKit fixture must appear exactly once in unit-test resources")
    return errors


def validate_schemes(default_scheme, local_scheme):
    errors = []
    try:
        default_root = ET.fromstring(default_scheme)
        local_root = ET.fromstring(local_scheme)
    except ET.ParseError as error:
        return [f"scheme XML is invalid: {error}"]

    if list(default_root.iter("StoreKitConfigurationFileReference")):
        errors.append("the default scheme activates a local StoreKit configuration")

    local_references = list(local_root.iter("StoreKitConfigurationFileReference"))
    if len(local_references) != 1:
        errors.append("the local scheme must contain exactly one StoreKit configuration")
    elif local_references[0].get("identifier") != LOCAL_CONFIGURATION_PATH:
        errors.append("the local scheme points at an unexpected StoreKit configuration")

    launch_actions = list(local_root.iter("LaunchAction"))
    if len(launch_actions) != 1 or launch_actions[0].get("buildConfiguration") != "Debug":
        errors.append("the local StoreKit scheme must launch only a Debug build")
    if any(
        entry.get("buildForArchiving") != "NO"
        for entry in local_root.iter("BuildActionEntry")
    ):
        errors.append("every local-scheme build entry must opt out of Archive")
    if list(local_root.iter("ArchiveAction")):
        errors.append("the local StoreKit scheme must not define an Archive action")
    return errors


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

negative_disclaimer = copy.deepcopy(positive)
negative_disclaimer["subscriptionGroups"][0]["subscriptions"][0]["localizations"][0][
    "description"
] = "Customer subscription"
if not validate(negative_disclaimer):
    raise SystemExit("StoreKit catalog validator accepted a customer-copy self-test")

positive_project = f"""
AA71 /* MindBudgetPro.storekit in Resources */ = {{
    isa = PBXBuildFile;
    fileRef = BB71 /* MindBudgetPro.storekit */;
}};
{APP_RESOURCES_ID} /* Resources */ = {{
    isa = PBXResourcesBuildPhase;
    files = (
    );
}};
{TEST_RESOURCES_ID} /* Resources */ = {{
    isa = PBXResourcesBuildPhase;
    files = (
        AA71 /* MindBudgetPro.storekit in Resources */,
    );
}};
"""
if validate_project_resources(positive_project):
    raise SystemExit("resource isolation rejected its multiline safe self-test")

negative_project = positive_project.replace(
    f"{APP_RESOURCES_ID} /* Resources */ = {{\n"
    "    isa = PBXResourcesBuildPhase;\n"
    "    files = (\n",
    f"{APP_RESOURCES_ID} /* Resources */ = {{\n"
    "    isa = PBXResourcesBuildPhase;\n"
    "    files = (\n"
    "        AA71 /* MindBudgetPro.storekit in Resources */,\n",
)
if not validate_project_resources(negative_project):
    raise SystemExit("resource isolation accepted an app-resource self-test")

positive_default_scheme = "<Scheme><LaunchAction buildConfiguration='Debug'/></Scheme>"
positive_local_scheme = f"""
<Scheme>
  <BuildAction><BuildActionEntries>
    <BuildActionEntry buildForArchiving="NO"/>
  </BuildActionEntries></BuildAction>
  <LaunchAction buildConfiguration="Debug">
    <StoreKitConfigurationFileReference identifier="{LOCAL_CONFIGURATION_PATH}"/>
  </LaunchAction>
</Scheme>
"""
if validate_schemes(positive_default_scheme, positive_local_scheme):
    raise SystemExit("scheme isolation rejected its safe self-test")

negative_default_scheme = f"""
<Scheme><LaunchAction buildConfiguration="Debug">
  <StoreKitConfigurationFileReference identifier="{LOCAL_CONFIGURATION_PATH}"/>
</LaunchAction></Scheme>
"""
if not validate_schemes(negative_default_scheme, positive_local_scheme):
    raise SystemExit("scheme isolation accepted a default-scheme fixture self-test")

negative_local_scheme = positive_local_scheme.replace(
    'buildForArchiving="NO"',
    'buildForArchiving="YES"',
).replace("</Scheme>", '<ArchiveAction buildConfiguration="Release"/></Scheme>')
if not validate_schemes(positive_default_scheme, negative_local_scheme):
    raise SystemExit("scheme isolation accepted an Archive-capable self-test")

with open(sys.argv[1], "r", encoding="utf-8") as handle:
    actual = json.load(handle)
actual_errors = validate(actual)

with open(sys.argv[2], "r", encoding="utf-8") as handle:
    default_scheme = handle.read()
with open(sys.argv[3], "r", encoding="utf-8") as handle:
    local_scheme = handle.read()
actual_errors.extend(validate_schemes(default_scheme, local_scheme))

with open(sys.argv[4], "r", encoding="utf-8") as handle:
    project = handle.read()
actual_errors.extend(validate_project_resources(project))

if actual_errors:
    raise SystemExit("StoreKit catalog/isolation contract failed:\n- " + "\n- ".join(actual_errors))
PY

echo "StoreKit local catalog and environment isolation passed"
