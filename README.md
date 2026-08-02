# MindBudget

MindBudget is a local-first iOS budgeting coach built with SwiftUI.

The project is developed one phase at a time. Before making changes, read
`AGENTS.md` and the project memory files under `Docs/`.

## Requirements

- Xcode 26.6 or newer compatible toolchain
- iOS 17.0+
- iPhone (V1)
- Swift 6 strict concurrency

## Build and test

```bash
Scripts/check-no-floating-point-money.sh
Scripts/validate.sh
```

Set `MINDBUDGET_TEST_DESTINATION` to override the default simulator. A fork can
create an ignored `Config/Local.xcconfig` and override
`MINDBUDGET_BUNDLE_ID_PREFIX` for local signing.

## License

This repository is publicly visible for review, but MindBudget is not open-source
software. All rights are reserved; see `LICENSE`.
