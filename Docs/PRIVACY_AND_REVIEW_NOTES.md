# PRIVACY_AND_REVIEW_NOTES

This file is the living source for App Store privacy answers and review notes.
Statements about future features must be revalidated against the shipped binary.

## Data handling

- Collected data: none. V1 financial records remain in the app's local container.
- Data leaving the device automatically or to the developer: none. A user may explicitly
  share an expense/income CSV to a destination they choose. Optional Foundation Models enhancement
  runs on device.
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

Local expense, income, budget, wishlist, cooling-off, and reflection data exists only to
provide the budgeting features initiated by the user. It is not used for ads,
profiling, cross-app tracking, resale, or third-party analytics.

## Export and deletion

V1 exports the user's expense and income ledger as a UTF-8-with-BOM CSV only after the user opens
Export CSV and invokes the system share sheet. It includes exact amount/currency fields,
dates, categories, and the user's optional source/merchant names and raw notes; the
screen discloses those fields before sharing. Formula-like user text is neutralized and
CSV punctuation/newlines are escaped. The export is transferred from memory, so the app
does not retain a second CSV file in its container. It is a ledger export, not a
full internal-database backup.

Delete All is implemented with a confirmation dialog followed by a localized confirmation
word. It performs these steps in order: cancel app notifications, delete and await all
app-owned Spotlight index removal, delete all current SwiftData model types, reset app
preferences while leaving system language untouched, and return to onboarding. Progress
names the current stage. After deletion, the app re-queries every current model count and resets
preferences only when every count is zero. The flow stops and names the failed stage if any
operation or verification fails; a partial failure is never reported as complete deletion.

Future commercialization channels are not part of the current 0.9.x claim. Before an optional
Free iCloud, first-party telemetry, or consented cloud-AI channel can ship, its owning COM phase
must add current bilingual disclosure, App Privacy answers, channel-specific revoke/delete
behavior, and signed release evidence. No forward-looking permission changes the current binary's
local-only data handling.

Unreadable or orphaned cooling-off records are isolated from valid reminder reconciliation and
are never deleted automatically. Settings shows the exact affected count and offers a separate
destructive repair action with explicit confirmation. At commit time the actor revalidates every
previously identified record, deleting only rows that are still unreadable and preserving any row
that became valid. A later notification-operation failure does not resurrect a stale data-warning
state; it remains visible as the independent notification error.

## AI disclosure

AI enhancement is implemented and off by default. When enabled on a supported device,
language, region, and runtime, it receives only redacted aggregate facts and runs through
Apple's on-device Foundation Models. If it is disabled or unavailable, the same feature
returns a complete local template answer.
Raw notes, transaction rows, merchant lists, and raw Ask questions never enter
the model context. Ask facts cross the redactor only through a closed per-intent typed payload;
there is no generic fact dictionary or caller-provided template body. Deterministic Swift code
computes all financial conclusions.
`FeatureFlags.enableFoundationModels` is a product-scope gate, not proof of an
implementation or the user's preference; the user setting defaults to off and remains
mandatory through a centralized availability gate. Generated wording is validated and is
not persisted as a conversation or profile.

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

Phase 8A implements that disclosure with one app-owned Spotlight domain. Expense search
content uses a category and budget-relative amount band, never an exact amount; raw expense
and wishlist notes are not accepted by the index builder. Wishlist item names may appear
because the user explicitly created them as searchable app data. Merchant names remain
excluded until both consent layers are true. Turning Spotlight off awaits domain deletion;
an indexing failure is shown as an integration error and never changes local financial data.
Siri queries and writes similarly fail closed until the independent Siri setting and every
capability gate are available. Siri strings are sanitized and truncated, candidate names
used for impact previews are not stored, and five-second duplicate execution protection
prevents one spoken/shortcut action from creating repeated expenses. Passive system output
continues to exclude exact amounts. When the user explicitly invokes the authenticated budget-
impact intent, its result may speak the exact deterministic flexible-budget value; Settings
discloses this in a separate scalable paragraph because authentication does not guarantee a
private listening environment. Spotlight and merchant-indexing privacy remain in their own
paragraph.

Phase 9 associates those same redacted documents with amount-free `IndexedEntity` values only
on iOS 26; it does not create another index or widen the indexed fields. Onscreen awareness is
also off with Siri by default and publishes only an app-owned entity identifier through an
`NSUserActivity`; those activities are not separately searchable, predictable, or eligible for
Handoff. Dashboard, expense detail, and wishlist detail are the supported single-subject
screens. List pages fail closed without an explicit selected row. The installed Xcode 26.6 /
iOS 26.5 SDK has no public notification entity-annotation property, so cooling-off
notifications retain their existing amount-free content and app-local `userInfo` navigation;
no private runtime workaround is used. Ask still derives every model fact from SwiftData and
deterministic engines, never from Spotlight text.

Disabling the onscreen gate passes a nil SwiftUI activity element, which stops advertising the
activity instead of relying on removal of a conditional modifier. The three single-subject
entities satisfy the public `Transferable` contract with an identity-only JSON reference:
version, entity kind, and stable identifier. That representation cannot contain a wishlist
name, date, category, amount band, exact amount, or note. `NSUserActivityTypes` is not declared
because these activities explicitly prohibit Handoff and are not continuation inputs; verify
same-device Siri resolution on a signed iOS 26 device before release. Emotion-tag index/entity
documents remain a fixed app vocabulary and carry no user selection, count, or transaction.

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
- The optional app lock is off by default. It checks Face ID availability before enabling, asks
  the owner to authenticate before either enabling or disabling, and locks on launch and
  foreground return. Authentication is performed entirely by `LocalAuthentication`; MindBudget
  receives only success/failure and never receives or stores face data. Device passcode remains
  the recovery path so a biometric enrollment change cannot permanently trap the owner outside
  local records. While locked, an opaque app-owned surface covers financial content, including
  the app-switcher transition.

## Privacy manifest baseline

`PrivacyInfo.xcprivacy` declares no tracking, no tracking domains, no collected
data types, and UserDefaults reason `CA92.1`. Add File Timestamp reasons only if
a shipped implementation actually uses the covered API.

## Current local planning data

The in-app language selection is a local UserDefaults preference and does not change device
language or contact a translation service. Budget-plan-semantics markers, income allocation, the
total savings goal, recurring fixed-expense rules, and generated occurrence identities are local
SwiftData records. Recurring rule notes remain behind the actor/detail boundary and are never
notification, Spotlight, Siri entity, or model context. App lifecycle reconciliation uses no
background server and makes no claim that an entry will be created while the app is not running.

CSV remains an explicit user export and now includes the exact income portions allocated to the
current spending budget and savings as minor-unit columns. Delete All removes and verifies the
budget-plan-semantics, allocation, savings-goal, recurring-rule, and occurrence tables before
reporting completion.
