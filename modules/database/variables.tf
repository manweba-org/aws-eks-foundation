variable "name_prefix" {
  description = "Naming prefix for database resources."
  type        = string
}

variable "database_subnet_ids" {
  description = "Subnet IDs for the DB subnet group (private/database tier)."
  type        = list(string)
}

variable "database_security_group_id" {
  description = "Security group ID attached to the RDS instance."
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN for RDS storage encryption."
  type        = string
  default     = null
  nullable    = true
}

variable "secrets_kms_key_arn" {
  description = "KMS key ARN for the managed master user secret."
  type        = string
  default     = null
  nullable    = true
}

variable "enable_encryption" {
  description = "Enable storage encryption."
  type        = bool
  default     = true
}

variable "enable_backup" {
  description = "When false, sets backup retention to 0 (not recommended outside experiments)."
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Automated backup retention in days."
  type        = number
  default     = 7
}

variable "instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.medium"
}

variable "engine_version" {
  description = "PostgreSQL engine version."
  type        = string
  default     = "15.8"
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment."
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "Enable deletion protection."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to database resources."
  type        = map(string)
  default     = {}
}
