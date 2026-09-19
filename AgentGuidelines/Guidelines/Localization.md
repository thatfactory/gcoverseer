# Localization

Follow Apple's [Localizing your app using agents](https://developer.apple.com/documentation/xcode/localizing-your-app-using-agents) workflow and current Xcode localization tools. Consumer repositories declare their supported languages, catalog and source locations, product voice, terminology, and narrow exceptions locally.

Storefront metadata uses separate App Store locale identifiers and files. Follow [App Store metadata](AppStore.md) for the repository structure and App Store Connect synchronization workflow; apply the consumer's local voice and product terminology to both application and storefront copy.

## Source artifacts

- Use the consumer's existing String Catalogs (`.xcstrings`) as the source of truth.
- Do not create a parallel catalog or migrate an existing `.strings` setup unless the task includes that migration.
- An app target uses its main bundle by default. Swift packages and frameworks must resolve localized resources from their own bundle, using the current Apple-recommended bundle API.
- Keep one source of truth for translator context: either the source comment or the catalog comment.

## Generated symbols

- Define user-facing text in the appropriate String Catalog first and use Xcode-generated `LocalizedStringResource` symbols from Swift. Enable Generate String Catalog Symbols when an older project does not already generate them.
- Give a string a semantic catalog key when deriving a readable symbol from its source value would be ambiguous. Name formatted variables in the source value so Xcode generates labeled parameters.
- Use generated properties and functions directly in SwiftUI, and resolve them with `String(localized:)` or `AttributedString(localized:)` only where that concrete value is required.
- Generated Swift is build output. Inspect it through Xcode or `xcstringstool` when useful, but never edit or check it in.
- Do not add new localizable Swift literals after a project adopts generated symbols. Use `Text(verbatim:)` only for nonlinguistic punctuation, identifiers, and other intentionally unlocalized content.

## User-facing values

- Let SwiftUI's localized string initializers preserve localization context.
- Use `LocalizedStringResource` when a model, view state, notification, or other non-view value carries user-facing text that should resolve later.
- Use `String(localized:)` when a resolved localized `String` is genuinely required outside SwiftUI.
- Use `Text(verbatim:)` for intentional non-localized literals such as debug identifiers.
- Do not pass a runtime `String` to a localized initializer and expect Xcode to extract it as a catalog key.

## Sentences and formatting

- Interpolate values into one localizable sentence rather than concatenating translated fragments.
- Add translator comments for ambiguous language and describe interpolated placeholders by position and meaning.
- Use locale-aware `FormatStyle` APIs for dates, numbers, lists, measurements, and currencies.
- Avoid runtime case transformations for localized interface text; allow translations to choose appropriate casing.
- Keep placeholder positions, semantic names, and conversion types identical across source and translated variants.
- Add language-specific plural variants for counts instead of branching between singular and plural text in Swift.
- Preserve the distinction between unavailable data and numeric zero.

## Layout

- Use leading and trailing instead of left and right for directional layout.
- Avoid fixed text frames that cannot accommodate translation length or script height.
- Prefer semantic text styles to fixed point sizes.
- Use the SwiftUI environment locale for view behavior that must respond to preview or subtree locale overrides.

## Agent workflow

1. Inspect the consumer's local localization instructions and catalogs.
2. Ask Xcode's current documentation or localization capability for the supported workflow.
3. Add the key, source-language value, and translator comment directly to the catalog. Mark an explicitly maintained generated-symbol entry as manual and use named placeholders for formatted values.
4. Inspect the generated API through Xcode's catalog inspector or, when needed, `xcrun xcstringstool generate-symbols`. Use the generated property or function from Swift.
5. For a legacy catalog whose keys were extracted from Swift literals, run the shared preparation script once. It preserves comments, variants, and translations, leaves stale entries for an explicit decision, and refuses to invent a missing source value for an already-manual semantic key. Use `--check` for a nonmutating readiness check.
6. Use Xcode's localization coordinator and String Catalog tools to add or update only the languages in scope. Do not replace contextual translation decisions with ad hoc JSON-rewriting scripts.
7. Resolve every stale extracted entry and every active translated value marked `new` or `needs_review`. Keep agent output machine-translated until a fluent reviewer approves it.
8. Run the shared catalog validator after every catalog or localization-source change. It checks generated-symbol readiness, stale entries, required languages, translation states, format signatures, and Swift literals that bypass generated symbols.
9. Open each changed catalog in Xcode and require zero catalog-editor errors or warnings; these diagnostics do not necessarily become compiler warnings. Record the inspected catalog paths, selected Xcode version and build, and explicit zero-error and zero-warning result. Automated catalog validation, a warning-clean build, or an unrecorded visual check does not satisfy this editor-evidence gate.
10. Build and test source and translated languages. Exercise long strings, every plural branch, and right-to-left layout even when no right-to-left locale ships.
11. Have a fluent reviewer inspect machine translations before recording them as reviewed.

## Shared scripts

Supply project-specific paths and supported languages at the consumer boundary:

```sh
AgentGuidelines/Scripts/prepare_localizable_symbols.swift \
  <path-to-Localizable.xcstrings> \
  --check

AgentGuidelines/Scripts/validate_string_catalogs.swift \
  --catalog-directory <catalog-directory> \
  --source-directory <swift-source-directory> \
  --required-language <language-identifier>
```

Repeat directory, catalog, or language options when the project has several. A consumer may keep a small repository-owned wrapper so existing developer and CI commands supply its paths and languages consistently; the wrapper must delegate to the synchronized shared script rather than copy its validation or migration logic.

The completion audit discovers changed String Catalogs relative to an explicit Git base and fails closed until every catalog has a recorded Xcode editor inspection. After opening each changed catalog and confirming zero editor errors and warnings, run the audit helper from the consumer root and keep its JSON outside the repository:

```sh
AgentGuidelines/.agents/skills/agent-guidelines-audit/scripts/check_xcstrings_inspection.swift \
  --base-ref <pull-request-base-ref> \
  --inspected-catalog <repository-relative-catalog-path> \
  --evidence-output <temporary-evidence-path>
```

Repeat `--inspected-catalog` for every changed catalog. The helper records the selected Xcode version and build together with the zero-diagnostic result. Summarize that record in the completion handoff and pull-request description; do not commit the temporary JSON evidence.

Do not invent translations from an unrelated project's conventions. Product vocabulary and tone remain consumer-specific.

## References

- [Using generated localizable symbols in your code](https://developer.apple.com/documentation/xcode/using-generated-localizable-symbols-in-your-code)
- [Localizing your app using agents](https://developer.apple.com/documentation/xcode/localizing-your-app-using-agents)
