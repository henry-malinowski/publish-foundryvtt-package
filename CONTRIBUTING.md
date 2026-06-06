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
make check        # shellcheck + format-check + test suite (the merge gate)
```

Formatting is enforced by the merge gate (`make check` runs `format-check`), so run `make format` before pushing — unformatted code fails CI.

Adding a test? See [`tests/README.md`](tests/README.md).

## Submitting changes

Open a PR. A few things to expect:

- `make check` is the gate: shellcheck, formatting, and the test suite must all pass. Run it locally before pushing.
- On same-repo PRs, shellcheck findings appear twice — once as a failed check, once as inline review comments. Fork PRs see the same findings only in the `check.yml` logs (inline review comments require a write-scoped token that GitHub does not grant to fork PRs).
