#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

source "${ROOT_DIR}/tests/helpers/assertions.sh"
source "${ROOT_DIR}/tests/helpers/fixtures.sh"
source "${ROOT_DIR}/tests/helpers/mocks.sh"
source "${ROOT_DIR}/tests/helpers/publish_runner.sh"

setup_test_env
install_mocks

run_publish fallback
assert_status fallback "0" "HTTP 200 exits successfully"
assert_request_json fallback '{"id":"sample-module","release":{"version":"1.2.3","manifest":"https://example.test/module.json","compatibility":{"minimum":"11","verified":"12"},"notes":"https://example.test/releases/1.2.3"}}' "manifest values are used as defaults"

RELEASE_VERSION=2.0.0 RELEASE_NOTES_URL=https://example.test/custom-notes DRY_RUN=true MAXIMUM=13 run_publish overrides
assert_request_json overrides '{"id":"sample-module","dry-run":true,"release":{"version":"2.0.0","manifest":"https://example.test/module.json","compatibility":{"minimum":"11","verified":"12","maximum":"13"},"notes":"https://example.test/custom-notes"}}' "overrides, dry-run, and maximum are included"

RELEASE_VERSION=2.0.0 run_publish version-override-notes-fallback
assert_request_json version-override-notes-fallback '{"id":"sample-module","release":{"version":"2.0.0","manifest":"https://example.test/module.json","compatibility":{"minimum":"11","verified":"12"},"notes":"https://example.test/releases/1.2.3"}}' "version override preserves manifest changelog fallback"

printf 'ok - payload tests passed\n'
