import Foundation

@MainActor
struct AppEnvironment {
    static let live = AppEnvironment()

    private init() {}
}
