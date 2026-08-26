# UI/UX redesign handoff

This interlude applies the owner's `MindBudget UIUX重新设计` handoff before Phase 10.

The Today card uses a start-of-day reference amount: each flexible expense reduces the visible
amount one for one, while the presentation stops at zero and pairs its red state with localized
explanatory copy. Expense entry presents all categories in a single horizontally scrollable row
instead of hiding the long tail behind a separate modal list.
It changes presentation and navigation only; SwiftData models, calculation rules,
privacy boundaries, reminder throttling, and system-integration gates remain authoritative.

## Shipped surface

- Four destinations are real tabs: Today, Log, Insights, and Wishlist.
- The center add control is a separate, accessible action rather than a fake tab.
- Settings opens from Today into a short category directory. Budget, reminders and notifications,
  Apple Intelligence, system integrations, export, privacy, and About each open as focused
  second-level pages so future controls do not extend one unbounded screen.
- Existing free flows use the shared Canvas/Surface/Ink/Accent/Attention tokens, rounded
  cards, consistent primary and secondary actions, and localized copy.
- Today receives its money and pace facts from `BudgetEngine`; views format facts but do
  not calculate financial values.
- Add Expense uses an app-owned, locale-aware keypad. Behavioral reminders use a
  full-screen pause surface with the existing 2–4-action safety contract.
- Budget setup keeps edited amounts as draft input until the single bottom Save Budget
  action is selected; it does not add a second keyboard-toolbar completion action.
- Settings > Budget loads the existing current period into editable amount fields. Its single Save
  Budget action updates that plan in place; accounting currency remains read-only, and changing the
  preferred cycle start day is explicitly future-facing rather than rewriting current history.
- The custom navigation announces its selected tab and tab-derived localized position, grows
  vertically for accessibility text sizes, keeps the independent add action inside its hit-test
  bounds, remains bottom-anchored during every destination's loading/empty/content state, and
  declares the traversal Today → Log → Add Expense → Insights → Wishlist. Its surface color owns
  the content separation; no decorative top rule crosses behind the raised add action.
- The Today pace track announces both spending progress and calendar position; visual-only bars
  are not accepted as the sole representation of those facts.
- Empty-state primary actions use a compact one-line treatment with stable horizontal breathing
  room; they do not inherit the full-width primary style inside `ContentUnavailableView`.
- Appearance is a first-level Settings destination with three included skins: Aurora Glow uses a
  deep teal aurora treatment, Warm Botanical uses warm cream and restrained green, and Neon Pulse
  uses midnight purple with cyan highlights. A persisted `AppSkin` selects one semantic
  `MindBudgetTheme`; feature views consume theme roles rather than naming skin-specific colors.
- Layout, controls, cards, materials, and symbols remain native SwiftUI. Each skin also owns one
  purpose-built portrait background artwork: aurora/stars/glass waves, paper/foliage/natural
  shadows, or neon light trails/grid/particles. The supplied UI references are never cropped into
  shipping screenshots, so no text, amount, control, or status-bar pixel enters the background;
  localization, Dynamic Type, controls, and accessibility remain native.
- Simplified Chinese surfaces say `花有数`; English surfaces say `MindBudget`. Xcode targets,
  bundle identifiers, store filenames, Spotlight domains, and Swift type names retain their
  established technical identifiers.
- A cold process launch adds one app-owned brand transition after the static system launch screen:
  the selected skin, localized product name and subtitle, and budget-track mark appear for less
  than one second while normal preparation proceeds underneath. It does not replay on foreground
  return. Reduce Motion replaces progress, marker, and scale motion with a short fade.

## Reserved commerce seams

Paid capabilities from the design handoff are deliberately not user-visible in this
interlude. There is no StoreKit product, entitlement state, quota counter, locked chart,
paywall, trial message, or paid custom-rule editor.

If commercialization is approved later, integrate it as a separate phase at these
existing composition boundaries:

- Insights: between the local summary/charts and insight cards.
- Ask: between question input and the answer surface; the template fallback remains
  available independently of any entitlement.
- Settings: as its own section, not mixed into privacy or system-integration controls.
- Appearance: future additional skins may gain an entitlement requirement only when a real
  StoreKit product, restore path, entitlement state, and purchase UX exist end to end. The three
  currently shipped skins remain included and show no lock, price, PRO badge, or paywall.
- Reminder rules: as a destination backed by a real rule model, never as a dead row.

Until those capabilities exist end to end, each seam renders nothing. Free behavior must
not be degraded in preparation for a future paid tier.

## Visual verification

Signed-device verification must cover every skin on Today plus at least one list, form, Settings,
and Insights surface; selection persistence across relaunch; Dynamic Type through AX5; VoiceOver
selection announcements; Reduce Motion; narrow iPhone widths; and keyboard avoidance. Warm
Botanical intentionally presents in a light scheme; Aurora Glow and Neon Pulse intentionally
present in dark schemes so their contrast is deterministic rather than inherited from an
unrelated system appearance choice.
Verify that the theme artwork is visibly present rather than reduced to a flat color, while its
quiet center and readability scrim keep all text and controls legible.
Force-quit before launch-animation verification; background and foreground transitions must not
replay it. Repeat with Reduce Motion enabled and verify that only opacity changes.

## Receipt capture redesign

C4C-05 uses the reviewed A implementation from the owner's receipt-capture handoff. The existing
bounded `DataScannerViewController` remains the camera surface with system guidance disabled. An
app-owned black overlay provides one dominant 72-point shutter, persistent local-only disclosure,
three-state torch control, one-image PHPicker access, white breathing composition corners, preview
confirmation, and accessible Reduce Motion/Dynamic Type adaptations. Because this path has no live
frame or rectangle delegate, the corners never turn green and the copy never claims alignment,
edge locking, automatic cropping, or perspective correction before capture.

The old source-choice, full-screen processing, and full-screen result sequence is replaced by:
first-use privacy explanation → camera → image preview → existing expense form. Recognition runs in
the form with an inline status row and navigation-edge progress indicator. Accepted fields remain
editable, the review result is an inline card, and failure leaves the manual form available. Save
is the only persistence boundary; cancel or background cancellation discards temporary work.

The camera's Photos affordance stays a generic icon because displaying the most recent asset would
require broad Photo Library access that the existing PHPicker privacy contract deliberately avoids.
The visual long-receipt slot is noninteractive and announces that section capture is unavailable;
multi-image stitching and original-image expansion have no accepted interaction design and remain
separate future work.
