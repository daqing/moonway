# Git Hooks

## Pre-commit Hook

This pre-commit hook runs before every commit and performs:

1. `moon fmt` — formats all MoonBit sources; the commit is rejected if this
   changes any file (stage the formatted files and commit again).
2. `moon check` — static diagnostics.
3. `moon test` — the full test suite.

It also adds `$HOME/.moon/bin` to `PATH` so the hook works in
non-interactive shells where the MoonBit toolchain is not on the default path.

### Usage Instructions

To use this pre-commit hook:

1. Make the hook executable if it isn't already:
   ```bash
   chmod +x .githooks/pre-commit
   ```

2. Configure Git to use the hooks in the .githooks directory:
   ```bash
   git config core.hooksPath .githooks
   ```

3. The hook will automatically run when you execute `git commit`
