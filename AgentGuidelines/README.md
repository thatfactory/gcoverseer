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
- [Codex review policy](ReviewPolicy/README.md)
- [Development and reusability](Guidelines/Development.md)
- [Device Hub, physical devices, and simulators](Guidelines/Xcode/DeviceInteraction.md)
- [Documentation](Guidelines/Documentation.md)
- [Git ignore files](Guidelines/Git/IgnoreFiles.md)
- [Git repositories and SSH-first cloning](Guidelines/Git/Repositories.md)
- [GitHub pull requests](Guidelines/GitHub/PullRequests.md)
- [Localization](Guidelines/Localization.md)
- [Logging](Guidelines/Logging.md)
- [Networking](Guidelines/Networking.md)
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
  0.0.48 \
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

Copy and adapt [the consumer template](Templates/AGENTS.md). Keep the consumer file small: describe the product or package, map its concrete physical folders, point to the applicable shared guides, and state only genuine exceptions. Keep the version-marked code-review contract, PR-lifecycle contract, documentation-maintenance contract, external-dependency contract, and runtime-observability contract directly in the repository-root `AGENTS.md`; Markdown links to shared guides are navigation, not automatic instruction includes.

Copy the shared [`.gitignore` template](Templates/.gitignore) into a new Xcode project or Swift package. Keep authored project files, workspaces, and package lockfiles eligible for version control, and follow the [Git ignore guidance](Guidelines/Git/IgnoreFiles.md) when an established consumer needs an additional project-specific rule.

### Adopt review instructions only

For a repository that needs only Codex reviewer rules and the PR flow, use the [review-only profile](ReviewPolicy/README.md). It installs managed root instructions and CI validation without the shared subtree or unrelated engineering contracts. Both profiles require the latest independently published review-policy revision. Use the central synchronizer rather than hand-copying policy text.

### Configure global Codex instructions

Copy the contents of [`Templates/GlobalCodexInstructions.md`](Templates/GlobalCodexInstructions.md) into the user's global Codex instructions.

Copy only its code-review section into Settings → Code Review → Review Instructions for manually started reviews. Automatic GitHub reviews use the checked-in root contracts.

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

The native Swift validator checks the version-marked root Code Review, PR Lifecycle, Documentation Maintenance, External Dependency, and Runtime Observability contracts, Codex subtree-review scope, `.gitattributes`, local guide links, and the audit-skill symlink. When the root `AGENTS.md` links the shared Swift-format guide, it also requires both configuration symlinks and a non-mutating `lint-strict` CI invocation. Pass `--require-swift-format` only when auditing formatter adoption before adding that guide link.

## Update a consumer

Review the target release's changelog, then pull it deliberately:

```sh
git subtree pull \
  --prefix=AgentGuidelines \
  https://github.com/thatfactory/agent-guidelines.git \
  0.0.48 \
  --squash
```

Confirm `AgentGuidelines/VERSION`, review the subtree diff, synchronize the marked code-review contract, PR-lifecycle contract, documentation-maintenance contract, external-dependency contract, and runtime-observability contract when their versions change, run `AgentGuidelines/Scripts/validate_consumer_setup.swift`, and run the consumer's relevant tests. Keep the subtree update in its own commit, and identify the old and new versions plus the central release or pull request in the consumer pull-request description. Updates are intentionally not automatic: one guideline release cannot silently change every project.

When first adopting [Networking](Guidelines/Networking.md), synchronize external-dependency contract v2 and perform the [networking adoption audit](.agents/skills/agent-guidelines-audit/SKILL.md#audit-networking), including existing paths and any explicitly approved migration deferrals.

## Upgrade a consumer's Xcode

Use the [`xcode-upgrade` skill](.agents/skills/xcode-upgrade/SKILL.md) to move an Apple-platform application or Swift package to a requested Xcode, update dependencies and compiler settings, align CI, and validate the result. In Codex, invoke `$xcode-upgrade to Xcode 27.2 and use the new JSON format` or select the skill. The skill also recognizes `/xcode-upgrade ...` as request text when the client passes it through; it does not register a client slash command. The skill follows the shared [project-settings guide](Guidelines/Xcode/ProjectSettings.md) and [package compiler-settings baseline](Guidelines/Packages.md#compiler-settings-baseline), preserving consumer-specific exceptions and the user's authorization boundaries.

The skill is discoverable in this central checkout. To use it in a consumer that has adopted this release, expose it from the subtree:

```sh
mkdir -p .agents/skills
ln -s ../../AgentGuidelines/.agents/skills/xcode-upgrade \
  .agents/skills/xcode-upgrade
```

Alternatively, explicitly provide `AgentGuidelines/.agents/skills/xcode-upgrade/SKILL.md` with the request. Keep the skill beside its linked guides in the subtree; copying only `SKILL.md` loses those references. Subtree adoption and skill exposure do not upgrade a consumer's toolchain until requested.

## Maintain the source of truth

Use the repository-local [`update-agent-guidelines` skill](.agents/skills/update-agent-guidelines/SKILL.md) with a request such as `$update-agent-guidelines include/update the rule that ...`. It chooses the guide, asks whether to add audit coverage when that choice is missing, and prepares the next version's metadata. Explicit invocation also authorizes the scoped PR, merge after required approval and green CI, and release; narrower instructions such as draft-only or no release take precedence. Consumer adoption remains separate.

The skill is discoverable when working in this central checkout. For a consumer on an older release, open a chat in the central checkout or explicitly supply the path to its `.agents/skills/update-agent-guidelines/SKILL.md` with the request; updating the consumer subtree is not a prerequisite. For use across repositories, the user can install the skill independently with Codex's skill installer from `thatfactory/agent-guidelines`, path `.agents/skills/update-agent-guidelines`, at a published tag. Do not implicitly install it or alter global configuration as part of a guideline change.

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
