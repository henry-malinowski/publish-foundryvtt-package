# Test suite

- Mocked-curl bash tests for `publish.sh`.
- `make test` runs each `tests/*_test.sh` in parallel.

## Contracts

- **Self-contained.** Each test file owns its own `TEST_DIR` and mocks. No cross-file state.
- **Parallel-safe.** Scripts run concurrently; scripts SHALL NOT write outside their own `TEST_DIR`.
- **No real network or sleep.** `curl` and `sleep` are intercepted via PATH-injected mocks.
- **One class of issue per file.** If a new issue class arises, it should be given a new file named as `tests/<topic>_test.sh`.

An existing `tests/*_test.sh` may be used as a template/reference for a new test script; source helpers from `tests/helpers/` as needed.
