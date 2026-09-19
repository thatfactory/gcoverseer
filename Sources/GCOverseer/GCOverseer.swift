import Foundation
public import GameController

/// Observes MFI or Remote Controllers in the area. Sets them up.
public class GCOverseer: GCOverseerProtocol, @unchecked Sendable {
    // MARK: - Properties

    /// Provides an `AsyncSequence` for observing connect/disconnect events of game controllers.
    public var connectionStream: AsyncStream<GameControllerEvent> {
        createConnectionStream()
    }

    /// Returns all controllers that are connected to the device. E.g. *DualShock*, *Xbox*, *Siri Remote* controllers, etc.
    ///
    /// The returned controllers support any gamepad profile: `extendedGamepad`, `microGamepad`, `motion`, etc.
    ///
    /// - Returns: All controllers that are connected to the device.
    public var controllers: [GCController] = GCController.controllers() {
        didSet { logConnectedControllers() }
    }

    // MARK: Internal

    /// Enables / disables logging output to both *Xcode's Console* and the macOS *Console app*. `true` by default.
    internal var isLoggingEnabled: Bool = true

    // MARK: Private

    private let notificationCenter = NotificationCenter.default
    private let controllersProvider: () -> [GCController]

    // MARK: - Lifecycle

    /// Creates an instance of the `GCOverseer` and starts observing game controller notifications.
    ///
    /// Observed `GCController` notifications:
    ///  - `.GCControllerDidConnect`
    ///  - `.GCControllerDidDisconnect`
    ///
    /// - Parameter controllersProvider: The source for the `controllers` property. Allows for mocking during tests.
    /// Defaults to `GCController.controllers`.
    public init(controllersProvider: @escaping () -> [GCController] = GCController.controllers) {
        self.controllersProvider = controllersProvider
        self.controllers = controllersProvider()
    }
}

// MARK: - Private

extension GCOverseer {
    /// Creates an `AsyncStream` that emits `true` when a controller connects
    /// and `false` when a controller disconnects.
    ///
    /// This stream listens to the following notifications in real-time:
    /// - `.GCControllerDidConnect`
    /// - `.GCControllerDidDisconnect`
    ///
    /// The stream continues running indefinitely until explicitly terminated or deallocated.
    ///
    /// - Returns: An `AsyncStream<GameControllerEvent>` representing the connection state changes.
    fileprivate func createConnectionStream() -> AsyncStream<GameControllerEvent> {
        AsyncStream { continuation in
            // Handle `.GCControllerDidConnect` notifications
            let connectTask = Task {
                for await _ in notificationCenter.notifications(named: .GCControllerDidConnect) {
                    await updateControllers()
                    continuation.yield(.connected)
                }
            }

            // Handle `.GCControllerDidDisconnect` notifications
            let disconnectTask = Task {
                for await _ in notificationCenter.notifications(named: .GCControllerDidDisconnect) {
                    await updateControllers()
                    continuation.yield(.disconnected)
                }
            }

            // Cancel tasks when the stream is terminated
            continuation.onTermination = { _ in
                connectTask.cancel()
                disconnectTask.cancel()
            }
        }
    }

    @MainActor
    fileprivate func updateControllers() {
        controllers = controllersProvider()
    }

    fileprivate func logConnectedControllers() {
        guard isLoggingEnabled else { return }
        log(information: "Number of connected controllers: \(controllers.count)", category: .controller)
        for (offset, controller) in controllers.enumerated() {
            let productCategory = String(describing: controller.productCategory)
            log(information: "Controller \(offset + 1): \(productCategory)", category: .controller)
        }
    }
}
