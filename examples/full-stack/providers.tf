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
