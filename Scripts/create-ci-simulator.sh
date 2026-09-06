#!/usr/bin/env bash
set -euo pipefail

[[ "${GITHUB_ACTIONS:-}" == "true" && -n "${GITHUB_ENV:-}" ]] || {
  echo "This entry creates a source simulator only on GitHub Actions" >&2
  exit 2
}
xcode_major="$(xcodebuild -version | awk '/^Xcode / { split($2, parts, "."); print parts[1] }')"
runtime_id="$(xcrun simctl list runtimes -j | python3 -c '
import json, sys
required_major = int(sys.argv[1])
runtimes = [runtime for runtime in json.load(sys.stdin)["runtimes"] if runtime.get("isAvailable") and runtime["identifier"].startswith("com.apple.CoreSimulator.SimRuntime.iOS-") and int(runtime.get("version", "0").split(".")[0]) == required_major]
if not runtimes:
    raise SystemExit(f"No available iOS {required_major} simulator runtime")
version = lambda runtime: tuple(map(int, runtime.get("version", "0").split(".")))
print(max(runtimes, key=version)["identifier"])
' "${xcode_major}")"
device_type_id="$(xcrun simctl list devicetypes -j | python3 -c '
import json, sys
device_types = json.load(sys.stdin)["devicetypes"]
by_name = {device["name"]: device["identifier"] for device in device_types}
preferred = ("iPhone 17 Pro", "iPhone 17", "iPhone 16 Pro", "iPhone 16")
selected = next((by_name[name] for name in preferred if name in by_name), None)
if selected is None:
    selected = next((device["identifier"] for device in device_types if device["name"].startswith("iPhone")), None)
if selected is None:
    raise SystemExit("No iPhone simulator device type")
print(selected)
')"
simulator_id="$(xcrun simctl create 'MindBudget CI' "${device_type_id}" "${runtime_id}")"
[[ "${simulator_id}" =~ ^[A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12}$ ]] || {
  echo "simctl create did not return one UUID" >&2
  exit 1
}
# Do not boot here. Ordinary validation boots after builds; FX creates its own non-cloned device.
echo "MINDBUDGET_TEST_DESTINATION=platform=iOS Simulator,id=${simulator_id}" >> "${GITHUB_ENV}"
