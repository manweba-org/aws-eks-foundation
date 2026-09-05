.PHONY: help fmt validate lint test security-scan clean-terraform

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?##' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-18s %s\n", $$1, $$2}'

fmt: ## Format Terraform files
	terraform fmt -recursive

validate: ## Init (-backend=false) and validate env roots, modules, example
	bash scripts/validate.sh

lint: ## Run TFLint on modules, environments, and example
	tflint --init
	@for dir in modules/* environments/* examples/full-stack; do \
	  echo "==> tflint $$dir"; \
	  (cd $$dir && tflint --config "$(CURDIR)/.tflint.hcl"); \
	done

test: ## Unit tests (no AWS); missing tools SKIP, failures FAIL
	bash scripts/unit-test.sh

security-scan: ## Run available security scanners
	bash scripts/security-scan.sh

clean-terraform: ## Remove all .terraform directories (never commit these)
	@for d in modules/* environments/* examples/full-stack; do \
	  rm -rf "$$d/.terraform"; \
	done
	@rm -rf .terraform
	@echo "Removed .terraform directories"
