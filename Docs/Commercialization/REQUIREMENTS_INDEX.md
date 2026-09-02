# Commercialization Requirements Index

## Contract

This index maps the stable v1.4 Requirement IDs to implementation ownership and objective
acceptance evidence. `Active` means the owner-approved v1.4 requirement is part of the target
product; it does not mean implementation is complete. `BLOCKED_BY_SPEC` means no affected code may
be implemented until the cited conflict is closed. `Baseline satisfied / delta pending` records a
current implementation that already meets the core invariant but still needs its later commercial
phase audit.

Source specification: `MindBudget 商业化与 Pro 云端 AI 开发方案 v1.4.md`, SHA-256
`290bc07fe87fe644f201ef33cba342d3dce0368c64a5d020005873014dd342a0`.
This is the external input's frozen audit fingerprint; `SOURCE_PROVENANCE.md` records why CI
checks repository-snapshot consistency rather than claiming automatic external-source monitoring.

No commercial Requirement grants permission to work ahead of the active COM phase.

## Core requirements

| ID | Status | Source | Implementation phase | Required acceptance evidence | Related decision/conflict | Release blocker |
|---|---|---|---|---|---|---|
| REQ-R1-NET-001 | Active; C3-03 complete and merged through PR #38 (`db7926d`) | v1.4 §1 rules 21–23, §4.7, §15.1 | COM-C0B policy; COM-C3 config; COM-C5 telemetry; COM-C6 verification | DEC-COM-021/022 accept only the exact dev/staging/prod hosts, anonymous `GET /v1/config`, bounded app/config-version headers, Ed25519 exact-byte verification, seven-day maximum validity, response-completion expiry validation, automatic signed-expiry invalidation, structured startup cancellation, retained scene-refresh lifecycle cancellation, a final pre-atomic-write persistence commit point, serialized rollback/equivocation protection, bounded signed cache, sticky corrupt-state failure, ephemeral no-cookie/no-cache transport, redirect/status/MIME/size/time failure, and closed non-content reason codes. The optional consumer additionally requires an actionable exact-Free StoreKit whole snapshot; unavailable/unverified authority cannot impersonate Free. C3-03A merged through PR #36 as `1ebb36c`; C3-03B head `09c382e` passed GitHub Actions run `31873664396` and merged through PR #38 as `db7926d`. C3-03B deploys only Development version `bf6c5049-a389-4ea7-af0a-e8425b8957e2`; its live app path passed 8/8 and Worker tests passed 13/13 plus typecheck/audit/dry-run. Staging/Production, final Release binary/traffic, privacy/review approval, and distribution remain blocked. No ledger/content request in R1 | SPEC-001/012 accepted; DEC-COM-021/022 | P0 / COM-C3, COM-C6 and 1.0 |
| REQ-R1-TELEMETRY-001 | Active; COM-C5 implementation Done after independent review of exact PR #84 head `84a96bc`, green run `33247176815`, and merge `4194b73`; verify again in COM-C6/C12 | v1.4 §§15.3, 16.5.3, 17 | COM-C5; verified again COM-C6/C12 | C5-01 supplies the dormant closed-schema encrypted client; exact head `d937dc8` passed GitHub Actions run `33085630481` before PR #76 merged it as `68304ad`. C5-02 adds the strict first-party Worker/D1 receiver, exact environment-specific hosts, bounded anonymous upload and proof-authenticated deletion, event UUID idempotency/conflict rejection, independent tombstones that prevent late-upload resurrection, maximum 90 x 24-hour UTC retention, repeated bounded Cron cleanup, fixed non-identifying User-Agent/language metadata, rate/cost ceilings, closed non-content monitoring, and best-effort in-flight upload cancellation. Delete tombstones retain a coarse UTC-day expiry bucket shared across requests, not a request-unique timestamp/group. Earlier Development Worker version `1c162a57-8789-4f7f-9fec-f2c484e9f4f2` ended at 0 events, 0 identities, and 2 historical tombstones. C5-03 defines nine closed aggregate metrics, exact counts/source hashes, explicit missing/suppressed/zero states, outward-rounded 95% Wilson intervals, fixed voluntary survey aggregates, exact-segment coverage with widest-interval visibility, and a read-only D1 receipt funnel without adding a route or customer data. PR #81's post-merge closeout review confirmed remediation head `0c61427`; DEC-COM-065 closes C5-03 without claiming a real evidence bundle or G1 decision. C5-04 adds the sole fixed factory behind bilingual default-off confirmation, the exhaustive three-source content-free capture audit, sticky non-retrying 404/405/421 states, bounded lifecycle/explicit Retry, conservative unlinked/non-tracking App Privacy source declarations, local-first deletion ordering, and a Development-only operations runbook. Independent review approved the deletion-order remediation on exact head `2c1cebe`; run `33233846430` passed and PR #82 merged it as `28d9eae`. Independent review of PR #83 head `daea2d2` raised two P2 findings and one P3 while excluding the manifest/capture/service/runbook surfaces. Remediation head `e6bbd3f` applied them and recorded the implementation author's supplemental inspection; run `33242024609` passed and PR #83 merged it as `becb020` without a pre-merge rereview. DEC-COM-069 records Development version `003c66fa-a57c-4b6a-a8d7-3f75b14cc716`: 202/202/409/204/202/204, exact `7776000000`-millisecond event TTL, UTC-day tombstone, non-resurrection, and exact synthetic cleanup passed. DEC-COM-070 adds actual iOS Simulator `FixedTelemetryTransport`/`URLSession` evidence: upload 202 and delete 204 passed the strict header contract, the post-`stop()` deletion retry has a deterministic regression, and final D1 aggregates were 0 events/0 identities/3 tombstones (2 historical plus the expected live-probe tombstone). Independent review approved exact PR #84 head `84a96bc`, GitHub Actions run `33247176815` passed, and PR #84 merged as `4194b73`; DEC-COM-071 closes C5-04/COM-C5 without deciding G1 or release. Staging has an unmigrated, undeployed isolated D1 resource; Production has no provisioned D1 and is not deployed. App Store Connect privacy answers, final-binary traffic, G1, Staging/Production, distribution, and release remain open | SPEC-009/012 accepted; SPEC-018 resolved; DEC-COM-056/057/058/059/060/061/062/063/064/065/066/067/068/069/070/071; `COM_C5_EXECUTION_PACKET.md`; `C5_METRICS_EVIDENCE_CONTRACT.md`; `C5_TELEMETRY_CAPTURE_AUDIT.md`; `C5_TELEMETRY_OPERATIONS_RUNBOOK.md` | P0 / COM-C6/C12, G1, 1.0 |
| REQ-ENTITLEMENT-001 | Active; COM-C1 complete and merged | v1.4 §§6.1–6.5 | COM-C1; reused by C2–C12 and Watch | Parameterized union and full feature-access matrices; concurrent immutable reads; Free fallback exact; removal returns exact Free; accepted existing entries consume one Commerce snapshot; Free record/export/delete/app-lock/template/24-hour/basic-Siri paths remain available; deferred bits and raw-bit consumers unreachable; Debug provider absent Release; no Product-ID/manual unlock/duplicate decision | SPEC-008/017 accepted; DEC-COM-012/013/014 | P0 / COM-C1 onward |
| REQ-STOREKIT-STATE-001 | Active; COM-C2 complete and merged | v1.4 §7.5 | COM-C2 | Table tests prove subscribed/verified grace on; retry/expired/revoked/unknown/unverified/pending off; expiration alone never invents grace; incomplete Free authority fails closed; cached state never permanently grants rights. PR #30 merged lifecycle authority as `3fc72b4`; PR #31 bound the mapper to a separately verified app environment and merged as `a293762` after green CI | SPEC-004 resolved; DEC-COM-016/017/018 | P0 / paid TestFlight and 1.0 |
| REQ-STOREKIT-LIFECYCLE-001 | Active; COM-C2 and C3-01 through C3-04 complete and merged through PR #40 (`9448ca9`) | v1.4 §§7.1–7.8, 8.3 | COM-C2/C3; server verification C7/C10 | One `EntitlementStore` authority/lifecycle task; typed purchase/restore; verified status/renewal facts; publish before required `finish`; failed finish retry; pending/cancel/error grant nothing. C2-04 completed verified `AppTransaction` bundle/environment agreement and exact environment isolation. PR #33 merged voluntary StoreKit-backed presentation as `747b628`; PR #34 merged verified trial projection/reminders as `12d9217`. Promotion shape remains outside entitlement authority. C3-03 configuration is structurally incapable of changing StoreKit facts, price/trial, entitlement, permanent Settings/Restore/Manage, or subscription status; its only consumer is an optional Pro value trigger and it is suppressed for an already-Pro user. C3-04 adds one non-blocking Dashboard navigation card, matching bilingual Pro guidance for verified grace/retry/expired/revoked states, AX5/VoiceOver presentation across all three appearances, and truthful review disclosure without changing that authority. PR #40 passed independent review and GitHub Actions run `31918968478`, then merged C3-04 as `9448ca9`. Formal economics, Production deployment, tester assignment, and public distribution remain later gates; the owner separately authorized only 0.9.7 (8) Archive and transport upload | SPEC-005/006/014/017 accepted; DEC-COM-015/016/017/018/019/020/021/022/023/024 | P0 / paid TestFlight and 1.0 |
| REQ-MONEY-001 | Active; COM-C4A Done through PR #55 `77292c6` | v1.4 §1 rule 25, §9.2, §9.6.4 | Existing product; COM-C4A delta; shared with Watch | Every stored/calculated amount is `Int64` minor units plus ISO code; currency exponent matrix; overflow/cross-currency failure; money-path float gate. C4A-01 inventories all 15 `ModelCounts` tables, including explicit no-persisted-money rows, and proves that V1–V4 authoritative amounts already satisfy the minor-unit representation. C4A-02 adds only the V5 companion currency record for the rebuildable merchant total. C4A-03 completes the currency/boundary matrix, and reviewed head `138c240` passed hosted run `32406654986` before PR #55 merged it as `77292c6` | SPEC-015 accepted tooling boundary; DEC-COM-025/026/027; `COM_C4A_EXECUTION_PACKET.md` | P0 / all financial phases |
| REQ-MONEY-MIGRATION-001 | Active; COM-C4A Done through PR #55 `77292c6` | v1.4 §9.6.4, COM-C4A | COM-C4A | Inventory every amount; old-store backup/restore; idempotent restart; no `Double`; anomalies stop and never become zero; USD/JPY/KWD/bounds/negative fixtures. C4A-02 surrounds non-fast-path opening with a checksum manifest and closed journal; no-store means no backup; only a supported committed current-target marker with no active journal is trusted. Post-open integrity validation commits only after success, while a failure restores a verified snapshot. C4A-03 supplies deterministic V1–V4 clean/interrupted/restart, retryable mid-restore, malformed-store, exponent, sign, and maximum-bound evidence; independent review, hosted run `32406654986`, and PR #55 merge `77292c6` satisfy the COM-C4A exit gate | Current V1–V4 are already minor-unit; no destructive rewrite justified; DEC-COM-026/027; `COM_C4A_EXECUTION_PACKET.md` | P0 / COM-C4 and 1.0 |
| REQ-RECEIPT-PIPELINE-001 | Active; local COM-C4C implementation Done through PR #74 `d751ff4`; release verification remains | v1.4 §9.6.1–9.6.9 | COM-C4C; verify C6/C12 | PR #74 merged the verified-Pro receipt entry, local off-main image/OCR/extraction path, edit-preserving form prefill, and existing explicit-Save persistence boundary. DEC-COM-053 keeps bounded DataScanner and honestly omits live alignment/automatic-crop claims; DEC-COM-054 makes explicit per-generation edit ownership, typed failures, inactive masking/background discard, and artifact-scoped cleanup authoritative. The checked-in matrix contains 60 exact USD/JPY/KWD receipts, 10 nonreceipts, offline tiers, privacy regressions, and 20 sequential real-image bounded cleanup iterations. Physical iOS 26.6.1 DataScanner/PHPicker/OCR passed; cancel wrote nothing and explicit Save produced exactly one expense, while the uncertain paper-invoice total remained manual-review-only. Independent review approved remediation head `8607356` and raised three nonblocking P3 observations. Final maintenance head `81cd107` applied them, Actions run `33035427257` passed, and PR #74 merged it as `d751ff4` without pre-merge rereview; PR #75's post-merge closeout review accepted that exact delta. The local C4C implementation is complete; COM-C5 still requires explicit owner entry and Production/distribution verification remains later | SPEC-010 resolved; SPEC-015 accepted; DEC-COM-044/045/046/047/048/049/050/051/052/053/054/055; `COM_C4C_EXECUTION_PACKET.md` | P0 / local Pro and 1.0 |
| REQ-RECEIPT-PRIVACY-001 | Active; local COM-C4C privacy boundary Done through PR #74 `d751ff4`; verify C6/C8/C12 | v1.4 §1 rules 26–27, §9.6.6 | COM-C4C; verify C6/C8/C12 | The verified-Pro entry keeps source/prepared images, raw or filtered OCR, model evidence, and duplicate evidence ephemeral and excludes them from SwiftData, iCloud, logs, HTTP(S), telemetry, and remote models. The optional model receives only privacy-filtered text and cannot override deterministic accepted/rejected authority. DEC-COM-053 adds no frame processing or broad Photos permission; DEC-COM-054 preserves in-progress work behind an inactive privacy shield and scopes deletion to background/cancel/owned cleanup with artifact identity. The zero-leak suite covers separated/full-width cards, labelled and continuous/spaced mask last-four forms, and authorization codes; physical cancel wrote nothing and explicit Save persisted only an ordinary expense plus non-content provenance. Review approved `8607356`; maintenance head `81cd107` then passed run `33035427257` and PR #74 merged as `d751ff4` without pre-merge rereview. PR #75's closeout review subsequently accepted that exact maintenance delta. C5's closed event type still cannot represent receipt image/OCR/model-safe text, amount, merchant, or receipt evidence; C5-04 records only closed non-content receipt-flow actions after explicit telemetry opt-in. Remote-provider and final-binary privacy verification remain C8/C6/C12 gates | SPEC-010/012 accepted; DEC-COM-044/045/046/047/048/049/050/051/052/053/054/055/056/066; `COM_C4C_EXECUTION_PACKET.md`; `COM_C5_EXECUTION_PACKET.md`; `C5_TELEMETRY_CAPTURE_AUDIT.md` | P0 / local Pro, cloud AI, 1.0 |
| REQ-ICLOUD-001 | Active; COM-C4B Done after reviewed PR #64 merge `4f6d7fe` and DEC-COM-043 | v1.4 §9.7, §16.5.2, COM-C4B | C4B-01 design; C4B-02P prerequisites; C4B-02/03; release verification remains in C6/C12 | `ICLOUD_SYNC_CONTRACT.md` defines default-off Free custom records in one private custom zone through `CKSyncEngine`, stable identities, typed/versioned envelopes, logical tombstones, replay detection, durable no-winner quarantine, separate engine-state/outbox persistence, account pause/re-consent, and local-first offline/quota failure. PR #58 merged repository-wide `cloudKitDatabase: .none`; PR #59 merged Schema V6 runtime as `211dff2`; PR #61 merged conflict/deletion/reimport/recovery and exact environment capabilities as `0f749ce`. DEC-COM-040 keeps automatic scheduling enabled, and DEC-COM-041 protects delegate cancellation and genesis-only zone creation. Reviewed final head `f1f37db` passed Actions run `32726507493`; PR #64 merged it as `4f6d7fe`. Deterministic tests, full local validation, signed Development configuration, one real Development zone lifecycle, and read-only Dashboard shape/environment evidence satisfy the product boundary. DEC-COM-039/042/043 permanently waive physical same-account, background-push, account-switch, offline, and quota observations as explicit non-passes without weakening deterministic behavior. Distribution signing and Production schema/deployment/release proof are not waived; COM-C6/COM-C12 own them before distribution/formal release | SPEC-003/012 accepted; SPEC-018 resolved; DEC-COM-006/028/029/031/032/033/034/035/038/039/040/041/042/043 accepted | P0 / COM-C4B and 1.0 |
| REQ-CLOUD-AUTH-001 | Active, G1-gated | v1.4 §§15.4–15.6, COM-C7/C10 | COM-C7 and COM-C10 | App Attest/DeviceCheck decision; verify JWS and app/bundle/environment/product; current non-consumable Pro authority plus consumable purchase/refund facts; short cache; notification invalidation; replay/environment tests | SPEC-007/013/014 accepted; DEC-COM-095/096 | P0 / any cloud request and 1.0 |
| REQ-CLOUD-CONSENT-001 | Active, G1-gated; production not admitted | v1.4 §0.3, §12, §16 | COM-C8; verify C12 | Explicit first-send consent naming sole OpenAI `gpt-5.6-luna`, exact data/purpose, Global processing, no voluntary training, and the configured standard up-to-30-day abuse-monitoring boundary; decline/revoke/delete; material policy change requires renewal; no request while missing or stale; no provider failover. DEC-COM-097 allows only synthetic Eval admission and keeps `productionAdmitted: false`; ZDR is optional and cannot be promised unless actually enabled | SPEC-012 accepted; DEC-COM-095/096/097 | P0 / any third-party model and 1.0 |
| REQ-CLOUD-USAGE-001 | Active, G1-gated and economics-gated | v1.4 §0.2–0.3, §14 | COM-C9; cost/config C11; verify C12 | DEC-COM-095/096 accept a server-authoritative ledger keyed from verified non-consumable Pro authority, 10 starter credits, 10/25/65-use cards at US$0.99/US$1.99/US$4.99, idempotent lots, and reserve/commit/release accounting: only a user-initiated valid structured Luna result ultimately displayed commits one credit; cancellation, invalid output, policy/network failure, or local fallback releases it. The trial grants zero Luna credits; lots expire one user-calendar year. Refund never deletes local data. The server must block new sales/grants below 1,000 trailing-30-day successes or 50% recomputed peak margin while honoring existing credits. Ordinary test users are denied Luna; Apple App Review may use only an isolated capped review environment. Product IDs and implementation remain gated | SPEC-012/014 accepted; DEC-COM-092/093/094/095/096 | P0 / cloud AI and 1.0 |
| REQ-G1-001 | Active; exact offer and independently reviewed synthetic Eval accepted, final decision pending | v1.4 §19.2–19.5 plus DEC-COM-092/093/094/095/096/097/098/099 | After COM-C6; Watch remains separately gated | DEC-COM-094 preserves reviewed PR #98 (`9226985`, run `33570570896`, merge `6e2d242`) and historical `INSUFFICIENT_QUOTE_EVIDENCE`. DEC-COM-095 selects Luna and the US$4.99/local-trial/accounting policy. DEC-COM-096 accepts 10 starter credits plus 10/25/65-use cards at US$0.99/US$1.99/US$4.99; planning remains US$0.011330 typical/P50 and US$0.018986 peak/P95 at 1,000 successes. DEC-COM-097 accepts standard up-to-30-day retention for synthetic Eval only, pins Global/Luna-only/Tier 1/bounded-billing evidence, and keeps production false. DEC-COM-098 records confirmed disabled sharing/logging, Keychain credential isolation, two explicit non-pass attempts, and attempt 3's 24/24 first-pass automated result under prompt/schema hash `c1d9f76e6a87ce116cac009eafe56f1bd57b6118e04d9c5a421ba6fb78734018`. Independent review found no P1/P2 on PR #100 head `323d8d7`; hosted run `33593253561` passed and merge `7a473d2` delivered it. DEC-COM-099 closes only that account/Eval evidence delivery and preserves four nonblocking follow-ups. The fixed bilingual three-way comparative Eval across deterministic template, supported on-device output, and Luna, StoreKit Product-ID/price-point evidence, and owner `PROCEED_TO_R2` remain open. Current result: `EVAL_REVIEWED_PENDING_STOREFRONT_EVIDENCE` | SPEC-013/014 accepted; DEC-COM-092/093/094/095/096/097/098/099; `G1_UNIT_ECONOMICS_PACKET.md`; `G1_LUNA_EVAL.md`; `G1_OPENAI_ACCOUNT_EVIDENCE.md`; `G1_LUNA_EVAL_RESULT_2026-09-02.json`; `Scripts/g1_unit_economics.py`; `Scripts/g1_luna_eval.py` | P0 / COM-C7 entry |
| REQ-WATCH-SCOPE-001 | Active; blocked pending 14-day no-P0/P1 gate plus owner entry | v1.4 §1 rules 31–39, §9.8.1–9.8.3, COM-C6.5 | Earliest eligible 2026-09-15; separate post-1.0 release | Companion-only scope; iPhone remains authoritative; no CloudKit/cloud AI/OCR/free note/account; iPhone works when unavailable; minimum/current device matrix | SPEC-011/013 accepted | P0 / Watch release only |
| REQ-WATCH-SYNC-001 | Active, not implemented | v1.4 §9.8.4–9.8.5, COM-C6.5 | COM-C6.5 | Versioned snapshot/outbox; stable command ID; persisted dedupe; canonical ID acknowledgement; retry/reorder/duplicate/offline/reinstall/delete-tombstone tests; 100 rapid records | SPEC-011/013 accepted | P0 / Watch release only |
| REQ-WATCH-ENTITLEMENT-001 | Active, not implemented | v1.4 §9.8.6, COM-C6.5 | COM-C6.5 reusing C1/C2 | Same Product ID allow-list/status mapper/set union; current verified StoreKit state; bounded offline cache; no Watch purchase/restore/manage UI; expiry tests | SPEC-011/017 accepted | P0 / Watch Pro release |
| REQ-WATCH-PRIVACY-001 | Active, not implemented | v1.4 §9.8.9, §20.7, COM-C6.5 | COM-C6.5; separate Watch release verification | Only latest snapshot/outbox/minimum metadata; no full ledger/note/receipt; Watch never contacts telemetry; amount complication opt-in; logs content-free; Delete All and offline replay proof | SPEC-011/012/013 accepted | P0 / Watch release only |

C5 provenance retained for auditability: C5-02 exact remediation head `72abf4b` passed hosted run
`33176551566` before PR #78 merged as `4715054`. C5-03 independent review covered `4ea7cd9`;
remediation head `0c61427` passed hosted run `33211270363` and PR #80 merged as `a587f42` without a
pre-merge rereview, then PR #81's closeout review confirmed that exact delta.

C5-04 review-scope qualification: PR #82's independent review approved the deletion-order
remediation on exact head `2c1cebe` within its declared scope. It did not inspect
`PrivacyInfo.xcprivacy`, the AddExpense/Pro capture sites, `TelemetryService` (defined in
`TelemetryClient.swift`), or the operations runbook. Independent review of PR #83 head `daea2d2`
retained that exclusion; remediation head `e6bbd3f` recorded the implementation author's
supplemental inspection and merged as `becb020` without a pre-merge rereview. PR #84's independent
review then covered its exact `84a96bc` evidence/remediation delta; green run `33247176815` and
merge `4194b73` close C5-04/COM-C5 without retroactively expanding the earlier review scopes.
COM-C6 must independently inspect `MindBudget/Resources/PrivacyInfo.xcprivacy`, the telemetry
capture calls in `MindBudget/Features/AddExpense/AddExpenseView.swift` and
`MindBudget/Features/Commerce/ProSubscriptionView.swift`, the `TelemetryService` wiring in
`MindBudget/Services/TelemetryClient.swift`, and
`Docs/Commercialization/C5_TELEMETRY_OPERATIONS_RUNBOOK.md` before any App Store Connect privacy
answer is copied or accepted. The implementation-author supplemental inspection does not satisfy
this release gate.

C6-01 reviewed state: the owner explicitly entered COM-C6 on 2026-08-29 after PR #85 merged as
`008b674`. The strict `C6_RELEASE_MATRIX.json` inventory binds seven automated rows to every
reviewed static gate, both first-party Worker local `check` scripts, a Release simulator build,
and 16 named Swift test containers. Its new cross-domain regression proves optional public-
configuration and telemetry failures cannot revoke an injected verified local-Pro snapshot. PR
#86 remediation requires each of the 33 declared type/method bindings to occur once as Passed in
the exact xcresult and requires every repository check script to be explicitly classified. This
automation performs no archive, upload, deployment, App Store Connect write, G1 decision, or
Requirement completion. Independent rereview approved exact remediation head `f77d2a6`, hosted run
`33255898196` passed, and PR #86 merged as `015d00e`; C6-01 is Done. The owner explicitly entered
C6-02 and its five-surface independent privacy review on 2026-08-30.
The first C6-02 implementation pass corrected the missing Purchase History declaration for the
closed subscription outcome and added exact source/embedded-manifest plus signed-app inspection.
A development-signed Release app passed that inspection and launched on an iPhone Air running iOS
26.6.1; this is not distribution/IPA/final-traffic evidence. `C6_02_PREFLIGHT.md` retains the
independent-review and manual signed-device work, and no App Store Connect answer was written.
Independent review accepted exact PR #88 head `0ac0500`, hosted run `33283398690` passed, and PR
#88 merged as `6c2a051`. Its non-blocking required-reason source-inventory finding is implemented
by `Scripts/check_required_reason_apis.py`; the gate requires the exact production-source category
set to equal the manifest. PR #89 review found missing Swift overlay
aliases; the remediation covers them and leaves literal raw-value keys plus distribution privacy-
report proof to C6-03/C12. Independent rereview accepted exact remediation head `6ffc6fa`, hosted
run `33287620965` passed, and PR #89 merged it as `72f016e`.
The continuing signed-device pass records bilingual live StoreKit/renewal/legal presentation,
offline verified-local-Pro retention, truthful privacy/receipt/iCloud/export copy, and receipt
cancellation without persistence. DEC-COM-078/079 remediate the physical AX5 tab-bar obstruction
without capping page content; canonical AX1/AX5 values now bind that content/chrome split in UI
tests. The corrected build's physical true-AX5 content and bilingual light/dark Pro evidence passed
on `拉沙的iPhone` only. DEC-COM-081 additionally binds Pro navigation chrome to the selected skin
after manual screenshots found an invisible first-push back indicator that green hierarchy checks
missed; its final three-skin run passed 1/1 with nine manually inspected captures. These are partial
C6-02 facts. Independent review accepted exact PR #91 head `b3ed24d` without P1/P2 findings,
hosted run `33362101536` passed, and PR #91 merged the bounded remediation as `4ddabcd` under
DEC-COM-082. DEC-COM-083 then makes `C6_02_ACCEPTANCE_MATRIX.json` bind 23 exact StoreKit, receipt,
accessibility-regression, and system-integration methods to a fresh complete xcresult. It accepts
existing physical continuity without rerun and preserves full VoiceOver, Instruments/exact
data-protection class, and physical system side effects as explicit non-passes owned by C6-03/C12.
This is not Requirement completion; C6-03 distribution artifacts and final-binary proof remain
open. Independent final review approved exact PR #93 head `016dd33` with no P1/P2 findings,
hosted run `33405016652` passed, and PR #93 merged as `c940e8e`; DEC-COM-088 marks C6-02 Done.
All four earlier hosted runs remain non-passes, and the back-button-selection/App-window-geometry plus upward-only
Save-drag P3 notes remain C6-03/C12 maintenance evidence. No Active Requirement is marked Done.

C6-03 owner entry: DEC-COM-089 records that on 2026-09-01 the owner authorized preparation of
`0.9.9 (10)` plus one Archive
and TestFlight transport upload only after the exact preparation head receives independent review,
passes hosted CI, and merges to `main`. `C6_03_RELEASE_BASELINE.md` binds the Distribution signature,
embedded privacy manifest/dependency inventory, release-environment, upload, and stop conditions.
Successful transport does not complete any Active Requirement, G1, App Store Connect privacy form,
service/schema deployment, tester assignment, distribution, or public release gate.

## COM-C0A implementation inventory against requirements

- Already present: exact `Money`, currency exponents, checked domain arithmetic, versioned
  SwiftData V1–V4 migration, deterministic finance engines, template fallback, Foundation Models
  availability/redaction/validation, local export and verified local deletion.
- Present after COM-C1 through completed and merged COM-C2: the closed entitlement/
  access model, accepted technical Product IDs,
  a test-bundle-only Xcode StoreKit Configuration fixture for Monthly/Annual, typed runtime product
  loading, presentation-only cache, launch/current/status reconciliation, one lifecycle task
  supervising transaction and subscription-status update sequences, full verified subscription-
  state mapping, explicit typed purchase/restore outcomes,
  publish-before-finish, and unfinished retry. Merged C3-01 adds voluntary customer-facing purchase,
  restore, and subscription-management presentation in unreleased source. C3-02 adds only a
  process-local verified trial lifecycle plus local generic reminder/in-app fallback. Not present: formal App
  Store Connect products, CloudKit
  entitlements or sync, centralized network egress, telemetry, first-party backend, third-party
  model provider, receipt/Vision pipeline, camera/photo picker permission, Watch target or
  WatchConnectivity.
- The current app has App Intents and reusable pure money/engine types, but they are members of the
  iOS app target rather than a cross-platform package. That is preparation evidence, not Watch
  implementation.

## Current official platform evidence (verified 2026-08-10)

These links verify API shape only, not product policy, pricing, provider availability, or a future
implementation:

- StoreKit `Transaction.updates` is an async sequence for transactions created/updated outside the
  current purchase result: <https://developer.apple.com/documentation/storekit/transaction/updates>.
- StoreKit `Product.SubscriptionInfo.Status.updates` is an async sequence of subscription-status
  change signals; C2-03 treats each signal only as a reason to perform a fresh full reconciliation:
  <https://developer.apple.com/documentation/storekit/product/subscriptioninfo/status/updates>.
- Apple documents `CKSyncEngine`, managed Core Data/CloudKit, and lower-level CloudKit as distinct
  synchronization choices: <https://developer.apple.com/documentation/cloudkit/deciding-whether-cloudkit-is-right-for-your-app>.
- Foundation Models exposes on-device availability and locale support; unsupported locale must
  have a fallback: <https://developer.apple.com/documentation/foundationmodels/supporting-languages-and-locales-with-foundation-models>.
- WatchConnectivity differentiates replace-latest application context, queued background user
  info, and reachable immediate messages: <https://developer.apple.com/documentation/watchconnectivity/wcsession>.

The accepted technical Product IDs are `com.xdgf558.mindbudget.pro.monthly` and
`com.xdgf558.mindbudget.pro.annual`; C2-01 uses them only in an isolated local configuration and no
App Store Connect product has been created. All provider
model names/prices/retention policies, StoreKit commercial terms, trial, storefront prices, cloud
quota, CloudKit architecture, App Attest design, backend domains, Watch target minimum, and formal
release metadata remain **UNVERIFIED** until their named phase produces dated first-party evidence
and an Accepted decision.

## C6-03 current transport evidence — 2026-09-01

DEC-COM-089 authorized only a reviewed/green/merged `0.9.9 (10)` Archive and TestFlight transport
upload. Exact head `11ab612` passed independent review and hosted run `33488815168`; PR #95 merged
it as `d5d0959`. DEC-COM-090 records the failed first export as a non-pass, the later cloud-managed
Apple Distribution inspection as passed, and App Store Connect delivery UUID
`1b358d3b-4544-4617-ab47-5be69addc7a8` as accepted for processing at
`2026-09-01 19:27:25 +0800`. This evidence does not mark any Active Requirement Done and does not
prove Production service/schema deployment, final-binary traffic, customer participation, tester
assignment, App Privacy form completion, G1, distribution, or public release. Independent review
approved exact PR #96 head `3ed1357`, hosted run `33508360536` passed, and PR #96 merged as
`246e7c1`; DEC-COM-091 closes C6-03/COM-C6 without marking any Active Requirement Done. G1 and
COM-C6.5 remain unentered behind their own evidence, timing, and explicit-owner gates.
