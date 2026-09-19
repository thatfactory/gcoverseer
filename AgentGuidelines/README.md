<p align="center">
  <a href="https://developer.apple.com/xcode/"><img alt="Xcode MCP" src="https://img.shields.io/badge/Xcode-MCP-50ace8.svg?logo=xcode&logoColor=white"></a>
  <a href="https://developers.openai.com/codex/mcp"><img alt="Codex MCP" src="https://img.shields.io/badge/Codex-MCP-1F70C1.svg?logo=icloud&logoColor=white"></a>
  <a href="https://en.wikipedia.org/wiki/MIT_License"><img alt="License" src="https://img.shields.io/badge/License-MIT-67ac5b.svg?logo=googledocs&logoColor=white"></a>
  <a href="https://github.com/thatfactory/agent-guidelines/commits/main/"><img alt="Updated" src="https://img.shields.io/github/last-commit/thatfactory/agent-guidelines?label=Updated&logo=convertio&logoColor=white"></a>
  <a href="https://github.com/thatfactory/agent-guidelines/releases"><img alt="Revision" src="https://img.shields.io/github/v/release/thatfactory/agent-guidelines?label=Revision&logo=gitbook&logoColor=white"></a>
  <a href="https://github.com/thatfactory/agent-guidelines/actions/workflows/ci.yml"><img alt="CI" src="https://github.com/thatfactory/agent-guidelines/actions/workflows/ci.yml/badge.svg"></a>
  <a href="https://github.com/thatfactory/agent-guidelines/actions/workflows/release.yml"><img alt="Release" src="https://github.com/thatfactory/agent-guidelines/actions/workflows/release.yml/badge.svg"></a>
</p>

# Agent Guidelines

`agent-guidelines` is ThatFactory's public, versioned source of truth for reusable instructions and development configuration. It centralizes stable decisions about Swift development, Redux architecture, testing, documentation, logging, packages, CI/CD, localization, and Xcode tooling while leaving product context and exceptions in each consuming repository.

The repository contains documentation and supporting configuration, not a Swift product. Consumers install a tagged release as a Git subtree at `AgentGuidelines/`, so every agent and supported tool sees ordinary version-controlled files at predictable paths.

## How it fits together

```text
                  thatfactory/agent-guidelines
                  versioned GitHub repository
                             |
                       tagged release
                         e.g. 0.0.3
                             |
                    git subtree add/pull
                             |
                             v
+---------------- Consumer project or package -----------------+
|                                                              |
|  AGENTS.md                                                   |
|  |-- local product/package context                           |
|  |-- concrete project paths                                  |
|  |-- local exceptions                                        |
|  `-- pointers to shared guidelines -----------------+        |
|                                                     |        |
|  AgentGuidelines/                                   |        |
|  |-- VERSION                                        |        |
|  |-- Configurations/                                |        |
|  `-- Guidelines/ <----------------------------------+        |
|      |-- Architecture/Redux.md                               |
|      |-- Swift/SwiftUI.md                                    |
|      |-- Testing/UnitTesting.md                              |
|      `-- Xcode/MCP.md                                        |
|                                                              |
|  Sources and project files                                   |
+----------------------------+---------------------------------+
                             |
              reads instructions and project files
                  +----------+----------+
                  v                     v
               Codex                Xcode agent
                  |
                  | Xcode MCP (`xcrun mcpbridge`)
                  v
                Xcode
```

The subtree does not automatically import every guide into an agent's context. A consumer's root or folder-scoped `AGENTS.md` tells the agent which shared guides to read for the task. The nearest local `AGENTS.md` can specialize or override the shared baseline.

## Guideline catalog

- [Agent workflow and tool execution](Guidelines/AgentWorkflow.md)
- [App Store metadata](Guidelines/AppStore.md)
- [CI/CD](Guidelines/CICD.md)
- [Development and reusability](Guidelines/Development.md)
- [Documentation](Guidelines/Documentation.md)
- [Git ignore files](Guidelines/Git/IgnoreFiles.md)
- [Git repositories and SSH-first cloning](Guidelines/Git/Repositories.md)
- [GitHub pull requests](Guidelines/GitHub/PullRequests.md)
- [Localization](Guidelines/Localization.md)
- [Logging](Guidelines/Logging.md)
- [Redux architecture and physical folder organization](Guidelines/Architecture/Redux.md)
- [Swift](Guidelines/Swift/Swift.md)
- [Swift format](Guidelines/Swift/SwiftFormat.md)
- [Swift packages](Guidelines/Packages.md)
- [Swift style](Guidelines/Swift/SwiftStyle.md)
- [SwiftUI](Guidelines/Swift/SwiftUI.md)
- [Unit and integration testing](Guidelines/Testing/UnitTesting.md)
- [Xcode MCP and visual verification](Guidelines/Xcode/MCP.md)
- [Xcode project settings](Guidelines/Xcode/ProjectSettings.md)
- [Xcode security audits](Guidelines/Xcode/Security.md)

Only reference the guides that apply. Agent workflow normally applies to both applications and packages. A UI-agnostic package normally also uses Swift, style, testing, documentation, logging, packages, CI/CD, and Xcode guidance, but not Redux or SwiftUI guidance.

## Add to a consumer

From the consumer repository root, install a tagged release:

```sh
git subtree add \
  --prefix=AgentGuidelines \
  https://github.com/thatfactory/agent-guidelines.git \
  0.0.33 \
  --squash
```

Swift consumers that adopt the shared formatter expose its configuration at the repository root so Xcode and other tools discover it:

```sh
ln -s AgentGuidelines/Configurations/Swift/.swift-format .swift-format
ln -s AgentGuidelines/Configurations/Swift/.editorconfig .editorconfig
```

Keep the subtree tracked, but add this to the consumer's tracked `.gitattributes` so GitHub collapses synchronized guideline files in pull-request diffs by default:

```gitattributes
# Synced from thatfactory/agent-guidelines; keep tracked but collapse GitHub diffs.
AgentGuidelines/** linguist-generated
```

Copy and adapt [the consumer template](Templates/AGENTS.md). Keep the consumer file small: describe the product or package, map its concrete physical folders, point to the applicable shared guides, and state only genuine exceptions. Keep the version-marked code-review contract, documentation-maintenance contract, external-dependency contract, and runtime-observability contract directly in the repository-root `AGENTS.md`; Markdown links to shared guides are navigation, not automatic instruction includes.

Copy the shared [`.gitignore` template](Templates/.gitignore) into a new Xcode project or Swift package. Keep authored project files, workspaces, and package lockfiles eligible for version control, and follow the [Git ignore guidance](Guidelines/Git/IgnoreFiles.md) when an established consumer needs an additional project-specific rule.

### Configure global Codex instructions

Copy the contents of [`Templates/GlobalCodexInstructions.md`](Templates/GlobalCodexInstructions.md) into the user's global Codex instructions.

These instructions bootstrap discovery of repository-local `AGENTS.md` files and shared guides and provide generic high-signal code-review defaults. Repository engineering policy and specialized threat models remain versioned in this repository or the consumer rather than duplicated in each user's global configuration.

Review this template when upgrading `agent-guidelines`, because the recommended global bootstrap instructions may change between releases. Installing or updating the Git subtree does not update a user's global Codex configuration.

Redux applications also copy [the canonical Store](Templates/Store.swift) as is, following the composition and placement rules in [Redux architecture](Guidelines/Architecture/Redux.md).

Expose the completion-audit skill at the consumer repository root so Codex can discover it:

```sh
mkdir -p .agents/skills
ln -s ../../AgentGuidelines/.agents/skills/agent-guidelines-audit \
  .agents/skills/agent-guidelines-audit
```

Validate the checked-in consumer integration directly or through the completion-audit skill:

```sh
AgentGuidelines/Scripts/validate_consumer_setup.swift
```

The native Swift validator checks the version-marked root Code Review, Documentation Maintenance, External Dependency, and Runtime Observability contracts, Codex subtree-review scope, `.gitattributes`, local guide links, and the audit-skill symlink. When the root `AGENTS.md` links the shared Swift-format guide, it also requires both configuration symlinks and a non-mutating `lint-strict` CI invocation. Pass `--require-swift-format` only when auditing formatter adoption before adding that guide link.

## Update a consumer

Review the target release's changelog, then pull it deliberately:

```sh
git subtree pull \
  --prefix=AgentGuidelines \
  https://github.com/thatfactory/agent-guidelines.git \
  0.0.33 \
  --squash
```

Confirm `AgentGuidelines/VERSION`, review the subtree diff, synchronize the marked code-review contract, documentation-maintenance contract, external-dependency contract, and runtime-observability contract when their versions change, run `AgentGuidelines/Scripts/validate_consumer_setup.swift`, and run the consumer's relevant tests. Keep the subtree update in its own commit, and identify the old and new versions plus the central release or pull request in the consumer pull-request description. Updates are intentionally not automatic: one guideline release cannot silently change every project.

## Maintain the source of truth

1. Export current Xcode skills to a temporary review location when a new Xcode release materially changes agent behavior:

   ```sh
   xcrun agent skills export --output-dir <temporary-directory>
   ```

2. Compare relevant guidance with this repository and official Apple documentation.
3. Bring over durable policy, not the exported skill text or an SDK API catalog.
4. Remove obsolete or conflicting rules instead of accumulating historical alternatives.
5. Run `Scripts/validate_guidelines.swift`.
6. Update `VERSION` and `CHANGELOG.md`, open a pull request, and wait for approval before merging.
7. After the pull request has merged, create the matching tag and GitHub release.

## Precedence

For a consumer task, apply instructions in this order:

1. The user's explicit request.
2. The nearest applicable consumer `AGENTS.md`.
3. The consumer root `AGENTS.md`.
4. The shared guides explicitly referenced by those files.

Official Apple documentation remains authoritative for API behavior. A local convention can deliberately narrow a choice, but it must not rely on behavior contradicted by the current SDK documentation.
