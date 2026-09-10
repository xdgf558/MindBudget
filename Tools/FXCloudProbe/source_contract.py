"""Closed build inventory and exact support declarations; no application execution."""
import copy
import json
from pathlib import Path
import re
import subprocess

LOCAL = {"ProbeApp.swift", "ProbeProtocol.swift", "ProbeLifecycle.swift", "ProbeEntry.swift", "ProbeSupport.swift"}
DEPENDENCIES = {
    "MindBudget/Data/DataActor.swift", "MindBudget/Data/DataTransferObjects.swift",
    "MindBudget/Data/ForeignCurrencyDataActor.swift", "MindBudget/Data/CloudSyncDataActor.swift",
    "MindBudget/Data/CloudSyncRemoteApply.swift", "MindBudget/Services/CloudSyncDomain.swift",
    "MindBudget/Services/CloudSyncRuntime.swift", "MindBudget/Services/BudgetCycleCalculator.swift",
    "MindBudget/Services/SpendingPatternDetector.swift", "MindBudget/Services/RuleConfiguration.swift",
    "MindBudget/Services/BudgetEngine.swift", "MindBudget/Commerce/FeatureAccessService.swift",
    "MindBudget/Commerce/EntitlementDomain.swift",
}
SUPPORT = {
    "IntentExpenseWriteResult": "MindBudget/AppIntents/IntentSupport.swift",
    "CoolingNotificationCandidate": "MindBudget/Services/NotificationScheduler.swift",
    "CoolingNotificationCandidateBatch": "MindBudget/Services/NotificationScheduler.swift",
    "CoolingNotificationIdentifierUpdate": "MindBudget/Services/NotificationScheduler.swift",
    "CoolingNotificationIdentifier": "MindBudget/Services/NotificationScheduler.swift",
    "SampleDataBundle": "MindBudget/Data/SampleDataFactory.swift",
}


def require(condition, message):
    if not condition:
        raise ValueError(message)


def declaration(text, name):
    matches = list(re.finditer(r"^(?:struct|enum) " + re.escape(name) + r"\b[^\n]*\{", text, re.M))
    require(len(matches) == 1, "missing/duplicate support declaration: " + name)
    start = matches[0].start()
    depth = 1
    for index in range(matches[0].end(), len(text)):
        if text[index] == "{": depth += 1
        if text[index] == "}": depth -= 1
        if depth == 0: return text[start:index + 1]
    raise ValueError("unterminated support declaration")


def validate(objects, sources, support, root):
    require(isinstance(sources, list) and sources == sorted(set(sources)), "source manifest not canonical")
    models = {str(p.relative_to(root)) for p in (root / "MindBudget/Models").rglob("*.swift")}
    require(set(sources) == models | DEPENDENCIES, "unexpected/missing production source")
    targets = [o for o in objects.values() if o.get("isa") == "PBXNativeTarget"]
    require(len(targets) == 1 and not targets[0].get("dependencies"), "unexpected target/dependency")
    require(not any(o.get("isa") in {"PBXShellScriptBuildPhase", "PBXBuildRule"} for o in objects.values()),
            "build hook forbidden")
    phases = [objects[key] for key in targets[0]["buildPhases"]]
    source_phases = [p for p in phases if p["isa"] == "PBXSourcesBuildPhase"]
    require(len(source_phases) == 1, "unexpected source phase")
    require(all(not p.get("files") for p in phases if p["isa"] != "PBXSourcesBuildPhase"),
            "unexpected linked/resource payload")
    paths = []
    for key in source_phases[0]["files"]:
        ref = objects[objects[key]["fileRef"]]
        require(ref["sourceTree"] == "<group>", "unexpected source tree")
        paths.append(ref["path"])
    require(len(paths) == len(set(paths)) and set(paths) == LOCAL | {"../../" + p for p in sources},
            "compiled source inventory differs")
    remainder = support
    for name, path in SUPPORT.items():
        fragment = declaration(support, name)
        require(fragment == declaration((root / path).read_text(), name),
                "support declaration drift: " + name)
        remainder = remainder.replace(fragment, "", 1)
    require(set(re.findall(r"^(?:struct|enum) (\w+)", support, re.M)) == set(SUPPORT),
            "extra support declaration")
    require(re.findall(r"^import (\w+)", support, re.M) == ["Foundation"], "support runtime import")
    remainder = re.sub(r"^//[^\n]*$|^import Foundation$", "", remainder, flags=re.M)
    require(not remainder.strip(), "support has additional code")


def self_test():
    directory = Path(__file__).resolve().parent
    root = directory.parent.parent
    result = subprocess.run(["plutil", "-convert", "json", "-o", "-",
                             str(directory / "FXCloudProbe.xcodeproj/project.pbxproj")],
                            check=True, capture_output=True, timeout=30)
    objects = json.loads(result.stdout)["objects"]
    sources = json.loads((directory / "production-sources.json").read_text())
    support = (directory / "ProbeSupport.swift").read_text()
    ordinary = [root / "MindBudget.xcodeproj/project.pbxproj"]
    ordinary += list((root / "MindBudget.xcodeproj").rglob("*.xcscheme"))
    ordinary += list((root / "MindBudget").rglob("*.swift"))
    ordinary += list((root / "Config").rglob("*.xcconfig"))
    ordinary_text = [path.read_text() for path in ordinary]
    check_ordinary(ordinary_text)
    try:
        check_ordinary(ordinary_text + ["SWIFT_ACTIVE_COMPILATION_CONDITIONS = MINDBUDGET_FX_CLOUD_PROBE"])
    except ValueError:
        pass
    else:
        raise ValueError("ordinary probe compile-flag mutation escaped")
    validate(objects, sources, support, root)
    mutations = []
    for replacement in ("../../MindBudget/App/MindBudgetApp.swift", "ProtocolTests.swift"):
        value = copy.deepcopy(objects)
        ref = next(o for o in value.values() if o.get("path") == "ProbeApp.swift")
        ref["path"] = replacement
        mutations.append((value, sources, support))
    value = copy.deepcopy(objects)
    value["hook"] = {"isa": "PBXShellScriptBuildPhase"}
    mutations.append((value, sources, support))
    value = copy.deepcopy(objects)
    phase = next(o for o in value.values() if o.get("isa") == "PBXSourcesBuildPhase")
    phase["files"].append(phase["files"][0])
    mutations.append((value, sources, support))
    mutations += [(objects, sources[:-1], support),
                  (objects, sorted(sources + ["MindBudget/App/MindBudgetApp.swift"]), support),
                  (objects, sources, support.replace("let wasDuplicate: Bool", "let wasDuplicate: Int")),
                  (objects, sources, support + "\nimport UserNotifications\n"),
                  (objects, sources, support + "\nlet hidden = 1\n")]
    for index, values in enumerate(mutations):
        try: validate(*values, root)
        except ValueError: continue
        raise ValueError(f"source inventory negative {index} escaped")
    print(f"PASS: explicit {len(sources)} production sources / 6 exact support declarations / 9 negatives.")
    print("PASS: ordinary project/schemes/product/config files cannot enable the physical probe flag.")


def check_ordinary(texts):
    require(not any("MINDBUDGET_FX_CLOUD_PROBE" in text for text in texts),
            "ordinary app must not enable isolated physical probe")


if __name__ == "__main__":
    self_test()
