# DECISIONS

Use this format for decisions: context, decision, alternatives, consequences, and affected files.

## 2026-07-29 — Store money as Int64 minor units

Context: SwiftData predicates on `Decimal` are unreliable, while floating-point
types introduce rounding errors that are unacceptable for financial state.

Decision: Persist `amountMinorUnits: Int64` with `currencyCode`. Use `Decimal`
only for explicit presentation conversions; aggregate and compare with integers.

Alternatives considered: stored `Decimal`, `Double`, and `NSDecimalNumber`.

Consequences: The project needs a `Money` value type and explicit currency
exponents. Cross-currency arithmetic fails rather than silently converting.

Files affected: future `Models/Money.swift`, model files, and budget services.

---

## 2026-08-02 — Close v3.1 money, reminder, and Ask contracts

Context: The v3 review found contradictions in currency switching, quiet hours,
and the boundary between raw Ask text and model input.

Decision: Lock the accounting currency after financial data exists; isolate the
App Intents floating-point transport edge; use value-type quiet hours and deferred
notification times; keep raw Ask text inside the local classifier.

Alternatives considered: relabelling amounts, `Range<Int>` quiet hours, and sending
the raw question to a language model.

Consequences: Changing currency requires export/delete/re-onboarding in V1. AI
receives only intent keys and redacted facts. Template Ask is an L0 feature.

Files affected: the authoritative v3.1 specification and future money, reminder,
redaction, Ask, and App Intents files.

---

## 2026-08-02 — Bootstrap with a manually versioned Xcode project

Context: The workspace was empty and neither XcodeGen nor Tuist was installed.
The specification requires an `.xcodeproj`, app target, unit-test target, and
UI-test target during Phase 0.

Decision: Commit a minimal Xcode project directly, target iOS 17.0, use Swift 6
with complete strict concurrency, and share one `MindBudget` scheme. Validate on
the installed iPhone 17 Pro simulator running iOS 26.5.

Alternatives considered: adding a project generator dependency or postponing the
project until a GUI-generated template was available.

Consequences: The repository has no bootstrap dependency. Future source files must
be added to the project file deliberately. The simulator destination may be
overridden through `MINDBUDGET_TEST_DESTINATION` on another machine.

Files affected: `MindBudget.xcodeproj`, `AGENTS.md`, `README.md`, and this file.
