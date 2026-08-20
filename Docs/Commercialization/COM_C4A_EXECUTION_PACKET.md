# COM-C4A Execution Packet — Money Migration Delta

Source specification: `MindBudget 商业化与 Pro 云端 AI 开发方案 v1.4.md`

Source SHA-256:
`290bc07fe87fe644f201ef33cba342d3dce0368c64a5d020005873014dd342a0`

This packet is the review boundary for COM-C4A. Repository evidence is authoritative for the
current implementation; the owner-held specification remains frozen through the provenance above.

## C4A-01 — Delta and migration plan

Status: **Implementation complete pending independent review; C4A-02 and C4A-03 remain blocked.**

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

| Owner | Persisted amount fields | Currency ownership | Accepted persisted sign |
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

1. Add one pre-open migration coordinator for the local store and sidecars. Before a migration it
   creates a recoverable backup and a durable journal containing an explicit migration identifier,
   source/target schema, backup location/integrity metadata, and state.
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

### C4A-03 acceptance matrix

C4A-03 remains blocked until C4A-02 passes independent review. It must prove:

- clean and interrupted V1, V2, V3, and V4 upgrades, including repeated restart and restore;
- backup integrity, failure-before-open, failure-during-validation, failure-during-restore, and
  committed-journal idempotence;
- USD, JPY, and KWD exponent fixtures; zero/positive/invalid-negative persisted fields; derived
  negative deltas; `Int64` bounds and checked overflow;
- unsupported currency, cross-currency, duplicate-identity, broken-reference, inconsistent-
  allocation, unreadable-payload, and merchant-context anomalies remain nonzero/noninvented and
  leave the old store recoverable;
- the money floating-point gate, full existing migration regression, Release build, and repository
  validation remain green.

## Stop conditions

- C4A-01 is not Done until this packet passes independent review, green CI, and merge.
- C4A-02 and C4A-03 may not begin from this branch.
- No iCloud, telemetry, receipt, Watch, backend, cloud-AI, formal economics, Production deployment,
  tester assignment, Beta review, App Store submission, or public distribution is authorized.
- App Store Connect transport acceptance of 0.9.8 (9) is historical release evidence only and
  does not relax the COM-C4A or public-launch gates.
