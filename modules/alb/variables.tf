variable "name_prefix" {
  description = "Naming prefix for ALB resources."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the target group."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for the internet-facing ALB."
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID attached to the ALB (from the security module)."
  type        = string
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS. When null, only HTTP listener is created (demo/dev pattern)."
  type        = string
  default     = null
  nullable    = true
}

variable "target_port" {
  description = "Default target port (NodePort or container port for TargetGroupBinding)."
  type        = number
  default     = 30080

  validation {
    condition     = var.target_port >= 1 && var.target_port <= 65535
    error_message = "target_port must be between 1 and 65535."
  }
}

variable "health_check_path" {
  description = "HTTP health check path."
  type        = string
  default     = "/healthz"
}

variable "idle_timeout" {
  description = "ALB idle timeout in seconds."
  type        = number
  default     = 60
}

variable "tags" {
  description = "Tags applied to ALB resources."
  type        = map(string)
  default     = {}
}
