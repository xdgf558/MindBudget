#if !DEBUG || !MINDBUDGET_FX_CLOUD_PROBE
#error("The isolated probe is Debug-only and requires its dedicated build configuration.")
#endif
import SwiftUI

/// Normal launch is inert. Only an explicit reviewed run request may enter the dedicated probe.
/// Installation/live execution remain separately authorized operations.
@main
struct FXCloudProbeApp: App {
    init() {
        precondition(Bundle.main.bundleIdentifier == "com.xdgf558.MindBudgetFXCloudProbe")
    }

    var body: some Scene {
        WindowGroup { Color.clear.task { await ProbeEntry.runIfRequested() } }
    }
}
