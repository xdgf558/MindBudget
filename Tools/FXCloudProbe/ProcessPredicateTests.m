// Local Foundation-only regression. Not linked into any app; no device/network calls.
#import <Foundation/Foundation.h>

static void require(BOOL condition, NSString *message) {
    if (!condition) {
        fprintf(stderr, "NON_PASS: %s\n", message.UTF8String);
        exit(1);
    }
}

int main(void) {
    @autoreleasepool {
        NSDictionary *native = @{@"executable": [NSURL fileURLWithPath:
            @"/private/synthetic/MindBudgetFXCloudProbe.app/MindBudgetFXCloudProbe"]};
        BOOL legacyRejected = NO;
        @try {
            NSPredicate *legacy = [NSPredicate predicateWithFormat:
                @"executable CONTAINS 'MindBudgetFXCloudProbe.app/'"];
            (void)[legacy evaluateWithObject:native];
        } @catch (NSException *exception) {
            legacyRejected = [exception.name isEqualToString:NSInvalidArgumentException];
        }
        require(legacyRejected, @"old URL CONTAINS defect not reproduced");

        // Foundation accepts .path, but real devicectl rejected that key before evaluation.
        // Keep this distinction tested: Foundation success alone is NOT CLI compatibility.
        NSPredicate *predicate = [NSPredicate predicateWithFormat:
            @"executable.path ENDSWITH '/MindBudgetFXCloudProbe.app/MindBudgetFXCloudProbe'"];
        NSArray<NSArray *> *cases = @[
            @[@"/private/synthetic/MindBudgetFXCloudProbe.app/MindBudgetFXCloudProbe", @YES],
            @[@"/var/containers/Bundle/Application/fixture/MindBudgetFXCloudProbe.app/MindBudgetFXCloudProbe", @YES],
            @[@"/private/synthetic space/MindBudgetFXCloudProbe.app/MindBudgetFXCloudProbe", @YES],
            @[@"/private/MindBudget.app/MindBudget", @NO],
            @[@"/private/MindBudgetFXCloudProbeOther.app/MindBudgetFXCloudProbe", @NO],
            @[@"/private/OtherMindBudgetFXCloudProbe.app/MindBudgetFXCloudProbe", @NO],
            @[@"/private/MindBudgetFXCloudProbe.app/MindBudgetFXCloudProbeHelper", @NO],
            @[@"/private/MindBudgetFXCloudProbe.app/Helper", @NO],
            @[@"/private/MindBudgetFXCloudProbe.app/MindBudgetFXCloudProbe/child", @NO],
            @[@"/private/MindBudgetFXCloudProbe.app/PlugIns/Extension.appex/Extension", @NO],
            @[@"/private/MindBudgetFXCloudProbe.app", @NO],
            @[@"/private/MindBudgetFXCloudProbe", @NO],
            @[@"/private/mindbudgetfxcloudprobe.app/MindBudgetFXCloudProbe", @NO],
            @[@"/private/MindBudgetFXCloudProbe.app/mindbudgetfxcloudprobe", @NO]
        ];
        for (NSArray *test in cases) {
            NSDictionary *row = @{@"executable": [NSURL fileURLWithPath:test[0]]};
            require([predicate evaluateWithObject:row] == [test[1] boolValue], @"URL path scope mismatch");
        }
        require(![predicate evaluateWithObject:@{}], @"missing URL matched");
        printf("PASS: native NSURL reproduces legacy rejection; Foundation-only .path passes 15 fixtures (NOT devicectl acceptance).\n");
    }
    return 0;
}
