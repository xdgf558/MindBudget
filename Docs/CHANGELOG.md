# CHANGELOG

## Unreleased

### Added

- Phase 0 SwiftUI app shell targeting iOS 17.0 with Swift 6 strict concurrency.
- Shared build/test scheme, unit-test target, and UI-test target.
- Feature flags, string catalog, privacy manifest, and persistent agent memory.
- Asset catalog scaffold with an accent color and App Icon slot.
- GitHub Actions validation and reusable local validation scripts.
- Proprietary public-repository license notice.
- English and Simplified Chinese rendered-localization smoke coverage.

### Changed

- Limited V1 device support to iPhone.
- Moved the bundle identifier prefix into an overridable xcconfig.
- Replaced constant-only smoke assertions with bundle localization checks.
- Clarified that capability FeatureFlags do not enable default-off user features.
- Aligned hosted CI with Xcode 26.6+, made simulator selection dynamic, and pinned
  the checkout action to its reviewed commit.
- Replaced duplicate build/test work with build-for-testing/test-without-building.

### Fixed

- Expanded the floating-point money guard to the complete app source tree while
  retaining the single documented App Intents transport exception.
- Made iOS deployment and bundle identifier validation target-specific and strict.

### Privacy

- Declared no tracking, no tracking domains, and no collected data types.
- Declared the required-reason UserDefaults API category for app settings.
