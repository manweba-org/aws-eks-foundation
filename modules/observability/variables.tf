variable "name_prefix" {
  description = "Naming prefix for observability resources."
  type        = string
}

variable "enable_cloudtrail" {
  description = "Create a multi-region CloudTrail trail to the audit bucket."
  type        = bool
  default     = true
}

variable "enable_config" {
  description = "Enable AWS Config recorder foundations (optional; org aggregation is a separate layer)."
  type        = bool
  default     = false
}

variable "enable_backup" {
  description = "Create AWS Backup vault, daily plan, and RDS selection."
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Days to retain AWS Backup recovery points."
  type        = number
  default     = 7
}

variable "backup_schedule" {
  description = "Cron expression for the Backup plan (AWS Backup format)."
  type        = string
  default     = "cron(0 5 * * ? *)"
}

variable "backup_kms_key_arn" {
  description = "KMS key ARN for the Backup vault (null uses AWS-owned key)."
  type        = string
  default     = null
  nullable    = true
}

variable "rds_instance_arn" {
  description = "RDS instance ARN for Backup selection (null skips selection)."
  type        = string
  default     = null
  nullable    = true
}

variable "sns_kms_key_arn" {
  description = "KMS key ARN for SNS topic encryption (null uses AWS-owned key)."
  type        = string
  default     = null
  nullable    = true
}

variable "alert_email" {
  description = "Optional email for SNS alert subscription. Empty skips subscription."
  type        = string
  default     = ""
}

variable "audit_bucket_arn" {
  description = "ARN of the audit logs bucket."
  type        = string
}

variable "audit_bucket_id" {
  description = "Name/ID of the audit logs bucket."
  type        = string
}

variable "audit_bucket_policy_id" {
  description = "Audit bucket policy ID — CloudTrail waits on this before create."
  type        = string
  default     = null
  nullable    = true
}

variable "cloudtrail_kms_arn" {
  description = "KMS key ARN for CloudTrail log encryption."
  type        = string
  default     = null
  nullable    = true
}

variable "logs_kms_key_arn" {
  description = "KMS key ARN for CloudWatch Logs (app, flow logs)."
  type        = string
  default     = null
  nullable    = true
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs to an encrypted CloudWatch log group."
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "VPC ID for Flow Logs (required when enable_flow_logs is true)."
  type        = string
  default     = null
  nullable    = true
}

variable "eks_cluster_name" {
  description = "EKS cluster name for dashboard/alarm dimensions."
  type        = string
}

variable "rds_instance_id" {
  description = "RDS instance identifier for alarms."
  type        = string
}

variable "tags" {
  description = "Tags applied to observability resources."
  type        = map(string)
  default     = {}
}
