output "s3_kms_key_arn" {
  description = "KMS key ARN for S3 (null when encryption disabled)."
  value       = try(aws_kms_key.this["s3"].arn, null)
}

output "rds_kms_key_arn" {
  description = "KMS key ARN for RDS (null when encryption disabled)."
  value       = try(aws_kms_key.this["rds"].arn, null)
}

output "eks_kms_key_arn" {
  description = "KMS key ARN for EKS secrets (null when encryption disabled)."
  value       = try(aws_kms_key.this["eks"].arn, null)
}

output "logs_kms_key_arn" {
  description = "KMS key ARN for CloudWatch Logs (null when encryption disabled)."
  value       = try(aws_kms_key.this["logs"].arn, null)
}

output "cloudtrail_kms_key_arn" {
  description = "KMS key ARN for CloudTrail (null when encryption disabled)."
  value       = try(aws_kms_key.this["cloudtrail"].arn, null)
}

output "secrets_kms_key_arn" {
  description = "KMS key ARN for Secrets Manager (null when encryption disabled)."
  value       = try(aws_kms_key.this["secrets"].arn, null)
}

output "sns_kms_key_arn" {
  description = "KMS key ARN for SNS (null when encryption disabled)."
  value       = try(aws_kms_key.this["sns"].arn, null)
}

output "backup_kms_key_arn" {
  description = "KMS key ARN for AWS Backup vault (null when encryption disabled)."
  value       = try(aws_kms_key.this["backup"].arn, null)
}

output "kms_key_arns" {
  description = "Map of purpose to KMS key ARN."
  value       = { for k, v in aws_kms_key.this : k => v.arn }
}

output "alb_security_group_id" {
  description = "ALB security group ID."
  value       = aws_security_group.alb.id
}

output "database_security_group_id" {
  description = "Database security group ID."
  value       = aws_security_group.database.id
}

output "eks_cluster_security_group_id" {
  description = "EKS cluster security group ID."
  value       = aws_security_group.eks_cluster.id
}

output "eks_node_security_group_id" {
  description = "EKS node security group ID."
  value       = aws_security_group.eks_nodes.id
}

output "eks_cluster_role_arn" {
  description = "IAM role ARN for the EKS control plane."
  value       = aws_iam_role.eks_cluster.arn
}

output "eks_node_role_arn" {
  description = "IAM role ARN for EKS worker nodes."
  value       = aws_iam_role.eks_nodes.arn
}

output "eks_cluster_iam_attachment_id" {
  description = "IAM policy attachment ID for AmazonEKSClusterPolicy (use for depends_on)."
  value       = aws_iam_role_policy_attachment.eks_cluster_policy.id
}

output "eks_node_iam_attachment_ids" {
  description = "IAM policy attachment IDs for node policies (use for depends_on)."
  value = [
    aws_iam_role_policy_attachment.eks_worker_node.id,
    aws_iam_role_policy_attachment.eks_cni.id,
    aws_iam_role_policy_attachment.eks_ecr_readonly.id,
  ]
}

output "guardduty_detector_id" {
  description = "GuardDuty detector ID when enabled."
  value       = try(aws_guardduty_detector.this[0].id, null)
}
