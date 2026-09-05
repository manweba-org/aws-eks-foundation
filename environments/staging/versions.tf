terraform {
  required_version = ">= 1.7.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  # Configure with: terraform init -backend-config=backend.hcl
  # Bootstrap the S3 bucket + DynamoDB lock table out-of-band first.
  backend "s3" {}
}

provider "aws" {
  region = var.primary_region

  default_tags {
    tags = {
      Project            = var.project_name
      Environment        = var.environment
      ManagedBy          = "terraform"
      Owner              = var.owner
      CostCenter         = var.cost_center
      DataClassification = var.data_classification
      Compliance         = join(",", var.compliance_frameworks)
    }
  }
}
