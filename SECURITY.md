# Security policy

## Supported versions

This repository is a **reference Terraform foundation**, not a hosted service. Security fixes land on `main` only; there are no long-lived release branches.

| Branch | Supported |
|--------|-----------|
| `main` | Yes |

## Reporting a vulnerability

Please **do not** open a public issue for security problems.

Prefer one of:

1. **[GitHub private vulnerability reporting](https://github.com/manweba-org/aws-eks-foundation/security/advisories/new)** (recommended)
2. If that is unavailable, open a **draft security advisory** from the repository Security tab, or contact a maintainer via GitHub with a brief non-sensitive summary and ask for a private channel

Include:

- Affected paths (module / environment / workflow)
- Impact (e.g. overly permissive IAM, secret exposure in examples, CI supply-chain risk)
- Reproduction steps or a minimal PoC when safe
- Whether you believe the issue is already exploitable in a default `apply`

We aim to acknowledge reports within **7 days** and share a remediation plan or status update within **30 days**. Timelines may vary for a small maintainer set.

## Scope

In scope:

- Unsafe defaults in Terraform modules or example environments
- Credential or secret leakage in the repo, CI, or docs
- Supply-chain issues in GitHub Actions pins or download checksums
- Misleading security claims in documentation

Out of scope:

- Misconfiguration after you change variables, IAM, or networking outside these examples
- Vulnerabilities in upstream AWS services, Terraform providers, or third-party tools
- Theoretical issues with no realistic impact on this reference architecture

## Safe Harbor

Good-faith research and responsible disclosure are welcome. Do not use findings to access accounts or data you do not own, and do not publicly disclose before a fix or coordinated disclosure.
