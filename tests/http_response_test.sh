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
assert_response_code fallback "200" "response-code output is written"
assert_response_json fallback '{"status":"success"}' "response-json output is written"
assert_header_sent fallback 'Authorization: fvttp_test' "Authorization header is sent"

queue_response 400 '' '{"error":"bad"}'
run_publish http-400 || true
assert_status http-400 "1" "HTTP 400 exits nonzero"
assert_response_code http-400 "400" "HTTP 400 writes response-code"
assert_response_json http-400 '{"error":"bad"}' "HTTP 400 writes response body"

queue_transport_failure 7
run_publish transport-failure || true
assert_status transport-failure "1" "transport failure exits nonzero"
assert_response_code transport-failure "000" "transport failure writes response-code 000"
assert_response_body transport-failure "" "transport failure writes empty response-json"
assert_stderr_contains transport-failure "Foundry release request failed before receiving an HTTP response"

printf 'ok - HTTP response tests passed\n'
