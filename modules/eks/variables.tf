variable "name_prefix" {
  description = "Naming prefix for EKS resources."
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the control plane ENIs and node group."
  type        = list(string)
}

variable "cluster_security_group_id" {
  description = "Additional security group for the EKS cluster."
  type        = string
}

variable "node_security_group_id" {
  description = "Security group for managed node group ENIs."
  type        = string
}

variable "cluster_role_arn" {
  description = "IAM role ARN for the EKS control plane."
  type        = string
}

variable "node_role_arn" {
  description = "IAM role ARN for managed node group instances."
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN for envelope encryption of Kubernetes secrets."
  type        = string
  default     = null
  nullable    = true
}

variable "logs_kms_key_arn" {
  description = "KMS key ARN for the EKS control-plane CloudWatch log group."
  type        = string
  default     = null
  nullable    = true
}

variable "enable_encryption" {
  description = "Enable secrets encryption with KMS and encrypt the control-plane log group."
  type        = bool
  default     = true
}

variable "cluster_iam_attachment_ids" {
  description = "IAM policy attachment IDs that must exist before cluster create (AmazonEKSClusterPolicy)."
  type        = list(string)
  default     = []
}

variable "node_iam_attachment_ids" {
  description = "IAM policy attachment IDs that must exist before node group create."
  type        = list(string)
  default     = []
}

variable "node_instance_types" {
  description = "EC2 instance types for the managed node group."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "desired_size" {
  description = "Desired node count."
  type        = number
  default     = 2
}

variable "min_size" {
  description = "Minimum node count."
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum node count."
  type        = number
  default     = 4
}

variable "tags" {
  description = "Tags applied to EKS resources."
  type        = map(string)
  default     = {}
}

variable "enable_irsa" {
  description = "Create IRSA IAM roles (EBS CSI, AWS Load Balancer Controller, sample app)."
  type        = bool
  default     = true
}

variable "enable_addons" {
  description = "Install managed EKS add-ons (vpc-cni, coredns, kube-proxy; EBS CSI when IRSA enabled)."
  type        = bool
  default     = true
}

variable "enable_access_entries" {
  description = "Create EKS access entries for cluster_admin_principal_arns."
  type        = bool
  default     = true
}

variable "cluster_admin_principal_arns" {
  description = "IAM principal ARNs granted AmazonEKSClusterAdminPolicy via access entries."
  type        = list(string)
  default     = []
}

variable "artifacts_bucket_arn" {
  description = "Artifacts S3 bucket ARN for the sample app IRSA role (null skips app role)."
  type        = string
  default     = null
  nullable    = true
}

variable "app_service_account_namespace" {
  description = "Kubernetes namespace for the sample app ServiceAccount (IRSA trust)."
  type        = string
  default     = "default"
}

variable "app_service_account_name" {
  description = "Kubernetes ServiceAccount name for the sample app IRSA trust."
  type        = string
  default     = "app"
}
