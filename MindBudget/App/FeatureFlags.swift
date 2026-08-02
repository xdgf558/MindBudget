enum FeatureFlags {
    static let enableFoundationModels = true
    static let enableSiriIntegration = true
    static let enableSpotlightIndexing = true
    static let enableOnscreenAwareness = true
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
