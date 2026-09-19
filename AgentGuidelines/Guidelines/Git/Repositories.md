# Git Repositories

Use these rules when cloning repositories or configuring remotes.

## SSH-first cloning

Clone a repository over SSH when the working copy may be used to commit, push, or open a pull request:

```sh
git clone git@github.com:<owner>/<repository>.git
```

- Prefer an SSH `origin` so command-line tools and Git clients such as Fork can reuse the machine's GitHub SSH authentication.
- Do not create a push-capable working copy with an HTTPS `origin` unless the user or environment explicitly requires HTTPS.
- After cloning for development, use `git remote -v` to confirm that fetch and push URLs are correct.
- If an existing development clone has an HTTPS `origin`, change it only when requested or when the task explicitly includes remote setup:

  ```sh
  git remote set-url origin git@github.com:<owner>/<repository>.git
  ```

HTTPS remains appropriate for deliberately read-only retrieval, ephemeral automation, or environments where SSH credentials are unavailable. A public Git subtree remote may also remain HTTPS because consumers fetch tagged content without pushing to the guideline repository.

## GitHub CLI authentication recovery

Treat a reported invalid `GITHUB_TOKEN` as potentially transient or environment-specific. Do not abandon the `gh` CLI or switch protocols solely because one Codex shell reports that token as invalid.

When `gh` authentication appears inconsistent:

1. Retry `gh auth status` in a fresh shell.
2. If the user can run commands locally, ask them to confirm `gh auth status` and share only the redacted result; never request or print the token itself.
3. Retry the original `gh` command after authentication is confirmed. Preserve the CLI workflow for repository inspection, Actions logs, and pull-request operations.
4. If an injected environment variable is shadowing the stored GitHub CLI credential, compare the credential-backed check without exposing secrets:

   ```sh
   env -u GITHUB_TOKEN gh auth status
   ```

   If that succeeds, use the authenticated CLI session for the task or refresh it with `gh auth refresh` as appropriate. Do not copy a token into shell history, command arguments, files, or chat.
5. Use SSH for Git transport only when the CLI remains unavailable after retry and the operation is specifically a Git fetch, commit, or push. Continue using `gh` for GitHub API operations whenever it is working.

An environment mismatch is not evidence that the user's GitHub account or token is invalid. Record the failed command and exact non-secret error, retry after the authentication check, and report the blocker only after repeated attempts fail.

### Login-shell credentials

Some developer environments export `GITHUB_TOKEN` from a shell startup file rather than from the non-interactive process that launched the agent. When the user has explicitly authorized using that local configuration, retry `gh` in a login shell that sources the user's startup configuration:

```sh
zsh -lc 'source "$HOME/.zshrc"; gh auth status'
```

Run the required `gh` operation in that same shell after authentication succeeds. Never print, inspect, copy, or persist the token value; suppress unrelated startup output when practical, and do not source a startup file merely to bypass a credential or permission boundary without the user's authorization.
