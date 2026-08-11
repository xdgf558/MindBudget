import Foundation

/// The paid rights that a Release build can currently represent.
///
/// Free is the empty set. The only owner-approved reachable paid right in COM-C1 is the Pro
/// subscription shared by the future Monthly and Annual products. Deferred product families are
/// intentionally absent: callers cannot construct them through this domain API.
struct EntitlementSet: Hashable, Sendable {
    private static let proSubscriptionBit: UInt64 = 1 << 0
    private static let knownVersion1Bits = proSubscriptionBit

    private let bits: UInt64

    private init(bits: UInt64) {
        self.bits = bits
    }

    static let free = EntitlementSet(bits: 0)
    static let proSubscription = EntitlementSet(bits: proSubscriptionBit)

    /// The complete set of paid singleton rights constructible by the current Release domain.
    static let reachablePaidEntitlements: [EntitlementSet] = [.proSubscription]

    var isFree: Bool {
        bits == 0
    }

    /// Returns whether every right in `other` is present in this set.
    ///
    /// In particular, every set is a superset of `.free`. Callers deciding whether the current
    /// user has no paid rights must use `isFree` instead of this collection operation.
    func isSuperset(of other: EntitlementSet) -> Bool {
        bits & other.bits == other.bits
    }

    func union(_ other: EntitlementSet) -> EntitlementSet {
        EntitlementSet(bits: bits | other.bits)
    }

    static func union<S: Sequence>(_ entitlements: S) -> EntitlementSet
    where S.Element == EntitlementSet {
        entitlements.reduce(.free) { result, entitlement in
            result.union(entitlement)
        }
    }

    func removing(_ entitlement: EntitlementSet) -> EntitlementSet {
        EntitlementSet(bits: bits & ~entitlement.bits)
    }

    /// Internal only for the explicit migration boundary and its structural completeness tests.
    /// Feature-access code must never inspect raw entitlement bits.
    var version1Bits: UInt64 {
        bits
    }

    /// Internal only for version-1 migration and the reachable-right completeness proof.
    static var version1KnownBits: UInt64 {
        knownVersion1Bits
    }
}

/// A versioned transport/persistence representation. `EntitlementSet` itself is deliberately not
/// `Codable`, so stored bits must cross the explicit migration boundary below.
struct EntitlementSetRepresentation: Codable, Equatable, Sendable {
    let version: UInt16
    let rawBits: UInt64

    init(version: UInt16, rawBits: UInt64) {
        self.version = version
        self.rawBits = rawBits
    }
}

enum EntitlementSetMigrationError: Error, Equatable, Sendable {
    case unsupportedVersion(UInt16)
    case unknownEntitlementBits(UInt64)
}

enum EntitlementSetMigrator {
    static let currentVersion: UInt16 = 1

    static func representation(for entitlements: EntitlementSet) -> EntitlementSetRepresentation {
        EntitlementSetRepresentation(
            version: currentVersion,
            rawBits: entitlements.version1Bits
        )
    }

    static func migrate(_ representation: EntitlementSetRepresentation) throws -> EntitlementSet {
        switch representation.version {
        case 1:
            return try migrateVersionOne(rawBits: representation.rawBits)
        default:
            throw EntitlementSetMigrationError.unsupportedVersion(representation.version)
        }
    }

    private static func migrateVersionOne(rawBits: UInt64) throws -> EntitlementSet {
        let unknownBits = rawBits & ~EntitlementSet.version1KnownBits
        guard unknownBits == 0 else {
            throw EntitlementSetMigrationError.unknownEntitlementBits(unknownBits)
        }

        var migrated = EntitlementSet.free
        if rawBits & EntitlementSet.proSubscription.version1Bits != 0 {
            migrated = migrated.union(.proSubscription)
        }
        return migrated
    }

    /// A corrupted, future, or deferred representation never grants a paid right.
    static func resolveFailClosed(_ representation: EntitlementSetRepresentation) -> EntitlementSet {
        (try? migrate(representation)) ?? .free
    }
}

/// Owner-approved paid feature vocabulary. This type names seams only; COM-C1-02 owns the single
/// access-decision service, and COM-C1-03 decides which existing entry points may consume it.
enum PremiumFeature: String, Codable, CaseIterable, Hashable, Sendable {
    case unlimitedCategoryBudgets
    case advancedLocalInsights
    case appleOnDeviceAI
    case cloudCoach
    case unlimitedWishlist
    case customCoolingOffPeriod
    case purchasePreflight
    case postPurchaseReview
    case receiptScan
    case receiptImport
    case shareExtension
    case advancedSiri
    case longRangeReports
    case appleWatchCompanion
}

/// Free/trust capabilities that must remain structurally outside `PremiumFeature`.
/// This is the C1 invariant set, not an exhaustive inventory of every Free screen.
enum FreeCoreFeature: String, CaseIterable, Sendable {
    case manualRecords
    case csvExport
    case deleteAllData
    case appLock
    case iCloudSync
}
