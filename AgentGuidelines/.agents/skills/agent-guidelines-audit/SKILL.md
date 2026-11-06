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
- Perform the mandatory [networking check](#audit-networking) for network implementation, dependency changes, and networking-policy adoption.
- Check SwiftUI composition, narrow inputs, local versus durable state, localization, accessibility, and safe deterministic previews where applicable.
- For each new or changed SwiftUI `ScrollView`, apply the shared [scrolling guidance](../../../Guidelines/Swift/SwiftUI.md#scrolling): verify `.scrollBounceBehavior(.basedOnSize)` covers its scrolling axes on supported deployment targets, including scroll views in modal sheets. Check the modifier's environment scope around nested scrollables and require a documented interaction reason for a different bounce behavior.
- Perform the mandatory [native-component and presentation decision check](#audit-native-components-and-presentation) for changed SwiftUI controls and presentation behavior.
- Perform the mandatory [system-control placement check](#audit-system-control-placement) for changed navigation, toolbars, dismissal controls, and window chrome, including affected UIKit/AppKit wrappers.
- Perform the mandatory [animation and image-rendering check](#audit-animation-and-image-rendering) for changed visual transitions, reusable control styles, and dynamic image paths, including directly affected consumers.
- Perform the [Reduce Motion check](#audit-reduce-motion) for affected motion and for Reduced Motion support declarations.
- Perform the [tvOS current-user identity check](#audit-tvos-current-user-identity) when changed behavior relies on selected-profile preferences, CloudKit accounts, or personal store binding.
- Check tests for the required framework, mirrored paths, shared tags, Given/When/Then structure, deterministic seams, and coverage of changed behavior and failure paths.
- Trace every new or changed stateful, asynchronous, fallible, or lifecycle-oriented behavior and verify that its owning artifact emits privacy-safe AppLogger events for the meaningful success, failure, cancellation, recovery, and state-transition outcomes needed to diagnose it. Dependency declaration and target linkage alone do not establish logging coverage. Accept silence for pure values or utilities only when there is no meaningful event boundary and the implementation handoff records that deliberate decision.
- Check logging ownership, subsystem, categories, emoji, privacy, severity, metadata stability, noise controls, and focused formatter or sink tests when logging changed.
- For every in-scope package that emits logs, resolve its canonical emoji from local instructions or documentation and the package list on the current `main` branch of the [ThatFactory Swift Package Collection](https://github.com/thatfactory/swift-package-collection). Enumerate the registered package entries and require each canonical emoji to identify exactly one package, treating visually identical presentation-selector variants as a collision. Confirm the package documentation, package-local logging gateway, and registry entry use the same emoji. When creating a package or assigning or changing its emoji, verify the intended emoji is unused before accepting it and require the registry update in the publication work. A collision, a missing registry entry for a published package, an unreachable current registry, or disagreement among these sources blocks audit completion and release readiness.
- For every Apple-platform application or Swift package in scope, except the AppLogger provider repository itself, verify integration with the shared [Logging guide](../../../Guidelines/Logging.md): confirm the AppLogger dependency is declared, the `AppLogger` library product is linked to every target that emits diagnostics, and any new project has it available in its primary runtime target before its first log call. Search the actual package or Xcode dependency graph rather than relying on an `import` alone, and treat `print`, direct `Logger` instances, or duplicate logging backends as incomplete integration when they emit project diagnostics. When implementation is authorized, add or repair the dependency and target linkage and migrate affected calls while preserving the guide's ownership, subsystem, category, emoji, privacy, severity, and noise rules; report an exact blocker when target or platform constraints make safe integration ambiguous.
- Inspect dependency manifests, resolver or lock files, Xcode package references, vendored source or binary frameworks, and equivalent dependency declarations. Compare the change with the baseline and identify every new third-party dependency or expansion of an existing third-party dependency into a new target or runtime role. Apply the shared [external dependency policy](../../../Guidelines/Development.md#external-dependencies): verify any explicit standing approval covers the exact dependency and role; otherwise require explicit repository-owner approval before the dependency is introduced and require the durable exception record in repository documentation. Do not infer approval merely from an execution plan, pull-request description, implementation convenience, package popularity, or the dependency already appearing in the diff. Treat an unapproved or undocumented third-party dependency as a blocker to completion. Do not flag Apple system frameworks, the Swift standard library, ThatFactory-owned packages, or guideline-mandated tooling used only for its documented tooling role. Apply the [networking standing approval](../../../Guidelines/Networking.md#standing-dependency-approval) only within its documented scope. If a newly resolved transitive third-party package will be linked into or shipped with the product, verify that its owning direct dependency is covered by an approved role and the transitive package fits that role rather than dismissing it solely because it is transitive.
- Search dependency manifests, generated directories, project files, and documentation for CocoaPods or Carthage adoption. The shared [external dependency policy](../../../Guidelines/Development.md#external-dependencies) forbids both without an exception path and requires Swift Package Manager for package dependencies. When implementation is authorized, remove newly introduced adoption and its generated or configuration files; report pre-existing adoption as a completion blocker when safe migration is outside the task scope.
- Check package configuration, CI/CD, Xcode project configuration, security-sensitive changes, and physical-device limitations when they are in scope. For every Xcode project, perform the project-settings audit below. Compare documented Swift and concurrency settings with the effective application and test-target settings; flag both redundant isolation annotations and missing annotations at compiler-verified boundaries.
- Search for stale type names, superseded files, direct APIs forbidden by the new architecture, empty folders, and references to removed behavior.
- Apply the shared [CI/CD guide](../../../Guidelines/CICD.md) to workflow and repository-automation changes. Search scripts, generated directories, workflow files, and documentation for fastlane adoption and treat it as forbidden without an exception path. Require focused ThatFactory tooling or repository-owned Swift scripts for CI/CD and delivery, and inspect new repository-owned executable scripts for compliance. For Swift-focused applications, games, and packages, accept Python or POSIX shell only when durable repository documentation identifies the missing Swift capability, exact script and task scope, runtime and dependency requirements, security and maintenance impact, validation method, and revisit or removal condition. Reject convenience, familiarity, shorter code, an existing interpreter, or another non-Swift script as justification. Treat every exception as narrow; the central `Scripts/swift_format.sh` wrapper is the retained documented exception for invoking Xcode's `swift-format` modes.
- For pull-request or merge readiness, apply the root review and lifecycle contracts and [review-policy integration](../../../ReviewPolicy/README.md). Rerun the latest published policy check immediately before merge. Require a completed initial Codex review for its recorded head, or that review plus a recorded locally verified remediation-only delta; do not claim the newer head was bot-reviewed. Confirm no allowed review is pending, every thread is dispositioned and resolved, and no unresolved P0/P1 blocker remains. Treat P2/P3 observations as non-blocking and never request another review unless the owner explicitly authorizes it. Review-only adoption enforces only these contracts, not unrelated engineering audits.

## Audit runner toolchains

Apply the [runner toolchain policy](../../../Guidelines/CICD.md#runner-toolchain) when reviewing or changing Apple build automation, adopting that policy, or performing an Xcode upgrade:

1. Inspect every applicable workflow and its invoked scripts, setup actions, environment overrides, and runner labels. Search for Xcode/Swift version comparisons, build-number checks, allowlists, upper bounds, and versioned installation paths; inspecting workflow YAML alone is insufficient when a script performs the check.
2. Verify ordinary CI uses and logs the runner's active toolchain. Distinguish version pins from minimum package tools versions, Swift language modes, SDK/deployment requirements, simulator destinations, and actual capability/readiness checks. A documented historical test version and a process-scoped selection for an explicit upgrade are not permanent CI constraints.
3. For each retained pin, inspect the canonical guide's required repository exception and evidence. Do not invent a compatibility reason or treat the previous upgrade target as one. When implementation is authorized, remove unjustified pins and reconcile current setup documentation; in review-only work, report their locations and missing justification. An unjustified pin in scope prevents audit completion.
4. Run affected toolchain reporting and the repository's build/test validation with the active installation. Record the selected Xcode/Swift versions, commands, outcomes, and any justified exception. Do not claim compatibility with untested future releases; removing a string check ensures those releases reach real validation.

| Scenario | Audit outcome |
| --- | --- |
| New runner Xcode passes compilation and tests, but an old equality check fails | Remove the unjustified check and rerun affected validation |
| Workflow accepts the runner, but its invoked script requires one build number | Treat the script as the same pin and require removal or a documented exception |
| A supported package declares its minimum Swift tools version and language mode | Preserve the capability requirements |
| An exact toolchain has a documented incompatibility or external requirement with evidence and a revisit condition | Accept only the scoped exception and report it |

## Audit Swift package badges

When creating or changing a Swift package README, adopting the badge policy, or auditing package documentation, inspect the actual README badge URLs and labels against [README badges](../../../Guidelines/Packages.md#readme-badges). Omit Updated/last-commit-date and Revision/latest-release-version badges unless the repository documents the guide's specific exception. Distinguish release-version endpoints from Release/publishing workflow-status badges; keep the latter when they describe the package's own workflow. A Release label alone does not identify which kind it is.

For authorized implementation, remove unjustified date/version badges and correct affected documentation; for review-only work, report the badge and missing rationale. An undocumented date/version badge in scope prevents audit completion. Record the inspected README, retained workflow-status badges, and any accepted exception. Do not create badges or release workflows solely to fill an inapplicable slot.

## Audit networking

Apply [Networking](../../../Guidelines/Networking.md) to Apple-platform applications, games, and Swift packages:

1. Identify changed networking, dependency declarations, and directly affected existing request paths. On first adoption of this networking policy, inventory all existing network implementations and dependencies. For unrelated changes, do not expand into a whole-repository migration. Record evidence-backed `not applicable` when there is no networking in scope, or distinguish non-HTTP and framework-owned traffic from owned HTTP.
2. Inspect actual transport calls, request construction, response handling, package manifests, resolver files, Xcode product references, and target linkage. For owned HTTP, verify `HTTPTypes` and `HTTPTypesFoundation` from Apple's `swift-http-types` are available to the appropriate targets and that requests, responses, methods, header fields/names, and statuses use the guide's typed representations with native `URLSession`. Dependency presence or imports alone do not establish compliance. Verify the selected release and compatibility evidence against supported platforms and toolchains.
3. Inspect native Foundation bridges in context. Require the native API reason, conversions at that boundary, failure handling, and retained typed request/response ownership. Accept non-HTTP Apple APIs and framework-owned traffic without artificial HTTP wrappers. Search directly affected code for parallel string/integer HTTP models and hidden alternative transports; a first-party wrapper does not exempt its implementation.
4. For an alternative networking dependency, require the guide's demonstrated Apple capability gap, explicit repository-owner approval, durable scoped exception, and validation. An existing dependency is not approval for a new role. For adoption debt outside authorized migration scope, require an explicit owner-approved migration deferral identifying paths, rationale, and follow-up condition; report it as deferred compliance, never full networking compliance. A deferral does not authorize new noncompliant networking.
5. Require the guide's relevant deterministic request/response, status, failure, cancellation, and bridge tests for changed implementation. Record source paths, target/dependency evidence, exceptions or deferrals, commands, and outcomes. Documentation-only policy work uses scenario walkthroughs; do not invent live-network requirements for pure policy changes.
6. Missing typed implementation or native transport in scope, unapproved alternatives, undocumented bridges, unaccounted adoption debt, or missing applicable validation prevents audit completion. Fix authorized in-scope violations; report exact blockers instead of rewriting unrelated consumers.

Use these scenarios to distinguish valid outcomes:

| Scenario | Audit outcome |
| --- | --- |
| Owned HTTP uses typed requests/responses and both products at the appropriate targets with `URLSession` | Accept with implementation and validation evidence |
| Dependency/import is present but the service still owns untyped HTTP | Incomplete |
| Native background/delegate API uses a documented, tested Foundation conversion boundary | Accept with retained typed HTTP ownership |
| Only CloudKit, WebKit, or non-HTTP Apple networking is in scope | No artificial HTTP dependency; verify the relevant native boundary |
| Alternative library chosen for convenience, including behind a ThatFactory wrapper | Block until compliant or covered by the capability-gap exception |
| Adoption discovers untouched legacy HTTP | Migrate within scope or record an explicit owner-approved deferral; no full-compliance claim |
| No networking implementation or dependency change, and no policy adoption | Evidence-backed not applicable |

## Audit native components and presentation

Apply the authoritative [SwiftUI native-component policy](../../../Guidelines/Swift/SwiftUI.md#native-components-and-presentation) to changed controls and presentation flows:

1. Inspect changed custom modal hosts, overlay/scrim/offset code, and gesture routing in context. These are investigation signals, not blanket prohibitions on overlays or styling. Include existing hosts directly affected by the change, including discard dialogs; do not assume a native child makes every surrounding presentation compliant.
2. Record the supported interaction, native alternative, deployment-target availability, and who owns presentation and dismissal. Distinguish branded content within a native component from replacing its lifecycle.
3. For each custom equivalent, verify the capability-gap evidence, explicit repository-owner approval, durable consumer exception, and compensating validation required by the policy. A suitable native alternative without the required approved and documented exception blocks audit completion. Do not treat a mockup or unchanged mounted state as approval.
4. Trace child dismissal, parent draft ownership, nested picker/editor presenters, cancellation, and dismissal-completion cleanup through the affected hierarchy and asynchronous work. Confirm that a native nested sheet with branded content is accepted when ownership and evidence satisfy the policy.
5. Require the policy's [interaction evidence](../../../Guidelines/Swift/SwiftUI.md#required-interaction-evidence) for each affected flow. Inspect actual actions and observed outcomes, including recorded manual gesture verification when needed; static screenshots and no-op automation do not establish gesture behavior. Missing relevant runtime evidence blocks audit completion. Record an exact blocker for unavailable verification and include decisions, exception references, and evidence in the handoff.

## Audit system control placement

Apply the authoritative [system control placement policy](../../../Guidelines/Swift/SwiftUI.md#system-control-placement):

1. Identify the owner and intent of each affected Back, Close, Cancel, Done, confirmation, or window control. Trace native toolbar placements and roles, app-authored headers, hidden Back controls, and surrounding system picker/editor presentations. Inspect directly affected existing code as well as added lines.
2. Verify that semantic placement and roles describe the action rather than force a physical side. Treat explicit leading/trailing slots, spacers, offsets, custom headers, and hidden native controls as investigation signals, not blanket failures. For standard controls, require the policy's documented platform reason for explicit placement or its approved capability-gap exception for a custom equivalent. Do not require such an exception for ordinary app-specific content layout that does not replace native system behavior.
3. Accept valid system-selected differences across platforms, OS versions, window sizes, and layout directions. Reject a universal left/right requirement, relocation of system-owned picker/editor controls, or replacement of native Back solely for visual consistency. Check affected design artifacts and durable documentation for conflicting placement mandates.
4. For changed navigation or toolbar behavior, record supported target/OS and targeted runtime actions and outcomes: Back navigates, dismissal closes the intended presentation, and cancellation/confirmation retain their actual semantics. Check relevant layout direction, accessibility, keyboard/remote, and gesture behavior. When presentation lifecycle also changes, apply the existing [interaction evidence requirements](../../../Guidelines/Swift/SwiftUI.md#required-interaction-evidence) to that affected flow. Documentation-only policy changes do not require simulator evidence.
5. An unjustified placement override or missing relevant interaction evidence blocks audit completion. Report the exact control, ownership, violated policy, and missing evidence; do not report an Apple-selected side as a defect.

## Audit animation and image rendering

Apply the authoritative [animation policy](../../../Guidelines/Swift/SwiftUI.md#animation) and [image-rendering policy](../../../Guidelines/Swift/SwiftUI.md#image-rendering) to changed components and directly affected consumers; do not expand the audit into unrelated screens.

1. Identify each meaningful visual transition, its owner, and its intended animation or justified immediate feedback. Inspect stable view identity and transaction scope, including simultaneous changes and surrounding layout animations; an `.animation` modifier alone is not evidence of correct scope. Accept appropriate native feedback without additional animation.
2. Verify reusable defaults without caller-added animation. Exercise enabled to disabled and disabled to enabled, ordinary presses, rapid reversals, and relevant show/hide behavior. Confirm enabled state, hit-testing, accessibility state, and action availability change immediately while appearance animates.
3. Inspect affected image paths for repeated preparation, oversized drawable content, unstable identity, unbounded caches, and stale publication. Verify derivative refresh for changed source or presentation requirements, bounded intermediate memory, preservation of authoritative originals, and rejection of stale results after replacement, cancellation, or removal. Use applicable deterministic tests for asynchronous races alongside interaction evidence.
4. Exercise representative large-image content when images participate in the interaction. For image-related regressions, compare with an image-free scenario and record the actual representation drawn; do not infer a provider defect from the source of one expensive image.
5. Require recorded runtime actions and outcomes for meaningful motion changes: platform/OS, scenario, actions, and observed behavior. Compilation, static screenshots, and idle captures do not prove smooth interaction. Documentation-only policy changes require scenario walkthroughs rather than simulator evidence.
6. For reported stutter, use Apple performance tools where available and authorized. Record the active interaction window, workload, observations, and limitations. Distinguish recorded manual verification from instrumented measurements; an idle capture reporting zero hitches is insufficient. Do not require profiling every cosmetic change or impose a universal frame-rate threshold.
7. Unexplained abrupt transitions in affected reusable controls, demonstrated performance regressions, or missing applicable interaction evidence prevent audit completion. Record the exact component, violated policy, required correction or justified intentional exception, and unavailable evidence.

Use these scenario walkthroughs when evaluating the check:

| Scenario | Audit outcome |
| --- | --- |
| Custom main-button style changes colors abruptly | Blocked until shared behavior is corrected or an intentional immediate transition is justified |
| Shared style animates both directions; actions remain immediate | Accepted with runtime evidence, including ordinary presses and rapid reversals |
| Appropriate native control already supplies feedback | Accepted without additional animation |
| Animated thumbnail repeatedly processes a large original | Requires correction and relevant verification |
| Prepared derivative preserves originals and rejects stale results | Accepted with applicable tests and interaction evidence |
| Zero hitches recorded without actual interaction | Insufficient performance evidence; applicable verification remains blocked |

## Audit Reduce Motion

Apply the canonical [Reduce Motion policy](../../../Guidelines/Swift/SwiftUI.md#reduce-motion) and its [support declaration requirements](../../../Guidelines/Swift/SwiftUI.md#declaring-support):

1. For changed motion and directly affected components, identify each potential trigger, its owner, and its chosen adaptation or evidence that no adaptation is needed. Inspect custom styles and surrounding transactions as well as native controls. Do not require removal of harmless feedback or a separate task request for an applicable adaptation.
2. Verify the source of the preference, response to changes during use, and preserved information, functional state, and native accessibility behavior. For an in-app alternative, inspect the consumer's rationale and criteria coverage. Reject blanket suppression that loses meaningful feedback and unresolved problematic motion.
3. Require runtime actions and outcomes with Reduce Motion on and off, plus a preference change while running. Record platform/OS, app revision, scenarios, results, and verification limits. Static screenshots, compilation, an environment read, or the use of a native component alone do not prove support. Accept recorded manual verification when automation cannot exercise the setting; missing applicable evidence blocks completion of the affected work.
4. For an app-wide support declaration, expand the evidence scope to all common tasks on the declared platform, following the linked Apple criteria for content and advertising. Check the consumer evidence and current release scope; withhold or correct unsupported claims. A local component check or guideline adoption is insufficient. Re-evaluate existing declarations during app updates; do not demand an unrelated whole-app audit for an isolated motion change when no declaration is in scope.
5. Documentation-only policy work uses scenario walkthroughs rather than simulator testing. Report the exact trigger, missing evidence, or unsupported declaration that prevents audit completion; do not claim this central audit establishes any consumer app's support.

| Scenario | Audit outcome |
| --- | --- |
| Decorative depth effect ignores the enabled preference | Blocked until adapted and exercised |
| Informative movement becomes a fade and retains its meaning | Accepted with on/off and live preference-change evidence |
| Native control already adapts correctly | Accepted with interaction evidence; no duplicate guard required |
| Every animation is removed and a status change becomes imperceptible | Blocked until meaningful feedback is restored |
| No problematic motion across evaluated common tasks | Support declaration may pass with platform-specific evidence |
| One compliant component or guideline adoption used to claim app-wide support | Declaration blocked pending common-task evaluation |

## Audit tvOS current-user identity

Apply the [tvOS current-user and CloudKit guidance](../../../Guidelines/Xcode/DeviceInteraction.md#tvos-current-user-data-and-cloudkit) only when the change implements or materially affects selected-profile storage, CloudKit account routing, or personal-store transitions on tvOS. Documentation-only work and unrelated UI changes do not require a physical multi-user run.

For applicable implementation, inspect the effective signed tvOS entitlement and provisioning privilege, then require privacy-safe real-device evidence from two distinct full Apple Accounts: native profile selection, fresh app process/build identity, the account verified by the CloudKit boundary, its bound store/checkpoint, and distinct A/B content across repeated A → B → A switches and a cold launch. A profile label, `shouldStorePreferencesForCurrentUser`, a new PID, unit tests, or an unsigned/simulator build does not establish account isolation. If CloudKit verifies one account while the store belongs to another, treat the host binding as a defect; if it verifies the default account under a selected secondary profile, preserve evidence and diagnose the device context before proposing app code. Do not retain raw account IDs, record IDs, credentials, or user-authored content in audit evidence.

When the consumer's acceptance contract requires genuine two-account behavior and that evidence is absent or contradictory, report the gate as incomplete and withhold completion or merge readiness. Record an explicit consumer-approved deferral only when its product contract permits one; never silently substitute compilation for physical isolation.

| Scenario | Audit outcome |
| --- | --- |
| A and B each verify distinct CloudKit accounts and stores through repeated native switches | Accept the isolation evidence for the tested build and path |
| B is selected but CloudKit verifies A despite a fresh, correctly entitled process | Block isolation acceptance and diagnose device profile context without app-side account guessing |
| CloudKit verifies B but the host opens A's store | Block as a host account-to-store binding defect |
| Only build, simulator, or profile-label evidence exists | Record the real-device isolation gate as unverified when applicable |

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
- networking applicability, typed/native implementation evidence, exceptions or migration deferrals, and relevant validation;
- `.gitignore` reconciliation, including added shared patterns and every accepted or unresolved project-specific entry;
- findings fixed during the audit;
- documentation updated or removed, or why no documentation change was required;
- validation commands and outcomes;
- changed-String-Catalog detection and, when applicable, the recorded Xcode version, catalog paths, and zero catalog-editor errors and warnings;
- any deliberate deviations, unavailable evidence, or remaining blockers.

Do not say the work is done merely because the audit ran. Say it is ready only when the requested outcome is complete and the relevant evidence passes.
