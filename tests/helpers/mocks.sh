#!/usr/bin/env bash
# Installs mock curl + sleep into ${MOCK_DIR}.

install_mocks() {
  local helpers_dir
  helpers_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
  install -m 0755 "${helpers_dir}/mocks/curl.sh" "${MOCK_DIR}/curl"
  install -m 0755 "${helpers_dir}/mocks/sleep.sh" "${MOCK_DIR}/sleep"
}
