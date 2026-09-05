# Contributing

Thanks for interest in **aws-eks-foundation**. This is an open-source Terraform reference for a single-account AWS app platform (VPC, ALB, private EKS, RDS, IRSA, backups, policy-as-code CI).

## Before you start

- Read the [README](README.md) for scope and intentional limitations
- Search [existing issues](https://github.com/manweba-org/aws-eks-foundation/issues) and PRs
- Never commit secrets, real account IDs, private keys, or `.terraform/` / `*.tfstate*`

## Development setup

Requirements: Terraform **1.9.x** (CI uses `1.9.8`), `make`, and optionally TFLint / Conftest / OPA for local parity with CI.

```bash
make fmt
make validate
make test
```

CI on every PR runs fmt/validate plus TFLint, Trivy, Checkov, Conftest, OPA, and Gitleaks. Plan is **manual only** (OIDC); there is no apply-from-PR.

## Pull requests

1. Fork the repo (or use a branch if you have write access)
2. Create a focused branch (`fix/…`, `feat/…`, `docs/…`)
3. Keep changes reviewable: one concern per PR when practical
4. Fill out the PR template
5. Ensure required checks are green:
   - `fmt / init / validate`
   - `lint / scan / policy`
6. Expect review from [CODEOWNERS](.github/CODEOWNERS)

Prefer **squash merge** into `main`. Do not force-push to `main`.

## Issues

- Bugs → Bug report template
- Ideas → Feature request template
- Security → [SECURITY.md](SECURITY.md) (private reporting only)

## Code style

- Match existing Terraform layout (`modules/`, `environments/`, `policies/`)
- Run `terraform fmt -recursive` before committing
- Prefer pinned GitHub Actions by commit SHA
- Document intentional Checkov/Trivy skips in the existing ignore configs, not ad-hoc silencing without rationale

## License

By contributing, you agree that your contributions are licensed under the [MIT License](LICENSE).

## Maintainer notes (repository protection)

Recommended GitHub settings for this public repo:

1. Enable **secret scanning** and **push protection**
2. Ruleset on `main`: require PR, require the two status checks above, require conversation resolution, block force pushes and deletions (admin bypass only)
3. Allow **squash** merges only; disable merge commits
4. Require **CODEOWNER** review when a Maintainers team exists
5. Dependabot alerts + security updates (Actions ecosystem is already configured in `.github/dependabot.yml`)
