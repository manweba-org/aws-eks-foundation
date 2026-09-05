variable "project_name" {
  type        = string
  description = "Short project identifier (2-15 chars). Keeps S3 bucket names under the 63-char AWS limit."

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,14}$", var.project_name))
    error_message = "project_name must be 2-15 chars, start with a letter, lowercase/digits/hyphens only."
  }
}

variable "environment" {
  type        = string
  description = "Environment name."
  default     = "staging"

  validation {
    condition     = var.environment == "staging"
    error_message = "This root is fixed to environment=staging."
  }
}

variable "primary_region" {
  type        = string
  description = "Primary AWS region."
  default     = "us-east-1"
}

variable "dr_region" {
  type        = string
  description = "DR region (documented only; unused for resources)."
  default     = "us-west-2"
}

variable "owner" {
  type        = string
  description = "Owner tag."
}

variable "cost_center" {
  type        = string
  description = "Cost center tag."
}

variable "data_classification" {
  type        = string
  description = "Data classification."
  default     = "internal"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR."
  default     = "10.1.0.0/16"
}

variable "availability_zones" {
  type        = list(string)
  description = "Optional explicit AZs."
  default     = []
}

variable "az_count" {
  type        = number
  description = "AZ count when availability_zones is empty."
  default     = 3
}

variable "enable_encryption" {
  description = "Enable encryption at rest."
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs."
  type        = bool
  default     = true
}

variable "enable_backup" {
  description = "Enable backup-related settings."
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "RDS backup retention days."
  type        = number
  default     = 14
}

variable "compliance_frameworks" {
  description = "Framework labels for tags (aligned with, not certified)."
  type        = list(string)
  default     = ["well-architected", "cis-aws"]
}

variable "additional_tags" {
  description = "Extra tags merged into common tags."
  type        = map(string)
  default     = {}
}

variable "single_nat_gateway" {
  description = "Use a single NAT gateway (non-prod cost pattern)."
  type        = bool
  default     = true
}

variable "enable_guardduty" {
  description = "Enable GuardDuty detector."
  type        = bool
  default     = false
}

variable "enable_security_hub" {
  description = "Enable Security Hub account standards."
  type        = bool
  default     = false
}

variable "enable_config" {
  description = "Enable AWS Config recorder foundations."
  type        = bool
  default     = false
}

variable "enable_cloudtrail" {
  description = "Enable CloudTrail to the audit bucket."
  type        = bool
  default     = true
}

variable "eks_kubernetes_version" {
  description = "EKS Kubernetes version."
  type        = string
  default     = "1.29"
}

variable "eks_node_instance_types" {
  description = "EKS node instance types."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "eks_desired_size" {
  description = "EKS desired node count."
  type        = number
  default     = 2
}

variable "eks_min_size" {
  description = "EKS minimum node count."
  type        = number
  default     = 2
}

variable "eks_max_size" {
  description = "EKS maximum node count."
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
  description = "Enable RDS Multi-AZ."
  type        = bool
  default     = true
}

variable "rds_deletion_protection" {
  description = "Enable RDS deletion protection."
  type        = bool
  default     = false
}

variable "allowed_admin_cidrs" {
  description = "Admin CIDRs (must not include 0.0.0.0/0)."
  type        = list(string)
  default     = []
}

variable "alert_email" {
  description = "Optional SNS email subscription."
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
