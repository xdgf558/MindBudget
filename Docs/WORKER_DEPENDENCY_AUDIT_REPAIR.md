# Worker dependency security repair for PR #121

Current FX-01D closeout: `Docs/FX_01D_CLOSEOUT.md` (implementation merged; D In Progress; E unentered).

Status: **REVIEWED_AND_MERGED_IN_PR121; NOT_D_CLOSEOUT_ACCEPTANCE.**

Exact `689b932` completed full local exit 0 (180.427333ms / unchanged 500ms) and hosted
`34302080136` ordinary/FX/join, including both Worker audit/check gates. Supplied independent
native/no-P1/P2 review accepted that head; owner authorized merge `039ecdf` with it as second
parent. See the canonical closeout above for exact device/method evidence. This supersedes
the pre-execution pending checkpoint below, not the retained 4086c59 failure or D obligations.
The sharp override remains required until its documented safe-removal conditions are met.

## Authorization and retained non-pass

Owner explicitly authorized repairing both Worker dependency audits and pushing a separate
commit to #121. No product/Swift/test-helper/workflow/runner/allowance change, remote deployment,
migration, credentials, #118 mutation, undraft/merge or D/E/share advance.

Hosted `34298810822` attempt 1 on `4086c59b7ab2a2554ccc1911ecee8e69482d35e3` failed:
ordinary `102301138897` stopped at `npm audit --audit-level=high` before Xcode, and join
`102304082720` failed. No ordinary xcresult exists; artifact upload failed and Telemetry's
audit step was skipped. PublicConfiguration reported 4 high / 2 moderate. Local reproduction
also found Telemetry 4 high, so repairing only the first project would leave the other blocker.
The lockfiles were unchanged by FX work. Do not call the advisory-triggered failure transient
or reuse #120's earlier green.

FX job `102301139000` / artifact `10084478044` passed on that OLD head. The user-supplied
independent audit reports fresh non-cloned `4460E94D-7A79-40F0-A0D4-06778C13061B`, hosted
Xcode 26.6 / iOS 26.5, three methods once, no Repetition: stewardship 121.980s, Chinese create
100.849s, English create 73.399s. This is not new-head FX acceptance or ordinary acceptance.
The old default complete local pass is retained in `FX_QUERY_SNAPSHOT_REPAIR.md` and SESSION_LOG.

## Minimal supported-package patch and override lifetime

Sources checked 2026-09-09:

- [sharp advisory GHSA-rgj7-g3m4-5g8c](https://github.com/advisories/GHSA-rgj7-g3m4-5g8c):
  affected `<0.35.4`; 0.35.4 supplies patched prebuilt libheif. GitHub Advisory Database
  publication on September 8 is distinct from the earlier upstream advisory publication.
- [Vitest advisory GHSA-82fw-gwwq-j7x9](https://github.com/advisories/GHSA-82fw-gwwq-j7x9):
  4.1.11 patches the moderate mocker path traversal; it alone did not trip the high threshold.
- [npm nested overrides](https://docs.npmjs.com/cli/v11/configuring-npm/package-json/#overrides).
  Registry `npm view` showed latest Wrangler 4.130.0 / plugin 1.1.6 using Miniflare
  5.20260908.0-alpha, which still depends on exact sharp 0.35.2. A latest-parent upgrade
  therefore does not remove this advisory. No forced downgrade or broad runtime migration.

Both root package manifests now restrict sharp **under Miniflare** to exact 0.35.4, with
its matching `@img/sharp-*` 0.35.4 and libvips 1.3.3 prebuilt packages in generated locks.
This intentionally overrides upstream's old exact pin; compatibility is tested, not assumed
from semver alone. Remove this temporary override only when an upstream compatible chain uses
patched sharp and clean-install audit plus all Worker checks succeed without it.

PublicConfiguration's minimum Vitest becomes ^4.1.11, locked to 4.1.11 with matching Vitest
siblings. npm regenerated that subtree with Vite 8.2.1 → 8.2.2, Rolldown 1.2.4 → 1.2.7,
@oxc-project/types 0.144.0 → 0.148.0, picomatch 4.0.5 → 4.0.7 and PostCSS 8.5.26 → 8.5.28.
These are disclosed transitive changes, not Worker runtime or TypeScript upgrades.
Telemetry Vitest remains 4.1.11. Wrangler stays 4.123.0 / 4.127.0, respectively;
Miniflare stays 5.20260811.1-alpha / 5.20260826.0-alpha and workerd stays unchanged.

## Historical local Worker evidence and then-pending acceptance

Node 24.15.0 / npm 11.12.1; clean `npm ci` then the same `npm audit --audit-level=high`
gate and `npm run check` pass in BOTH projects. Both audit JSON reports contain zero
vulnerabilities at every severity. PublicConfiguration: typecheck, 13 tests, deployment dry-run.
Telemetry: generated types/typecheck, 35 Worker tests, 8 evidence contract tests, all three
environment dry-runs and local startup checks pass. No live deployment/migration was run;
Wrangler metrics were disabled. Startup profiles are local CPU measurements, not edge evidence.

Local raw logs and before/after audit JSON: `/private/tmp/worker-audit-repair.ZIgNda`.
The initial unprivileged simulator inventory was sandbox-denied; no runtime test was launched
by that read-only query. Simulator/runtime validation uses the approved executable permissions.

Default `Scripts/validate.sh` does NOT replace the separate npm audit checks. Freeze the repair
commit first, then require that EXACT head's default complete local validation (500 ms benchmark,
zero retry, isolated FX host), hosted ordinary/FX/join green, native audit with 625/17 ordinary
methods and 49 FX unit bindings once, and all three FX methods once bound to its fresh UUID.
No old green or unchanged-head retry is a substitute. Independent review and explicit merge
authorization remain required; this candidate stays Draft.

#118's four failures `34097606992` / `34108994597` / `34218693463` / `34250759552` remain
non-pass. D's four boxes remain open; physical CloudKit, mixed-version and cross-calendar
coverage remain absent. No change to UNPROVEN historical causes or previously recorded debts.
