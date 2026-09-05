#!/usr/bin/env bash
# Run unit-style checks that do not require AWS credentials.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "==> shell: validate module file presence"
required=(
  modules/networking/main.tf
  modules/security/main.tf
  modules/storage/main.tf
  modules/database/main.tf
  modules/eks/main.tf
  modules/alb/main.tf
  modules/observability/main.tf
)
for f in "${required[@]}"; do
  [[ -f "$f" ]] || { echo "missing $f"; exit 1; }
done

if command -v conftest >/dev/null 2>&1; then
  echo "==> conftest (pass fixtures must succeed)"
  conftest test tests/unit/fixtures/pass/ --policy policies/conftest/
  echo "==> conftest (deny fixtures must fail)"
  for f in tests/unit/fixtures/deny/*.json; do
    if conftest test "$f" --policy policies/conftest/; then
      echo "ERROR: expected policy denial for $f" >&2
      exit 1
    fi
    echo "  denied as expected: $f"
  done
else
  echo "SKIP: conftest not installed"
fi

if command -v opa >/dev/null 2>&1; then
  echo "==> opa test"
  opa test policies/opa/ -v
else
  echo "SKIP: opa not installed"
fi

if command -v tflint >/dev/null 2>&1; then
  echo "==> tflint"
  tflint --init
  ROOTS=(modules/* environments/* examples/full-stack)
  for dir in "${ROOTS[@]}"; do
    echo "  tflint $dir"
    (cd "$dir" && tflint --config "$ROOT_DIR/.tflint.hcl")
  done
else
  echo "SKIP: tflint not installed"
fi

echo "OK: unit checks finished"
