import Foundation
import os

/// Structured logs keep launch, capture, and persistence failures searchable in Console.app.
enum AppLog {
    private static let logger = Logger(subsystem: "com.icopy.app", category: "runtime")

    static func info(_ event: String, _ fields: [String: String] = [:]) {
        logger.info("\(format(event: event, fields: fields), privacy: .public)")
    }

    static func error(_ event: String, _ fields: [String: String] = [:]) {
        logger.error("\(format(event: event, fields: fields), privacy: .public)")
    }

    private static func format(event: String, fields: [String: String]) -> String {
        let extras = fields
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: " ")
        return extras.isEmpty ? event : "\(event) \(extras)"
    }
}
