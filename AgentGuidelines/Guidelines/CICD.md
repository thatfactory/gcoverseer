# CI/CD

## Workflow principles

- Keep CI deterministic, reproducible, and aligned with the repository's supported Xcode, Swift, and platform versions.
- Treat warnings introduced by a change as failures even when the compiler does not.
- Prefer the smallest permissions required by each workflow and job.
- For a new workflow, use the latest stable major version of every GitHub Action available at the time of creation.
- Do not copy an older major version into a fresh workflow unless a documented compatibility constraint requires it.
- For existing workflows, review action release notes and update deliberately rather than allowing runtime deprecation warnings to accumulate.
- Pin third-party actions to an intentional version and review updates.
- Do not place secrets in workflow files, logs, fixtures, or command arguments that may be echoed.
- Keep release workflows separate from pull-request validation when their permissions differ.

## Tooling and automation

Fastlane is forbidden in every ThatFactory project and has no exception path. Build repository-owned CI/CD and delivery automation with focused ThatFactory tooling such as `xcode-cloud-mcp` and `app-store-connect-mcp`, plus Swift scripts where repository-specific orchestration is needed.

Use Swift for new repository-owned executable scripts in Swift-focused applications, games, and packages. Prefer the Swift standard library and Foundation so automation uses the same native toolchain and dependency policy as the codebase. Convenience, familiarity, shorter code, or an existing interpreter is not a reason to choose another language.

Fall back to Python or a POSIX shell script only when the required behavior cannot be implemented with the repository's supported Swift toolchain and Foundation APIs. Document the exception in durable repository documentation in the same change, including the missing Swift capability, exact script and task scope, runtime and dependency requirements, security and maintenance impact, validation method, and condition for revisiting or removing the exception. Keep the fallback narrow; an existing non-Swift script does not authorize another one. The central `Scripts/swift_format.sh` command wrapper is the retained documented exception for invoking Xcode's `swift-format` modes.

## Private repository dependencies

The workflow repository's `GITHUB_TOKEN` does not grant access to private dependencies in sibling repositories. When Swift Package Manager or another build tool must clone private ThatFactory repositories, use a GitHub App installed on every required dependency repository. The app does not need access to the workflow repository unless that repository is also an intended token target. Grant the app only read access to repository contents, mint a short-lived installation token with `actions/create-github-app-token`, and list the exact dependency repositories in the action's `repositories` input. Do not use a personal access token, a long-lived machine credential, or an organization-wide token when the GitHub App can provide the required scope.

Expose the installation token only to steps that resolve or build the private dependencies. Supply HTTPS authentication through Git's process-level `GIT_CONFIG_COUNT`, `GIT_CONFIG_KEY_0`, and `GIT_CONFIG_VALUE_0` environment variables so the credential is not persisted in repository or global Git configuration. Keep the existing dependency URLs as `https://github.com/<owner>/<repository>` URLs. For example:

```yaml
- name: Create private dependency token
  id: private-dependencies
  uses: actions/create-github-app-token@v3
  with:
    client-id: ${{ vars.PRIVATE_DEPENDENCIES_APP_CLIENT_ID }}
    private-key: ${{ secrets.PRIVATE_DEPENDENCIES_APP_PRIVATE_KEY }}
    owner: ${{ github.repository_owner }}
    repositories: |
      first-private-package
      second-private-package
    permission-contents: read

- name: Test
  env:
    GIT_CONFIG_COUNT: 1
    GIT_CONFIG_KEY_0: url.https://x-access-token:${{ steps.private-dependencies.outputs.token }}@github.com/.insteadOf
    GIT_CONFIG_VALUE_0: https://github.com/
  run: swift test
```

The GitHub App's installation and repository selection are part of the security boundary. Consumer documentation must name the app variable and secret, list the private repositories the workflow requires, record the required `Contents: read` permission, and identify the jobs or steps that receive the token. Keep pull-request and protected-branch workflows consistent unless a documented trust boundary requires otherwise. Because `GIT_CONFIG_*` values are ordinary inherited environment variables, treat the credential-bearing resolve or build step and its complete subprocess tree as privileged. Tests, build scripts, SwiftPM plugins, and other code executed beneath that step must be trusted to receive read access to every repository in the token scope.

Repository secrets are unavailable to workflows triggered by pull requests from forks. A repository that accepts fork-originated or otherwise untrusted pull requests must keep a secretless validation path or deliberately skip private-dependency jobs with an explicit, documented condition. Untrusted code must not execute on a persistent self-hosted runner that is later reused for credential-bearing work. Use an isolated disposable or ephemeral self-hosted runner, an appropriate GitHub-hosted runner where possible, or a separate runner pool or host that never subsequently receives secrets; otherwise skip the untrusted validation.

This trust rule is event-independent. Do not combine credentials with code that is not trusted at that privilege level under `pull_request`, `pull_request_target`, `issue_comment`, `workflow_run`, or another trigger. On self-hosted runners, do not expose the token to unrelated steps, caches, artifacts, logs, or persistent configuration; retain the action's default post-job token revocation.

## `ci-pr.yml`

Projects using GitHub Actions should keep pull-request validation in `.github/workflows/ci-pr.yml`, triggered by `pull_request` events for `opened`, `synchronize`, and `reopened`.

Use GitHub-hosted runners for jobs that can run on the hosted operating system and toolchain. When a job uses a self-hosted runner, document and select it through the repository's `Runner labels:` rather than hard-coding a machine name in shared guidance.

### Runner labels:

When a workflow uses self-hosted runners, document the labels required by each job in this section of the consumer's CI/CD guide. Always include `self-hosted` and add only stable capability or environment labels needed to select the runner, such as an operating system, architecture, toolchain, or signing capability. Keep machine names and changing fleet details out of shared guidance.

A typical Swift package validates:

- package resolution;
- build;
- Swift Testing tests;
- DocC generation when the package publishes documentation;
- repository-specific lint or validation scripts.

An Xcode application validates its declared scheme and test plan. Use the same project/workspace, configuration, and platform assumptions documented for local development.

Xcode projects and Swift packages must run on self-hosted macOS runners with the required Xcode, Swift toolchains, simulators, certificates, and signing environment. Do not use `macos-latest` for those jobs. For Xcode projects, test with `xcodebuild test` and explicit simulators, then validate compilation with `xcodebuild build CODE_SIGNING_ALLOWED=NO` across the supported platforms. For Swift packages, use Swift Package Manager commands such as `swift test` and `swift build`; packages do not require simulator selection, but may require the self-hosted signing environment for packaging or collection workflows. Generic jobs that do not require Apple tooling may use GitHub-hosted Linux or other suitable runners. CI validates tests and compile health, not app-store distribution.

## `ci.yml`

Validation of merges to `main` should live in `.github/workflows/ci.yml`, triggered by `push` on `main`. Use the same build, test, lint, and platform coverage as pull-request validation unless the repository documents a deliberate difference.

## Failure investigation

1. Use GitHub MCP connector tools to inspect check runs and logs for the failing commit or pull request.
2. Use `gh` for fast local triage when needed.
3. Reproduce locally with the exact build or test command shown in the failing job logs.

Useful commands:

```bash
gh run list --limit 10
gh run view <run-id>
gh run view <run-id> --log
```

Distinguish compiler errors from lint violations, test failures from simulator or runtime infrastructure failures, and single-job failures from cross-platform matrix failures. Identify the first meaningful failing step, fix the narrowest root cause, and re-run affected validation.

## Releases

- A release tag and GitHub release must match the intended semantic version.
- Release notes summarize user- or integrator-relevant changes since the previous release.
- Use a notes file for multiline CLI release descriptions.
- Do not publish a release from an unverified or dirty worktree.
- Follow the consumer's local instructions for deployment, signing, notarization, App Store, or documentation publishing steps.
