#!/usr/bin/env bash
# Validate Terraform roots with local backend disabled (no AWS credentials required).
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if ! command -v terraform >/dev/null 2>&1; then
  echo "ERROR: terraform not found on PATH" >&2
  exit 127
fi

# Deployable roots: environments only.
# Modules validate in isolation; examples/full-stack is a non-backend composition study.
ROOTS=(
  modules/networking
  modules/security
  modules/storage
  modules/database
  modules/eks
  modules/alb
  modules/observability
  environments/dev
  environments/staging
  environments/prod
  examples/full-stack
)

echo "==> terraform fmt -check -recursive"
terraform fmt -check -recursive

for dir in "${ROOTS[@]}"; do
  echo "==> validate $dir"
  (
    cd "$dir"
    terraform init -backend=false -input=false >/dev/null
    terraform validate
  )
done

echo "OK: all roots validated"
