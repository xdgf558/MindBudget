"""Exercise the complete validator's command ordering without Xcode or a simulator."""

from __future__ import annotations

import os
from pathlib import Path
import re
import subprocess
import tempfile


SIMULATOR_ID = "00000000-0000-0000-0000-000000000001"
STATIC_STEPS = (
    "check-release-readiness.sh",
    "check-fx01-contract.sh",
    "check-network-egress.sh",
    "check-commercialization-docs.sh",
    "check-public-configuration-contract.sh",
    "check-telemetry-contract.sh",
    "check-telemetry-worker-contract.sh",
    "check-telemetry-metrics-contract.sh",
    "check-feature-access-boundary.sh",
    "check-storekit-test-catalog.sh",
    "check-c6-release-matrix.sh",
    "check_c6_02_acceptance.py --self-test",
)

COMMAND_STUB = r'''#!/usr/bin/env bash
set -euo pipefail
command_name="${0##*/}"
event="${command_name}"
case "${command_name}" in
  xcodebuild)
    case " $* " in
      *" -showBuildSettings "*) event="build-settings" ;;
      *" build-for-testing "*) event="build-for-testing" ;;
      *" build "*) event="release-build" ;;
      *" test-without-building "*) event="test" ;;
      *) exit 92 ;;
    esac ;;
  xcrun)
    [[ "$*" == "simctl bootstatus ${ORDER_SIMULATOR_ID} -b" ]] || exit 93
    event="boot-ready" ;;
  check_c6_02_acceptance.py)
    if [[ "${1:-}" == "--self-test" ]]; then
      event="check_c6_02_acceptance.py --self-test"
    elif [[ "${1:-}" == "--verify-result-bundle" ]]; then
      event="acceptance"
    else
      exit 94
    fi ;;
  fx01_ui_contract.py)
    [[ "${1:-}" == "--verify-unit-bundle" ]] || exit 95
    event="fx-unit-bindings" ;;
  run-fx01-ui-tests.sh)
    [[ "$#" == 2 && "$2" == *-FX-UI.xcresult ]] || exit 96
    event="fx-ui-host" ;;
esac
printf '%s\n' "${event}" >> "${ORDER_TRACE}"
if [[ "${ORDER_FAIL_AT:-}" == "${event}" ]]; then
  exit 73
fi
if [[ "${event}" == "build-settings" ]]; then
  printf '    PRODUCT_BUNDLE_IDENTIFIER = example.MindBudget\n'
fi
'''


def run_validation_order_self_test(project_root: Path) -> None:
    workflow = (project_root / ".github/workflows/ci.yml").read_text(encoding="utf-8")
    # The actual complete validator is exercised below; its caller must not boot early.
    workflow_code = "\n".join(line for line in workflow.splitlines() if not line.lstrip().startswith("#"))
    if re.search(r"\bsimctl\s+boot(?:status)?\b", workflow_code):
        raise RuntimeError("CI must leave simulator boot/readiness to the complete validator")
    if workflow.count("run: Scripts/validate.sh") != 1:
        raise RuntimeError("CI must invoke the complete validator exactly once")

    with tempfile.TemporaryDirectory(prefix="mindbudget-validation-order-") as temporary:
        fixture = Path(temporary)
        scripts = fixture / "Scripts"
        scripts.mkdir()
        commands = fixture / "bin"
        commands.mkdir()
        validator = scripts / "validate.sh"
        validator.write_text((project_root / "Scripts/validate.sh").read_text(encoding="utf-8"), encoding="utf-8")
        for name in {step.split()[0] for step in STATIC_STEPS} | {
            "check-coverage.sh", "fx01_ui_contract.py", "run-fx01-ui-tests.sh"
        }:
            path = scripts / name
            path.write_text(COMMAND_STUB, encoding="utf-8")
            path.chmod(0o700)
        for name in ("xcodebuild", "xcrun"):
            path = commands / name
            path.write_text(COMMAND_STUB, encoding="utf-8")
            path.chmod(0o700)

        before_boot = [*STATIC_STEPS, "build-settings", "release-build", "build-for-testing"]
        trace = fixture / "trace.txt"
        base_env = {
            "PATH": f"{commands}:/usr/bin:/bin",
            "MINDBUDGET_TEST_DESTINATION": f"platform=iOS Simulator,id={SIMULATOR_ID}",
            "MINDBUDGET_RESULT_BUNDLE_PATH": str(fixture / "NeverCreated.xcresult"),
            "MINDBUDGET_RETRY_TESTS_ON_FAILURE": "0",
            "MINDBUDGET_SKIP_WALL_CLOCK_BENCHMARK": "1",
            "ORDER_TRACE": str(trace),
            "ORDER_SIMULATOR_ID": SIMULATOR_ID,
        }
        # Preserve only OS temp lookup; never pass API secrets or real tools to the stubs.
        if "TMPDIR" in os.environ:
            base_env["TMPDIR"] = os.environ["TMPDIR"]

        def verify(expected: list[str], *, failure: str = "", benchmark: bool = False,
                   destination: str | None = None) -> None:
            trace.write_text("", encoding="utf-8")
            environment = dict(base_env, ORDER_FAIL_AT=failure)
            if benchmark:
                environment["MINDBUDGET_SKIP_WALL_CLOCK_BENCHMARK"] = "0"
            if destination is not None:
                environment["MINDBUDGET_TEST_DESTINATION"] = destination
            result = subprocess.run(
                ["/bin/bash", str(validator)], cwd=fixture, env=environment,
                capture_output=True, text=True, timeout=30, check=False,
            )
            observed = trace.read_text(encoding="utf-8").splitlines()
            if result.returncode != (73 if failure else 0) or observed != expected or result.stderr:
                raise RuntimeError(
                    f"validation ordering failed at {failure or 'success'}: "
                    f"exit={result.returncode}, observed={observed}, stderr={result.stderr!r}"
                )

        after_test = ["check-coverage.sh", "acceptance", "fx-unit-bindings", "fx-ui-host"]
        verify([*before_boot, "boot-ready", "test", *after_test])
        verify([*before_boot, "boot-ready", "test", "test", *after_test], benchmark=True)
        # Named local destinations keep xcodebuild's existing boot behavior.
        verify([*before_boot, "test", *after_test], destination="platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5")
        for index, failure in enumerate([*before_boot, "boot-ready"]):
            verify([*before_boot, "boot-ready"][:index + 1], failure=failure)
        for index, failure in enumerate(["test", *after_test]):
            verify([*before_boot, "boot-ready", *["test", *after_test][:index + 1]], failure=failure)
    print("Validation ordering self-test passed: 3 success paths / 21 fail-closed command failures")
