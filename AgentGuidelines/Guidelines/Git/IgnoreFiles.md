# Git Ignore Files

Use the shared [`.gitignore` template](../../Templates/.gitignore) for new Xcode projects and Swift packages. It covers generated Xcode and Swift Package Manager state plus the local output, caches, and credentials used by supported Node.js, Python, App Store, and ThatFactory development tooling.

The template deliberately does not ignore `Package.resolved`, `.xcodeproj`, or `.xcworkspace` files. Decide whether a package lockfile belongs in source control based on the package's role, and keep authored Xcode project and workspace definitions tracked. Narrow generated files are ignored instead of ignoring containers that may hold shared configuration.

## Consumer reconciliation

Compare a consumer's active `.gitignore` patterns with the template without requiring comments, blank lines, section order, or duplicate rules to match. Add missing shared patterns using their template spelling, preserving the consumer's rule order and negation semantics. Before adding a pattern, check whether a later consumer rule negates it or whether it would hide a currently tracked source or configuration path; report a conflict instead of changing behavior silently.

Treat every active consumer pattern that is not in the template as a project-specific entry. Do not remove it or silently accept it. Report it to the repository owner so they can choose whether the reusable template should gain the pattern or the consumer should retain it as a local exception.

When the repository owner chooses a local exception, document the rationale immediately above the entry in the consumer `.gitignore` using `# Project-specific: <rationale>`. A concrete non-placeholder rationale marks that entry as reviewed, so later completion audits may accept it without reporting it again. Keep exception comments and their patterns adjacent; each independently motivated group needs its own rationale.

Do not copy ignored caches or generated artifacts into the repository merely to make the comparison pass. Existing tracked files remain tracked even when a matching ignore rule is added, so inspect `git ls-files` and `git check-ignore -v` when a rule's effect is uncertain.
