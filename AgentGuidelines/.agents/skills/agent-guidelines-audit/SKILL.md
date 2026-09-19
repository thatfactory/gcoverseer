---
name: agent-guidelines-audit
description: Audit completed repository work and checked-in consumer integration against applicable agent-guidelines, local AGENTS.md instructions, requested scope, and declared validation workflow. Use after implementing changes and before claiming completion, handing work to the user, preparing, opening, or updating a pull request, declaring merge readiness, or preparing a release. Do not use for simple answers, read-only exploration, or work that is still actively being implemented.
---

# Agent Guidelines Audit

Perform a final, evidence-based compliance pass. Treat the applicable guidelines and local instructions as the source of truth; do not duplicate their full content in this skill.

## Establish the audit scope

1. Re-read the user request and list every requested outcome and explicit constraint.
2. Locate the repository root and every applicable `AGENTS.md` from the current directory to that root.
3. Read the shared guides referenced by those instructions that apply to the changed files and workflow.
4. Inspect `git status`, the complete diff, and relevant untracked files. Preserve unrelated user changes.
5. Check the consumer's `AgentGuidelines/VERSION` and provenance when the task changes or depends on the synchronized subtree. Do not update it implicitly.
6. When the repository contains an `AgentGuidelines/` subtree, run `AgentGuidelines/Scripts/validate_consumer_setup.swift` from the consumer root. The validator detects Swift-format adoption from the root `AGENTS.md`; add `--require-swift-format` only when the repository must adopt it before that link is present. Treat failures as integration drift to fix or report before handoff.
7. Audit the root `.gitignore` against the shared [Git ignore guide](../../../Guidelines/Git/IgnoreFiles.md) and [`Templates/.gitignore`](../../../Templates/.gitignore). Compare active patterns rather than comments, blank lines, section order, or duplicates. When implementation is authorized, add every missing non-conflicting shared pattern using the template spelling, then verify its effect with `git check-ignore -v` and inspect matching tracked files with `git ls-files`; do not untrack files merely because a new rule matches them. Preserve rule order and negation semantics, and report a conflict instead of silently changing behavior. Treat an active pattern absent from the template as project-specific: accept it only when an adjacent `# Project-specific: <rationale>` comment contains a concrete non-placeholder repository-owner-approved rationale. Otherwise report the exact extra pattern and ask the repository owner to choose between updating agent-guidelines or documenting it locally; do not remove, rewrite, or silently approve it. A missing root `.gitignore`, an unresolved missing shared pattern, or an undecided undocumented extra pattern blocks audit completion.

Do not inspect or require the user's global Codex instructions. They are user-level state outside the repository audit boundary; validate the checked-in root `AGENTS.md` contract instead.

## Audit the implementation

Review the actual change rather than only checking whether files exist:

- Confirm every requested outcome is implemented and no material behavior was dropped.
- Confirm physical folders, familiar domain grouping, filenames, declaration order, type ownership, namespacing, documentation, and `MARK` organization follow the applicable guides. Distinguish values that describe data from tools that primarily execute algorithms or accumulate behavior.
- For Redux applications, trace actions, state, reducers, middleware, services, tools, presentation models, views, and side-effect results through the complete data flow. Confirm each Redux component folder contains only that component type.
- Check that framework objects, persistence, logging, and asynchronous work remain in their allowed boundaries.
- Check SwiftUI composition, narrow inputs, local versus durable state, localization, accessibility, and safe deterministic previews where applicable.
- Check tests for the required framework, mirrored paths, shared tags, Given/When/Then structure, deterministic seams, and coverage of changed behavior and failure paths.
- Trace every new or changed stateful, asynchronous, fallible, or lifecycle-oriented behavior and verify that its owning artifact emits privacy-safe AppLogger events for the meaningful success, failure, cancellation, recovery, and state-transition outcomes needed to diagnose it. Dependency declaration and target linkage alone do not establish logging coverage. Accept silence for pure values or utilities only when there is no meaningful event boundary and the implementation handoff records that deliberate decision.
- Check logging ownership, subsystem, categories, emoji, privacy, severity, metadata stability, noise controls, and focused formatter or sink tests when logging changed.
- For every Apple-platform application or Swift package in scope, except the AppLogger provider repository itself, verify integration with the shared [Logging guide](../../../Guidelines/Logging.md): confirm the AppLogger dependency is declared, the `AppLogger` library product is linked to every target that emits diagnostics, and any new project has it available in its primary runtime target before its first log call. Search the actual package or Xcode dependency graph rather than relying on an `import` alone, and treat `print`, direct `Logger` instances, or duplicate logging backends as incomplete integration when they emit project diagnostics. When implementation is authorized, add or repair the dependency and target linkage and migrate affected calls while preserving the guide's ownership, subsystem, category, emoji, privacy, severity, and noise rules; report an exact blocker when target or platform constraints make safe integration ambiguous.
- Inspect dependency manifests, resolver or lock files, Xcode package references, vendored source or binary frameworks, and equivalent dependency declarations. Compare the change with the baseline and identify every new third-party dependency or expansion of an existing third-party dependency into a new target or runtime role. Apply the shared [external dependency policy](../../../Guidelines/Development.md#external-dependencies): require explicit repository-owner approval before the dependency is introduced and require the durable exception record in repository documentation. Do not infer approval merely from an execution plan, pull-request description, implementation convenience, package popularity, or the dependency already appearing in the diff. Treat an unapproved or undocumented third-party dependency as a blocker to completion. Do not flag Apple system frameworks, the Swift standard library, ThatFactory-owned packages, or guideline-mandated tooling used only for its documented tooling role. If a newly resolved transitive third-party package will be linked into or shipped with the product, verify that its owning direct dependency is covered by an approved exception rather than dismissing it solely because it is transitive.
- Search dependency manifests, generated directories, project files, and documentation for CocoaPods or Carthage adoption. The shared [external dependency policy](../../../Guidelines/Development.md#external-dependencies) forbids both without an exception path and requires Swift Package Manager for package dependencies. When implementation is authorized, remove newly introduced adoption and its generated or configuration files; report pre-existing adoption as a completion blocker when safe migration is outside the task scope.
- Check package configuration, CI/CD, Xcode project configuration, security-sensitive changes, and physical-device limitations when they are in scope. For every Xcode project, perform the project-settings audit below. Compare documented Swift and concurrency settings with the effective application and test-target settings; flag both redundant isolation annotations and missing annotations at compiler-verified boundaries.
- Search for stale type names, superseded files, direct APIs forbidden by the new architecture, empty folders, and references to removed behavior.
- Apply the shared [CI/CD guide](../../../Guidelines/CICD.md) to workflow and repository-automation changes. Search scripts, generated directories, workflow files, and documentation for fastlane adoption and treat it as forbidden without an exception path. Require focused ThatFactory tooling or repository-owned Swift scripts for CI/CD and delivery, and inspect new repository-owned executable scripts for compliance. For Swift-focused applications, games, and packages, accept Python or POSIX shell only when durable repository documentation identifies the missing Swift capability, exact script and task scope, runtime and dependency requirements, security and maintenance impact, validation method, and revisit or removal condition. Reject convenience, familiarity, shorter code, an existing interpreter, or another non-Swift script as justification. Treat every exception as narrow; the central `Scripts/swift_format.sh` wrapper is the retained documented exception for invoking Xcode's `swift-format` modes.
- For pull-request or merge readiness, apply the root `## Code Review Rules`: confirm the Codex review covers the current head, no allowed Codex review round is pending, every Codex review thread has a disposition, and no unresolved P0/P1 blocker remains. Treat P2/P3 observations as non-blocking and never request another Codex review unless the repository owner explicitly authorizes it. This Codex review-round budget does not apply to otherwise-authorized Reasoning Relay/ChatGPT review delegations; do not block them waiting for a Codex-budget exception.

## Audit Xcode project settings

For every checked-in `.xcodeproj`, read and apply the shared [Xcode project-settings guide](../../../Guidelines/Xcode/ProjectSettings.md):

1. Identify the selected Xcode and its newest stable Swift language mode. Inspect every `PBXProject` build configuration and project-level `.xcconfig`; target-only values do not satisfy project-level ownership.
2. Require `GCC_TREAT_WARNINGS_AS_ERRORS`, `MTL_TREAT_WARNINGS_AS_ERRORS`, and `SWIFT_TREAT_WARNINGS_AS_ERRORS` to be `YES`; require `SWIFT_APPROACHABLE_CONCURRENCY = YES`, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, and `SWIFT_STRICT_CONCURRENCY = complete`; require `SWIFT_VERSION` to select that newest stable language mode; and require application targets to inherit `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO` in every configuration.
3. Discover every build setting exposed by the active Xcode whose name begins with `SWIFT_UPCOMING_FEATURE_`. For the selected Swift language mode, use the setting documentation and compiler diagnostics to identify which features remain opt-in. Require those settings to be `YES` at project level, and require flags for features already incorporated into the language mode to be absent so warnings-as-errors cannot turn a redundant-feature diagnostic into a build failure. Treat the settings listed in the shared guide as the Xcode 27 discovery inventory, not as flags that must all be enabled and not as a future-exhaustive list.
4. Enumerate every target and configuration, including application, unit-test, and UI-test targets, and inspect effective values with Xcode project-aware tooling or `xcodebuild -showBuildSettings`. For every application target, inspect the built `Info.plist` and confirm the `ITSAppUsesNonExemptEncryption` Boolean is `NO`. Remove redundant target copies and language-mode-redundant upcoming-feature flags. Treat a disabling or different target override for an applicable baseline setting as a violation unless an exact exception applies.
5. Before reporting a failure, search the nearest applicable `AGENTS.md` and durable project documentation linked from it for an exception naming the exact setting, scope, concrete incompatibility, replacement, impact, validation, and revisit condition. Accept and report an applicable documented exception; do not infer one from transient discussion, generic project prose, or the existing build setting itself. An application may use `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = YES` only when that exact exception documents the shipped non-exempt cryptography and resulting export-compliance workflow.
6. When implementation is authorized, move or add compliant values at project level, remove redundant target copies, and rerun build-setting inspection plus relevant builds. For review-only work, report undocumented gaps without editing.

## Audit Swift package settings

Enumerate every checked-in `Package.swift` that belongs to repository source, ignoring `.build` and other generated build artifacts, and treat each manifest's directory as a package root. For every package, read and apply [the shared package compiler-settings baseline](../../../Guidelines/Packages.md#compiler-settings-baseline); do not infer package rules solely from the Xcode guide.

1. Identify the selected Swift/Xcode toolchain, inspect `// swift-tools-version:` and `swiftLanguageModes`, and require the newest stable language mode from the shared baseline, currently Swift 6. Reject an older effective mode unless an exact documented exception applies.
2. Run `swift package --package-path <package-root> dump-package`, or the selected-toolchain equivalent, and use the evaluated manifest to enumerate locally defined targets and their effective settings. Do not rely only on textual grep because manifests may construct or mutate settings programmatically.
3. For every locally defined target that compiles Swift and for which SwiftPM exposes `swiftSettings`, including production, test, and other applicable Swift target kinds, require unconditional `.treatAllWarnings(as: .error)` plus `ExistentialAny`, `InferIsolatedConformances`, `InternalImportsByDefault`, `MemberImportVisibility`, and `NonisolatedNonsendingByDefault` as `.enableUpcomingFeature(...)` settings. Do not require Swift settings on binary targets, system-library targets, or package plug-in targets because `Target.plugin(...)` does not expose `swiftSettings`.
4. For locally compiled C or Objective-C targets, require the applicable typed `CSetting.treatAllWarnings(as: .error)`; require the corresponding `CXXSetting` where C++ is compiled. Do not require C-family settings when those languages are absent, and do not accept `unsafeFlags` in place of available typed APIs.
5. In Swift 6 mode, treat complete strict concurrency as supplied by the language mode and require every redundant explicit `StrictConcurrency` opt-in to be removed, including `.enableUpcomingFeature("StrictConcurrency")`, `.enableExperimentalFeature("StrictConcurrency")`, and `StrictConcurrency=complete` representations found in the evaluated manifest or effective compiler arguments. Require other upcoming-feature declarations to be removed when they become unconditional in the selected language mode, especially because warnings-as-errors can promote the resulting diagnostics.
6. Do not require or automatically add `.defaultIsolation(MainActor.self)`. Its absence is compliant with the shared package baseline; source-level actor-isolation review remains a separate Swift and concurrency concern.
7. Search the nearest applicable `AGENTS.md` and linked durable documentation before reporting a package-setting failure. Accept only an exception that names the exact setting or feature, package and targets, incompatibility, replacement or omission, impact, compensating validation where applicable, and revisit condition. Do not infer an exception from the manifest.
8. Run the package's documented validation workflow and, at minimum where applicable, `swift build` and `swift test`. Warnings promoted to errors must leave both warning-clean. When conditions or helper logic make the effective invocation uncertain, use verbose SwiftPM output to verify `-warnings-as-errors`, the language mode, and every `-enable-upcoming-feature` argument.

For authorized implementation work, repair the manifest and rerun evaluated-manifest inspection plus builds. For review-only work, report the exact missing, conditional, redundant, or conflicting setting without modifying the package.

## Audit localization

When the repository contains localized targets or String Catalogs, read the shared [Localization guide](../../../Guidelines/Localization.md) and the consumer's local translation guidance:

1. Keep supported languages, catalog and source paths, product voice, glossary, non-translatable terms, and project-specific exceptions in consumer documentation. Do not move those specifics into shared guidance or infer them from another product.
2. Confirm the project uses generated localizable symbols for maintained Swift catalog entries, does not check generated Swift into source control, and does not add localizable Swift literals that bypass the generated API.
3. Require the synchronized `prepare_localizable_symbols.swift` and `validate_string_catalogs.swift` logic. A local wrapper may supply project paths and languages to preserve a stable developer or CI command, but it must not retain a forked copy of shared migration or validation logic.
4. Run the consumer's documented nonmutating preparation check and catalog validator. Confirm CI runs the validator for localized projects and that every configured catalog and Swift source root is covered.
5. Inspect stale entries, required-language coverage, translation states, plural variants, and format placeholders in context. Require source/translated-language, long-text, plural, and right-to-left verification when affected.
6. Establish the explicit Git base for the completed change. If any added, copied, modified, renamed, or untracked `.xcstrings` file exists relative to that base, open every changed catalog in Xcode and inspect its String Catalog editor diagnostics. Record the repository-relative catalog path, selected Xcode version and build, and an explicit result of zero editor errors and zero editor warnings for each catalog.
7. From the consumer root, run `AgentGuidelines/.agents/skills/agent-guidelines-audit/scripts/check_xcstrings_inspection.swift --base-ref <base-ref> --inspected-catalog <catalog-path> --evidence-output <temporary-evidence-path>`, repeating `--inspected-catalog` for every changed catalog. In this source repository, use `.agents/skills/agent-guidelines-audit/scripts/check_xcstrings_inspection.swift`. Keep the JSON evidence outside the repository and summarize its catalog paths, Xcode build, and zero-diagnostic results in the completion handoff and pull-request description.
8. Fail closed when a changed catalog lacks that recorded editor evidence. A catalog validator, `xcstringstool`, warning-clean build, test run, or unrecorded statement that Xcode was checked is not a substitute. Do not claim audit success, open or update a pull request, or declare merge readiness until the evidence gate passes.
9. Preserve machine-translation state until fluent review. Treat missing required validation, unresolved catalog errors or warnings, missing catalog-editor evidence, or undocumented project-specific deviations as incomplete implementation.

## Audit App Store metadata

When a repository contains an `AppStore/` directory or the change affects storefront content, read the shared [App Store metadata guide](../../../Guidelines/AppStore.md) and the consumer's product-specific App Store documentation:

1. Confirm the repository remains the source of truth and follows the app-store-connect-mcp directory format. Keep the app identity, platform versions, locales, product copy, screenshot production, reviewer prerequisites, and export-compliance rationale in consumer documentation.
2. Verify that changed fields and files match the requested domains and locales. Treat omitted fields as unmanaged, preserve curated content outside scope, and apply the consumer's localization voice and terminology to storefront copy.
3. Require scope-matched `validate_repository` and immutable plan evidence for any requested remote synchronization. Inspect additions, changes, removals, destructive modes, operation IDs, plan identity, and digest before application.
4. After an authorized apply, inspect uncertain outcomes through `get_operation_status` without replaying writes, then plan the unchanged scope again and require `noOp: true` remote reconciliation.
5. Confirm `.appstore-connect-mcp/` is ignored and that repository content, diffs, logs, and evidence contain no credentials, private contacts, demo secrets, upload URLs, or operational journals.
6. Treat App Store submission and release as separately authorized operations. Ordinary metadata or asset synchronization never proves release readiness and never authorizes submission.

## Audit documentation consistency

When implementation, configuration, or workflow behavior changed, perform an explicit documentation-drift pass:

1. Read the applicable [Documentation guide](../../../Guidelines/Documentation.md) and identify code-level or durable project documentation that describes the affected feature, API, configuration, workflow, or invariant.
2. Compare those documented claims with the final implementation. Require a documentation update when the change alters durable or core behavior, or when any existing documented claim becomes inaccurate, incomplete, misleading, or obsolete, regardless of change size.
3. Search relevant durable documentation for changed names, removed behavior, defaults, examples, diagrams, setup steps, and references. Inspect matches in context rather than assuming a keyword search alone proves consistency.
4. Do not require new project-level prose for incidental implementation details that are not durable and do not affect an existing documented claim.
5. When implementation is authorized, update or remove stale documentation in the same change. For review-only work, report the drift without editing. Known stale documentation blocks completion.

## Audit documentation formatting

Apply the conventions in the applicable [Documentation guide](../../../Guidelines/Documentation.md) to governed Markdown:

1. Audit every added or changed Markdown file outside a synchronized, provenance-verified `AgentGuidelines/` subtree.
2. When the completed change adds or changes a documentation convention, or updates a consumer to a guideline release that does so, also audit the consumer's existing root Markdown files and declared durable documentation folders. This adoption pass is required even when those files did not otherwise change.
3. From the repository root, run `.agents/skills/agent-guidelines-audit/scripts/check_markdown_wrapping.swift <paths...>` against those files or folders. The checker is read-only and reports prose paragraphs, list items, ordinary blockquotes, and GitHub alert body paragraphs that span multiple physical lines while excluding alert marker lines, fenced code, and other common verbatim Markdown constructs.
4. Inspect each reported span in context. Join confirmed hard-wrapped prose so each paragraph, list item, or blockquote occupies one physical line. Preserve intentional structure such as headings, separate list items, tables, fenced code, and ASCII diagrams.
5. When implementation is authorized, fix confirmed violations and rerun the checker. For review-only work, report them without editing. Do not claim the audit passes while a confirmed line-wrapping violation remains in scope.

## Validate the evidence

Run the repository's declared non-destructive checks in proportion to the change:

- formatter and strict lint;
- focused tests, followed by the declared broader test plan when warranted;
- relevant builds or package validation;
- repository-specific validators;
- `git diff --check`.

When the shared Swift-format guide applies:

- For implementation work, run `AgentGuidelines/Scripts/swift_format.sh format-and-lint` over every changed or applicable checked-in Swift source root before tests. For review-only work, use `lint-strict` so the audit does not mutate files.
- Confirm the root `.swift-format` and `.editorconfig` symlinks resolve to the synchronized shared configurations.
- Confirm pull-request and protected-branch CI run the shared wrapper with `lint-strict` in a dedicated non-mutating job. Reject `format` or `format-and-lint` in CI and verify the listed paths cover the repository's checked-in Swift roots.
- For Xcode projects, verify every independently buildable app or test target has the target-scoped pre-compilation phase described by the guide, including its `CI=true` bypass.
- For Swift packages, format `Package.swift`, `Sources`, `Tests`, and other checked-in Swift roots that exist before running `swift test`. Do not require `swift build` or `swift test` themselves to rewrite source; formatting and testing are consecutive, independently visible checks.

Use fresh successful evidence already produced in the same task instead of rerunning expensive checks without reason. Distinguish automated compilation and simulator evidence from hardware, signing, deployment, or manual validation that automation cannot prove.

## Resolve findings

- When the user authorized implementation, fix safe in-scope findings and rerun the affected checks.
- For review-only work, report findings without modifying code.
- Do not broaden the feature, rewrite unrelated files, edit a synchronized `AgentGuidelines/` subtree, or perform commits, pushes, pull requests, merges, tags, or releases without the required authority.
- Treat an unresolved required guideline violation or missing relevant validation as a blocker to claiming completion.

## Hand off

Summarize:

- the instruction and guideline areas audited;
- consumer-integration validation and any drift found;
- `.gitignore` reconciliation, including added shared patterns and every accepted or unresolved project-specific entry;
- findings fixed during the audit;
- documentation updated or removed, or why no documentation change was required;
- validation commands and outcomes;
- changed-String-Catalog detection and, when applicable, the recorded Xcode version, catalog paths, and zero catalog-editor errors and warnings;
- any deliberate deviations, unavailable evidence, or remaining blockers.

Do not say the work is done merely because the audit ran. Say it is ready only when the requested outcome is complete and the relevant evidence passes.
