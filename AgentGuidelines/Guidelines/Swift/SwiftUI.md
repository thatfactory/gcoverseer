# SwiftUI

Use official Apple documentation and Xcode's current SwiftUI skills for API-specific behavior. This guide captures stable project policy rather than reproducing the current SDK's API catalog.

## View structure

- Put SwiftUI dynamic properties such as `@Environment`, `@Query`, `@State`, and `@Binding` before ordinary stored `let` and `var` properties. Keep injected environment dependencies before locally owned state when both are present.
- Keep a parent view focused on composition.
- Model meaningful sections such as headers, lists, metadata, sidebars, and footers as separate `View` types with narrow inputs.
- Keep each independently meaningful `View` in its own file, including private supporting views. Give every view its own deterministic preview when the required dependencies can be represented safely; when they cannot, document the concrete limitation in the handoff.
- Do not extract sections into computed `some View` properties merely to shorten `body`; computed properties remain in the parent's invalidation boundary.
- Tiny fragments reused within one body may use a small helper when they have no independent state, input, or invalidation story.
- Keep view initializers cheap. Do not decode data, access files, build large structures, or allocate formatters in `init`.
- Avoid a single-child `Group` that adds no structure or behavior.

## Data flow

- Pass a view only the value-type fields it reads or forwards.
- Use private `@State` for state genuinely owned by the view.
- Use `Binding` when a child edits state owned by its parent.
- In non-Redux designs, prefer `@Observable` to `ObservableObject` for new shared reference models when platform support allows it.
- In Redux applications, keep durable app and domain state in Redux. Do not introduce an observable view model as a parallel source of truth.
- Make observable stored-property types `Equatable` when equality matches their semantics, allowing redundant assignments to avoid unnecessary invalidation.
- Isolate side effects in `.task`, `.onChange`, actions, or explicit async functions rather than hiding them in rendering logic.
- Use the current `.onChange(of:)` form and read the updated captured value when the previous value is unnecessary.
- Avoid closure-based bindings when a writable key-path binding expresses the same relationship.

With SDKs where `@State` is a macro, do not give a state property a declaration default and then attempt to replace that value in `init`. Choose one initialization source and verify current compiler guidance when migrating existing code.

## Collections and identity

- Give `ForEach`, `List`, `Table`, and similar data-driven views stable, unique element identity.
- Prefer meaningful `Identifiable` conformance when the model has natural identity.
- Do not use collection indices, offsets, or transient UUIDs as identity for mutable collections.
- Do not sort, filter, or map large collections inline inside a frequently evaluated view body. Prepare the collection before rendering.
- Use a dedicated row `View` for meaningful rows and pass it narrow inputs.
- Avoid `AnyView` in collection rows.

## Modifiers and environment

- Preserve stable view identity. Prefer modifiers whose values change over conditionally adding and removing modifier branches.
- Do not place high-frequency values in the environment when explicit narrow inputs work.
- Avoid unstable environment defaults and freshly created closures that invalidate large subtrees.
- Do not hide unstable values behind fake `Equatable` implementations.

## Modern APIs and scope

- Do not introduce APIs that current Xcode documentation identifies as deprecated or soft-deprecated.
- When fixing a feature, modernize only the code directly required by the task unless the user requests a broader migration.
- For SDK-sensitive features, search current Apple documentation through Xcode rather than relying on remembered signatures.
- Apply the current Xcode SwiftUI skill when a new SDK changes source behavior, builder resolution, state initialization, or modifier availability.

## Previews

- Put previews at the end of the file under `// MARK: - Preview`.
- Use `#Preview`.
- Use `@Previewable` for interactive preview state when appropriate.
- Keep preview fixtures deterministic and lightweight.
- After UI changes, follow [Xcode MCP and visual verification](../Xcode/MCP.md) when runtime verification adds meaningful confidence.

## Localization

Follow [Localization](../Localization.md) for user-facing text, layout direction, formatting, and package bundles.
