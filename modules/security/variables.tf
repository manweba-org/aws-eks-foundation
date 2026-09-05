variable "name_prefix" {
  description = "Naming prefix for security resources."
  type        = string
}

variable "enable_encryption" {
  description = "Create customer-managed KMS keys for encryption at rest."
  type        = bool
  default     = true
}

variable "enable_guardduty" {
  description = "Enable GuardDuty detector in this account/region."
  type        = bool
  default     = false
}

variable "enable_security_hub" {
  description = "Enable Security Hub. Org aggregation needs management/delegated admin (optional layer)."
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "VPC ID for security groups."
  type        = string
}

variable "allowed_admin_cidrs" {
  description = "CIDRs allowed for administrative HTTPS to management paths. Must not include 0.0.0.0/0."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for c in var.allowed_admin_cidrs : can(cidrnetmask(c)) && c != "0.0.0.0/0"
    ])
    error_message = "allowed_admin_cidrs must be valid CIDRs and must not include 0.0.0.0/0."
  }
}

variable "tags" {
  description = "Tags applied to security resources."
  type        = map(string)
  default     = {}
}
