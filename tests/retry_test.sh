#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

source "${ROOT_DIR}/tests/helpers/assertions.sh"
source "${ROOT_DIR}/tests/helpers/fixtures.sh"
source "${ROOT_DIR}/tests/helpers/mocks.sh"
source "${ROOT_DIR}/tests/helpers/publish_runner.sh"

setup_test_env
install_mocks

queue_response 429 'Retry-After: 1' '{"error":"rate limited"}'
queue_response 200 '' '{"status":"success"}'
run_publish http-429-then-200
assert_status http-429-then-200 "0" "HTTP 429 with Retry-After retries successfully"
assert_attempt_count http-429-then-200 "2" "HTTP 429 retry makes two POST attempts"
assert_sleep_log http-429-then-200 "1" "HTTP 429 retry sleeps for Retry-After seconds"
assert_response_code http-429-then-200 "200" "HTTP 429 retry writes final 200 response-code"
assert_response_json http-429-then-200 '{"status":"success"}' "HTTP 429 retry writes final response body"

queue_response 429 'retry-after: 1' '{"error":"rate limited"}'
queue_response 429 '' '{"error":"still rate limited"}'
run_publish http-429-then-429 || true
assert_status http-429-then-429 "1" "HTTP 429 after retry exits nonzero"
assert_attempt_count http-429-then-429 "2" "HTTP 429 after retry makes two POST attempts"
assert_sleep_log http-429-then-429 "1" "HTTP 429 after retry sleeps once"
assert_response_code http-429-then-429 "429" "HTTP 429 after retry writes final response-code"
assert_response_json http-429-then-429 '{"error":"still rate limited"}' "HTTP 429 after retry writes final response body"

queue_response 429 '' '{"error":"rate limited"}'
run_publish http-429-missing-retry-after || true
assert_status http-429-missing-retry-after "1" "HTTP 429 without Retry-After exits nonzero"
assert_stderr_contains http-429-missing-retry-after "Warning: Foundry returned HTTP 429 without a Retry-After header"
assert_response_code http-429-missing-retry-after "429" "HTTP 429 without Retry-After writes response-code"
assert_response_json http-429-missing-retry-after '{"error":"rate limited"}' "HTTP 429 without Retry-After writes response body"

queue_response 429 'Retry-After: soon' '{"error":"rate limited"}'
run_publish http-429-invalid-retry-after || true
assert_status http-429-invalid-retry-after "1" "HTTP 429 with invalid Retry-After exits nonzero"
assert_stderr_contains http-429-invalid-retry-after "Warning: Foundry returned invalid Retry-After value: soon"
assert_response_code http-429-invalid-retry-after "429" "HTTP 429 with invalid Retry-After writes response-code"
assert_response_json http-429-invalid-retry-after '{"error":"rate limited"}' "HTTP 429 with invalid Retry-After writes response body"

queue_response 429 'Retry-After: 121' '{"error":"rate limited"}'
run_publish http-429-excessive-retry-after || true
assert_status http-429-excessive-retry-after "1" "HTTP 429 with excessive Retry-After exits nonzero"
assert_stderr_contains http-429-excessive-retry-after "Warning: Foundry Retry-After value 121 exceeds maximum 120"
assert_response_code http-429-excessive-retry-after "429" "HTTP 429 with excessive Retry-After writes response-code"
assert_response_json http-429-excessive-retry-after '{"error":"rate limited"}' "HTTP 429 with excessive Retry-After writes response body"

printf 'ok - retry tests passed\n'
