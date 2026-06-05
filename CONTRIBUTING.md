# Contributing

Thanks for considering a contribution.

## Local environment

- **Windows**: develop inside WSL2. Native Cygwin/Git-Bash is missing the shell linting stack and `make check` won't run cleanly.
- **macOS / Linux**: stock environments are fine.
- Required on `PATH`: `bash`, `jq`, `curl`, `openssl`, `awk`, `shellcheck`, `shfmt`. The last two are the ones you'll likely need to install explicitly (`apt install shellcheck shfmt`, `brew install shellcheck shfmt`); the rest are typically already present.

## Development

```sh
make format       # apply shfmt formatting in-place
make format-check # report formatting diff without applying
make check        # shellcheck + test suite (the merge gate)
```

CI auto-applies formatting on same-repo PRs, so running `make format` locally is optional but encouraged — fork PRs don't get the auto-format step.

Adding a test? See [`tests/README.md`](tests/README.md).

## Submitting changes

Open a PR. A few things to expect:

- Same-repo PRs may receive an automatic `Format shell scripts` commit.
- On same-repo PRs, shellcheck findings appear twice — once as a failed check, once as inline review comments. Fork PRs see the same findings only in the `check.yml` logs (inline review comments require a write-scoped token that GitHub does not grant to fork PRs).
- If you're contributing from a fork, formatting won't be auto-applied; run `make format` locally before pushing.
