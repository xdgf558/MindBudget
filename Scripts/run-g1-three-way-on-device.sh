#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/.." && pwd)"
EXPECTED_DEVICE_NAME="拉沙的iPhone"
EXCLUDED_DEVICE_NAME="Xiao li的 iPhone (2)"
SCHEME="MindBudget-G1-OnDevice-Eval"
TEST_FILTER="MindBudgetTests/G1ThreeWayOnDeviceEvalTests/emitsFrozenBilingualFoundationModelsTranscript()"
DEVELOPER_DIRECTORY="${MINDBUDGET_DEVELOPER_DIR:-/Applications/Xcode-27-beta-6.app/Contents/Developer}"
OUTPUT_DIRECTORY="${MINDBUDGET_G1_EVAL_OUTPUT_DIRECTORY:-/private/tmp/mindbudget-g1-three-way-eval}"
BUILD_LOG="${OUTPUT_DIRECTORY}/on-device-xcodebuild.log"
RESULT_BUNDLE="${OUTPUT_DIRECTORY}/on-device-eval.xcresult"
TRANSCRIPT="${OUTPUT_DIRECTORY}/on-device-transcript.jsonl"
REVIEW_PACKET="${OUTPUT_DIRECTORY}/three-way-blind-review.json"
REVIEW_SIDECAR="${OUTPUT_DIRECTORY}/three-way-review-sidecar.json"

if [[ "${MINDBUDGET_G1_DEVICE_NAME:-${EXPECTED_DEVICE_NAME}}" != "${EXPECTED_DEVICE_NAME}" ]]; then
  echo "G1 Eval is authorized only for ${EXPECTED_DEVICE_NAME}." >&2
  exit 1
fi
if [[ "${MINDBUDGET_G1_DEVICE_NAME:-}" == "${EXCLUDED_DEVICE_NAME}" ]]; then
  echo "The explicitly excluded device must never run this Eval." >&2
  exit 1
fi
for path in "${BUILD_LOG}" "${RESULT_BUNDLE}" "${TRANSCRIPT}" "${REVIEW_PACKET}" "${REVIEW_SIDECAR}"; do
  if [[ -e "${path}" ]]; then
    echo "Refusing to overwrite evidence path: ${path}" >&2
    exit 1
  fi
done
if [[ ! -x "${DEVELOPER_DIRECTORY}/usr/bin/xcodebuild" ]]; then
  echo "Xcode developer directory is unavailable: ${DEVELOPER_DIRECTORY}" >&2
  exit 1
fi

mkdir -p -- "${OUTPUT_DIRECTORY}"
cd "${PROJECT_ROOT}"
xcodebuild_command=(env "DEVELOPER_DIR=${DEVELOPER_DIRECTORY}" /usr/bin/xcodebuild)

available_destinations="$({
  "${xcodebuild_command[@]}" -project MindBudget.xcodeproj -scheme "${SCHEME}" -showdestinations
} 2>&1)"
if ! grep -F "name:${EXPECTED_DEVICE_NAME}" <<< "${available_destinations}" >/dev/null; then
  echo "${EXPECTED_DEVICE_NAME} is not an available Xcode destination. Connect and unlock it first." >&2
  exit 1
fi
if grep -F "name:${EXCLUDED_DEVICE_NAME}" <<< "${available_destinations}" >/dev/null; then
  echo "Notice: ${EXCLUDED_DEVICE_NAME} is visible but remains explicitly excluded." >&2
fi

set +e
"${xcodebuild_command[@]}" -project MindBudget.xcodeproj -scheme "${SCHEME}" \
  -destination "platform=iOS,name=${EXPECTED_DEVICE_NAME}" \
  -parallel-testing-enabled NO \
  -resultBundlePath "${RESULT_BUNDLE}" \
  "-only-testing:${TEST_FILTER}" test 2>&1 | tee "${BUILD_LOG}"
xcode_status="${PIPESTATUS[0]}"
set -e
if [[ "${xcode_status}" -ne 0 ]]; then
  echo "Physical G1 Eval failed; the log and result bundle are non-pass diagnostic evidence." >&2
  exit "${xcode_status}"
fi

python3 -B Scripts/g1_three_way_eval.py \
  --extract-on-device-log "${BUILD_LOG}" --output "${TRANSCRIPT}"
python3 -B Scripts/g1_three_way_eval.py \
  --build-review-packet "${TRANSCRIPT}" --output "${REVIEW_PACKET}" \
  --sidecar-output "${REVIEW_SIDECAR}"
python3 -B Scripts/g1_three_way_eval.py \
  --check-review-packet "${REVIEW_PACKET}" \
  --on-device-transcript "${TRANSCRIPT}" \
  --review-sidecar "${REVIEW_SIDECAR}"

echo "Physical G1 three-way outputs captured from ${EXPECTED_DEVICE_NAME}."
echo "Transcript: ${TRANSCRIPT}"
echo "Pending independent blind-review packet: ${REVIEW_PACKET}"
echo "Post-score-only mapping/diagnostic sidecar: ${REVIEW_SIDECAR}"
