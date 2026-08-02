import Foundation
import Testing
@testable import MindBudget

struct LocalizationTests {
    @Test
    func appBundleLoadsLocalizedBootstrapCopy() {
        let key = "bootstrap.status.ready"
        let localizedValue = Bundle.main.localizedString(
            forKey: key,
            value: nil,
            table: nil
        )

        #expect(Bundle.main.bundleURL.pathExtension == "app")
        #expect(localizedValue != key)
        #expect(localizedValue.isEmpty == false)
    }
}
