# App Store metadata

Use a version-controlled `AppStore/` directory as the source of truth for managed App Store Connect content. Edit repository files first, then synchronize them with ThatFactory's [app-store-connect-mcp](https://github.com/thatfactory/app-store-connect-mcp). Do not maintain managed descriptions, promotional text, screenshots, or review notes through independent browser edits.

## Repository structure

Follow the MCP's current [AppStore directory format](https://github.com/thatfactory/app-store-connect-mcp/blob/main/Documentation/AppStore-Format.md). Keep structured values in JSON, prose in UTF-8 text files, and reusable screenshot originals under `AppStore/assets/`. One `AppStore/` root represents one App Store app; require an explicit root when a repository contains more than one app.

Keep product-specific values in the consumer repository, including the Apple ID, bundle identifier, platforms, version strings, storefront locales, categories, URLs, product copy, review instructions, screenshot sets, and any narrower synchronization commands. Storefront locale identifiers and files are distinct from application String Catalogs, but the consumer's documented voice and terminology apply to both.

Omission means unmanaged. Add only fields and domains the project intends to reconcile. Do not infer missing translations, version values, categories, availability, capabilities, or release choices from another project.

## Synchronization workflow

1. Edit only the requested files and fields in `AppStore/`. Preserve curated content outside the requested scope and obtain the project's required translation review for localized copy.
2. Run `validate_repository` with the explicit App Store root, platform, version, locales, and selected domains. Treat validation as scope-aware: unfinished content outside the intended operation must not expand that operation.
3. Run the applicable planning tool with the same scope. Use `plan_metadata_changes` for listing and review metadata, `plan_screenshot_changes` for screenshot sets, and the corresponding dedicated planner for commerce, provisioning, signing, or submission. Inspect the exact app, platform version, locales, operation IDs, additions, changes, removals, and destructive effects.
4. Apply only an inspected immutable plan within the owner's authorized scope. Supply the exact `planId`, digest, operation IDs, and required host confirmation to `apply_plan`. Plans are process-bound, so keep planning and application in the same MCP server process.
5. If an outcome is uncertain, inspect `get_operation_status` and remote state. Never replay a write whose execution may have started.
6. Plan the same scope again against unchanged repository inputs and require `noOp: true`. Record the reconciliation result alongside the repository change.

Ordinary metadata, screenshot, commerce, provisioning, or signing synchronization does not authorize submitting a version for review or releasing it. Use the MCP's explicit readiness and submission workflow only when the owner has separately placed submission in scope.

## Screenshots

Treat each localization's `screenshots.json` as the ordered manifest for its selected display sets. Paths are relative to `AppStore/`, and the explicit array order is the storefront order. Preserve reusable originals in the repository; do not silently resize, transcode, substitute another locale, or derive ordering from filenames.

Use `merge` when unrelated remote screenshots must remain unmanaged. Use `replace` only when the selected set should match the manifest exactly, and inspect every planned removal before applying it. After upload, allow Apple processing to finish and reconcile the final remote bytes and order. A temporarily absent source checksum is processing-pending evidence, not proof of a mismatch.

## Credentials and operational state

Keep `.appstore-connect-mcp/` as an ignored sibling of `AppStore/`; it contains process and recovery state, not repository content. Never commit or print App Store Connect keys, signing keys, certificates, private contacts, demo credentials, upload URLs, environment files, or MCP journals. Represent supported App Review secrets through the MCP's narrow environment-variable references, and pass credential variable names rather than values when configuring an MCP client.

If the MCP process does not inherit credentials that are available to an authorized shell, correct or deliberately bridge the process environment without exposing values. Do not diagnose a credential as invalid merely because a different process did not inherit it.

## Project-specific documentation

Consumer documentation should identify its concrete `AppStore/` paths and managed domains, explain how product voice and locale coverage apply to storefront copy, describe screenshot production, and record any review, export-compliance, or release prerequisites. Keep generic MCP mechanics in this guide and link to them instead of copying the workflow into every repository.
