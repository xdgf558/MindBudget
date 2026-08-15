# MindBudget Public Configuration Worker

This independent Worker serves exactly one anonymous, read-only endpoint. It stores no user data,
has no database or analytics binding, and contains no signing private key. Each environment deploys
only a pre-signed Ed25519 payload through non-secret Wrangler variables.

The signing key lives outside the repository. To rotate a seven-day response locally:

```bash
xcrun swift scripts/sign-envelope.swift \
  "/absolute/path/to/mb-config-2026-01-private.raw" \
  2 2026-08-22T02:00:00Z 2026-08-29T02:00:00Z false
```

Copy only the resulting public payload and signature Base64 strings into the appropriate Wrangler
environment. Never copy, encode, upload, or log the private key. Run `npm run check` before any
deployment. Development and staging deploy separately; production deployment requires its own
release approval and does not follow automatically from a successful dry run.
