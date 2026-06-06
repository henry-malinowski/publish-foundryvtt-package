#!/usr/bin/env bash
# CI-only staging for the action-level integration test (see check.yml's
# `integration` job). Shadows curl with the unit-suite mock and queues a single
# HTTP 200, then exports the wiring to $GITHUB_ENV so the following `uses: ./`
# step runs publish.sh against the mock instead of the live Foundry API.
#
# This is the one seam the PATH-mocked bash suite in tests/ can't reach: those
# tests set publish.sh's env vars directly, so they never prove action.yml maps
# its inputs to those same names. Running the real composite action here does.
#
# Linux/GitHub-runner only; requires $GITHUB_ENV.
set -Eeuo pipefail

: "${GITHUB_ENV:?GITHUB_ENV must be set — this script only runs in CI}"

root_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
work=$(mktemp -d)

# Shadow curl with the existing mock; first match on PATH wins.
mkdir -p "${work}/bin"
cp "${root_dir}/tests/helpers/mocks/curl.sh" "${work}/bin/curl"
chmod +x "${work}/bin/curl"

# Queue one HTTP 200 for the first (and only) attempt the mock serves.
printf '200' > "${work}/resp-1.code"
printf '%s' '{"status":"success"}' > "${work}/resp-1.body"

# Minimal manifest carrying exactly the fields publish.sh requires.
cat > "${work}/module.json" << 'JSON'
{
  "id": "integration-test-module",
  "version": "1.0.0",
  "compatibility": { "minimum": "12", "verified": "13" }
}
JSON

{
  printf 'PATH=%s\n' "${work}/bin:${PATH}"
  printf 'MOCK_RESPONSE_PREFIX=%s\n' "${work}/resp-"
  printf 'MOCK_HEADERS_FILE=%s\n' "${work}/headers.txt"
  printf 'MOCK_ATTEMPT_FILE=%s\n' "${work}/attempt.txt"
  printf 'MOCK_REQUEST_FILE=%s\n' "${work}/request.json"
  printf 'INTEGRATION_MANIFEST_PATH=%s\n' "${work}/module.json"
} >> "${GITHUB_ENV}"
