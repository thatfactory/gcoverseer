import Foundation
import AppLogger

/// `GCOverseer` logging categories to further distinguish the running parts of the package.
///
/// Refer to: https://developer.apple.com/documentation/os/logging
public enum GCOverseerLoggingCategory: String {
    case controller     = "GCOverseer_Controller"
    case notification   = "GCOverseer_Notification"
}

// MARK: - Interface

public extension GCOverseer {

    // MARK: Enable / Disable Logging

    /// Enables logging information via `AppLogger`.
    ///
    /// When logging is enabled, the output will be available in *Xcode's Console* or
    /// in the *macOS Console app*.
    ///
    /// In the **macOS Console app**, you can filter GCOverseer's output by
    /// `SUBSYSTEM`: `com.thatfactory.GCOverseer`.
    func enableLogging() {
        isLoggingEnabled = true
    }

    /// Disables logging information via `AppLogger`.
    func disableLogging() {
        isLoggingEnabled = false
    }
}

// MARK: - Internal

internal extension GCOverseer {

    func log(notification: Notification) {
        log(information: "Received game controller notification: \(notification)", category: .notification)
    }

    /// Logs the given `String` information via `AppLogger`.
    ///
    /// - Parameters:
    ///   - information: The `String` to be logged.
    ///   - category: A member of the `GCOverseerLoggingCategory` enum.
    func log(information: String, category: GCOverseerLoggingCategory) {
        guard isLoggingEnabled else { return }
        let subsystem = "com.thatfactory.GCOverseer"
        let logger = AppLogger(subsystem: subsystem, category: category.rawValue)
        logger.log(information)
    }
}
