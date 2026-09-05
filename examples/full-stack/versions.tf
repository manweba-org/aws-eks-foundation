terraform {
  required_version = ">= 1.7.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    # Used by the EKS module for OIDC thumbprint (IRSA-ready). Not k8s/helm/argo.
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  # Example-only composition — no remote backend. Validate with:
  #   terraform init -backend=false && terraform validate
  # Deployable roots live under environments/{dev,staging,prod}.
}
