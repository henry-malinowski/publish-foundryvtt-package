#!/usr/bin/env bash
# Generic assertion primitives. Topic-specific assertions live in
# publish_runner.sh next to the artifacts they read.

fail() {
  printf 'not ok - %s\n' "$*" >&2
  exit 1
}

assert_eq() {
  local expected=$1
  local actual=$2
  local message=$3

  [[ "${actual}" == "${expected}" ]] || fail "${message}: expected '${expected}', got '${actual}'"
}

assert_nonzero() {
  local actual=$1
  local message=$2

  [[ "${actual}" != "0" ]] || fail "${message}: expected nonzero status"
}

assert_json_eq() {
  local expected=$1
  local actual=$2
  local message=$3

  jq -ne --argjson actual "${actual}" --argjson expected "${expected}" '$actual == $expected' > /dev/null ||
    fail "${message}: expected ${expected}, got ${actual}"
}
