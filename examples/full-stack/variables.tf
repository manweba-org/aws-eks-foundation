variable "project_name" {
  description = "Short project identifier used in resource naming (lowercase alphanumeric and hyphens)."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,14}$", var.project_name))
    error_message = "project_name must be 2-15 chars (keeps S3 bucket names under 63 chars with account+region), start with a letter, and contain only lowercase letters, digits, and hyphens."
  }
}

variable "environment" {
  description = "Deployment environment name."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "primary_region" {
  description = "Primary AWS region for workload resources."
  type        = string
  default     = "us-east-1"
}

variable "dr_region" {
  description = "Disaster-recovery AWS region (documented for future multi-region; unused in Phase 1 resources)."
  type        = string
  default     = "us-west-2"
}

variable "owner" {
  description = "Owning team or individual for cost and operational ownership tags."
  type        = string
}

variable "cost_center" {
  description = "Cost center or billing code for chargeback tags."
  type        = string
}

variable "data_classification" {
  description = "Data classification label applied via default tags."
  type        = string
  default     = "internal"

  validation {
    condition     = contains(["public", "internal", "confidential", "restricted"], var.data_classification)
    error_message = "data_classification must be one of: public, internal, confidential, restricted."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid IPv4 CIDR."
  }
}

variable "availability_zones" {
  description = "Availability zones to use. Empty list selects the first N zones in the region."
  type        = list(string)
  default     = []
}

variable "az_count" {
  description = "Number of AZs when availability_zones is empty."
  type        = number
  default     = 3

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 4
    error_message = "az_count must be between 2 and 4."
  }
}

variable "enable_encryption" {
  description = "Enable encryption at rest for supported services (KMS-backed)."
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs."
  type        = bool
  default     = true
}

variable "enable_backup" {
  description = "Create AWS Backup vault, daily plan, and RDS selection."
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Backup retention period in days."
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_days >= 1 && var.backup_retention_days <= 35
    error_message = "backup_retention_days must be between 1 and 35 for Phase 1 RDS/Backup defaults."
  }
}

variable "compliance_frameworks" {
  description = "Framework labels for tagging (aligned with — not certified)."
  type        = list(string)
  default     = ["well-architected", "cis-aws"]
}

variable "additional_tags" {
  description = "Additional tags merged into local.common_tags."
  type        = map(string)
  default     = {}
}

variable "single_nat_gateway" {
  description = "Use a single NAT gateway (lower cost; suitable for non-prod). Prod should typically set false."
  type        = bool
  default     = true
}

variable "enable_guardduty" {
  description = "Enable GuardDuty detector foundations in this account/region."
  type        = bool
  default     = false
}

variable "enable_security_hub" {
  description = "Enable Security Hub foundations. Some org-level features need management/delegated admin."
  type        = bool
  default     = false
}

variable "enable_config" {
  description = "Enable AWS Config recorder foundations (optional; may need org/delegated admin for multi-account)."
  type        = bool
  default     = false
}

variable "enable_cloudtrail" {
  description = "Enable a regional CloudTrail trail writing to the audit bucket."
  type        = bool
  default     = true
}

variable "eks_kubernetes_version" {
  description = "EKS Kubernetes version."
  type        = string
  default     = "1.29"
}

variable "eks_node_instance_types" {
  description = "EC2 instance types for the managed node group."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "eks_desired_size" {
  description = "Desired managed node group size."
  type        = number
  default     = 2
}

variable "eks_min_size" {
  description = "Minimum managed node group size."
  type        = number
  default     = 1
}

variable "eks_max_size" {
  description = "Maximum managed node group size."
  type        = number
  default     = 4
}

variable "rds_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.medium"
}

variable "rds_engine_version" {
  description = "PostgreSQL engine version."
  type        = string
  default     = "15.8"
}

variable "rds_multi_az" {
  description = "Enable Multi-AZ for RDS."
  type        = bool
  default     = false
}

variable "rds_deletion_protection" {
  description = "Enable RDS deletion protection."
  type        = bool
  default     = false
}

variable "allowed_admin_cidrs" {
  description = "CIDR blocks permitted for administrative access (SSH/HTTPS management paths). Never 0.0.0.0/0 for admin ports."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for c in var.allowed_admin_cidrs : can(cidrnetmask(c)) && c != "0.0.0.0/0"
    ])
    error_message = "allowed_admin_cidrs must be valid CIDRs and must not include 0.0.0.0/0."
  }
}

variable "alert_email" {
  description = "Optional email subscription for SNS alert topic. Leave empty to skip subscription."
  type        = string
  default     = ""
}

variable "enable_alb" {
  description = "Provision an internet-facing Application Load Balancer."
  type        = bool
  default     = true
}

variable "alb_certificate_arn" {
  description = "ACM certificate ARN for ALB HTTPS. Null = HTTP-only (dev/demo)."
  type        = string
  default     = null
  nullable    = true
}

variable "alb_target_port" {
  description = "ALB target group port (NodePort or container port)."
  type        = number
  default     = 30080
}

variable "alb_health_check_path" {
  description = "ALB health check path."
  type        = string
  default     = "/healthz"
}

variable "enable_irsa" {
  description = "Create IRSA roles (EBS CSI, Load Balancer Controller, sample app)."
  type        = bool
  default     = true
}

variable "enable_addons" {
  description = "Install managed EKS add-ons."
  type        = bool
  default     = true
}

variable "enable_access_entries" {
  description = "Create EKS access entries for cluster admins."
  type        = bool
  default     = true
}

variable "cluster_admin_principal_arns" {
  description = "IAM user/role ARNs granted cluster-admin via EKS access entries."
  type        = list(string)
  default     = []
}

variable "app_service_account_namespace" {
  description = "Namespace for sample app IRSA ServiceAccount trust."
  type        = string
  default     = "default"
}

variable "app_service_account_name" {
  description = "ServiceAccount name for sample app IRSA trust."
  type        = string
  default     = "app"
}
