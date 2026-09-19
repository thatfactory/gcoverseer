# Redux Architecture

Use this guide for applications that explicitly adopt the ThatFactory Redux architecture. Do not apply it to reusable packages or repositories whose local instructions choose another architecture.

## Principles

- Keep one application store as the source of truth for durable application state.
- Views read state and dispatch actions; they do not mutate application state directly.
- Actions describe events or intent, not implementation steps.
- Reducers are pure and synchronous.
- Middleware performs asynchronous work and other side effects.
- Services wrap external frameworks, packages, persistence, clocks, APIs, and system capabilities.
- Selectors derive shared domain information from state.
- Render-ready value models live under `Model/`; SwiftUI `View` types stay under `View/`.
- Every side-effect result returns to the store as an action before it changes state.

## Data flow

```text
                         await dispatch(Action)
    +--------------+ --------------------------> +-----------+
    | SwiftUI view |                             | Store     |
    |              | <-------------------------- |           |
    +--------------+      observable state       | 1. Reducer|
                                                 | 2. Middle-|
                                                 |    ware   |
                                                 +-----+-----+ <---------------+
                                                       |                       |
                                                       | side effect           |
                                                       v                       |
                                                +--------------+               |
                                                | Service      |               |
                                                | package/API  |               |
                                                +------+-------+               |
                                                       |                       |
                                                       | Action?               |
                                                       +-----------------------+
```

The store reduces the original action first, then awaits middleware and sequentially dispatches returned follow-up actions. Keep ordering observable and deterministic. Do not start unstructured work inside reducers or hide state changes inside services.

## Store

Use one observable store as the source of truth and inject it at the application root. The canonical Store requires `Default Actor Isolation` set to `MainActor` and `nonisolated(nonsending) By Default` set to `Yes` in every application and test target that compiles or exercises it. New projects copy [the Store template](../../Templates/Store.swift) as is; do not add redundant isolation annotations or change its dispatch ordering, observation exclusions, or documentation.

Dispatch is asynchronous and ordered:

1. Reduce the original action.
2. Capture the resulting state.
3. Await each registered middleware with that state and action.
4. Collect returned actions.
5. Dispatch follow-up actions sequentially.

Use only `await store.dispatch(_:)`. Do not add a fire-and-forget dispatch API.

## Dependency composition

Create one application-owned `DependencyContainer` that constructs and retains services, persistence, providers, and other side-effect dependencies. Create the container before the store, restore synchronous initial state through its dependencies, and pass the container to `makeMiddlewares(_:)`.

```swift
@main
struct ExampleApp: App {
    @State private var dependencies: DependencyContainer
    @State private var store: AppStore

    init() {
        let dependencies = DependencyContainer()
        let store = AppStore(
            initialState: dependencies.restoredAppState(),
            middlewares: makeMiddlewares(dependencies),
            reducer: appReducer
        )
        _dependencies = State(initialValue: dependencies)
        _store = State(initialValue: store)
    }
}
```

Keep application bootstrap responsible for composition, not feature behavior. Do not construct individual services directly in the app after a dependency container exists.

## Canonical physical folders

These are filesystem folders, not Xcode groups. New single-application repositories use this structure by default:

```text
<AppName>/
|-- App/
|-- Model/
|-- Redux/
|   |-- Action/
|   |-- Middleware/
|   |-- Reducer/
|   |-- Selector/
|   |-- State/
|   `-- Store.swift
|-- Services/
|-- Tools/
|-- View/
`-- Resources/

<AppName>Tests/
|-- Mocks/
|-- Model/
|-- Redux/
|   |-- Action/
|   |-- Middleware/
|   |-- Reducer/
|   |-- Selector/
|   `-- State/
|-- Services/
|-- Tools/
`-- View/
```

A multi-target application may use a shared source root such as `Shared/Redux/` and target-specific roots such as `<AppName>/View/`. Its root `AGENTS.md` must provide a concrete path map:

```markdown
| Role | Physical folder |
|---|---|
| Redux | `Shared/Redux/` |
| Models | `Shared/Model/` |
| Services | `Shared/Services/` |
| Views | `<AppName>/View/` |
| Unit tests | `<AppName>Tests/` |
```

Once mapped, use the same component layout beneath those roots. Never guess a destination or create a parallel folder spelling such as `Views/` when the project declares `View/`.

## Placement rules

### App

Put application bootstrap, app delegates, scene definitions, store construction, environment wiring, and root configuration in `App/`. Do not place feature logic there.

### Model

Put domain and presentation values in `Model/`. Models describe data, state, configuration, categories, or render-ready values; their primary responsibility is not executing an algorithm or coordinating side effects. Keep each important type in a focused file. Do not hide response models, payloads, logging categories, levels, or other values inside action or service folders merely because only one caller currently uses them.

When several models are familiar parts of one domain, group them by that domain:

```text
Model/
|-- Camera/
|-- Face/
`-- Logging/
```

Use names that help a reader reason about the domain. Keep `Model/` flat while a domain has only one file; do not create a folder for every type.

### Action

Put domain action enums in `Redux/Action/`. Use a root routing action that wraps focused feature actions:

```swift
enum AppAction: Equatable {
    case account(AccountAction)
    case navigation(NavigationAction)
}
```

Name actions after what happened or what the user requested. Keep cases in the order required by the project's Swift style guide.

Declare `AppAction` and each domain action in separate files. `AppAction.swift` contains the root routing action only; do not append logging models, categories, feature actions, or unrelated supporting declarations to it.

Every production file under `Redux/Action/` must define an action. Values carried by actions, including categories, levels, payloads, and capability descriptions, belong in `Model/`.

### State

Put the root state and domain sub-states in `Redux/State/`. Prefer focused value types with compiler-synthesized conformances. Add a new sub-state for a durable domain instead of folding unrelated values into an existing feature.

State stores durable facts. Avoid storing values that are cheap, deterministic derivations unless caching is an explicit measured requirement.

Sub-states should conform to `Equatable` and `Codable`; add `Sendable` when their values and concurrency boundaries require it. Keep root state and root actions for genuine cross-domain behavior. Keep domain action cases descriptive of intent or outcomes and route them through the root action.

Declare `AppState` and each domain sub-state in separate files. `AppState.swift` contains the root state only.

### Reducer

Put reducer functions in `Redux/Reducer/`. A reducer receives state and an action and returns new state. It must not:

- perform asynchronous work;
- call services or packages;
- read the clock or generate random values;
- access files, databases, network clients, or system APIs;
- dispatch actions;
- trigger UI behavior directly.

Use the smallest state and action inputs that correctly express the transition. Root reducers compose domain reducers.

Declare the root reducer and each domain reducer in separate files. `AppReducer.swift` contains only root composition. Every production file under `Redux/Reducer/` must define a reducer; move events, capability values, policies, and other supporting domain types to `Model/` or their own appropriate component.

### Middleware

Put middleware in `Redux/Middleware/`. Middleware may call injected services and return a follow-up action. It must not mutate store state directly.

Inject services, providers, managers, clocks, and identifier generators through parameters so middleware tests remain deterministic. Register middleware in one root composition file such as `AppMiddlewares.swift`. Reducers own every state mutation.

Every production file under `Redux/Middleware/` must define or compose middleware. A helper, closure signature, or type alias used only by one middleware stays in that middleware file and should be private when its test seam and call sites allow it. Do not create a standalone middleware file for a declaration that is not middleware.

Create a feature subfolder only when a domain has multiple middleware files:

```text
Redux/Middleware/Account/
|-- AccountMiddleware.swift
|-- LoadAccountMiddleware.swift
`-- UpdateAccountMiddleware.swift
```

### Selector

Put pure, reusable domain extraction in `Redux/Selector/`. A selector may answer questions such as the current signed-in account, whether a capability is enabled, or which domain items are visible.

Do not put SwiftUI types, colors, images, localized display strings, or render-ready screen state in selectors.

### Services

Put focused external-boundary abstractions in `Services/`. Services wrap APIs, persistence, packages, frameworks, sensors, system features, and other impure operations. Keep this folder flat while a capability has only one file; introduce a familiar capability folder such as `Services/FaceService/` or `Services/CalibrationService/` when that capability genuinely requires several related files. Middleware calls services; views and reducers do not.

Prefer a protocol or otherwise injectable contract when a service must be replaced in tests. Keep transport-specific details behind the service boundary.

Keep a supporting delegate, adapter, or helper beside its service when only that capability uses it. Local ownership is clearer than promoting a service-private framework bridge to a global `Tools/` folder.

Views dispatch actions; middleware calls services. Views never call a service directly for Redux-owned behavior.

### Tools

Put specialized algorithms, accumulators, framework adapters, and genuinely cross-cutting implementation utilities in `Tools/`. This is not a miscellaneous folder. A type belongs here when its primary responsibility is performing computation or implementing technical behavior rather than describing values or owning an external capability. Feature-only helpers stay beside that feature. Keep `Tools/` flat until one familiar topic requires several files, then group them under a domain folder such as `Tools/Face/`.

### View

Put SwiftUI screens and components in `View/`. A new view belongs to the feature it renders, not in Redux. Reusable visual components may use `View/Generic/` or another explicitly declared shared-view folder. Keep `View/` flat while it has only a few files; introduce `View/<Feature>/` when a familiar feature genuinely has several views.

Render-facing value types that do not conform to `View` are presentation models and live under `Model/<Feature>/`:

```text
Model/Account/
`-- AccountViewState.swift

View/Account/
`-- AccountView.swift
```

Keep a tiny private projection beside its consuming view only when it is an implementation detail rather than a named value type.

### Resources

Put catalogs, assets, preview assets, configuration resources, and test plans in `Resources/` or the concrete resource folders declared locally. Production targets must not depend on test fixtures.

## File organization

- Prefer one primary concern per file.
- When a feature has several files of one Redux component, introduce a feature subfolder under that component.
- Group several related models, services, or tools by a familiar domain or capability so readers can reason about them together.
- Keep root routing and composition at the component root; keep feature implementations below it.
- File names match their primary type or clearly describe their primary pure function.
- Do not introduce artificial enum namespaces solely to satisfy filename lint rules.
- Mirror production organization in tests so components are easy to locate.
- Do not keep empty component folders. Add `Selector/`, `Tools/`, feature folders, or mirrored test folders only when they contain a real implementation.

## SwiftUI connection

Create and inject the store at the application root. Views observe only the state they need and dispatch actions for application events.

Keep view-local interaction state in private `@State` when it is not durable application state. Do not create an `@Observable` view model as a second source of truth for Redux-owned state.

Prefer narrow view inputs or a focused view-state projection. This aligns SwiftUI invalidation with the smallest useful surface while Redux remains the durable source of truth.

## Adding a feature

| Step | Change | Default destination |
|---|---|---|
| 1 | Define domain models | `Model/` or `Model/<Feature>/` when several are familiar |
| 2 | Define feature state | `Redux/State/<Feature>State.swift` |
| 3 | Add it to root state | `Redux/State/AppState.swift` |
| 4 | Define feature actions | `Redux/Action/<Feature>Action.swift` |
| 5 | Route them through the root action | `Redux/Action/AppAction.swift` |
| 6 | Implement the reducer | `Redux/Reducer/<Feature>Reducer.swift` |
| 7 | Compose the reducer | `Redux/Reducer/AppReducer.swift` |
| 8 | Add side effects if needed | `Redux/Middleware/` or a feature folder when several |
| 9 | Register middleware | `Redux/Middleware/AppMiddlewares.swift` |
| 10 | Add external boundaries if needed | `Services/` or `Services/<Capability>/` when several |
| 11 | Add shared domain selectors if needed | `Redux/Selector/<Feature>/` |
| 12 | Build the feature UI | `View/` or `View/<Feature>/` when several are familiar |
| 13 | Mirror tests | `<AppName>Tests/` |

Skip components that provide no value. A state-only transition needs no middleware; a screen-only projection does not need a Redux selector.

## Testing responsibilities

- Reducer tests provide state plus an action and assert the returned state.
- Selector tests provide state and assert the derived domain result.
- Middleware tests inject mocks, execute an action, and assert the returned follow-up action.
- Service tests exercise the external boundary without involving views.
- Presentation-model tests live under the matching `<AppName>Tests/Model/<Feature>/` folder, or the consumer-mapped test root.
- Test mocks and fixture data live under the test target's `Mocks/` folder.

Follow [Unit testing](../Testing/UnitTesting.md) for framework and concurrency conventions.
