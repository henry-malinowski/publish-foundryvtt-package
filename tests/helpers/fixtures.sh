#!/usr/bin/env bash
# Test fixtures: builds a minimal valid module.json on disk. MANIFEST_ID,
# MANIFEST_VERSION, and MANIFEST_VERIFIED can be overridden in the caller's
# env (as raw JSON values) to inject malformed shapes (e.g. `null`, a number)
# for validation tests.

write_manifest() {
  local path=$1
  local maximum=${2-}
  local id=${MANIFEST_ID-'"sample-module"'}
  local version=${MANIFEST_VERSION-'"1.2.3"'}
  local verified=${MANIFEST_VERIFIED-'"12"'}

  if [[ -n "${maximum}" ]]; then
    jq -n --argjson id "${id}" --argjson version "${version}" --argjson verified "${verified}" --arg maximum "${maximum}" '{
      id: $id,
      version: $version,
      changelog: "https://example.test/releases/1.2.3",
      compatibility: {
        minimum: "11",
        verified: $verified,
        maximum: $maximum
      }
    }' > "${path}"
  else
    jq -n --argjson id "${id}" --argjson version "${version}" --argjson verified "${verified}" '{
      id: $id,
      version: $version,
      changelog: "https://example.test/releases/1.2.3",
      compatibility: {
        minimum: "11",
        verified: $verified
      }
    }' > "${path}"
  fi
}
