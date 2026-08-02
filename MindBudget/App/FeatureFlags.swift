enum FeatureFlags {
    // Product-scope gates only. `true` means V1 permits the capability to be
    // implemented; it does not claim the implementation exists or enable it for a user.
    // Feature call sites must use a centralized gate that also requires API/OS
    // availability, runtime capability, and an explicit default-off user setting.
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
