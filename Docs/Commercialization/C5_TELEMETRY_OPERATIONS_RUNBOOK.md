# C5 Telemetry Operations Runbook

Status: **C5-04 product capability merged from exact remediation head `2c1cebe` after its
deletion-order remediation passed scoped independent review and green GitHub Actions run
`33233846430`; PR #82 merged it as `28d9eae`. Only Development is eligible for the still-open
current-source deployment/probe; Staging and Production remain unauthorized.**

PR #82's independent review did not inspect this runbook, `PrivacyInfo.xcprivacy`, the receipt and
Pro capture sites, or `TelemetryService`. PR #83's closeout review is explicitly asked to inspect
those surfaces. `TelemetryService` is defined in `MindBudget/Services/TelemetryClient.swift`.

This runbook is for the fixed MindBudget first-party telemetry Worker. It never authorizes a remote
write by itself. The operator must name the exact environment and receive explicit approval before
running a migration, deploy, rollback, synthetic probe, or D1 cleanup.

## Environment authority

| Environment | Worker | D1 | Current authority |
| --- | --- | --- | --- |
| Development | `mindbudget-telemetry-dev` | `mindbudget-telemetry-development` | May be deployed/probed only after explicit session approval |
| Staging | `mindbudget-telemetry-staging` | isolated resource exists | No migration, deployment, probe, or customer traffic |
| Production | `mindbudget-telemetry` | checked-in UUID is an invalid placeholder | No resource, migration, deployment, probe, or release |

Stop if the Wrangler account, exact host, D1 ID, source commit, or requested environment differs
from the reviewed record. Never substitute the base configuration for Development. Never paste D1
rows, request bodies, deletion secrets, IP addresses, or customer identifiers into logs or PRs.

## Preflight

From `Services/TelemetryWorker`:

```bash
npm ci
npm run check
npx wrangler whoami
npx wrangler deployments list --env development --json
npx wrangler d1 migrations list TELEMETRY_DB --env development --remote
```

Record the git SHA, Wrangler version, account ID, prior Development version/deployment ID, migration
result, and the green local test counts. `npm run check` must pass generated bindings, TypeScript,
35 Worker tests, eight evidence-contract tests, all three dry-runs, and all three startup checks.
Do not continue when a migration is unexpected or a high-severity dependency issue is open.

## Development publish

After the owner explicitly approves this exact remote write:

```bash
npm run migrate:development
npm run deploy:development
npx wrangler deployments list --env development --json
```

Wrangler captures a D1 backup before applying migrations. A code rollback does not reverse D1;
therefore migrations must remain forward-compatible with both the previous and new Worker. There
are intentionally no Staging/Production migration or deployment scripts.

## Synthetic current-source probe

Use a reserved synthetic UUID pair and a disposable 32-byte secret. Send only the exact fixed
headers used by the native adapter. The probe must establish:

1. `/v1/events` accepts the closed Development envelope with 202 and an empty body.
2. D1 aggregate inspection finds exactly one matching identity/event and proves
   `expires_at_ms - accepted_at_ms = 7776000000` (90 x 24 hours).
3. An identical upload is idempotent; a changed fact under the same event UUID returns 409.
4. `/v1/delete` with the matching proof returns 204 and an empty body.
5. D1 aggregate inspection finds zero matching event/identity rows and one matching tombstone whose
   expiry is an earlier-or-equal UTC-day bucket, not a request timestamp.
6. A late identical upload returns 202 but creates no event/identity row.
7. A repeated delete remains 204. After recording aggregate evidence, remove only the reserved
   synthetic tombstone by exact UUID so the probe leaves no new retained row.

The command transcript must record only status codes, response byte counts, version/deployment ID,
and aggregate counts/deltas. It must not record the deletion secret or full request. A probe against
the prior Worker is historical evidence, not current-source proof.

## Monitoring and incident response

Worker logs are closed JSON records containing only component, environment, route, and reason.
Invocation logs and traces are disabled; Development samples closed logs at 100%, Staging 10%, and
Production 1%. Use a bounded tail only during an approved incident:

```bash
npx wrangler tail mindbudget-telemetry-dev --format json --sampling-rate 0.1
```

Never add request/response logging to investigate an incident. Use aggregate D1 counts and closed
reason codes. If cost, rate, or row growth is unexpected, stop Development capture by disabling the
client in the test build; do not delete customer rows without the authenticated product flow.

| Condition | Client behavior | Operator action |
| --- | --- | --- |
| 429/5xx/network | bounded persisted retry; product unaffected | inspect closed reasons and D1 availability; do not force-loop |
| 404 | sticky `endpointNotFound` | verify exact deployment/route; use Send Retry for an upload or repeat Delete for retained deletion proofs; failed deletion cannot re-enable |
| 405 | sticky `methodNotAllowed` | verify Worker version/method; use Send Retry for an upload or repeat Delete for retained deletion proofs; failed deletion cannot re-enable |
| 421 | sticky `misdirectedRequest` | verify environment/host isolation; never redirect or substitute host; retry only through the matching explicit Send/Delete action, and do not re-enable after failed deletion |
| corrupt local queue | capture stays unavailable; local file/key remains deletable | disclose that remote deletion cannot be proven without authenticated proofs |
| four retained generations | re-enable fails closed | customer deletes telemetry data or waits for an expired proof; never drop a proof silently |

## Local Delete All retry reachability

App-wide Delete All resets `firstLaunchCompleted` and returns the app to onboarding. A pending
remote telemetry deletion therefore is not immediately reachable from the post-delete navigation
state: the customer must complete setup again, then open Privacy & Security > Product Analytics
and choose Delete to retry the retained proof. Do not describe that retry as still visible on the
Delete All completion screen after the reset.

`TelemetryService.stop()` only cancels and clears its drain/retry task handles. It does not replace
the service, destroy the `TelemetryClient`, or erase retained proofs. The same service instance's
explicit `deleteAllTelemetry()` path remains callable after `stop()` and independently cancels any
tasks before delegating to the persisted client. The current UX has no automatic deep link from
onboarding to this pending retry; that is a known manual-reachability boundary, not evidence that
remote deletion completed.

## Rollback

List deployments and select the last known reviewed Development version:

```bash
npx wrangler deployments list --env development --json
npx wrangler rollback VERSION_ID --env development --message "C5 telemetry incident" --yes
```

After rollback, repeat the status/aggregate-only probe. If the older code cannot safely use the
current D1 schema, do not rollback; disable the Development client and prepare a forward fix.
Staging/Production rollback is forbidden until those environments are separately authorized.

## Keys and credentials

Telemetry has no server signing key and no shared customer credential. Each app installation
creates random deletion secrets locally; only SHA-256 deletion handles reach D1. The app rotates
upload pseudonyms every 30 user-calendar days and on reset/re-enable while retaining bounded delete
proofs for 90 user-calendar days. Never export or centrally rotate those client secrets.

Cloudflare OAuth/API credentials are operator credentials outside the repository. Refresh or revoke
them through Cloudflare account controls when staff/access changes, then rerun `wrangler whoami`;
never put a token in source, `.dev.vars`, evidence JSON, command transcripts, or CI output.

## Release handoff

Before any TestFlight/App Store build may ship this channel, COM-C6/C12 must independently verify
the final binary host inventory and captured traffic, App Store Connect privacy answers, bilingual
controls, opt-out/delete behavior, current Production resource/schema/deployment, TTL/cleanup,
budget alerts, and rollback. A green C5-04 source PR or Development probe is not distribution
authority and does not decide G1.
