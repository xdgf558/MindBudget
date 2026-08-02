# MindBudget

MindBudget is a local-first iOS budgeting coach built with SwiftUI.

The project is developed one phase at a time. Before making changes, read
`AGENTS.md` and the project memory files under `Docs/`.

## Requirements

- Xcode 26.6 or newer compatible toolchain
- iOS 17.0+
- Swift 6 strict concurrency

## Build and test

```bash
export DEVELOPER_DIR="/Users/shaola/Downloads/软件/Xcode.app/Contents/Developer"
export MINDBUDGET_TEST_DESTINATION="${MINDBUDGET_TEST_DESTINATION:-platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5}"
xcodebuild -project MindBudget.xcodeproj -scheme MindBudget \
  -destination "$MINDBUDGET_TEST_DESTINATION" build
xcodebuild -project MindBudget.xcodeproj -scheme MindBudget \
  -destination "$MINDBUDGET_TEST_DESTINATION" test
```
