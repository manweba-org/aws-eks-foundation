terraform {
  required_version = ">= 1.7.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    # Used solely to fetch the EKS OIDC issuer TLS thumbprint for IRSA.
    # Not a Kubernetes/Helm/Argo provider.
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}
