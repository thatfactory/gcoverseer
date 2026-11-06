# Changelog

All notable changes to this project are documented in this file.

## [0.0.48] - 2026-11-06

### Changed

- Simplified the repository review declaration to state directly that automatic Codex PR review is enabled. The canonical review contracts and independent review-policy revision remain unchanged.

## [0.0.47] - 2026-11-06

### Added

- Added independently versioned Codex review policy with full and review-only adoption profiles, exact managed root contracts, a Swift synchronizer, and a pinned shared CI action. Latest-policy checks reject stale or modified content and uncertain provenance.
- Added regression coverage for synchronization, preservation of local instructions, profile boundaries, duplicate contracts, publication identities, and unavailable policy sources.

### Changed

- Restricted review output to substantiated P0/P1 defects, clarified one automatic opening/ready review with local verification of batched remediation, and retained bounded monitoring and explicit owner authorization for extra review.
- Made reviewer rules and PR lifecycle available directly in every root instruction file without adopting unrelated guidance. Removed retired delegated-review exceptions and aligned audit, release, and global instruction templates.

## [0.0.46] - 2026-11-05

### Changed

- Made the self-hosted runner's active Xcode/Swift toolchain the CI default, with environment logging and real build/test validation. Exact version or build pins require a documented, evidence-backed repository exception with a revisit condition.
- Updated the Xcode-upgrade skill to remove unjustified CI pins instead of moving them to the newly validated version.
- Clarified Swift package badges: omit Updated and Revision/latest-release-version badges unless a documented reader need justifies them; retain Release/publishing workflow-status badges for the package's own workflows.

### Added

- Added completion-audit checks for toolchain constraints in workflows and invoked scripts, documented exceptions, active-toolchain validation, and Swift package badge semantics.

## [0.0.45] - 2026-11-04

### Added

- Added the canonical Networking guide requiring Apple-native networking and typed HTTP through Apple's `swift-http-types` HTTPTypes and HTTPTypesFoundation products with URLSession transport, including native bridges and justified capability-gap exceptions.
- Added networking audit coverage for actual typed implementation, target linkage, native transport, validation, and explicit adoption deferrals without a false full-compliance claim.

### Changed

- Centralized network transport ownership and validation guidance with links from architecture, package, testing, and security guides.
- Updated the consumer external-dependency contract to v2 for the narrow standing approval of `swift-http-types`; consumers must synchronize the root contract on adoption. Other external runtime dependencies retain their approval requirements.

## [0.0.44] - 2026-10-30

### Added

- Added the reusable `xcode-upgrade` skill for intentional Xcode, dependency, compiler-settings, and CI upgrades in applications and Swift packages, including requested project-format conversion and evidence-based validation.
- Documented consumer discovery through a subtree skill symlink and explicit invocation with a target Xcode and additional instructions.

## [0.0.43] - 2026-10-29

### Added

- Documented a bounded physical Apple TV diagnostic for current-user CloudKit and local-store identity, including the observed secondary-profile account crossover, privacy-safe comparisons, profile re-addition, and limits on attributing a tvOS cause.
- Added audit coverage for real two-account evidence when a consumer changes tvOS per-user storage or CloudKit account binding; unrelated changes and documentation-only work remain outside that gate.

## [0.0.42] - 2026-10-20

### Changed

- Replaced the explicit-request restriction on Reduce Motion adaptations with Apple-aligned evaluation of individual motion triggers, responsive preference handling, and preservation of useful feedback.
- Required platform-specific common-task evidence before declaring Reduced Motion support, with re-evaluation on app updates and a link from App Store metadata guidance.
- Added focused Reduce Motion audit checks, scenario walkthroughs, and validator regression coverage for policy, evidence, and support claims.

## [0.0.41] - 2026-10-20

### Added

- Required reusable custom-styled controls to own smooth visual transitions while functional state changes immediately, preserving native feedback, stable identity, and narrow animation scope.
- Added display-appropriate image preparation, bounded memory, derivative invalidation, original preservation, and stale-result rejection guidance.
- Added an animation and image-rendering audit with targeted runtime evidence, honest performance measurements, scenario walkthroughs, and validator mutation coverage. Existing Reduce Motion policy is unchanged.

## [0.0.40] - 2026-10-20

### Added

- Made Apple-owned placement authoritative for standard navigation, dismissal, confirmation, and window controls, with semantic toolbar intent and native Back behavior preserved across platforms.
- Added a completion-audit check for control ownership, unjustified placement overrides, conflicting design mandates, and relevant interaction evidence.
- Added the `update-agent-guidelines` skill to persist shared decisions, ask about audit coverage when unspecified, update release metadata, and deliver an authorized reviewed PR and release.

## [0.0.39] - 2026-10-19

### Added

- Added shared Device Hub, physical-device, and simulator guidance covering tool and skill discovery, authorization, signing, keyboard controls, resource coordination, runtime evidence, controlled comparisons, and cleanup.
- Linked the workflow from Xcode MCP, Development, the guideline catalog, and the consumer instructions template while keeping product-specific environment constraints in consumers.

## [0.0.38] - 2026-10-15

### Added

- Made size-based scroll bounce the SwiftUI `ScrollView` default on supported deployment targets, with axis and environment-scope guidance for nested scrolling and modal sheets.
- Added a completion-audit check for new or changed `ScrollView` bounce behavior and documented exceptions.

## [0.0.37] - 2026-10-14

### Added

- Made native SwiftUI and platform components the default for supported interactions, with approved durable exceptions required for verified native capability gaps.
- Defined presentation hierarchy, independent child dismissal, parent draft retention, cancellation, dismissal-completion cleanup, and required runtime interaction evidence.
- Added a mandatory completion-audit decision check for custom component and presentation lifecycle replacements, with validator and regression coverage.

## [0.0.36] - 2026-10-09

### Added

- Added SwiftUI animation guidance favoring purposeful native feedback, default SwiftUI animation, system transitions, and SF Symbol effects while keeping animations scoped and interactions responsive.
- Required an explicit task-prompt request before adding app-level Reduce Motion guards, while preserving accessibility behavior supplied automatically by native system components.

## [0.0.35] - 2026-09-27

### Changed

- Require positive repository-specific evidence before automatic Codex review becomes a merge gate. Track configuration separately from current-head execution, default undiscoverable settings to `unknown`, and bound deduplicated start-signal monitoring to five minutes.

## [0.0.34] - 2026-09-20

### Changed

- Required every ThatFactory package emoji to be unique in the Swift Package Collection and synchronized across package documentation, the logging gateway, and the collection registry.
- Extended the completion audit to block package publication when emoji uniqueness cannot be verified or the registered and emitted identities disagree.

## [0.0.33] - 2026-09-19

### Added

- Added a Swift Package compiler-settings baseline aligned with the applicable Xcode project warning, Swift language-mode, concurrency, and upcoming-feature policies.
- Added completion-audit enforcement for compiler settings in checked-in Swift packages.

### Changed

- Required future Xcode compiler-policy changes to evaluate and update Swift Package Manager parity when an equivalent package setting is applicable.

## [0.0.32] - 2026-09-13

### Changed

- Made runtime observability an explicit consumer contract for changed stateful, asynchronous, fallible, and lifecycle behavior, while preserving silence for pure values and utilities without meaningful diagnostic boundaries.
- Extended the completion audit to require useful privacy-safe AppLogger outcome coverage instead of accepting dependency declaration and target linkage alone.

## [0.0.31] - 2026-09-13

### Added

- Added a least-privilege GitHub App authentication pattern for workflows that resolve private sibling repositories, including short-lived read-only tokens, process-scoped Git configuration, exact repository selection, and fork pull-request and self-hosted-runner security boundaries.

## [0.0.30] - 2026-09-12

### Changed

- Prohibited dedicated License headings and conventional standalone license-description paragraphs in Swift package READMEs while retaining root license files and standard license badges.

## [0.0.29] - 2026-09-12

### Added

- Added a reusable `.gitignore` template for Xcode, Swift Package Manager, and supported development tooling, plus shared guidance for reviewed project-specific exceptions.

### Changed

- Extended the completion audit to reconcile consumer `.gitignore` files with the shared template and escalate undocumented extra patterns for a repository-owner decision.
- Prohibited CocoaPods and Carthage under the external-dependency policy, and prohibited fastlane under CI/CD guidance while requiring first-party Swift or ThatFactory delivery tooling and narrowing Python or shell automation to documented Swift capability gaps.

## [0.0.28] - 2026-09-09

### Added

- Added a shared version-controlled App Store metadata and app-store-connect-mcp synchronization workflow, including scoped planning, immutable application, reconciliation, screenshot, credential, and submission boundaries.
- Added `ITSAppUsesNonExemptEncryption = NO` to the Xcode application baseline and completion audit, with a documented-exception path for apps that ship non-exempt encryption.
- Added mandatory post-merge cleanup of merged local feature branches after returning to an updated primary branch.

### Changed

- Linked localization guidance to the shared App Store metadata workflow while keeping product voice, locales, and concrete storefront content in consumer repositories.

## [0.0.27] - 2026-09-05

### Fixed

- Preserved valid GitHub alert syntax in the Markdown wrapping audit while continuing to reject hard-wrapped alert bodies, ordinary blockquotes, malformed alert markers, and nested alerts.

## [0.0.26] - 2026-09-02

### Added

- Added a fail-closed completion-audit helper that requires structured Xcode String Catalog editor evidence for every changed `.xcstrings` file.
- Added native Swift tests for guideline, consumer-integration, Markdown, and String Catalog automation.

### Changed

- Moved the shared localization guide from `Guidelines/Swift/` to `Guidelines/` and updated repository and consumer-template links.
- Replaced Python validation, localization, and audit-helper scripts with native Swift executables, and moved CI and release validation to macOS runners.
- Required new repository-owned executable scripts in Swift-focused repositories to use Swift, with the existing `swift_format.sh` wrapper retained as a narrow exception.

## [0.0.25] - 2026-09-02

### Added

- Added generic generated-symbol localization guidance plus reusable String Catalog preparation and validation scripts with consumer-configured paths and languages.
- Added an Xcode project-settings baseline covering warnings-as-errors, strict and approachable concurrency, default MainActor isolation, the latest stable Swift language mode, and every upcoming feature that remains opt-in for that language mode.
- Added documentation conventions for single-line Markdown prose and aligned ASCII diagrams, together with a deterministic wrapping checker.

### Changed

- Expanded the completion audit to verify localization workflows, project-level Xcode setting inheritance and documented exceptions, documentation formatting, and convention adoption across existing durable documentation.
- Updated the consumer template and guideline catalog for the new Xcode project-settings and localization workflows.

## [0.0.24] - 2026-08-31

### Added

- Added a versioned external-dependency contract to consumer `AGENTS.md` files so applications, games, and reusable packages default to native or ThatFactory-owned implementations and require explicit repository-owner approval plus a durable decision record for third-party product dependencies.
- Extended the completion audit and consumer-setup validation to detect unapproved or undocumented dependency additions and contract drift.

### Changed

- Clarified package guidance so first-party packages cannot conceal third-party runtime dependencies and guideline-mandated tooling remains tooling-only.

## [0.0.23] - 2026-08-26

### Added

- Added a versioned documentation-maintenance contract to the consumer `AGENTS.md` template and consumer-setup validation so guideline upgrades detect projects that have not adopted the contract.

### Changed

- Strengthened documentation guidance and the completion audit so durable behavior changes and any change that makes existing documentation stale require documentation updates, while incidental implementation details do not create documentation churn.

## [0.0.22] - 2026-08-24

### Added

- Required completion audits to verify and repair shared AppLogger integration for ThatFactory Apple-platform applications and Swift packages.

## [0.0.21] - 2026-08-23

### Changed

- Clarified that the bounded review-round policy applies to Codex GitHub reviews, while other explicitly selected advisory workflows used their own limits.
- Namespaced Codex review tracking fields and advanced the consumer code-review contract to v2.

## [0.0.20] - 2026-08-21

### Changed

- Documented squash merge as the default for ThatFactory repositories and instructed agents to use `gh pr merge <pull-request> --squash` instead of attempting merge commits.

## [0.0.19] - 2026-08-19

### Added

- Added a complete README badge-block example covering Swift, Xcode, platform, package manager, agent/tooling, DocC, license, updated, revision, CI, and publishing badges.

### Changed

- Updated this repository's README badges to use the canonical order and applicable tooling, release, and maintenance badges.
- Updated the README contract validator to require the canonical `Xcode MCP` badge alt text.

## [0.0.18] - 2026-08-18

### Changed

- Corrected the standard README badge order to place DocC/documentation before license, updated date, revision, CI badges, and release/publishing status.

## [0.0.17] - 2026-08-18

### Added

- A version-marked consumer Code Review contract that defines P0/P1 release blockers, non-blocking P2/P3 observations, and bounded follow-up review scope.
- A deterministic consumer-setup validator for review-contract drift, subtree review scope, `.gitattributes`, local guide links, audit-skill wiring, and Swift-format adoption.

### Changed

- Expanded the global Codex instruction template and pull-request workflow to prioritize concrete release risk, group shared root causes, and stop review loops after blockers are resolved.
- Extended the completion-audit skill to verify consumer integration, review convergence, Swift-format configuration, local execution, and non-mutating CI coverage.
- Documented explicit Swift package formatting before tests and added a strict Swift-format CI template with package path coverage.

## [0.0.16] - 2026-08-13

### Changed

- Required SwiftUI dynamic properties to precede ordinary stored properties and clarified deterministic preview expectations.
- Required one top-level type per file, focused function decomposition, logical enum grouping, and consistent declaration-modifier and multiline-signature layout.
- Documented which declaration layout conventions remain review-guided because swift-format cannot enforce them without broad source reflow.

## [0.0.15] - 2026-07-27

### Added

- A shared agent-workflow guide for bounded grouping of independent repository inspections, with dependency, ordering, scope, and output-size safeguards.
- A versioned global Codex instruction template that bootstraps discovery of repository-local guidance without duplicating engineering policy.

### Changed

- Linked the workflow guide from the consumer template, documented the manual global Codex setup, and required alphabetical ordering of the README guideline catalog.
- Clarified that Codex review requests are automatic by default and must not be triggered manually without an explicit user request.

## [0.0.14] - 2026-07-27

### Changed

- Clarify Store/Middleware @MainActor usage.
- Removed workaround for a resolved Xcode issue.

## [0.0.13] - 2026-07-26

### Added

- A reusable `agent-guidelines-audit` skill and mandatory completion gate before handoff, pull requests, merge readiness, and releases.
- A canonical Redux Store template plus dependency-container and middleware-composition guidance.
- Consumer Stack guidance for recording toolchain, platform, strict-concurrency, and actor-isolation settings.

### Changed

- Clarified Redux folder ownership, familiar domain grouping, model-versus-tool classification, service-local helpers, presentation models, and one-component-per-file organization.
- Required documentation for new Swift declarations, meaningful `MARK` sections, one meaningful SwiftUI view per file, and deterministic previews where possible.
- Clarified when target isolation defaults replace explicit annotations and when compiler-verified boundaries still require them.
- Enabled conditional-import sorting and expanded validation for Swift templates, the audit skill, Stack guidance, and formatting policy.

## [0.0.12] - 2026-07-25

### Added

- Login-shell guidance for using explicitly authorized `gh` credentials exported by local shell startup configuration without exposing token values.

## [0.0.11] - 2026-07-25

### Added

- Pre-compilation Xcode build-phase guidance and a reusable `format-and-lint` command for human and agent workflows.
- An easy-to-find record of Xcode-aligned layout settings, enabled rule overrides, and deliberate non-adoptions.
- Pull-request guidance that prevents duplicate manual Codex requests when automatic review is enabled.

### Changed

- Enabled empty-array literals, force-try rejection, brace whitespace cleanup, `where` clauses in eligible loops, and documentation-comment validation.

## [0.0.10] - 2026-07-24

### Added

- Shared Xcode-aligned swift-format and EditorConfig configuration.
- Reusable format, warning-lint, and strict-lint commands for Swift consumers.

### Changed

- Replaced SwiftLint guidance with toolchain-native swift-format guidance.

## [0.0.9] - 2026-07-23

### Added

- Consumer pull-request review scope that excludes synchronized `AgentGuidelines/**` files from substantive Codex and human review outside the central repository.

## [0.0.8] - 2026-07-23

### Added

- Consumer guidance for keeping `AgentGuidelines/` tracked while collapsing synchronized files in GitHub pull-request diffs with `.gitattributes`.
- Pull-request conventions for isolated subtree commits, explicit version notes, central review links, and continued CI validation.

## [0.0.7] - 2026-07-23

### Added

- Shared logging ownership, subsystem, package emoji, message design, privacy, testing, and filtering guidance.
- Logging pointers for application development, Swift packages, and consumer instruction templates.

## [0.0.6] - 2026-07-22

### Added

- Generic Redux store contracts, state/action, service-boundary, projection, and middleware guidance.
- Generic GitHub Actions workflow, self-hosted runner, build strategy, and failure-investigation guidance.
- Shared documentation conventions and test-tag/mock guidance.

## [0.0.5] - 2026-07-21

### Added

- Default DocC documentation and GitHub Pages publishing guidance for Swift packages.

## [0.0.4] - 2026-07-21

### Added

- Development guidance for reusability-first design and checking the latest shared-guidelines version before project work.

### Changed

- Require an approved pull request before releasing `agent-guidelines` or any consumer package.

## [0.0.3] - 2026-07-21

### Added

- A Codex review-monitoring workflow covering paginated processing reactions and review threads, clean reviews, inline feedback, replies, thread resolution, and CI checks.

## [0.0.2] - 2026-07-21

### Added

- Standard README badge conventions for ThatFactory projects and packages.
- Git repository guidance that defaults push-capable clones to SSH remotes.
- GitHub pull-request review and merge-gate guidance.
- Updated and Revision badges to the repository README.

### Changed

- Updated GitHub workflows to `actions/checkout@v7` and documented using current stable action versions in new workflows.
- Clarified the Redux side-effect loop and the canonical view-projection test path.
- Expanded and tested semantic-version validation to support prerelease plus build metadata and reject invalid numeric identifiers.
- Removed the redundant README license section while retaining the MIT license badge and root license file.

## [0.0.1] - 2026-07-21

### Added

- Initial shared guidelines for Redux, Swift, SwiftUI, SwiftLint, localization, testing, documentation, package maintenance, CI/CD, Xcode MCP, and Xcode security audits.
- A consumer `AGENTS.md` template and Git subtree installation workflow.
- Structural validation for links, the documentation catalog, version metadata, subtree instructions, and public-repository safety.
- A tag-driven GitHub release workflow that validates the tag against `VERSION` and publishes changelog notes.
