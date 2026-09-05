variable "name_prefix" {
  description = "Naming prefix for storage resources."
  type        = string
}

variable "enable_encryption" {
  description = "Use customer-managed KMS for bucket encryption when a key ARN is provided."
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "KMS key ARN for S3 SSE-KMS. When null, SSE-S3 (AES256) is used."
  type        = string
  default     = null
  nullable    = true
}

variable "tags" {
  description = "Tags applied to storage resources."
  type        = map(string)
  default     = {}
}
