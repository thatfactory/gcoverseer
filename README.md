<p align="center">
  <a href="https://developer.apple.com/swift/"><img alt="Swift Version" src="https://img.shields.io/badge/Swift-6.4-ea7a50.svg?logo=swift&logoColor=white"></a>
  <a href="https://developer.apple.com/xcode/"><img alt="Xcode Version" src="https://img.shields.io/badge/Xcode-27-50ace8.svg?logo=xcode&logoColor=white"></a>
  <a href="https://en.wikipedia.org/wiki/List_of_Apple_operating_systems"><img alt="Platforms" src="https://img.shields.io/badge/Platforms-iOS%2026%2B%20%7C%20macOS%2026%2B%20%7C%20tvOS%2026%2B-lightgrey.svg?logo=apple&logoColor=white"></a>
  <a href="https://developer.apple.com/documentation/xcode/swift-packages"><img alt="SPM" src="https://img.shields.io/badge/SPM-ready-b68f6a.svg?logo=gitlfs&logoColor=white"></a>
  <a href="https://en.wikipedia.org/wiki/MIT_License"><img alt="License" src="https://img.shields.io/badge/License-MIT-67ac5b.svg?logo=googledocs&logoColor=white"></a>
  <a href="https://github.com/thatfactory/gcoverseer/actions/workflows/ci.yml"><img alt="CI" src="https://github.com/thatfactory/gcoverseer/actions/workflows/ci.yml/badge.svg"></a>
  <a href="https://github.com/thatfactory/gcoverseer/actions/workflows/release.yml"><img alt="Release" src="https://github.com/thatfactory/gcoverseer/actions/workflows/release.yml/badge.svg"></a>
</p>

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
        from: "0.1.2"
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
