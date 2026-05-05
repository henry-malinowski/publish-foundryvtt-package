#!/usr/bin/env bash
set -Eeuo pipefail

readonly FOUNDRY_RELEASE_URL="https://foundryvtt.com/_api/packages/release_version/"
# Retries beyond the initial attempt; total POSTs = MAX_429_RETRIES + 1.
readonly MAX_429_RETRIES=1
readonly MAX_RETRY_AFTER_SECONDS=120
RESPONSE_FILE=""
HEADER_FILE=""

cleanup_temp_files() {
  if [[ -n "${RESPONSE_FILE}" ]]; then
    rm -f "${RESPONSE_FILE}"
  fi

  if [[ -n "${HEADER_FILE}" ]]; then
    rm -f "${HEADER_FILE}"
  fi
}

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

require_input() {
  local name=$1
  local value=$2

  [[ -n "${value}" ]] || die "${name} is required"
}

require_foundry_token() {
  local value=$1

  require_input "foundry-token" "${value}"
  [[ "${value}" == fvttp_* ]] || die "foundry-token must start with fvttp_"
}

parse_bool() {
  local value
  value=$(printf '%s' "${1}" | tr '[:upper:]' '[:lower:]')

  case "${value}" in
    true) printf 'true' ;;
    '' | false) printf 'false' ;;
    *) die "dry-run must be 'true', 'false', or empty" ;;
  esac
}

jq_string() {
  local query=$1
  local message=$2
  local input=$3

  jq -er "${query} | select(type == \"string\" and length > 0)" <<< "${input}" ||
    die "${message}"
}

write_github_output() {
  local output_file=$1
  local response_code=$2
  local response_json=$3
  local delimiter

  [[ "${output_file}" == "/dev/null" ]] && return 0

  delimiter="foundry_response_$(openssl rand -hex 16)"
  {
    printf 'response-code=%s\n' "${response_code}"
    printf 'response-json<<%s\n' "${delimiter}"
    printf '%s\n' "${response_json}"
    printf '%s\n' "${delimiter}"
  } >> "${output_file}"
}

retry_after_seconds() {
  local header_file=$1
  local retry_after

  retry_after=$(
    awk -F: '
      tolower($1) == "retry-after" {
        value = substr($0, index($0, ":") + 1)
        # strip trailing \r in addition to whitespace; HTTP headers are CRLF-terminated
        gsub(/^[[:space:]]+|[[:space:]\r]+$/, "", value)
        print value
        exit
      }
    ' "${header_file}"
  )

  if [[ -z "${retry_after}" ]]; then
    printf 'Warning: Foundry returned HTTP 429 without a Retry-After header\n' >&2
    return 1
  fi
  if [[ ! "${retry_after}" =~ ^[0-9]+$ ]]; then
    printf 'Warning: Foundry returned invalid Retry-After value: %s\n' "${retry_after}" >&2
    return 1
  fi
  # 10# forces base-10 so values like "08" or "09" aren't parsed as invalid octal
  if ((10#${retry_after} > MAX_RETRY_AFTER_SECONDS)); then
    printf 'Warning: Foundry Retry-After value %s exceeds maximum %s\n' "${retry_after}" "${MAX_RETRY_AFTER_SECONDS}" >&2
    return 1
  fi

  printf '%s' "${retry_after}"
}

main() {
  local foundry_token=${FOUNDRY_TOKEN:-}
  local manifest_url=${MANIFEST_URL:-}
  local release_version=${RELEASE_VERSION:-}
  local release_notes_url=${RELEASE_NOTES_URL:-}
  local dry_run=${DRY_RUN:-false}
  local github_output=${GITHUB_OUTPUT:-/dev/null}
  local dry_run_json manifest_json package_id manifest_version notes_url
  local minimum verified maximum request_json response_json response_code curl_status
  local retry_count retry_after

  require_foundry_token "${foundry_token}"
  require_input "manifest-url" "${manifest_url}"

  dry_run_json=$(parse_bool "${dry_run}")

  manifest_json=$(
    curl \
      --connect-timeout 10 \
      --fail-with-body \
      --location \
      --max-time 60 \
      --silent \
      --show-error \
      "${manifest_url}"
  )

  package_id=$(jq_string '.id' "Manifest is missing required .id" "${manifest_json}")
  manifest_version=$(jq_string '.version' "Manifest is missing required .version" "${manifest_json}")
  minimum=$(jq_string '.compatibility.minimum' "Manifest is missing required .compatibility.minimum" "${manifest_json}")
  verified=$(jq_string '.compatibility.verified' "Manifest is missing required .compatibility.verified" "${manifest_json}")
  maximum=$(jq -er '.compatibility.maximum // "" | if type == "string" then . else "" end' <<< "${manifest_json}")

  if [[ -n "${release_version}" ]]; then
    manifest_version=${release_version}
  fi

  notes_url=${release_notes_url}
  if [[ -z "${notes_url}" ]]; then
    notes_url=$(jq -er '.changelog // "" | if type == "string" then . else "" end' <<< "${manifest_json}")
  fi

  request_json=$(
    jq -cn \
      --arg id "${package_id}" \
      --arg version "${manifest_version}" \
      --arg manifest "${manifest_url}" \
      --arg notes "${notes_url}" \
      --arg minimum "${minimum}" \
      --arg verified "${verified}" \
      --arg maximum "${maximum}" \
      --argjson dry_run "${dry_run_json}" \
      '
        {
          id: $id,
          release: {
            version: $version,
            manifest: $manifest,
            compatibility: {
              minimum: $minimum,
              verified: $verified
            }
          }
        }
        | if $dry_run then .["dry-run"] = true else . end
        | if $notes != "" then .release.notes = $notes else . end
        | if $maximum != "" then .release.compatibility.maximum = $maximum else . end
      '
  )

  RESPONSE_FILE=$(mktemp)
  HEADER_FILE=$(mktemp)
  trap cleanup_temp_files EXIT

  retry_count=0
  while true; do
    : > "${RESPONSE_FILE}"
    : > "${HEADER_FILE}"

    curl_status=0
    response_code=$(
      curl \
        --connect-timeout 10 \
        --dump-header "${HEADER_FILE}" \
        --max-time 60 \
        --silent \
        --show-error \
        --output "${RESPONSE_FILE}" \
        --write-out '%{http_code}' \
        --request POST \
        --header 'Content-Type: application/json' \
        --header "Authorization: ${foundry_token}" \
        --data "${request_json}" \
        "${FOUNDRY_RELEASE_URL}"
    ) || curl_status=$?

    response_json=$(cat "${RESPONSE_FILE}")

    if [[ "${curl_status}" -ne 0 ]]; then
      break
    fi

    if [[ "${response_code}" != "429" || "${retry_count}" -ge "${MAX_429_RETRIES}" ]]; then
      break
    fi

    if ! retry_after=$(retry_after_seconds "${HEADER_FILE}"); then
      break
    fi
    retry_count=$((retry_count + 1))
    printf 'Foundry returned HTTP 429; sleeping %ss before retry %s/%s\n' "${retry_after}" "${retry_count}" "${MAX_429_RETRIES}" >&2
    sleep "${retry_after}"
  done

  cleanup_temp_files
  trap - EXIT

  write_github_output "${github_output}" "${response_code}" "${response_json}"

  if [[ "${curl_status}" -ne 0 ]]; then
    die "Foundry release request failed before receiving an HTTP response"
  fi

  [[ "${response_code}" == "200" ]] || die "Foundry returned HTTP ${response_code}"
}

main "$@"
