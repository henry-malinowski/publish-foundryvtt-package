#!/usr/bin/env bash
# Test harness for publish.sh.

MANIFEST_URL="https://example.test/module.json"
QUEUE_INDEX=0

# Call once per file. mktemps TEST_DIR + MOCK_DIR; cleans up on EXIT.
setup_test_env() {
  TEST_DIR=$(mktemp -d)
  MOCK_DIR="${TEST_DIR}/bin"

  trap 'rm -rf "${TEST_DIR}"' EXIT

  mkdir -p "${MOCK_DIR}"
}

# Queue (code, headers, body) for the next attempt. Consumed by run_publish.
queue_response() {
  QUEUE_INDEX=$((QUEUE_INDEX + 1))
  local prefix="${TEST_DIR}/queue-${QUEUE_INDEX}"
  printf '%s' "$1" > "${prefix}.code"
  printf '%s' "$2" > "${prefix}.headers"
  printf '%s' "$3" > "${prefix}.body"
}

# Queue a curl-exits-nonzero attempt with the given exit code.
queue_transport_failure() {
  QUEUE_INDEX=$((QUEUE_INDEX + 1))
  local prefix="${TEST_DIR}/queue-${QUEUE_INDEX}"
  printf '%s' "$1" > "${prefix}.exit"
}

# Move queued records into per-case slots; default to one 200 {"status":"success"}.
stage_responses() {
  local case_prefix=$1
  local i ext src

  if [[ "${QUEUE_INDEX}" -eq 0 ]]; then
    printf '200' > "${case_prefix}1.code"
    : > "${case_prefix}1.headers"
    printf '%s' '{"status":"success"}' > "${case_prefix}1.body"
    return
  fi

  for ((i = 1; i <= QUEUE_INDEX; i++)); do
    src="${TEST_DIR}/queue-${i}"
    for ext in code headers body exit; do
      if [[ -f "${src}.${ext}" ]]; then
        mv "${src}.${ext}" "${case_prefix}${i}.${ext}"
      fi
    done
  done
  QUEUE_INDEX=0
}

# Run publish.sh under mocks. Consumes the queue and writes per-case artifacts
# (request.json, output.txt, headers.txt, attempt.txt, sleep.txt, stdout, stderr,
# status) under ${TEST_DIR}/${name}-* for the assert_* helpers below.
run_publish() {
  local name=$1
  local manifest_file="${TEST_DIR}/${name}-manifest.json"
  local request_file="${TEST_DIR}/${name}-request.json"
  local output_file="${TEST_DIR}/${name}-output.txt"
  local headers_file="${TEST_DIR}/${name}-headers.txt"
  local attempt_file="${TEST_DIR}/${name}-attempt.txt"
  local sleep_file="${TEST_DIR}/${name}-sleep.txt"
  local stdout_file="${TEST_DIR}/${name}-stdout.txt"
  local stderr_file="${TEST_DIR}/${name}-stderr.txt"
  local status_file="${TEST_DIR}/${name}-status.txt"
  local response_prefix="${TEST_DIR}/${name}-response-"
  local maximum=${MAXIMUM-}
  local manifest_path

  # Three byte-source modes for the local manifest the action reads:
  #   MANIFEST_PATH_OVERRIDE — point at a caller-given path (e.g. a missing file)
  #   MANIFEST_RAW           — write these raw bytes (e.g. non-JSON)
  #   default                — a valid manifest via write_manifest
  if [[ -n "${MANIFEST_PATH_OVERRIDE-}" ]]; then
    manifest_path="${MANIFEST_PATH_OVERRIDE}"
  elif [[ -n "${MANIFEST_RAW+x}" ]]; then
    printf '%s' "${MANIFEST_RAW}" > "${manifest_file}"
    manifest_path="${manifest_file}"
  else
    write_manifest "${manifest_file}" "${maximum}"
    manifest_path="${manifest_file}"
  fi
  stage_responses "${response_prefix}"

  (
    export PATH="${MOCK_DIR}:${PATH}"
    export MANIFEST_PATH="${manifest_path}"
    export MOCK_HEADERS_FILE="${headers_file}"
    export MOCK_ATTEMPT_FILE="${attempt_file}"
    export MOCK_SLEEP_FILE="${sleep_file}"
    export MOCK_REQUEST_FILE="${request_file}"
    export MOCK_RESPONSE_PREFIX="${response_prefix}"
    export GITHUB_OUTPUT="${output_file}"
    export FOUNDRY_TOKEN="${FOUNDRY_TOKEN-fvttp_test}"
    export MANIFEST_URL="${MANIFEST_URL}"
    export RELEASE_VERSION="${RELEASE_VERSION-}"
    export RELEASE_NOTES_URL="${RELEASE_NOTES_URL-}"
    export DRY_RUN="${DRY_RUN-false}"
    "${ROOT_DIR}/publish.sh"
  ) > "${stdout_file}" 2> "${stderr_file}"
  printf '%s' "$?" > "${status_file}"
}

status_for() {
  cat "${TEST_DIR}/$1-status.txt"
}

request_json_for() {
  cat "${TEST_DIR}/$1-request.json"
}

attempt_count_for() {
  cat "${TEST_DIR}/$1-attempt.txt"
}

sleep_log_for() {
  cat "${TEST_DIR}/$1-sleep.txt"
}

github_output_value() {
  local name=$1
  local key=$2

  awk -F= -v key="${key}" '$1 == key { print $2; exit }' "${TEST_DIR}/${name}-output.txt"
}

github_response_json() {
  local name=$1

  awk '
    /^response-json<</ { in_block = 1; next }
    in_block && /^foundry_response_/ { exit }
    in_block { print }
  ' "${TEST_DIR}/${name}-output.txt"
}

assert_status() {
  local name=$1
  local expected=$2
  local message=$3

  assert_eq "${expected}" "$(status_for "${name}")" "${message}"
}

assert_request_json() {
  local name=$1
  local expected=$2
  local message=$3

  assert_json_eq "${expected}" "$(request_json_for "${name}")" "${message}"
}

assert_response_code() {
  local name=$1
  local expected=$2
  local message=$3

  assert_eq "${expected}" "$(github_output_value "${name}" response-code)" "${message}"
}

assert_response_json() {
  local name=$1
  local expected=$2
  local message=$3

  assert_json_eq "${expected}" "$(github_response_json "${name}")" "${message}"
}

assert_response_body() {
  local name=$1
  local expected=$2
  local message=$3

  assert_eq "${expected}" "$(github_response_json "${name}")" "${message}"
}

assert_no_api_call() {
  local name=$1
  local message=$2

  [[ ! -e "${TEST_DIR}/${name}-request.json" ]] || fail "${message}"
}

assert_stderr_contains() {
  local name=$1
  local expected=$2

  grep -F "${expected}" "${TEST_DIR}/${name}-stderr.txt" > /dev/null ||
    fail "${name} stderr should contain: ${expected}"
}

assert_attempt_count() {
  local name=$1
  local expected=$2
  local message=$3

  assert_eq "${expected}" "$(attempt_count_for "${name}")" "${message}"
}

assert_sleep_log() {
  local name=$1
  local expected=$2
  local message=$3

  assert_eq "${expected}" "$(sleep_log_for "${name}")" "${message}"
}

assert_header_sent() {
  local name=$1
  local expected=$2
  local message=$3

  grep -Fx "${expected}" "${TEST_DIR}/${name}-headers.txt" > /dev/null ||
    fail "${message}"
}
