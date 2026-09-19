# Swift Style

- Keep conditional, loop, and closure bodies on separate lines.
- Keep `guard` exits on separate lines.
- Prefer seconds-based duration APIs such as `Task.sleep(for: .seconds(10))` over nanosecond literals.
- Use `///` for documentation comments and end documentation sentences with periods.
- Use meaningful names of at least three characters. Widely established type-level conventions are allowed only when the consumer explicitly uses them.
- Keep enum cases alphabetical unless ordering communicates behavior or a local lint suppression documents the exception.
- Use `// MARK: -` to separate meaningful sections.
- Use `// MARK: - Private` when separating private implementation from non-private declarations in the same file.
- Break branching or multi-step implementation into small, focused functions whose names make the caller read as a sequence of intentions. Keep orchestration concise, move implementation details below `// MARK: - Private`, and avoid extracting trivial expressions that are clearer inline.
- Do not add Xcode boilerplate filename, author, or creation-date headers.
- Keep each top-level type in its own file, even when multiple types are closely related. Nest a supporting type only when it is private to one primary type and the relationship forms a natural namespace.
- Match a type file's name to its primary type.
- Put the declaration named by the file immediately after imports and file-level directives. Opening `EffectAssetLoader.swift`, for example, must reveal `EffectAssetLoader` before supporting declarations. A shared canonical template may retain type aliases that its documented layout deliberately places first.
- Keep declaration modifiers such as `nonisolated` on the same line as the declaration they modify. For a multiline function signature, keep the opening brace on the return-type line.
- Separate groups of enum cases with blank lines when the groups represent distinct operations, phases, or workflows. Keep cases consistently ordered within each group; meaningful workflow order may override alphabetical order.
- Keep physical folders flat until one topic genuinely contains several files. When grouping becomes useful, organize related models, services, tools, views, and Redux components by a familiar domain, feature, or capability so readers can reason about them together.

Example:

```swift
guard isEnabled else {
    return
}

withAnimation {
    isPresented = true
}
```

Namespaced supporting types keep their ownership visible:

```swift
struct Measurement {
    // ...
}

// MARK: - Errors

extension Measurement {
    enum ValidationError: Error {
        case invalidValue
    }
}
```

Multiline declarations keep their modifiers and braces attached to the declaration:

```swift
nonisolated func reduce(
    _ state: State,
    _ action: Action
) -> State {
    // ...
}
```
