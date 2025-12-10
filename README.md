[![swift-version](https://img.shields.io/badge/swift-6.2-ea7a50.svg?logo=swift&logoColor=white)](https://developer.apple.com/swift/)
[![xcode-version](https://img.shields.io/badge/xcode-26.2-50ace8.svg?logo=xcode&logoColor=white)](https://developer.apple.com/xcode/)
[![spm-ready](https://img.shields.io/badge/spm-ready-b68f6a.svg?logo=gitlfs&logoColor=white)](https://developer.apple.com/documentation/xcode/swift-packages)
[![platforms](https://img.shields.io/badge/platforms-iOS%20%7C%20iPadOS%20%7C%20macOS%20%7C%20Mac%20Catalyst%20%7C%20tvOS%20%7C%20visionOS-lightgrey.svg?logo=apple&logoColor=white)](https://en.wikipedia.org/wiki/List_of_Apple_operating_systems)
[![license](https://img.shields.io/badge/license-MIT-67ac5b.svg?logo=googledocs&logoColor=white)](https://en.wikipedia.org/wiki/MIT_License)
[![release](https://github.com/thatfactory/gcoverseer/actions/workflows/release.yml/badge.svg)](https://github.com/thatfactory/gcoverseer/actions/workflows/release.yml)

# GCOverseer 🎮
[AsyncSequence](https://developer.apple.com/documentation/swift/asyncsequence) wrapper around Apple's [Game Controller Framework](https://developer.apple.com/documentation/gamecontroller).

## Usage Examples

### Handle Controller Connection/Disconnection Events
```swift
import SpriteKit
import GCOverseer

class GameScene: SKScene {

    let gcOverseer = GCOverseer()

    override init(size: CGSize) {
        super.init(size: size)

        // 🎮 Handle game controller connection/disconnection asynchronously
        Task {
            for await controllerEvent in gcOverseer.connectionStream {
                switch controllerEvent {
                case .connected:
                    print("A game controller connected.")
                case .disconnected:
                    print("A game controller disconnected.")
                }
            }
        }
    }
}
```
## Available Properties
Property | Description
-------- | -----------
`var connectionStream: AsyncStream<GameControllerEvent>` | Provides an `AsyncSequence` for observing connect/disconnect events of game controllers.
`var controllers: [GCController]` | Returns all controllers connected to the device. E.g. *DualShock*, *Xbox*, *Siri Remote* controllers, etc.

## Available APIs
API | Description
--- | -----------
`extendedGamepadControllers()` | Returns all controllers supporting the `extendedGamepad` profile connected to the device. E.g., *DualShock*, *Xbox* controllers, etc.
`dualShockControllers()` | Returns all *DualShock* controllers that are connected to the device.
`dualSenseControllers()` | Returns all *DualSense* controllers that are connected to the device.
`xboxControllers()` | Returns all *Xbox* controllers that are connected to the device.
`microGamepadControllers()` | Returns all controllers supporting the `microGamepad` profile connected to the device. E.g. Apple's *Siri Remote*.
`motionControllers()` | Returns all controllers supporting the `motion` profile connected to the device.
`controllerFor(playerIndex:)` | Returns the controller for the player 1, player 2, etc.
`enableLogging() / disableLogging()` | Enables/disables logging output.

## Integration
### Xcode
Use Xcode's [built-in support for SPM](https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app).

*or...*

### Package.swift
In your `Package.swift`, add `GCOverseer` as a dependency:
```swift
dependencies: [
    .package(
        url: "https://github.com/thatfactory/gcoverseer",
        from: "0.1.0"
    )
]
```

Associate the dependency with your target:
```swift
targets: [
    .target(
        name: "YourTarget",
        dependencies: [
            .product(
                name: "GCOverseer",
                package: "gcoverseer"
            )
        ]
    )
]
```

Run: `swift build`
