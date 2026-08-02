import Testing
@testable import MindBudget

struct MindBudgetPlaceholderTests {
    @Test
    func bootstrapConfigurationLoads() {
        #expect(FeatureFlags.enableReceiptImport == false)
        #expect(FeatureFlags.enableCSVImport == false)
    }
}
