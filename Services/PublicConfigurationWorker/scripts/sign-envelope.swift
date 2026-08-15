#!/usr/bin/env swift

import CryptoKit
import Foundation

enum SigningFailure: Error, CustomStringConvertible {
    case usage
    case invalidArgument(String)
    case invalidPrivateKey

    var description: String {
        switch self {
        case .usage:
            return "usage: sign-envelope.swift <private-key.raw> <config-version> <issued-at> <expires-at> <true|false>"
        case let .invalidArgument(argument):
            return "invalid argument: \(argument)"
        case .invalidPrivateKey:
            return "private key must be exactly one raw Ed25519 private key"
        }
    }
}

private let timestampPattern = try NSRegularExpression(
    pattern: #"^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$"#
)

private func requireTimestamp(_ value: String) throws -> Date {
    let range = NSRange(value.startIndex..<value.endIndex, in: value)
    guard timestampPattern.firstMatch(in: value, range: range)?.range == range else {
        throw SigningFailure.invalidArgument(value)
    }
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
    guard let date = formatter.date(from: value) else {
        throw SigningFailure.invalidArgument(value)
    }
    return date
}

do {
    let arguments = CommandLine.arguments
    guard arguments.count == 6 else { throw SigningFailure.usage }

    let privateKeyURL = URL(fileURLWithPath: arguments[1])
    guard let configVersion = UInt64(arguments[2]), configVersion > 0 else {
        throw SigningFailure.invalidArgument(arguments[2])
    }
    let issuedAt = try requireTimestamp(arguments[3])
    let expiresAt = try requireTimestamp(arguments[4])
    let validityInterval = expiresAt.timeIntervalSince(issuedAt)
    guard validityInterval > 0, validityInterval <= 7 * 24 * 60 * 60 else {
        throw SigningFailure.invalidArgument("validity window")
    }
    guard let enabled = Bool(arguments[5]) else {
        throw SigningFailure.invalidArgument(arguments[5])
    }

    let privateKeyData = try Data(contentsOf: privateKeyURL)
    guard privateKeyData.count == 32 else { throw SigningFailure.invalidPrivateKey }
    let privateKey = try Curve25519.Signing.PrivateKey(rawRepresentation: privateKeyData)

    // This is the signer-owned canonical form. The client verifies these exact bytes before
    // decoding and therefore never needs to reproduce this serialization.
    let payload = "{\"configVersion\":\(configVersion),\"expiresAt\":\"\(arguments[4])\",\"issuedAt\":\"\(arguments[3])\",\"presentation\":{\"proValueTriggersEnabled\":\(enabled)},\"schemaVersion\":1}"
    let payloadData = Data(payload.utf8)
    let signature = try privateKey.signature(for: payloadData)
    let envelope = "{\"algorithm\":\"Ed25519\",\"keyID\":\"mb-config-2026-01\",\"payloadBase64\":\"\(payloadData.base64EncodedString())\",\"signatureBase64\":\"\(signature.base64EncodedString())\"}"
    print(envelope)
} catch {
    FileHandle.standardError.write(Data("sign-envelope: \(error)\n".utf8))
    exit(2)
}
