import Foundation
import Observation

typealias AppStore = Store<AppState, AppAction>
typealias StateType = Equatable & Sendable & Codable
typealias ActionType = Equatable & Sendable
typealias Reducer<State: StateType, Action: ActionType> = (State, Action) -> State
typealias Middleware<State: StateType, Action: ActionType> = (State, Action) async -> Action?

/// A class representing the state management store for the app.
///
/// The `Store` class is responsible for managing the state of the application and handling actions
/// through a reducer and optional middlewares. It's an `@Observable`, which allows SwiftUI views
/// to observe state changes. This template requires every application and test target that compiles
/// or exercises it to set `Default Actor Isolation` to `MainActor` and
/// `nonisolated(nonsending) By Default` to `Yes`. These settings keep middleware on the main actor
/// without redundant isolation annotations.
///
/// - Parameters:
///   - State: The type representing the state of the application.
///   Must conform to `Equatable & Sendable & Codable`.
///   - Action: The type representing actions that can be dispatched to the store.
///   Must conform to `Equatable & Sendable`.
///
/// Example usage:
/// ```
/// let store = AppStore(initialState: AppState(), reducer: appReducer)
/// await store.dispatch(.someAction)
/// ```
@Observable final class Store<State: StateType, Action: ActionType> {
    private(set) var state: State

    @ObservationIgnored
    private let middlewares: [Middleware<State, Action>]

    @ObservationIgnored
    private let reducer: Reducer<State, Action>

    init(
        initialState: State,
        middlewares: [Middleware<State, Action>] = [],
        reducer: @escaping Reducer<State, Action>
    ) {
        self.state = initialState
        self.middlewares = middlewares
        self.reducer = reducer
    }
}

// MARK: - Dispatcher

extension Store {
    /// Dispatches an action, awaiting the entire middleware chain before returning.
    ///
    /// The reducer runs first, then every middleware executes sequentially against the same
    /// post-reducer state snapshot; any follow-up actions they return are dispatched
    /// recursively (depth-first) and awaited too. This guarantees:
    /// - Middleware executes sequentially and completes before returning.
    /// - Nested actions dispatched by middleware are also awaited.
    /// - State updates are fully processed before subsequent operations.
    /// - Network requests don't overlap or time out due to race conditions.
    ///
    /// Awaiting also keeps state mutation off the synchronous SwiftUI update/layout pass,
    /// avoiding the re-entrant `@Observable` mutation that crashes on iOS 26 (recursive
    /// layout / `SIGTRAP`).
    ///
    /// For fire-and-forget dispatching from a synchronous context (e.g. a `Button` action,
    /// `onAppear` / `onChange`, app startup), wrap the call in a `Task`:
    /// ```swift
    /// Task { await store.dispatch(action) }
    /// ```
    /// When several actions must keep their relative order, dispatch them from a single `Task`
    /// so they can't interleave:
    /// ```swift
    /// Task {
    ///   await store.dispatch(firstAction)
    ///   await store.dispatch(secondAction)
    /// }
    /// ```
    /// Conversely, **independent** actions are intentionally left as one `Task` per call so they
    /// run concurrently — don't merge them into a single `Task` just to save lines, as that
    /// serializes them (the second waits for the first's full middleware chain):
    /// ```swift
    /// // Independent: keep separate so neither blocks the other.
    /// Task { await store.dispatch(firstAction) }
    /// Task { await store.dispatch(secondAction) }
    /// ```
    ///
    /// - Parameter action: The action to dispatch.
    func dispatch(_ action: Action) async {
        state = reducer(state, action)

        // Capture the post-reducer state snapshot so all middlewares in this action's
        // chain see the same state, even if nested actions mutate state during execution.
        let currentState = state

        // Execute all middlewares against the same state snapshot and collect their next
        // actions. This ensures every middleware for this action sees the same state (Redux pattern).
        var nextActions: [Action] = []
        for middleware in middlewares {
            if let nextAction = await middleware(currentState, action) {
                nextActions.append(nextAction)
            }
        }

        // Then dispatch the collected next actions sequentially, maintaining depth-first
        // execution while preserving state-snapshot consistency.
        for nextAction in nextActions {
            await dispatch(nextAction)
        }
    }
}
