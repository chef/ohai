# CI runner preflight (2026-11-09)

- [x] GitHub CLI has `repo` scope and write access to this PR branch.
- [x] `macos-15` is a supported ARM64 runner; GitHub retired macOS 14 on November 2, 2026 ([notice](https://github.blog/changelog/2026-10-01-github-actions-macos-14-runner-image-retirement/)).
- [x] Existing workflow permissions and secret usage remain unchanged; no new tokens, scopes, secrets, license keys, or deploy keys are required.
