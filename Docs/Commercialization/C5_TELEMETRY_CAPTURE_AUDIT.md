# C5 Telemetry Capture Audit

Status: **C5-04 product capability merged after independent review of exact remediation head
`2c1cebe`, green GitHub Actions run `33233846430`, and PR #82 merge `28d9eae`; current-source
Development deployment/probe remains open.**

This is the exhaustive production capture inventory for the optional MindBudget first-party
telemetry channel. `Scripts/check-telemetry-contract.sh` requires the concrete client/transport to
remain inside one reviewed factory and limits capture references to the three source files named
below. A new event, field, construction, or capture source is a contract change, not an ordinary
refactor.

## Authority and lifecycle

- Collection is off when state is missing. Reading or repeatedly selecting Off creates no file,
  Keychain key, pseudonym, event, or request.
- Enabling requires a customer confirmation in Privacy settings. Only then does the client create
  a random app-scoped pseudonym and queue the first session event.
- Disabling clears unsent events, retires the current pseudonym, best-effort cancels an in-flight
  upload, and prevents future capture. It does not claim to recall a request already accepted at
  the edge.
- Ordinary upload envelopes contain one pseudonym generation. Re-enable and 30-user-calendar-day
  rotation never reuse the earlier upload pseudonym. A complete-delete request deliberately groups
  at most four retained authenticated proofs only long enough to delete them.
- Telemetry success, failure, backoff, or deletion never grants entitlement, changes a budget,
  blocks local use, or alters any product decision.

## Exact capture inventory

| Production source | Closed event | Trigger and outcome | Explicitly absent |
| --- | --- | --- | --- |
| `AppRouter.swift` / `TelemetryService` | `app_session_started` | One event after an enabled lifecycle starts; also the first event after an explicit enable | screen name, duration, locale, device model, account, ledger state |
| `ProSubscriptionView.swift` | `pro_surface` / `presented`, `dismissed` | One paired event interval each time the Pro screen becomes visible and later disappears, including navigation to and back from its legal subpages | price, product ID, trial state, StoreKit transaction, entitlement |
| `AppRouter.swift` | `subscription_action` / `purchase`, `restore`, `manage` | Typed completed/cancelled/unavailable/failed outcome after the customer action | product ID, price, storefront, transaction/JWS, subscription dates |
| `AddExpenseView.swift` | `receipt_flow` / `opened`, `acquired`, `reviewed`, `saved` | Completed stage, plus a failed review outcome; `saved` occurs only after the existing explicit expense Save succeeds | image, OCR, merchant, date, total, currency, category, note, model evidence |
| `AppRouter.swift` | `cloud_sync_control` / `enable`, `disable`, `deleteCloudCopy`, `resolveConflict` | Typed completed/failed control result after an explicit action | record name/type/content, zone/account ID, error body, ledger fact |

The only capture-bearing production files are:

1. `MindBudget/App/AppRouter.swift`
2. `MindBudget/Features/AddExpense/AddExpenseView.swift`
3. `MindBudget/Features/Commerce/ProSubscriptionView.swift`

The channel intentionally does not capture ordinary expense/income/budget/wishlist/cooling-off
content or saves, Dashboard/Insights/Ask viewing, search, notifications, app-language/storefront,
device/OS model, advertising identifiers, push token, iCloud account, receipt content, StoreKit
identifiers, network bodies, arbitrary strings, or caller-defined properties. A funnel stage not
listed above is `not_collected`; absence must never be converted into a zero or success claim.

## Wire and retention map

The encrypted local queue contains only the closed event, event UUID, occurrence time, app version,
environment, one random pseudonym, and its deletion proof. It is bounded to 256 events and four
identity generations, excluded from backup, and protected until first unlock. Upload batches are
bounded to 20 events/32 KiB. The Worker stores the same closed event facts and acceptance/expiry
times for no more than 90 x 24 UTC hours. It stores no request IP, header, locale, content, or
request grouping; Cloudflare necessarily processes ordinary connection metadata at the edge.

Product events map to App Privacy `Product Interaction`; the rotating app-generated pseudonym maps
conservatively to `Device ID`. Both are declared as not linked to identity, not used for tracking,
and used only for Analytics. App Store Connect privacy answers must match this manifest before any
distribution build is submitted; checking in the manifest does not update App Store Connect.

## Review checklist

- Verify every `TelemetryEvent` case has fixed coding keys and fixed enum values.
- Verify the capture-source allow-list matches this document and no source contains financial or
  receipt-content types.
- Verify Off and unavailable/corrupt states cannot capture or silently recreate state.
- Verify terminal 404/405/421 is sticky, non-retrying, visible, and cleared only by explicit retry
  or disable.
- Verify Delete All commits telemetry opt-out and attempts proof-authenticated remote deletion
  before financial deletion, but network, endpoint, or unavailable telemetry results never block
  the authoritative local erase. Any retained proof must remain visible for a separate retry, and
  the app must not relabel that remote remainder as deleted.
- Treat Development synthetic probes as operational evidence only, never customer participation,
  a Production result, or a G1 threshold pass.
