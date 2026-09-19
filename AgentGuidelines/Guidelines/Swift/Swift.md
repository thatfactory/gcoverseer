# Swift

## Language and SDK guidance

- Use the Swift language and platform versions declared by the consumer repository.
- Use current official Apple documentation through Xcode documentation search when API behavior or availability matters.
- Use current `swift-collections` documentation when working with its collection types.
- Import the module that owns an API. For example, APIs specific to `OrderedCollections` require `import OrderedCollections`.
- Maintain a zero-warning policy for warnings introduced by the change.
- For Xcode projects, apply the shared [project-settings baseline](../Xcode/ProjectSettings.md) at project level so every application and test target inherits it.

## Implementation

- Prefer concise, readable, maintainable code over clever abstractions.
- Prefer structured concurrency with `async`/`await`, task groups, actors, and `Task` where appropriate.
- Do not introduce `DispatchQueue.async` as a substitute for structured concurrency.
- Respect strict concurrency and the repository's default actor isolation.
- Prefer compiler-synthesized `Codable`, `Equatable`, `Hashable`, and `Sendable` conformances when their semantics are correct.
- Write manual serialization, equality, or hashing only when a documented requirement prevents synthesis.
- Import the narrowest framework the file requires. Models should not import SwiftUI merely to gain transitive access to Foundation types.
- A new Swift file must contain at least one required import; use `import Foundation` when it otherwise needs no module.

## State and isolation

- Treat actor isolation as part of an API's contract.
- When application and test targets use MainActor default isolation, infer isolated conformances, and `nonisolated(nonsending)` by default, omit annotations that merely restate those effective settings. Verify every affected target before removing annotations.
- `nonisolated(nonsending)` by default governs how nonisolated asynchronous functions run; it does not make synchronous types or conformances nonisolated. Keep explicit `nonisolated` where a value conformance must satisfy a `Sendable` generic contract, a synchronous API is called from a `@Sendable` closure, or another compiler-verified actor boundary requires it.
- Keep an explicit isolation annotation when a declaration intentionally differs from the target default, crosses an actor boundary, belongs to reusable code compiled under different defaults, or implements a documented compiler workaround.
- Use `Sendable` where values cross concurrency domains and their stored values support it.
- Avoid adding `@MainActor` to tests or domain types merely to silence a diagnostic. Resolve the actual isolation boundary.

## C-family interoperability

When a target exposes or consumes C, Objective-C, or C++ interfaces, use Xcode's current `adopt-c-bounds-safety` skill and official compiler documentation for that scoped work. Do not apply C bounds-safety rules to pure Swift targets.

## Documentation

Follow [Swift style](SwiftStyle.md) for source formatting and [Documentation](../Documentation.md) for DocC and project-level guidance.
