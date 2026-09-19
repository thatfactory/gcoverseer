# Logging

Use this guide for Apple-platform applications and Swift packages that emit runtime diagnostics. Logging should improve observability without changing behavior, exposing sensitive data, or overwhelming the console.

## Ownership

- Each application or package owns the logs for operations it implements.
- A consuming application logs its own orchestration and lifecycle events. It must not reproduce or reformat a dependency's internal steps or outcomes.
- A reusable package describes events using its own domain language. Do not introduce concepts from one current client into package categories or messages.
- Ownership does not require every API or package to emit logs. Pure utilities and operations without a meaningful diagnostic event may emit nothing.
- New or changed stateful, asynchronous, fallible, or lifecycle-oriented behavior must identify its meaningful diagnostic boundaries during implementation. Emit a privacy-safe outcome for success and each operationally distinct failure, cancellation, recovery, or state transition that a developer needs to distinguish. If an artifact is limited to pure values or utilities and has no such boundary, keep it silent and state that decision in the implementation handoff instead of adding initializer or property-access noise.
- Logging is a side effect. It must not affect returned values, state transitions, error handling, or control flow.
- Architectures that isolate side effects must call a logging package from an allowed side-effect boundary, such as middleware or a service, rather than from a pure reducer.

## AppLogger and identity

- Use the shared [AppLogger Swift package](https://github.com/thatfactory/applogger) rather than `print`, direct `Logger` instances, or project-specific logging backends that duplicate it.
- Add the package's `AppLogger` library product to each target that emits logs. Follow the package's current integration instructions for dependency configuration and version requirements.
- Give each artifact an explicit, stable, lowercase subsystem in reverse-DNS form: `com.thatfactory.<artifact>`.
- A package always uses its own subsystem, even when its code runs inside a consuming application. This allows filtering all ThatFactory logs or one artifact independently.
- Choose stable categories from the artifact's reusable domain. Categories are not a global vocabulary: a language-evaluation package might use `evaluation`, a progression engine might use `progression`, and an application might use `session` or `lifecycle`.
- Keep the category set as small and generic as possible while still distinguishing meaningful operations within that artifact.
- Do not add a category solely because one current client uses that concept.

## Package emoji

- Every log message emitted by a ThatFactory package starts with that package's canonical emoji followed by one space.
- Use the emoji registered in the [ThatFactory Swift Package Collection](https://github.com/thatfactory/swift-package-collection).
- Declare the selected emoji in the package's local instructions or documentation.
- Route package logging through one package-local gateway that owns the subsystem, categories, and emoji prefix. Production call sites must not construct unprefixed package messages directly.

## Message design

- Keep each message short, direct, and on one line.
- Prefer one completion or outcome message over separate start, intermediate, and completion messages.
- Use a compact action followed by stable `key=value` metadata when context is useful:

  ```text
  <emoji> evaluate | type=classification, correct=true, score=10
  ```

- Do not log routine property access, initializers, collection iterations, or other high-frequency implementation details.
- Use `.debug` for routine diagnostics, `.info` or `.default` for meaningful lifecycle events, `.error` for failures, and `.fault` only for severe conditions that indicate a system-level problem.
- Do not prepend the current time or date. Apple unified logging already records the event timestamp.
- Use AppLogger's `Date.formattedLogTimestamp()` and `TimeInterval.formattedLogDuration()` only when a domain date or elapsed duration is part of the event itself.

## Privacy

- Never log credentials, tokens, secrets, personal data, prompts, submitted answers, or other user-generated content as public metadata.
- Prefer omitting sensitive values. If a diagnostic genuinely requires them, mark the entire AppLogger message private.
- Do not emit complete models, collections, or application-state snapshots in routine logs.
- Any temporary state snapshot must be debug-only, explicitly enabled, and private.

## Testing

- Keep message rendering independently testable through an internal formatter, injectable sink, or similarly narrow seam.
- Verify that every package message starts with its canonical emoji.
- Verify the stable category, meaningful fields, privacy choice, log level, and single-emission behavior for each logged operation.
- Do not make tests depend on querying the operating system's persisted log store.
- For every changed lifecycle covered by the observability requirement, test the event formatter or sink for its successful and operationally distinct unsuccessful outcomes. Dependency declaration and target linkage alone do not establish logging coverage.

## Filtering

Use the subsystem in Console or the macOS `/usr/bin/log` command. For example:

```sh
/usr/bin/log stream --level debug \
  --predicate 'subsystem BEGINSWITH "com.thatfactory"'
```

Filter one artifact with an exact subsystem:

```sh
/usr/bin/log stream --level debug \
  --predicate 'subsystem == "com.thatfactory.example"'
```
