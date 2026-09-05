#!/usr/bin/env bash
# Optional security scanners — skip gracefully when tools are missing.
# Failures from installed tools fail this script.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
STATUS=0

run() {
  local name="$1"; shift
  if command -v "$1" >/dev/null 2>&1; then
    echo "==> $name"
    "$@" || STATUS=$?
  else
    echo "SKIP: $name ($1 not installed)"
  fi
}

run "tflint" tflint --recursive --config "$ROOT_DIR/.tflint.hcl"
run "trivy" trivy config --severity CRITICAL,HIGH --exit-code 1 .
run "checkov" checkov -d . --config-file "$ROOT_DIR/.checkov.yml"
run "conftest" conftest test tests/unit/fixtures/pass/ --policy policies/conftest/
run "opa" opa test policies/opa/ -v

exit "$STATUS"
