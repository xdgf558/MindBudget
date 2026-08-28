# MindBudget first-party telemetry Worker

This isolated Worker implements the dormant C5-02 ingestion and proof-deletion contract. It
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

Only Development deployment is authorized in C5-02:

```bash
npm run migrate:development
npm run deploy:development
```

There are intentionally no Staging or Production deployment/migration scripts. Those environments
remain configuration-only until their later owner and release gates are accepted. The app-side
`FixedTelemetryTransport` is likewise compiled and tested but has no production construction or
capture call site.
