"""Exercise the complete validator's command ordering without Xcode or a simulator."""

from __future__ import annotations

import os
from pathlib import Path
import re
import subprocess
import tempfile
import textwrap


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
if [[ "${event}" == "test" && ( " $* " == *" -retry-tests-on-failure "* || " $* " == *" -test-iterations "* ) ]]; then
  exit 97
fi
printf '%s\n' "${event}" >> "${ORDER_TRACE}"
if [[ "${ORDER_FAIL_AT:-}" == "${event}" ]]; then
  exit 73
fi
if [[ "${event}" == "build-settings" ]]; then
  printf '    PRODUCT_BUNDLE_IDENTIFIER = example.MindBudget\n'
fi
'''


def validate_hosted_retry_policy(workflow_code: str) -> None:
    name = "MINDBUDGET_RETRY_TESTS_ON_FAILURE"
    settings = re.findall(rf'^\s*{name}:\s*(.*?)\s*$', workflow_code, re.MULTILINE)
    if (settings != ['"0"'] or workflow_code.count(name) != 1
            or "-retry-tests-on-failure" in workflow_code or "-test-iterations" in workflow_code):
        raise RuntimeError("hosted CI must disable test retries without another override")


ACCEPTANCE_JOB = '''  acceptance:
    name: Build and test
    needs: [ordinary, fx-ui]
    if: always()
    runs-on: ubuntu-latest
    timeout-minutes: 5
    steps:
      - name: Require both suites
        env:
          ORDINARY_RESULT: ${{ needs.ordinary.result }}
          FX_UI_RESULT: ${{ needs.fx-ui.result }}
        run: |
          set -euo pipefail
          test "${ORDINARY_RESULT}" = "success"
          test "${FX_UI_RESULT}" = "success"
'''


def workflow_jobs(workflow: str) -> dict[str, str]:
    """Accept only this workflow's explicit, unaliased job structure, not arbitrary YAML."""
    code = "\n".join(line for line in workflow.splitlines() if line.strip() and not line.lstrip().startswith("#"))
    validate_hosted_retry_policy(code)
    if code.count("\njobs:\n") != 1:
        raise RuntimeError("CI needs one explicit jobs mapping")
    body = code.split("\njobs:\n", 1)[1]
    headers = list(re.finditer(r"^  ([a-z][a-z0-9-]*):$", body, re.M))
    if [m[1] for m in headers] != ["ordinary", "fx-ui", "acceptance"]:
        raise RuntimeError("CI requires ordinary, FX UI, and the mandatory acceptance join")
    jobs = {m[1]: body[m.start():headers[i + 1].start() if i + 1 < len(headers) else len(body)].rstrip()
            for i, m in enumerate(headers)}
    if jobs["acceptance"] != ACCEPTANCE_JOB.rstrip():
        raise RuntimeError("required Build and test check must fail unless both suites succeed")
    if re.search(r"\b(?:continue-on-error|strategy|shell|container|defaults):", code):
        raise RuntimeError("CI may not mask failures or replace the execution shell/environment")
    for identifier, title in (("ordinary", "Ordinary build and test"), ("fx-ui", "FX UI build and test")):
        job = jobs[identifier]
        header = f"  {identifier}:\n    name: {title}\n    runs-on: macos-26\n    timeout-minutes: 60\n    steps:\n"
        if not job.startswith(header):
            raise RuntimeError(f"{identifier} must be an unconditional independent macOS job")
        steps = list(re.finditer(r"^      - name: (.+)$", job, re.M))
        names = [step[1] for step in steps]
        if len(names) != len(set(names)):
            raise RuntimeError("duplicate CI step identity")
        blocks = {m[1]: job[m.start():steps[i + 1].start() if i + 1 < len(steps) else len(job)].rstrip()
                  for i, m in enumerate(steps)}
        for name, block in blocks.items():
            conditions = re.findall(r"^\s*if:\s*(.*)$", block, re.M)
            allowed = {"Upload test report", "Record test report path", "Upload FX test report and simulator provenance"}
            if conditions and (name not in allowed or conditions != ["always()"]):
                raise RuntimeError("test/build/contract steps cannot be conditional")
        def exact(name: str, tail: str) -> None:
            if blocks.get(name) != f"      - name: {name}\n" + tail.rstrip():
                raise RuntimeError(f"{identifier} lost required step {name}")
        exact("Check out repository", "        uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7")
        exact("Create test simulator", "        run: Scripts/create-ci-simulator.sh")
        if identifier == "ordinary":
            # Comments are removed above, so match the actual command and result path only.
            exact("Build and test", '''        env:
          MINDBUDGET_RESULT_BUNDLE_PATH: ${{ runner.temp }}/MindBudget.xcresult
        run: Scripts/validate.sh --ci-ordinary-only''')
            artifact = "MindBudget-ordinary-xcresult-${{ github.run_id }}-${{ github.run_attempt }}"
        else:
            exact("Verify FX contract", "        run: Scripts/check-fx01-contract.sh")
            exact("Build and test FX host", '''        env:
          MINDBUDGET_FX_RESULT_BUNDLE_PATH: ${{ runner.temp }}/MindBudget-FX-UI.xcresult
        run: Scripts/run-fx01-ui-tests.sh "${MINDBUDGET_TEST_DESTINATION}" "${MINDBUDGET_FX_RESULT_BUNDLE_PATH}"''')
            artifact = "MindBudget-fx-xcresult-${{ github.run_id }}-${{ github.run_attempt }}"
            if job.count("${{ runner.temp }}/MindBudget-FX-UI.simulator.json") != 1:
                raise RuntimeError("FX artifact must retain its own simulator provenance")
        if job.count(artifact) != (2 if identifier == "ordinary" else 1):
            raise RuntimeError("separate per-attempt artifacts are mandatory")
        if job.count("retention-days: 14") != 1 or job.count("if-no-files-found: error") != 1:
            raise RuntimeError("missing artifact cannot pass or lose evidence retention")
    return jobs


def run_ci_simulator_self_test(project_root: Path) -> None:
    stub = r'''#!/usr/bin/env bash
set -euo pipefail
printf '%s %s\n' "${0##*/}" "$*" >> "${SIMULATOR_TRACE}"
if [[ "${0##*/}" == "xcodebuild" && "$*" == "-version" ]]; then
  printf 'Xcode 26.6\nBuild version synthetic\n'
elif [[ "$*" == "simctl list runtimes -j" ]]; then
  if [[ "${SIMULATOR_CASE}" == "no-runtime" ]]; then
    printf '{"runtimes":[]}'
  else
    printf '{"runtimes":[{"isAvailable":true,"identifier":"com.apple.CoreSimulator.SimRuntime.iOS-26-6","version":"26.6"}]}'
  fi
elif [[ "$*" == "simctl list devicetypes -j" ]]; then
  if [[ "${SIMULATOR_CASE}" == "no-phone" ]]; then
    printf '{"devicetypes":[]}'
  else
    printf '{"devicetypes":[{"name":"iPhone 17 Pro","identifier":"com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro"}]}'
  fi
elif [[ "$*" == "simctl create MindBudget CI com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro com.apple.CoreSimulator.SimRuntime.iOS-26-6" ]]; then
  [[ "${SIMULATOR_CASE}" != "create-failure" ]] || exit 73
  if [[ "${SIMULATOR_CASE}" == "invalid-uuid" ]]; then printf 'booted\n'; else printf '%s\n' "${ORDER_SIMULATOR_ID}"; fi
else
  exit 99
fi
'''
    with tempfile.TemporaryDirectory(prefix="mindbudget-ci-simulator-") as temporary:
        fixture = Path(temporary)
        commands = fixture / "bin"
        commands.mkdir()
        for name in ("xcodebuild", "xcrun"):
            command = commands / name
            command.write_text(stub, encoding="utf-8")
            command.chmod(0o700)
        for case in ("success", "no-runtime", "no-phone", "create-failure", "invalid-uuid", "outside-ci", "missing-env"):
            trace = fixture / f"{case}.trace"
            exported = fixture / f"{case}.env"
            environment = {"PATH": f"{commands}:{os.defpath}", "GITHUB_ACTIONS": "true", "GITHUB_ENV": str(exported),
                           "SIMULATOR_TRACE": str(trace), "SIMULATOR_CASE": case, "ORDER_SIMULATOR_ID": SIMULATOR_ID}
            if case == "outside-ci":
                environment["GITHUB_ACTIONS"] = "false"
            if case == "missing-env":
                del environment["GITHUB_ENV"]
            result = subprocess.run(["/bin/bash", str(project_root / "Scripts/create-ci-simulator.sh")],
                                    env=environment, capture_output=True, text=True, timeout=15)
            if case == "success":
                expected = f"MINDBUDGET_TEST_DESTINATION=platform=iOS Simulator,id={SIMULATOR_ID}\n"
                if result.returncode != 0 or exported.read_text() != expected or len(trace.read_text().splitlines()) != 4:
                    raise RuntimeError("CI simulator source creation contract failed")
            elif result.returncode == 0 or exported.exists():
                raise RuntimeError(f"CI simulator invalid case was accepted: {case}")
            if case in ("outside-ci", "missing-env") and trace.exists():
                raise RuntimeError("CI simulator must reject invalid invocation before any command")
    print("CI source simulator self-test passed: 1 success / 6 failures; no real simulator touched")


def run_validation_order_self_test(project_root: Path) -> None:
    workflow = (project_root / ".github/workflows/ci.yml").read_text(encoding="utf-8")
    # The actual complete validator is exercised below; its caller must not boot early.
    workflow_code = "\n".join(line for line in workflow.splitlines() if not line.lstrip().startswith("#"))
    jobs = workflow_jobs(workflow)
    retry_setting = 'MINDBUDGET_RETRY_TESTS_ON_FAILURE: "0"'
    for mutation in (
        workflow_code.replace(retry_setting, 'MINDBUDGET_RETRY_TESTS_ON_FAILURE: "1"'),
        workflow_code.replace(retry_setting, ''),
        workflow_code + '\n      ' + retry_setting,
        workflow_code + '\n        run: MINDBUDGET_RETRY_TESTS_ON_FAILURE=1 Scripts/validate.sh',
        workflow_code + '\n        run: xcodebuild -retry-tests-on-failure test',
        workflow_code + '\n        run: xcodebuild -test-iterations 2 test',
    ):
        try:
            validate_hosted_retry_policy(mutation)
        except RuntimeError:
            continue
        raise RuntimeError("hosted retry-policy mutation escaped rejection")
    if re.search(r"\bsimctl\s+boot(?:status)?\b", workflow_code):
        raise RuntimeError("CI must leave simulator boot/readiness to the complete validator")
    workflow_negatives = (
        workflow.replace("needs: [ordinary, fx-ui]", "needs: [ordinary]"),
        workflow.replace("    if: always()\n    runs-on: ubuntu-latest", "    if: success()\n    runs-on: ubuntu-latest"),
        workflow.replace('test "${FX_UI_RESULT}" = "success"', 'true'),
        workflow.replace("  fx-ui:\n", "  optional-fx-ui:\n"),
        workflow.replace("    name: FX UI build and test", "    if: false\n    name: FX UI build and test"),
        workflow.replace("      - name: Build and test FX host", "      - name: Build and test FX host\n        if: false"),
        workflow.replace("--ci-ordinary-only", ""),
        workflow.replace("run: Scripts/run-fx01-ui-tests.sh", "run: echo Scripts/run-fx01-ui-tests.sh"),
        workflow.replace("      - name: Build and test FX host", "      - name: Build and test FX host\n        continue-on-error: true"),
        workflow.replace("timeout-minutes: 60", "timeout-minutes: 90"),
        workflow.replace("${{ runner.temp }}/MindBudget-FX-UI.simulator.json", "missing.json"),
        workflow.replace("if-no-files-found: error", "if-no-files-found: ignore"),
        workflow.replace("name: Build and test\n    needs:", "name: Optional gate\n    needs:"),
        workflow.replace("      - name: Check out repository\n        uses:", "      - name: Check out repository\n        if: false\n        uses:"),
    )
    for mutation in workflow_negatives:
        try:
            workflow_jobs(mutation)
        except RuntimeError:
            continue
        raise RuntimeError("split-job workflow mutation escaped rejection")
    join_shell = textwrap.dedent(jobs["acceptance"].split("        run: |\n", 1)[1])
    states = ("success", "failure", "cancelled", "skipped", "timed_out", "")
    for ordinary in states:
        for fx in states:
            result = subprocess.run(["/bin/bash", "-c", join_shell], capture_output=True, timeout=5,
                                    env={"PATH": "/usr/bin:/bin", "ORDINARY_RESULT": ordinary, "FX_UI_RESULT": fx})
            if (result.returncode == 0) != (ordinary == fx == "success"):
                raise RuntimeError("required join accepted an incomplete CI result")

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

        before_boot = [*STATIC_STEPS, "build-settings", "build-for-testing"]
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
                   destination: str | None = None, partial: bool = False) -> None:
            trace.write_text("", encoding="utf-8")
            environment = dict(base_env, ORDER_FAIL_AT=failure)
            if benchmark:
                environment["MINDBUDGET_SKIP_WALL_CLOCK_BENCHMARK"] = "0"
            if destination is not None:
                environment["MINDBUDGET_TEST_DESTINATION"] = destination
            if partial:
                environment["GITHUB_ACTIONS"] = "true"
            result = subprocess.run(
                ["/bin/bash", str(validator), *(["--ci-ordinary-only"] if partial else [])], cwd=fixture, env=environment,
                capture_output=True, text=True, timeout=30, check=False,
            )
            observed = trace.read_text(encoding="utf-8").splitlines()
            if result.returncode != (73 if failure else 0) or observed != expected or result.stderr:
                raise RuntimeError(
                    f"validation ordering failed at {failure or 'success'}: "
                    f"exit={result.returncode}, observed={observed}, stderr={result.stderr!r}"
                )
            if not failure and ("PARTIAL ordinary CI" in result.stdout) != partial:
                raise RuntimeError("partial CI validation must not claim complete local acceptance")

        after_test = ["check-coverage.sh", "acceptance", "fx-unit-bindings", "fx-ui-host"]
        complete_sequence = [*before_boot, "boot-ready", "release-build", "test", *after_test]
        benchmark_sequence = [*before_boot, "boot-ready", "test", "release-build", "test", *after_test]
        named_sequence = [*before_boot, "release-build", "test", *after_test]
        partial_sequence = [*before_boot, "boot-ready", "release-build", "test", *after_test[:-1]]
        verify(complete_sequence)
        verify(benchmark_sequence, benchmark=True)
        # Named local destinations keep xcodebuild's existing boot behavior.
        verify(named_sequence, destination="platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5")
        verify(partial_sequence, partial=True)
        for bad_args in (("--ci-ordinary-only",), ("--skip-fx",), ("--ci-ordinary-only", "extra")):
            trace.write_text("", encoding="utf-8")
            result = subprocess.run(["/bin/bash", str(validator), *bad_args], cwd=fixture, env=base_env,
                                    capture_output=True, text=True, timeout=5)
            if result.returncode != 2 or trace.read_text():
                raise RuntimeError("unknown/local partial validation must fail before any command")
        for index, failure in enumerate(complete_sequence):
            verify(complete_sequence[:index + 1], failure=failure)
        for index, failure in enumerate(partial_sequence):
            verify(partial_sequence[:index + 1], failure=failure, partial=True)
    print("Validation ordering self-test passed: 4 success paths / 41 fail-closed command failures / 3 argument negatives")
    print("Hosted no-retry policy passed: actual validator arguments / 6 workflow negatives")
    print(f"Hosted split-job contract passed: {len(workflow_negatives)} workflow negatives / 36 executed join outcomes")
    run_ci_simulator_self_test(project_root)
