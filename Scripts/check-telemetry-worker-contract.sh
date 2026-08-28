#!/usr/bin/env bash
set -euo pipefail

# These anchors are the reviewed C5-02 receiver contract. Change the Worker, iOS adapter,
# execution packet, tests, and this gate together; never widen one surface in isolation.

SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/.." && pwd)"
cd "${PROJECT_ROOT}"

WORKER_ROOT="Services/TelemetryWorker"
WORKER_SOURCE="${WORKER_ROOT}/src/index.ts"
WORKER_TEST="${WORKER_ROOT}/test/index.spec.ts"
WORKER_MIGRATION="${WORKER_ROOT}/migrations/0001_initial.sql"
WORKER_CONFIG="${WORKER_ROOT}/wrangler.jsonc"
WORKER_PACKAGE="${WORKER_ROOT}/package.json"

for file in \
  "${WORKER_SOURCE}" \
  "${WORKER_TEST}" \
  "${WORKER_MIGRATION}" \
  "${WORKER_CONFIG}" \
  "${WORKER_PACKAGE}" \
  "${WORKER_ROOT}/package-lock.json" \
  "${WORKER_ROOT}/vitest.config.ts"; do
  if [[ ! -s "${file}" ]]; then
    echo "Missing C5-02 telemetry Worker artifact: ${file}" >&2
    exit 1
  fi
done

for source_contract in \
  'const EVENTS_PATH = "/v1/events"' \
  'const DELETE_PATH = "/v1/delete"' \
  'const MAXIMUM_UPLOAD_BYTES = 32 * 1024' \
  'const MAXIMUM_DELETE_BYTES = 2 * 1024' \
  'const MAXIMUM_BATCH_EVENTS = 20' \
  'const MAXIMUM_DELETE_PROOFS = 4' \
  'const RETENTION_MILLISECONDS = 90 * 24 * 60 * 60 * 1000' \
  'if (keys.has(key)) throw new StrictJSONError("duplicate_key")' \
  'request.headers.get("CF-Connecting-IP") ?? "local-development"' \
  'await env.TELEMETRY_DB.batch(statements)' \
  'INSERT INTO telemetry_deleted_identities' \
  'NOT EXISTS (' \
  'console.log(operationalLogRecord(env.DEPLOYMENT_ENVIRONMENT, route, reason))' \
  'return new Response(null, { status, headers })'; do
  grep -Fq "${source_contract}" "${WORKER_SOURCE}" || {
    echo "Telemetry Worker is missing contract: ${source_contract}" >&2
    exit 1
  }
done

for forbidden_source_shape in \
  'request.json()' \
  'request.text()' \
  'console.error(' \
  'console.warn(' \
  'await fetch(' \
  'globalThis.fetch(' \
  'Authorization: Bearer' \
  'telemetry_deletion_requests'; do
  if grep -Fq "${forbidden_source_shape}" "${WORKER_SOURCE}"; then
    echo "Telemetry Worker contains forbidden source shape: ${forbidden_source_shape}" >&2
    exit 1
  fi
done

for migration_contract in \
  'CREATE TABLE telemetry_identities' \
  'CREATE TABLE telemetry_events' \
  'CREATE TABLE telemetry_deleted_identities' \
  'reject_telemetry_identity_handle_conflict' \
  'reject_telemetry_event_id_conflict' \
  'idx_telemetry_events_expiration' \
  'idx_telemetry_deleted_expiration'; do
  grep -Fq "${migration_contract}" "${WORKER_MIGRATION}" || {
    echo "Telemetry migration is missing contract: ${migration_contract}" >&2
    exit 1
  }
done

if grep -Eq 'request|group|batch' "${WORKER_MIGRATION}"; then
  echo "Telemetry storage must not persist request or grouped-deletion association" >&2
  exit 1
fi

for config_contract in \
  '"name": "mindbudget-telemetry"' \
  '"name": "mindbudget-telemetry-dev"' \
  '"name": "mindbudget-telemetry-staging"' \
  '"EXPECTED_HOST": "mindbudget-telemetry.yehao1105.workers.dev"' \
  '"EXPECTED_HOST": "mindbudget-telemetry-dev.yehao1105.workers.dev"' \
  '"EXPECTED_HOST": "mindbudget-telemetry-staging.yehao1105.workers.dev"' \
  '"database_id": "2faff8ac-de17-4fd0-aaa7-546bd1902e74"' \
  '"database_id": "776d171d-ec10-4a90-9235-b537e063e04b"' \
  '"database_id": "00000000-0000-4000-8000-000000000003"' \
  '"invocation_logs": false' \
  '"crons": ["17 * * * *"]'; do
  grep -Fq "${config_contract}" "${WORKER_CONFIG}" || {
    echo "Telemetry Worker configuration is missing contract: ${config_contract}" >&2
    exit 1
  }
done

for forbidden_package_contract in \
  'deploy:staging' \
  'deploy:production' \
  'migrate:staging' \
  'migrate:production'; do
  if grep -Fq "${forbidden_package_contract}" "${WORKER_PACKAGE}"; then
    echo "C5-02 must not expose a live Staging/Production command: ${forbidden_package_contract}" >&2
    exit 1
  fi
done

for test_contract in \
  'accepts exact closed events and keeps identical retries idempotent' \
  'rolls back a whole batch when one accepted event ID changes facts' \
  'treats an app-version change as conflicting facts for the same event ID' \
  'rejects duplicate JSON keys before parser semantics can collapse them' \
  'deletes every valid proof atomically, keeps no group, and accepts an identical retry' \
  'rejects one invalid proof without partially deleting the other identity' \
  'accepts but discards a late matching upload after deletion' \
  'removes expired events, independent identities, and tombstones in bounded cleanup' \
  'persists only the closed operational log object'; do
  grep -Fq "${test_contract}" "${WORKER_TEST}" || {
    echo "Telemetry Worker tests are missing contract: ${test_contract}" >&2
    exit 1
  }
done

echo "C5-02 telemetry Worker contract passed"
