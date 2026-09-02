# G1 fixed bilingual three-way comparative Eval

Status: **PHYSICAL_OUTPUT_CAPTURED_PENDING_INDEPENDENT_BLIND_REVIEW**

This packet compares the user-visible value of three already-authorized local/cloud presentation
paths without changing production code or admitting customer traffic:

1. the frozen deterministic template embedded in `G1_LUNA_EVAL_CASES.json`;
2. Apple Foundation Models output generated on the physical `拉沙的iPhone`, with the same
   deterministic template used whenever generation fails or the existing closed validator rejects
   the raw output; and
3. the previously captured and independently reviewed OpenAI `gpt-5.6-luna` attempt-3 output.

The comparison reuses the exact 12-scenario/24-case bilingual dataset with SHA-256
`d509c8fee36578e66fe361bf0dd635fb25fb947891aff2f1a5e7fc9c7747c014`. It reuses the accepted Luna
transcript with SHA-256
`4800cc6c8458fa39b0bd4419d90fbf7ee4bfa47bc3deffa73475b751e947999e`; it does not perform or charge
for another OpenAI request. The three arms must all pass the same existing closed-schema,
fact/action allow-list, locale, number, length, and no-judgment validator before review. An invalid
Apple output is not repaired or silently omitted: the effective user-visible local arm becomes the
frozen deterministic template and the reason is counted.

## Physical execution boundary

`MindBudget-G1-OnDevice-Eval` is a shared Debug test-only scheme. It cannot run or archive the App,
and its opt-in environment variable is absent from the ordinary `MindBudget` scheme. The test
requires Apple Foundation Models availability for both `en_US` and `zh_Hans_CN`; emits only the
frozen synthetic cases; and records no user financial data. `Scripts/run-g1-three-way-on-device.sh`
accepts only `拉沙的iPhone`, explicitly rejects `Xiao li的 iPhone (2)`, refuses to overwrite an
evidence path, and stops if the selected physical test fails. A simulator, Mac, generic build,
ordinary test run, Archive, or App Store build cannot satisfy this evidence gate.

iOS reports the privacy-reduced `UIDevice.name` value `iPhone`; it does not expose the owner's
custom device name to the test. The extractor therefore requires the exact
`-destination platform=iOS,name=拉沙的iPhone` invocation in the saved Xcode log before adding
`xcode_destination_name` to the normalized transcript. The generic UIDevice value alone is not
accepted as device-selection proof.

The generic iOS test build under Xcode 27 beta 6 proves only that the harness compiles. The later
authorized run using the exact Xcode destination string `拉沙的iPhone` passed its single selected
test and emitted structured Apple output for all 24 cases in 29.579 seconds. The normalized
metadata proves only that destination string plus the privacy-reduced `device_model: iPhone`,
`system_name: iOS`, and `system_version: 26.6.1`. The raw Xcode log and xcresult are not retained,
so this durable transcript does not prove the marketing name `iPhone Air` or hardware identifier
`iPhone18,4`. The normalized transcript is
`G1_APPLE_ON_DEVICE_EVAL_TRANSCRIPT_2026-09-02.jsonl`, SHA-256
`d6236a29293e0c16068fb24b6b7a6392af9cfedc9dadb9c7cdc06b8fabb5a20b`. Nearest-rank generation
latency was P50 1,171 ms, P95 1,432 ms, and maximum 2,281 ms. These are Debug synthetic-device
measurements, not final-binary/customer or production-service latency.

The raw Apple output is passed through the existing deterministic validator, and invalid output
fails closed to the frozen template. Exact source classifications, validation errors, arm mappings,
and any affected case identifiers are deliberately absent from this pre-review document and blind
packet. They are preserved only in the sealed post-score sidecar. No rejected raw output is
presented as acceptable model evidence.

This is a product-path comparison, not a controlled model benchmark. The Apple prompt/schema mechanism differs from Luna: the Apple path uses the
Foundation Models `@Generable` schema, camelCase generated fields such as `factIDs`, and a prompt
with `DATA START`/`DATA END` delimiters. The reused Luna path uses the previously frozen Responses
API prompt and strict `json_schema` wire contract. The dataset, facts, task intent, allowed
fact/action IDs, output fields after normalization, validator, and displayed candidates are shared;
the prompt and schema mechanisms are not. Any observed difference therefore cannot be attributed
to model quality alone.

## Blinded review contract

`Scripts/g1_three_way_eval.py` validates and deterministically labels the three candidates A/B/C
per case. The scoring surface contains only frozen inputs, candidate bodies, empty review fields,
and a SHA-256 commitment to the label mapping. Device metadata, source counts, source/error fields,
and the A/B/C answer key live only in this post-score-only artifact:
`G1_THREE_WAY_REVIEW_SIDECAR_2026-09-02.json`, SHA-256
`d29fca8246df5641d876be19ea56a936edd975616d2b3101bc18cca9d7bff507`. This is procedural blindness, not cryptographic secrecy: a reviewer must score and lock every review field before
opening the sidecar, raw device transcript, Luna transcript, mapping code, or diagnostic prose.
A reviewer who read the pre-remediation leaked packet or already knows the Luna outputs cannot
serve as this blind reviewer. Every case requires one preferred label or TIE, non-empty best-label sets
for clarity/usefulness/locale naturalness, an explicit material-increment decision, and notes. A
complete record must name an independent PR reviewer, UTC review time, and reviewed head.

Fail-closed fallback can leave two candidate bodies identical. The blind packet discloses that
generic protocol residue without naming a source or case: identical bodies must be scored equally,
and the case cannot establish material incremental value. The post-score summarizer rechecks this
from the sealed sidecar and fails closed if a reviewer marks such a case as material.

The pending packet is `G1_THREE_WAY_BLIND_REVIEW_2026-09-02.json`, SHA-256
`bcbf943ba7d6a1a9d18442efc38e760cc798c30e8674c8d877f9e0cb751ab2a5`. Its status is
`PENDING_BLIND_REVIEW`; all preference/value fields are unfilled. Therefore the physical run closes
only output capture and deterministic validation, not comparative value.

Passing deterministic safety is necessary but not sufficient. G1 incremental-value acceptance
requires the independent review to identify at least one task represented in both English and
Simplified Chinese where Luna is preferred over both local arms and adds material user value
without inventing facts, advice, judgment, or unsafe actions. If that does not occur, the evidence
must return a non-pass; the dataset, mapping, or criteria cannot be rewritten to manufacture a
cloud advantage.
After all review fields and independent-review provenance are complete,
`g1_three_way_eval.py --summarize-review` derives the hidden arm labels and returns `PASS` only for
that bilingual condition. A one-language preference, TIE, local-arm preference, incomplete review,
unsafe candidate, altered mapping, or failed derivation returns or triggers a non-pass/error.

## Carried scorer limitation

DEC-COM-099's number-word observation remains applicable: the shared deterministic scorer detects
Arabic numeric tokens, not English or Chinese number words. This packet therefore does not claim
complete automated semantic-number proof. The independent reviewer must inspect every candidate's
displayed factual/numeric meaning as part of the value review, and any suspected word-form
invention is a non-pass. The other DEC-COM-099 scorer notes do not affect this physical capture:
there was no provider retry, every Apple case has nonzero measured latency, and the reused reviewed
Luna transcript retains its original complete usage payload.

## Current boundary

This harness/evidence task does not select a new provider, make a Luna call, configure production
credentials, enable cloud traffic, implement credits or a backend, create a Product ID, close G1,
enter COM-C7, or authorize distribution/release. G1 remains In Progress with
`EVAL_REVIEWED_PENDING_STOREFRONT_EVIDENCE` until the independent blind review is complete,
StoreKit US$4.99 Product-ID/price-point evidence exists, the server breaker and legal
gates are resolved, and the owner explicitly records `PROCEED_TO_R2`.
