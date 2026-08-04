# PRIVACY_AND_REVIEW_NOTES

This file is the living source for App Store privacy answers and review notes.
Statements about future features must be revalidated against the shipped binary.

## Data handling

- Collected data: none. V1 financial records remain in the app's local container.
- Data leaving the device automatically or to the developer: none. A user may explicitly
  share an expense CSV to a destination they choose. Planned Foundation Models enhancement
  is on-device.
- Tracking: none.
- Third-party sharing: none.
- Accounts: none in V1.
- CloudKit: disabled in V1.
- Third-party SDKs: none.
- Data protection: deliberately rely on the Core Data persistent-store default,
  `NSFileProtectionCompleteUntilFirstUserAuthentication`, which applies to stores
  created by current iOS applications. This includes the SQLite store managed by
  SwiftData; verify the effective class on a release-signed device before shipping.

## Data purpose

Local expense, budget, wishlist, cooling-off, and reflection data exists only to
provide the budgeting features initiated by the user. It is not used for ads,
profiling, cross-app tracking, resale, or third-party analytics.

## Export and deletion

V1 exports the user's expense ledger as a UTF-8-with-BOM CSV only after the user opens
Export CSV and invokes the system share sheet. It includes exact amount/currency fields,
dates, categories, and the user's optional merchant names and raw expense notes; the
screen discloses those fields before sharing. Formula-like user text is neutralized and
CSV punctuation/newlines are escaped. The export is transferred from memory, so the app
does not retain a second CSV file in its container. It is an expense-ledger export, not a
full internal-database backup.

Delete All is implemented with a confirmation dialog followed by a localized confirmation
word. It performs these steps in order: cancel app notifications, delete and await all
app-owned Spotlight index removal, delete all nine SwiftData entity types, reset app
preferences while leaving system language untouched, and return to onboarding. Progress
names the current stage. After deletion, the app re-queries all nine model counts and resets
preferences only when every count is zero. The flow stops and names the failed stage if any
operation or verification fails; a partial failure is never reported as complete deletion.

## AI disclosure

AI enhancement is planned to be off by default. When enabled, it receives only
redacted aggregate facts and runs through Apple's on-device Foundation Models.
Raw notes, transaction rows, merchant lists, and raw Ask questions never enter
the model context. Deterministic Swift code computes all financial conclusions.
`FeatureFlags.enableFoundationModels` is a product-scope gate, not proof of an
implementation or the user's preference; the future user setting defaults to off
and remains mandatory through a centralized availability gate.

## Siri and Spotlight disclosure

Siri integration and Spotlight indexing are off by default and independently
controlled by the user. Settings must explain what is indexed. Disabling indexing
or deleting data removes the app-owned index. Exact amounts, notes, and merchant
names are excluded by default from display representations and index content.
The corresponding FeatureFlags only permit planned product capabilities and never
bypass centralized availability checks or the independent default-off user settings.
Local merchant aggregates include all expenses and remain private inside SwiftData;
they do not imply indexing consent. A merchant name is eligible for Spotlight only
after the global merchant-name opt-in and at least one matching expense's explicit
`allowMerchantIndexing` value are both true.

## Emotion-tag review explanation

Chinese: 情绪标签只是用户主动选择的消费背景记录，用于回顾自己的消费情境；
MindBudget 不提供心理测评、评分、诊断或治疗建议，也不会据此给用户贴标签。

English: Emotion tags are optional, user-selected context for reviewing spending.
MindBudget does not assess, score, diagnose, or treat mental-health conditions and
does not label a person based on those tags.

## Permission timing

- Notifications are requested only after the user creates a cooling-off reminder
  or explicitly enables reminders, never on first launch.
- Background reconciliation reads authorization without prompting. Denial preserves the
  local cooling-off countdown and presents a System Settings link instead of retrying the
  permission dialog.
- Cooling-off lock-screen content contains the user-entered wishlist item name and neutral
  review copy, but never its amount or notes. Quiet hours defer rather than discard it.
- V1 has no receipt, photo, or document import and requests no photo-library access.
- Siri and Spotlight integration require explicit opt-in.

## Privacy manifest baseline

`PrivacyInfo.xcprivacy` declares no tracking, no tracking domains, no collected
data types, and UserDefaults reason `CA92.1`. Add File Timestamp reasons only if
a shipped implementation actually uses the covered API.
