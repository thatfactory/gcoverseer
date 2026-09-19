# Documentation

Documentation is part of implementation. For every codebase change, evaluate whether durable project knowledge or any existing documentation is affected; do not treat documentation as optional cleanup after code and tests are complete.

## Conventions

- Use PascalCase Markdown filenames without spaces.
- Keep the folder flat until one topic genuinely requires several files.
- Prefer current implementation over speculative future design; label known gaps explicitly.

### Line wrapping

**Write each paragraph as a single physical line — do not hard-wrap prose at a fixed column width.** A paragraph hand-wrapped at ~100 columns shows up with breaks mid-sentence, which looks broken. Let your editor **soft-wrap** instead of inserting newlines.

The same rule applies to multi-sentence **list items** and **blockquotes** — keep each item/quote on one line. GitHub alerts are the exception: keep the alert marker on its required quoted line and keep each following body paragraph on one physical quoted line. Do not nest alerts. This concerns **prose only**: fenced code blocks and ASCII diagrams are published verbatim, so wrap those exactly as they should appear (one line per row).

### Diagrams

Use ASCII art inside fenced code blocks:

```
┌──────────┐       ┌──────────┐       ┌──────────┐
│   View   │──────>│  Store   │──────>│ Service  │
└──────────┘       └──────────┘       └──────────┘
```

Use box-drawing characters (`─`, `│`, `┌`, `┐`, `└`, `┘`) and arrows (`──>`, `<──`, `v`, `^`).

#### Keep diagrams aligned

Diagrams are published verbatim, so a diagram that is misaligned in the repo will look misaligned on MD readers/editors. Misalignment is also the most common defect in these files — it creeps in when someone edits a label without re-padding the rest of the row.

- **Every vertical rule must sit in the same character column on every row.** Decide the column positions up front, then pad each row with spaces to hit them. In a sequence diagram, each participant's lifeline (`│`) is one such column.
- **A box's interior width must match its border width.** `┌──────────┐` (10 dashes) needs exactly 10 characters between the `│` on the rows below it.
- **Put arrowheads beside the target rule, not on top of it** — `│─────>│`, so the lifeline stays unbroken. An arrow that spans intermediate participants simply passes through their columns.
- **When a label is too long for its cell, wrap it onto a second row** rather than letting it push the rules out of alignment.
- **Count characters, not bytes.** Box-drawing glyphs are 3-byte UTF-8, so `wc -c` and `awk '{print length}'` report well above the visual width — around 2× for a typical row, up to 3× for one that is mostly box-drawing. Measure with `swift -e 'import Foundation; let value = String(data: FileHandle.standardInput.readDataToEndOfFile(), encoding: .utf8) ?? ""; print(value.split(separator: "\n", omittingEmptySubsequences: false).map(\.count).max() ?? 0)' < FILE` or an editor's column indicator.

Check the result in a monospace view before committing: scan down each vertical rule and confirm it never jogs left or right. For a large or heavily edited diagram, it is quicker and safer to generate the block from a list of column positions in a throwaway script than to count spaces by hand.

## Code-level documentation

- Document every new struct, class, enum, protocol, actor, and function with focused `///` DocC comments.
- Use `// MARK: -` pragmas to separate meaningful logical sections so source files remain easy to scan and navigate.
- Update documentation when changing a documented API, parameter, behavior, or invariant.
- End documentation sentences with periods.
- Explain intent, contracts, units, side effects, isolation, and non-obvious constraints; do not restate syntax.
- Add a short Swift example when it materially clarifies correct use.
- Keep documentation close to the declaration it describes.

## Project-level documentation

- Keep durable architecture and cross-cutting guides in the consumer's declared documentation folder.
- Update project documentation when a change alters durable or core feature behavior, architecture, data flow, public API, persistence, navigation, localization process, testing workflow, delivery workflow, configuration, or another documented contract.
- Regardless of change size, update or remove existing documentation when the implementation makes a documented statement inaccurate, incomplete, misleading, or obsolete.
- Do not create broad documentation for incidental implementation details that are neither durable knowledge nor already documented. A small change that leaves durable knowledge and existing documentation accurate needs no project-level documentation edit.
- When renaming or removing behavior, search durable documentation for old names, examples, defaults, diagrams, setup steps, and references that may now be stale.
- Keep investigations, temporary plans, and one-time spike notes out of durable documentation unless they become lasting guidance.
- Prefer ASCII diagrams in fenced code blocks when universal rendering matters.

## Review checklist

When reviewing a change, ask:

- Which existing documentation describes the changed feature, API, configuration, workflow, or invariant?
- Does the change alter durable or core feature behavior?
- Would any existing statement become inaccurate, incomplete, misleading, or obsolete even if the implementation change is small?
- Does it introduce a reusable architectural pattern?
- Does it change data flow, ownership, persistence, localization, testing, or delivery?
- Does it remove or supersede an existing guide?
- Are code comments and project guides consistent with the implementation?
- If no documentation changed, is that because no durable knowledge changed and no existing documented claim was affected?

Treat known stale documentation as incomplete implementation. Avoid documentation churn when the change neither affects durable knowledge nor changes an existing documented claim.

## Shared versus local guidance

This repository owns reusable policy. Consumer documentation owns its product domain, concrete paths, package relationships, feature registries, and explicit exceptions. Link across those layers instead of copying shared prose locally.
