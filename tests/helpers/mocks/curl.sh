#!/usr/bin/env bash
# Mock curl. Two roles by argv shape:
#   --fail-with-body present  →  manifest fetch
#   otherwise                 →  POST to Foundry; emits the next queued
#                                response from MOCK_RESPONSE_PREFIX.
set -Eeuo pipefail

if [[ "$*" == *"--fail-with-body"* ]]; then
  if [[ "${MOCK_MANIFEST_EXIT:-0}" -ne 0 ]]; then
    printf '%s' "${MOCK_MANIFEST_ERROR:-manifest fetch failed}" >&2
    exit "${MOCK_MANIFEST_EXIT}"
  fi
  cat "${MOCK_MANIFEST_FILE}"
  exit 0
fi

body_file=
write_out=
data=
dump_header=
headers_file="${MOCK_HEADERS_FILE}"
: >> "${headers_file}"
while (($#)); do
  case "$1" in
    --dump-header)
      dump_header=$2
      shift 2
      ;;
    --header)
      printf '%s\n' "$2" >> "${headers_file}"
      shift 2
      ;;
    --output)
      body_file=$2
      shift 2
      ;;
    --write-out)
      write_out=$2
      shift 2
      ;;
    --data)
      data=$2
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

attempt=1
if [[ -f "${MOCK_ATTEMPT_FILE}" ]]; then
  attempt=$(($(cat "${MOCK_ATTEMPT_FILE}") + 1))
fi
printf '%d' "${attempt}" > "${MOCK_ATTEMPT_FILE}"
printf '%s' "${data}" > "${MOCK_REQUEST_FILE}"

prefix="${MOCK_RESPONSE_PREFIX}${attempt}"

# Transport failure: empty body, "000" http_code, requested exit.
if [[ -f "${prefix}.exit" ]]; then
  : > "${body_file}"
  if [[ "${write_out}" == "%{http_code}" ]]; then
    printf '000'
  fi
  exit "$(cat "${prefix}.exit")"
fi

if [[ ! -f "${prefix}.code" ]]; then
  printf 'mock curl: no queued response for attempt %d\n' "${attempt}" >&2
  exit 99
fi

response_code=$(cat "${prefix}.code")

if [[ -n "${dump_header}" ]]; then
  printf 'HTTP/1.1 %s Mock\r\n' "${response_code}" > "${dump_header}"
  if [[ -s "${prefix}.headers" ]]; then
    while IFS= read -r line || [[ -n "${line}" ]]; do
      printf '%s\r\n' "${line}" >> "${dump_header}"
    done < "${prefix}.headers"
  fi
  printf '\r\n' >> "${dump_header}"
fi

if [[ -f "${prefix}.body" ]]; then
  cat "${prefix}.body" > "${body_file}"
fi

if [[ "${write_out}" == "%{http_code}" ]]; then
  printf '%s' "${response_code}"
fi
