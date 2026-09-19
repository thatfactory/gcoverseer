# Xcode Project Settings

Use Apple's [Build settings reference](https://developer.apple.com/documentation/xcode/build-settings-reference) for the current setting names and behavior. Apply this baseline to every checked-in Xcode project.

## Project-level ownership

Define the required settings in every project build configuration so application, extension, framework, unit-test, UI-test, and other targets inherit one baseline. An `.xcconfig` counts as project-level ownership only when the project's build configurations reference it; a target-only configuration does not.

Do not satisfy this policy with repeated target-level values. Remove redundant target copies so inheritance remains visible. A target may override a project value only under a documented exception that names that target and setting.

## Required baseline

Set all warning policies to `YES`:

- `GCC_TREAT_WARNINGS_AS_ERRORS`
- `MTL_TREAT_WARNINGS_AS_ERRORS`
- `SWIFT_TREAT_WARNINGS_AS_ERRORS`

Set the concurrency baseline:

- `SWIFT_APPROACHABLE_CONCURRENCY = YES`
- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`
- `SWIFT_STRICT_CONCURRENCY = complete`

For application targets, set `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO` at project level so every configuration generates Apple's [`ITSAppUsesNonExemptEncryption`](https://developer.apple.com/documentation/bundleresources/information-property-list/itsappusesnonexemptencryption) Boolean with the value `NO`. This declares that the shipped app does not use non-exempt encryption and avoids App Store Connect's recurring missing-compliance questionnaire. Verify the generated Boolean in the built app before upload and reassess it whenever the app or a linked dependency introduces cryptography.

Set `SWIFT_VERSION` to the newest stable Swift language mode supported by the selected Xcode. The current language mode is Swift 6, serialized as `SWIFT_VERSION = 6.0`; move to 7, 8, 9, and later stable modes when their supporting Xcode releases are adopted. Do not confuse the compiler's minor release, such as Swift 6.4, with the Swift language mode.

Inspect every build setting exposed by the selected Xcode whose name begins with `SWIFT_UPCOMING_FEATURE_`. Enable each feature that remains opt-in under the selected Swift language mode. Do not set an upcoming-feature flag when that language mode already enables the feature unconditionally: Swift diagnoses some redundant flags, and warnings-as-errors can turn that diagnostic into a build failure. `SWIFT_APPROACHABLE_CONCURRENCY` enables a subset of concurrency features but does not replace the applicable explicit upcoming-feature settings.

The Xcode 27 inventory to evaluate is:

- `SWIFT_UPCOMING_FEATURE_CONCISE_MAGIC_FILE`
- `SWIFT_UPCOMING_FEATURE_DEPRECATE_APPLICATION_MAIN`
- `SWIFT_UPCOMING_FEATURE_DISABLE_OUTWARD_ACTOR_ISOLATION`
- `SWIFT_UPCOMING_FEATURE_DYNAMIC_ACTOR_ISOLATION`
- `SWIFT_UPCOMING_FEATURE_EXISTENTIAL_ANY`
- `SWIFT_UPCOMING_FEATURE_FORWARD_TRAILING_CLOSURES`
- `SWIFT_UPCOMING_FEATURE_GLOBAL_ACTOR_ISOLATED_TYPES_USABILITY`
- `SWIFT_UPCOMING_FEATURE_GLOBAL_CONCURRENCY`
- `SWIFT_UPCOMING_FEATURE_IMPLICIT_OPEN_EXISTENTIALS`
- `SWIFT_UPCOMING_FEATURE_IMPORT_OBJC_FORWARD_DECLS`
- `SWIFT_UPCOMING_FEATURE_INFER_ISOLATED_CONFORMANCES`
- `SWIFT_UPCOMING_FEATURE_INFER_SENDABLE_FROM_CAPTURES`
- `SWIFT_UPCOMING_FEATURE_INTERNAL_IMPORTS_BY_DEFAULT`
- `SWIFT_UPCOMING_FEATURE_ISOLATED_DEFAULT_VALUES`
- `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY`
- `SWIFT_UPCOMING_FEATURE_NONFROZEN_ENUM_EXHAUSTIVITY`
- `SWIFT_UPCOMING_FEATURE_NONISOLATED_NONSENDING_BY_DEFAULT`
- `SWIFT_UPCOMING_FEATURE_REGION_BASED_ISOLATION`

Treat this list as discovery input for Xcode 27, not as a set of flags that must all be present and not as a permanent exhaustive list. When adopting a newer Xcode, compare its build settings with this prefix and evaluate newly exposed settings against the selected Swift language mode. Require each still-upcoming feature at project level; omit each feature already incorporated into the language mode.

## Swift package parity

Whenever this Xcode project baseline adds, removes, or changes a Swift or Clang compiler policy, evaluate whether Swift Package Manager exposes a semantically equivalent setting and whether that policy is appropriate for reusable packages. When it is, update the [Swift package compiler-settings baseline](../Packages.md#compiler-settings-baseline), the Swift-package completion audit, and their structural validation in the same change. Do not mechanically copy application-only policy such as `Info.plist` declarations, Metal settings without a SwiftPM equivalent, or default MainActor isolation into the package baseline.

## Audit procedure

1. Identify the selected Xcode version and its newest stable Swift language mode.
2. Inspect the `PBXProject` build configurations and any project-level `.xcconfig` files. Confirm every Debug, Release, and custom configuration defines the complete baseline.
3. Compare the active Xcode's build settings with the `SWIFT_UPCOMING_FEATURE_` prefix so newly introduced settings are not missed. Use the setting documentation and compiler diagnostics for the selected language mode to distinguish still-upcoming features from features that are already unconditional.
4. Enumerate every target, including application targets and unit-test and UI-test targets, and every supported configuration. Use Xcode project-aware tooling or `xcodebuild -showBuildSettings` to verify the effective values. For each application target, also inspect the built `Info.plist` and require the `ITSAppUsesNonExemptEncryption` Boolean to be `NO`.
5. Inspect target build configurations for redundant copies, disabling values, overrides, or upcoming-feature flags that are redundant in the selected language mode. Remove redundant copies and resolve undocumented overrides.
6. Build the relevant configurations and treat every warning as a failure unless an applicable documented exception explicitly covers the setting that would otherwise promote it.

## Exceptions

An incompatible project or target requirement may specialize one or more settings only when the nearest applicable `AGENTS.md`, or durable project documentation linked from it, records:

- each exact setting name;
- the affected project, configurations, and targets;
- the concrete requirement that prevents the baseline value;
- the replacement value or omitted setting and its engineering impact;
- compensating validation where relevant; and
- the condition for removing or revisiting the exception.

The audit accepts an applicable documented exception and reports the deviation without failing the project for that setting. A transient discussion, generic statement that a project uses different settings, or the existing target configuration by itself is not an exception.

An application that uses non-exempt encryption must set `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = YES` and document that exact setting as an exception, including the cryptography that requires the declaration and the resulting export-compliance workflow. The audit accepts a generated `ITSAppUsesNonExemptEncryption = YES` under that documented exception instead of reporting a false positive.
