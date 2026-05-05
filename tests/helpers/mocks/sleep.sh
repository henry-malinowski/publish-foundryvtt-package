#!/usr/bin/env bash
# Mock sleep. Logs argv to MOCK_SLEEP_FILE; does not sleep.
set -Eeuo pipefail
printf '%s\n' "$*" >> "${MOCK_SLEEP_FILE}"
