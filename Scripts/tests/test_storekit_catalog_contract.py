#!/usr/bin/env python3
"""Unit tests for the StoreKit catalog/project/scheme contract."""

import copy
import sys
import unittest
from pathlib import Path


SCRIPTS_DIRECTORY = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(SCRIPTS_DIRECTORY))

from storekit_catalog_contract import (  # noqa: E402
    ANNUAL,
    APP_RESOURCES_ID,
    EXPECTED,
    LOCAL_CONFIGURATION_PATH,
    MONTHLY,
    TEST_RESOURCES_ID,
    validate_catalog,
    validate_project_resources,
    validate_schemes,
)


def accepted_catalog():
    def subscription(product_id, expected):
        return {
            "adHocOffers": [],
            "billingPlans": [{
                "billingPlanType": "BILLED_UPFRONT",
                "commitmentDisplayPrice": expected["displayPrice"],
                "displayPrice": expected["displayPrice"],
                "isEnabled": True,
            }],
            "codeOffers": [],
            "displayPrice": expected["displayPrice"],
            "familyShareable": False,
            "groupNumber": 1,
            "introductoryOffers": [],
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


def accepted_project():
    return f"""
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


def accepted_default_scheme():
    return "<Scheme><LaunchAction buildConfiguration='Debug'/></Scheme>"


def accepted_local_scheme():
    return f"""
<Scheme>
  <BuildAction><BuildActionEntries>
    <BuildActionEntry buildForArchiving="NO"/>
  </BuildActionEntries></BuildAction>
  <LaunchAction buildConfiguration="Debug">
    <StoreKitConfigurationFileReference identifier="{LOCAL_CONFIGURATION_PATH}"/>
  </LaunchAction>
</Scheme>
"""


class StoreKitCatalogContractTests(unittest.TestCase):
    def test_accepted_catalog(self):
        self.assertEqual(validate_catalog(accepted_catalog()), [])

    def test_lifetime_is_rejected(self):
        catalog = copy.deepcopy(accepted_catalog())
        catalog["subscriptionGroups"][0]["subscriptions"][1]["productID"] = (
            "com.xdgf558.mindbudget.pro.lifetime"
        )
        self.assertTrue(validate_catalog(catalog))

    def test_family_sharing_is_rejected(self):
        catalog = copy.deepcopy(accepted_catalog())
        catalog["subscriptionGroups"][0]["subscriptions"][0][
            "familyShareable"
        ] = True
        self.assertTrue(validate_catalog(catalog))

    def test_customer_copy_is_rejected(self):
        catalog = copy.deepcopy(accepted_catalog())
        catalog["subscriptionGroups"][0]["subscriptions"][0]["localizations"][0][
            "description"
        ] = "Customer subscription"
        self.assertTrue(validate_catalog(catalog))

    def test_multiline_test_bundle_project_is_accepted(self):
        self.assertEqual(validate_project_resources(accepted_project()), [])

    def test_app_resource_fixture_is_rejected(self):
        project = accepted_project().replace(
            f"{APP_RESOURCES_ID} /* Resources */ = {{\n"
            "    isa = PBXResourcesBuildPhase;\n"
            "    files = (\n",
            f"{APP_RESOURCES_ID} /* Resources */ = {{\n"
            "    isa = PBXResourcesBuildPhase;\n"
            "    files = (\n"
            "        AA71 /* MindBudgetPro.storekit in Resources */,\n",
        )
        self.assertTrue(validate_project_resources(project))

    def test_isolated_debug_scheme_is_accepted(self):
        self.assertEqual(
            validate_schemes(accepted_default_scheme(), accepted_local_scheme()),
            [],
        )

    def test_default_scheme_fixture_is_rejected(self):
        default_scheme = f"""
<Scheme><LaunchAction buildConfiguration="Debug">
  <StoreKitConfigurationFileReference identifier="{LOCAL_CONFIGURATION_PATH}"/>
</LaunchAction></Scheme>
"""
        self.assertTrue(validate_schemes(default_scheme, accepted_local_scheme()))

    def test_archive_capable_local_scheme_is_rejected(self):
        local_scheme = accepted_local_scheme().replace(
            'buildForArchiving="NO"',
            'buildForArchiving="YES"',
        ).replace(
            "</Scheme>",
            '<ArchiveAction buildConfiguration="Release"/></Scheme>',
        )
        self.assertTrue(validate_schemes(accepted_default_scheme(), local_scheme))


if __name__ == "__main__":
    unittest.main()
