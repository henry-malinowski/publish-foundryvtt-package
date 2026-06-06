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

`make check` covers the action's shell scripts and tests. The CI **workflow files** (`.github/workflows/*.yml`) are a separate concern, linted by [actionlint](https://github.com/rhysd/actionlint) — not by `make check`. Checking them locally is optional (CI gates them either way); to do so, install the binary and run it from the repo root:

```sh
go install github.com/rhysd/actionlint/cmd/actionlint@v1.7.12  # or: brew install actionlint
actionlint
```

Adding a test? See [`tests/README.md`](tests/README.md).

## Submitting changes

Open a PR. A few things to expect:

- Two gates decide pass/fail: `make check` (shellcheck, formatting, the test suite) for the action's shell scripts, and `actionlint` for the workflow files. Run `make check` locally before pushing; workflow edits are gated in CI (or check them locally with `actionlint`).
- On same-repo PRs you also get inline review comments on the diff — shellcheck and actionlint, via `review.yml`. These are **advisory**; the gates above are what block a merge. Fork PRs don't get inline comments (they need a write-scoped token GitHub withholds from forks), so fork contributors see findings in the gate logs instead.
