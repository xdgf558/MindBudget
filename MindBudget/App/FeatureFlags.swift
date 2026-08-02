enum FeatureFlags {
    // Capability gates only. `true` means the implementation may be considered;
    // it never means the feature is enabled for the user by default.
    // Effective access still requires API availability, runtime capability, and
    // an explicit user setting. Unsupported paths must use their documented fallback.
    static let enableFoundationModels = true
    static let enableSiriIntegration = true
    static let enableSpotlightIndexing = true
    static let enableOnscreenAwareness = true

    // V1 scope exclusions.
    static let enableReceiptImport = false
    static let enableCSVImport = false
    static let enableDeveloperDiagnostics: Bool = {
        #if DEBUG
        true
        #else
        false
        #endif
    }()
}
