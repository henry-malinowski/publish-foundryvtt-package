#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

source "${ROOT_DIR}/tests/helpers/assertions.sh"
source "${ROOT_DIR}/tests/helpers/fixtures.sh"
source "${ROOT_DIR}/tests/helpers/mocks.sh"
source "${ROOT_DIR}/tests/helpers/publish_runner.sh"

setup_test_env
install_mocks

DRY_RUN=maybe run_publish bad-dry-run || true
assert_status bad-dry-run "1" "invalid dry-run exits before API call"
assert_no_api_call bad-dry-run "invalid dry-run should not call the API"

DRY_RUN=true run_publish dry-run-true
assert_status dry-run-true "0" "dry-run=true is accepted"

DRY_RUN=TRUE run_publish dry-run-uppercase
assert_status dry-run-uppercase "0" "dry-run=TRUE is accepted (case-insensitive)"

FOUNDRY_TOKEN='' run_publish missing-token || true
assert_status missing-token "1" "missing token fails validation"
assert_no_api_call missing-token "missing token should not call the API"

FOUNDRY_TOKEN='bad_token' run_publish bad-token-prefix || true
assert_status bad-token-prefix "1" "bad token prefix fails validation"
assert_no_api_call bad-token-prefix "bad token prefix should not call the API"

MANIFEST_PATH_OVERRIDE="${TEST_DIR}/does-not-exist.json" run_publish missing-manifest-file || true
assert_status missing-manifest-file "1" "missing manifest file fails validation"
assert_no_api_call missing-manifest-file "missing manifest file should not call the API"

MANIFEST_RAW='not json' run_publish non-json-manifest || true
assert_status non-json-manifest "1" "non-JSON manifest fails validation"
assert_no_api_call non-json-manifest "non-JSON manifest should not call the API"

MANIFEST_ID=null run_publish null-id || true
assert_status null-id "1" "null manifest id fails validation"
assert_no_api_call null-id "null manifest id should not call the API"

MANIFEST_VERSION=42 run_publish numeric-version || true
assert_status numeric-version "1" "numeric manifest version fails validation"
assert_no_api_call numeric-version "numeric manifest version should not call the API"

MANIFEST_VERIFIED=null run_publish missing-verified || true
assert_status missing-verified "1" "null .compatibility.verified fails validation"
assert_no_api_call missing-verified "null .compatibility.verified should not call the API"

printf 'ok - validation tests passed\n'
