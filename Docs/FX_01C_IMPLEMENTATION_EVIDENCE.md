# FX-01C manual-entry implementation evidence

Status: **FX-01C In Progress; candidate validation and independent review pending.**

This packet covers the manual entry, saved detail, edit, and existing Commerce access boundary
only. It does not close FX-01, enter FX-01D/E or FX-02, enable optional services, or authorize
COM-C12, physical runs, Archive, upload, distribution, or release. PR #113 closed B separately;
the C owner entry and its exact provenance remain in `FX_01_MANUAL_CURRENCY_PLAN.md`.

## Implementation boundary

- `ForeignCurrencyFormState` retains user inputs and resolves through the accepted B integer
  converter. A validation error produces no usable preview or write. An explicit accounting
  override retains its exact amount-derived fraction across reopening; its rounded display rate
  is not parsed back into authority. Editing uses the saved row's accounting currency and rate
  time zone, not changed settings or a changed device time zone.
- The single `PremiumFeature.manualForeignCurrency` consumes the existing Pro snapshot; C adds
  no trial clock or StoreKit product. DataActor checks the live authority immediately before a
  new FX write or ordinary-to-FX conversion. Existing persisted FX retains Free stewardship.
  Caller-supplied metadata is not proof of existing ownership. Recurring, receipt and wishlist
  creation are not expanded into FX. Ordinary expense entry remains Free.
- The form exposes original currency/amount, manual rate, rate date, locked accounting preview,
  and explicit accounting override. Saved detail shows original amount first, accounting
  approximation second, and rate direction/date/source. English and Simplified Chinese are
  localized. The source date formatting explicitly uses the saved rate time zone.
- C preserves B's frozen Expense envelope and pre-D FX/sync exclusion. Consumer/CSV work and the
  thirteenth encrypted iCloud companion envelope belong to D, not this packet.

## Test host and runtime acceptance

The normal `MindBudget` application and complete default suite remain mandatory. Additional UI
coverage uses a different executable entry compiled only with Debug, simulator, and the explicit
`MINDBUDGET_FX_UI_TEST_HOST` build flag. No normal configuration enables that flag. The dedicated
scheme has no Launch/Profile/Archive action. The alternate entry constructs only an in-memory
store, isolated preferences, a fixed Commerce test authority and the real form/detail views;
it does not construct AppBootstrap, StoreKit or network/system lifecycles. The notification
dependency is a fail-on-call stub. These UI results cannot prove a StoreKit purchase or physical
VoiceOver behavior, and their compile-time fixture cannot grant normal-app paid rights.

`Scripts/fx01_ui_contract.py` owns 32 exact FX unit bindings (17 B and 15 C) and two UI bindings.
It reads this run's native tree and each required test's native details, requires one Passed
device/configuration/execution, and rejects skipped, failed, duplicate, parameterized or unknown
attempt shapes. No schema-version override or C6 tree-reader dependency is used. The UI runner
requires fresh result and DerivedData paths, normal simulator signing and no test retries.
Hosted artifacts must retain both ordinary and dedicated UI bundles.

## Retained local development non-passes

All paths below are local `/private/tmp/mindbudget-fx01c-*` artifacts, not public hosted evidence.
They do not satisfy final-head acceptance.

| Run | Result and disposition |
| --- | --- |
| `focused-1` | Two new assertions expected `6.00` instead of the existing parser's `6`; corrected as assertion-format mistakes. Non-pass. |
| `focused-2` | 50 methods Passed, including all 32 FX bindings, with no retry. Retrospective strict native verification passed, but later Swift edits require fresh evidence. |
| `ui-1` through `ui-3` | SKTestSession configuration writes failed with SKInternalErrorDomain Code 3 / notEntitled before reaching the form. No purchase or form pass claimed. |
| `host-ui-1` through `host-ui-3` | Iterations exposed switch-label targeting, menu virtualization, obscured underlying host-strip geometry, then AX5 form width 457pt in a 402pt window. All whole runs non-pass. |
| `host-ui-4` | Reused unsigned artifacts executed removed assertion paths; not accepted as current-source proof. Permanent runner now requires fresh DerivedData and normal signing. |
| `host-ui-5` through `host-ui-8` | English passed, Chinese preview remained obscured by fixed Save. Outer-padding gestures did not scroll usefully. Whole runs non-pass; per-method 240s timeout added after run 5. |
| `host-ui-9` | Both cases failed. Per-pan coordinates exposed gestures consumed by the accounting TextField; slow release alone did not fix it. Non-pass. |
| `host-ui-10` | English passed after avoiding text-editor pan origins. Chinese hit a viewport filled by the embedded date wheel. Whole run non-pass. |
| `host-ui-11` | The separate AX5 date sheet allowed Chinese creation; an edit pan starting on its button reopened it. English passed, but the whole run remains non-pass. |
| `host-ui-12` | The new date mutation and accessibility values passed; Chinese editing still activated the date editor while panning with the keyboard present. English passed; whole run non-pass. |
| `host-ui-13` | Both tests executed once Passed (104.530s Chinese / 40.663s English); the initial wrapper rejected native Runtime Warning leaves as unknown attempts. The reviewed diagnostic-reader remediation revalidates the same bundle; it does not erase the original wrapper non-pass. |

The candidate replaces the AX5 embedded date wheel with a wrappable date button and independent
native date-editor sheet. Ordinary sizes retain compact date selection. Neither content text
nor the form environment is capped. The UI test keeps full target-frame visibility above Save
and below navigation; it does not treat `isHittable` alone as proof of readable content.
Pan origins exclude buttons as well as text editors and wheels. The candidate UI assertions
inspect localized input labels/values, original-before-accounting order in the combined
accessibility element, and the saved/reopened year after a real date-wheel change. They do not
claim a physical spoken VoiceOver session.
FX numeric fields also expose a localized keyboard Done action while focused; the candidate UI
must press it and observe keyboard dismissal before reading the preview. Ordinary-entry fields
do not acquire that toolbar. The hosted timeout is 60 minutes to accommodate the additional
fresh host build after the complete ordinary suite (B closeout already used 35m25s).

Run 13 contains two `Invalid frame dimension (negative or non-finite).` diagnostics, one per
test, represented in both the tree and native details. Native activity timing places them after
the first original-amount tap and before entering `3`; source URLs are empty. Both independent
and author inspection of the four retained screenshots found the amounts/preview readable, but
the emitting source has not been identified and the warnings are **not fixed or dismissed**.
The native reader separates only exact `{name, nodeType}` non-execution Runtime Warning leaves,
requires matching tree/detail warning multisets and reports each once. Extra keys, identities,
results or nested children cannot disguise an execution as a warning; retry acceptance is
unchanged. Self-tests add 612 disguised-execution negatives and 68 diagnostic-mismatch negatives,
with four real CLI positives / 16 negatives. The fresh complete validator must run this reader
against its own new bundle; retrospective run-13 verification is remediation evidence only.

## Review and remaining acceptance

The implementation author performed the development checks above. A separate read-only review
agent inspected the entry and implementation boundaries; intermediate review is not final-head
approval. Its two gate P2 findings and subsequent independent reproduction/closure are recorded
in `SESSION_LOG.md`, including the exact reviewed script SHA. No independent review is attributed
to work that only received author self-inspection.

The full candidate source review found no P1/P2/P3 at UI-test SHA-256
`66d7bdfb57560aa31460912534c4dde58c40463a8bf9d950875acae30c77b5d5` and sorted 36-file SHA-list
digest `7786d1da7d0164d197a29680740639c58dcecd8b4e057cd40cee7035c302788b` on base `ebd5785`.
The reviewer ran static checks only, did not modify source or start Xcode/devices, and explicitly
withheld a frozen-head/merge approval pending execution evidence. Later documentation additions
are not retrospectively included in that snapshot.

- [ ] Fresh final-candidate unit and dedicated UI execution, including localization/accessibility metadata.
- [ ] Complete ordinary application validation, Release build, coverage and strict local performance check.
- [ ] Final frozen-head independent review and exact-head hosted CI with native execution audit.
- [ ] Merge, then separate reviewed/green documentation closeout before D entry.
