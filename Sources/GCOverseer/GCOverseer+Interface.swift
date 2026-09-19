public import GameController

/// Public APIs go here.
extension GCOverseer {
    /// Returns all controllers supporting the `extendedGamepad` profile that are connected to the device. E.g. *DualShock*, *Xbox* controllers, etc.
    ///
    /// The controls associated with the extended gamepad profile include the following:
    /// - Two shoulder buttons.
    /// - Two triggers.
    /// - Four face buttons arranged in a diamond pattern.
    /// - One directional pad.
    /// - Two thumbsticks.
    ///
    /// See: https://developer.apple.com/documentation/gamecontroller/gcextendedgamepad
    ///
    /// Notice: the `gamepad` type is deprecated and it's now included in the `extendedGamepad` type, as
    /// *... a controller supporting the Extended Gamepad profile for example supports the Gamepad profile and more...*.
    ///
    /// - Returns: All the connected controllers supporting the `extendedGamepad` profile.
    public func extendedGamepadControllers() -> [GCController] {
        let controllers = controllers.filter { $0.extendedGamepad != nil }
        log(information: "Number of extended controllers: \(controllers.count)", category: .controller)
        return controllers
    }

    /// Returns all *DualShock* controllers that are connected to the device.
    ///
    /// - Returns: All the connected controllers with `physicalInputProfile` matching `GCDualShockGamepad`.
    public func dualShockControllers() -> [GCController] {
        let controllers = controllers.filter {
            $0.physicalInputProfile.isKind(of: GCDualShockGamepad.self)
        }
        log(information: "Number of DualShock controllers: \(controllers.count)", category: .controller)
        return controllers
    }

    /// Returns all *DualSense* controllers that are connected to the device.
    ///
    /// - Returns: All the connected controllers with `physicalInputProfile` matching `GCDualSenseGamepad`.
    public func dualSenseControllers() -> [GCController] {
        let controllers = controllers.filter {
            $0.physicalInputProfile.isKind(of: GCDualSenseGamepad.self)
        }
        log(information: "Number of DualSense controllers: \(controllers.count)", category: .controller)
        return controllers
    }

    /// Returns all *Xbox* controllers that are connected to the device.
    ///
    /// - Returns: All the connected controllers with `physicalInputProfile` matching `GCXboxGamepad`.
    public func xboxControllers() -> [GCController] {
        let controllers = controllers.filter { $0.physicalInputProfile.isKind(of: GCXboxGamepad.self) }
        log(information: "Number of Xbox controllers: \(controllers.count)", category: .controller)
        return controllers
    }

    /// Returns all controllers supporting the `microGamepad` profile that are connected to the device. E.g. Apple's *Siri Remote*.
    ///
    /// The controls associated with the micro gamepad profile include the following:
    /// - Two digital face buttons (A and X).
    /// - One analog directional pad (D-pad), implemented as a touchpad.
    ///
    /// Controllers that implement the micro gamepad profile can be used in either landscape or portrait orientations. By default, these devices are usually used in
    /// portrait mode.
    ///
    /// See: https://developer.apple.com/documentation/gamecontroller/gcmicrogamepad
    ///
    /// - Returns: All the connected controllers supporting the `microGamepad` profile.
    public func microGamepadControllers() -> [GCController] {
        let controllers = controllers.filter { $0.microGamepad != nil }
        log(information: "Number of micro controllers: \(controllers.count)", category: .controller)
        return controllers
    }

    /// Returns all controllers supporting the `motion` profile that are connected to the device.
    ///
    /// The `motion` profile provides information about the orientation and motion of the controller.
    ///
    /// See: https://developer.apple.com/documentation/gamecontroller/gcmotion
    ///
    /// - Returns: All the connected controllers supporting the `microGamepad` profile.
    public func motionControllers() -> [GCController] {
        let controllers = controllers.filter { $0.motion != nil }
        log(information: "Number of motion controllers: \(controllers.count)", category: .controller)
        return controllers
    }

    /// Returns the controller for the player 1, player 2, etc.
    ///
    /// - Parameter playerIndex: The player number that may have a controller associated with. E.g.: `.index1`
    /// - Returns: An optional `GCController` associated with the given player number (`GCControllerPlayerIndex`).
    public func controllerFor(playerIndex: GCControllerPlayerIndex) -> GCController? {
        let controller = controllers.first(where: { $0.playerIndex == playerIndex })
        let controllerInfo = String(describing: controller)
        let playerNumber = playerIndex.rawValue + 1
        log(information: "Player \(playerNumber) controller: \(controllerInfo)", category: .controller)
        return controller
    }
}
