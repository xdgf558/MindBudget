# MindBudget first-party telemetry Worker

This isolated Worker implements the C5 first-party ingestion and proof-deletion contract. It
accepts only MindBudget's closed event vocabulary, stores no request metadata or free text, and
keeps Development, Staging, and Production resources separate.

## Local verification

```bash
npm ci
npm run check
```

The test suite uses the Cloudflare Vitest integration with a real local D1 database. The check
also type-checks the Worker and performs dry-run/startup validation for all three configurations.

## Deployment boundary

Only Development deployment is eligible for C5-04 operational evidence, and every actual remote
write still requires explicit authorization in the execution session:

```bash
npm run migrate:development
npm run deploy:development
```

There are intentionally no Staging or Production deployment/migration scripts. Those environments
remain configuration-only until their later owner and release gates are accepted. C5-04 activates
the app-side fixed transport only behind a bilingual, default-off customer control. Its exact
capture inventory and operational procedures are documented in
`Docs/Commercialization/C5_TELEMETRY_CAPTURE_AUDIT.md` and
`Docs/Commercialization/C5_TELEMETRY_OPERATIONS_RUNBOOK.md`.

## C5-03 offline evidence

The `src/metrics.ts` receipt funnel is a read-only D1 aggregate with no HTTP route. The offline
evidence builder accepts only the closed aggregate schema documented in
`Docs/Commercialization/C5_METRICS_EVIDENCE_CONTRACT.md`; it does not query App Store Connect,
collect a survey, or contact the telemetry Worker.

Copy `evidence/c5-evidence-input.template.json` outside the repository, replace the explicit
`not_collected` rows with independently verified aggregate counts and matching source-file
SHA-256 digests, then create a new immutable output path:

```bash
npm run evidence:build -- --input INPUT.json --output OUTPUT.json
```

The template is demonstrative and is not observation evidence. C5-03 did not authorize a live
client or App Store credential. C5-04 does not authorize Staging/Production deployment or release.
