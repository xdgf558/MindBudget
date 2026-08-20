# COM-C4A Execution Packet — Money Migration Delta

Source specification: `MindBudget 商业化与 Pro 云端 AI 开发方案 v1.4.md`

Source SHA-256:
`290bc07fe87fe644f201ef33cba342d3dce0368c64a5d020005873014dd342a0`

This packet is the review boundary for COM-C4A. Repository evidence is authoritative for the
current implementation; the owner-held specification remains frozen through the provenance above.

## C4A-01 — Delta and migration plan

Status: **Done after independent review, green CI, and PR #51 merge `bcd56a3`.**

C4A-02 is Done after independent review, GitHub Actions run `32375823770`, and PR #53 merge
`c905415`. C4A-03 remains blocked pending explicit owner instruction.

### Audit result

The V1–V4 store does not contain a floating-point money representation that needs conversion.
Every authoritative user-entered amount already uses `Int64` minor units, and every independently
owned amount carries an ISO currency code. `Money` supplies the accepted exponent table, exact
`Decimal` conversion, banker rounding, supported-currency validation, and range checks. The
repository money gate rejects `Double` and `Float` from app source except the documented isolated
App Intents transport adapter.

Consequently, COM-C4A must not invent a destructive amount rewrite. The missing delta is an
operational migration/recovery envelope plus one explicit currency-ownership cleanup for a
rebuildable derived cache.

### Persisted amount inventory and sign policy

| `ModelCounts` owner | Persisted amount fields | Currency ownership | Accepted persisted sign |
|---|---|---|---|
| `Expense` | `amountMinorUnits` | own `currencyCode` | strictly positive |
| `Income` | `amountMinorUnits` | own `currencyCode` | strictly positive |
| `IncomeAllocation` | budget and savings allocations | referenced `Income`; budget allocation also matches the owning plan | nonnegative; checked sum cannot exceed income |
| `SavingsGoal` | target and starting balance | own `currencyCode` | nonnegative |
| `RecurringFixedExpenseRule` | `amountMinorUnits` | own `currencyCode` | strictly positive |
| `BudgetPlan` | income, total budget, fixed expenses, savings goal | own `currencyCode` | nonnegative; deliberate overcommit remains representable |
| `CategoryBudget` | `limitMinorUnits` | owning `BudgetPlan` | nonnegative |
| `WishItem` | optional estimated price | own `currencyCode` | strictly positive when present |
| `Merchant` | all-time derived total | current accounting currency is only implicit today | nonnegative rebuildable cache; explicit currency ownership is a C4A-02 delta |
| `SpendingInsight` | typed money values inside `payloadJSON` | each encoded `Money` owns its ISO code | source fact determines sign; invalid payload fails closed |
| `BudgetPlanSemantics` | none | not applicable | not applicable; authority discriminator only |
| `CoolingOffPlan` | none | not applicable | not applicable; dates, duration, and state only |
| `ReminderEvent` | none | not applicable | not applicable; `categoryRiskBasisPoints` is a ratio, not money |
| `ReflectionLog` | none | not applicable | not applicable; reflection metadata and optional text/IDs only |
| `RecurringExpenseOccurrence` | none | not applicable | not applicable; amount and currency remain on its referenced rule/expense |

This is the complete 15-table `ModelCounts` inventory. The five explicit no-money rows make the
audit closed: they were reviewed and contain no persisted monetary amount rather than being
omitted from a list of monetary owners.

Negative values remain valid only for derived in-memory differences such as remaining budget,
variance, and deltas. They are never used to repair an invalid persisted amount. Cross-currency
operations, unsupported currencies, overflow, invalid signs, broken references, and inconsistent
allocation sums are anomalies: migration stops, preserves the old store, and reports the reason;
no anomaly becomes zero.

### Existing evidence accepted by C4A-01

- `Money.swift` uses `Int64` minor units, explicit ISO codes, 0/1/2/3 currency exponents, exact
  `Decimal` parsing/formatting, and bounded conversion.
- `BudgetEngine` and `DataActor` use checked integer arithmetic and typed currency validation for
  authoritative budget, income, expense, recurring, merchant, and allocation paths.
- `MindBudgetSchemaV1` through `MindBudgetSchemaV4` already preserve minor-unit fields and stable
  UUID identities through the lightweight V1 → V2 → V3 → V4 plan.
- Existing migration tests prove representative V1 expense, V2 income, V3 allocation, and V4
  budget-semantics preservation. Existing money tests cover USD-style two-decimal input, JPY,
  KWD, banker rounding, unsupported currency, and exact arithmetic.
- Apple's `SchemaMigrationPlan` and `MigrationStage` remain the schema-evolution mechanism; the
  app's recovery envelope must surround container opening rather than replace SwiftData's plan.

### Proven C4A-02 delta

C4A-02 may implement only these missing boundaries:

1. Add one pre-open migration coordinator for the local store and sidecars. It must not infer a
   SwiftData schema version from undocumented persistent-store metadata. With no store, it creates
   no backup. A trusted, committed sidecar marker naming the current target schema is the normal
   fast path. `Trusted` means the app-owned marker is parseable in a supported marker format, its
   state is committed, its target identifier exactly matches the current schema target, and no
   active/nonterminal recovery journal exists. A marker that fails any one of those checks, or a
   marker naming another target, is an
   unknown-or-different source: before that one attempted open, create a recoverable snapshot and
   durable journal containing an explicit migration identifier, source/target marker values,
   backup location/integrity metadata, and state. Opening and post-open validation may commit a
   trusted target marker only after success. Thus an old install may take one conservative backup,
   but a normal cold start never copies the store. This pre-open recovery path is excluded from the
   normal Dashboard first-screen performance budget and receives its own C4A-03 evidence.
2. Define idempotent journal transitions for prepared, migrating, validating, committed, and
   restoring outcomes. A restart resumes or restores from durable state; it never guesses that a
   partially opened store succeeded.
3. Open the existing SwiftData `SchemaMigrationPlan`, then run a post-open integrity inventory
   before committing. Any unsupported currency, sign/range violation, broken required reference,
   duplicate stable identity, inconsistent allocation, unreadable store, or interrupted operation
   restores the original store and retains a content-minimized anomaly report.
4. Make the rebuildable `Merchant.totalMinorUnitsAllTime` currency ownership explicit at its typed
   persistence/read boundary. Do not reinterpret historical totals in another currency; rebuild
   from validated expenses when the accounting-currency context cannot be proven.
5. Keep all existing V1–V4 amount values and stable identifiers byte-for-value equivalent. Do not
   add a floating-point intermediate, default an invalid value, or run a destructive rewrite only
   to satisfy the shape of a generic specification.

### C4A-02 — Implementation boundary

Status: **Done after independent review, GitHub Actions run `32375823770`, and PR #53 merge
`c905415`.**

C4A-02 adds Schema V5 only for the `MerchantAccountingContext` companion keyed by the existing
merchant UUID, preserving every V1–V4 model hash and source amount. Existing untrusted stores are
snapshotted with their SQLite sidecars and support directory before opening; only an app-owned
committed exact-target marker is copy-free. Post-open inventory may rebuild the merchant total and
its context only from verified same-currency expenses. It does not reinterpret a historic total or
modify the merchant's stable identity or presentation fields. A failed open or inventory restores
the checksum-verified snapshot and writes only a closed reason-code anomaly. After both the target
marker and journal durably reach committed, backup/journal cleanup is terminal best-effort work:
cleanup failure cannot roll back a store that already committed, and the next cold start or Delete
All retries removal. An earlier anomaly is retained for support diagnosis; Delete All removes every
recovery artifact that can contain local data, including that report.

### C4A-03 — Recovery and currency matrix

Status: **Blocked pending explicit owner instruction.**

C4A-03's C4A-02 prerequisite is satisfied, but the phase has not started. On explicit owner
instruction it must prove:

- clean and interrupted V1, V2, V3, and V4 upgrades, including repeated restart and restore;
- backup integrity, failure-before-open, failure-during-validation, failure-during-restore, and
  committed-journal idempotence;
- USD, JPY, and KWD exponent fixtures; zero/positive/invalid-negative persisted fields; derived
  negative deltas; `Int64` bounds and checked overflow;
- unsupported currency, cross-currency, duplicate-identity, broken-reference, inconsistent-
  allocation, unreadable-payload, and merchant-context anomalies remain nonzero/noninvented and
  leave the old store recoverable;
- preserve the owner-confirmed retry-only/reinstall recovery boundary, or obtain a separate
  Accepted decision and prove a deliberate destructive-reset flow before exposing one in-app;
- the money floating-point gate, full existing migration regression, Release build, and repository
  validation remain green.

## Stop conditions

- C4A-02 is Done through PR #53 (`c905415`) after independent review and green CI.
- C4A-03 remains blocked pending explicit owner instruction; this closeout branch must not
  implement it.
- No iCloud, telemetry, receipt, Watch, backend, cloud-AI, formal economics, Production deployment,
  tester assignment, Beta review, App Store submission, or public distribution is authorized.
- App Store Connect transport acceptance of 0.9.8 (9) is historical release evidence only and
  does not relax the COM-C4A or public-launch gates.
