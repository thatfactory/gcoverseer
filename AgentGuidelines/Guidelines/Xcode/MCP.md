# Xcode MCP and Visual Verification

Use Xcode as the primary source for Apple documentation, project knowledge, builds, tests, previews, simulator/device interaction, and diagnostics.

Apple documents external agent access through [`xcrun mcpbridge`](https://developer.apple.com/documentation/xcode/giving-external-agents-access-to-xcode). Xcode must be open with the relevant project or package, and external-agent access must be enabled in Xcode settings.

## Tool priority

1. Use Xcode MCP for Apple documentation search and operations on an open Xcode project or package.
2. Use official Apple web documentation when Xcode documentation search is unavailable or an external reference is useful.
3. Use XcodeBuildMCP only when Xcode MCP is unavailable or cannot complete the required operation.

Discover the tools exposed by the active Xcode server. Tool prefixes and exact names can vary by client; do not hardcode a server prefix when the active tool catalog can be inspected.

## Documentation lookup

- Search current Apple documentation before using an API whose signature, availability, behavior, or replacement may have changed.
- Prefer the documentation returned by the installed Xcode toolchain for SDK-sensitive work.
- Use Xcode-provided skills for specialized current workflows such as SwiftUI modernization, localization, security auditing, device interaction, and C bounds safety.
- Distill durable project policy into local documentation; do not copy an exported Apple skill into a repository.

## Project operations

- Prefer Xcode project-aware file, target, build-setting, issue, build, test, preview, and documentation tools when available.
- Build the smallest relevant target or scheme first.
- Read Xcode diagnostics and fix the first root failure before retrying broadly.
- Run focused tests before the full affected suite.
- Keep the project open and active throughout a multi-step Xcode MCP workflow.

## SwiftUI previews

After a meaningful SwiftUI change:

1. Build the affected target.
2. Render or refresh the relevant preview when Xcode exposes preview tooling.
3. Inspect errors and warnings from the preview and build.
4. Verify representative states, localization, accessibility sizes, and appearances when relevant to the task.
5. If preview tooling is unavailable or insufficient, run the feature in a simulator or device session.

## Build, run, and interaction

Use runtime interaction when static compilation cannot establish that a user-visible workflow behaves correctly. Follow [Device Hub, physical devices, and simulators](DeviceInteraction.md) for authorization, tool and skill discovery, signed builds, session ownership, hierarchy and screenshot targeting, keyboard diagnostics, evidence, and cleanup. Keep consumer-specific destinations and CI/Canvas constraints in the consumer's `AGENTS.md`.

## Reporting

State:

- what target, scheme, preview, test, simulator, or device was used;
- what behavior was exercised;
- whether build and runtime diagnostics were clean;
- what visual evidence was inspected;
- what could not be verified and why.
