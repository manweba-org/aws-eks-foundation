output "vpc_id" {
  description = "VPC ID."
  value       = module.networking.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs."
  value       = module.networking.private_subnet_ids
}

output "eks_cluster_name" {
  description = "EKS cluster name."
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS endpoint."
  value       = module.eks.cluster_endpoint
}

output "eks_oidc_provider_arn" {
  description = "EKS OIDC provider ARN for IRSA."
  value       = module.eks.oidc_provider_arn
}

output "ebs_csi_role_arn" {
  description = "IRSA role for EBS CSI driver."
  value       = module.eks.ebs_csi_role_arn
}

output "load_balancer_controller_role_arn" {
  description = "IRSA role for AWS Load Balancer Controller."
  value       = module.eks.load_balancer_controller_role_arn
}

output "app_irsa_role_arn" {
  description = "Sample app IRSA role (annotate ServiceAccount with this ARN)."
  value       = module.eks.app_irsa_role_arn
}

output "alb_dns_name" {
  description = "ALB DNS name when enable_alb is true."
  value       = try(module.alb[0].alb_dns_name, null)
}

output "alb_target_group_arn" {
  description = "ALB target group ARN when enable_alb is true."
  value       = try(module.alb[0].target_group_arn, null)
}

output "artifacts_bucket_id" {
  description = "Artifacts bucket."
  value       = module.storage.artifacts_bucket_id
}

output "audit_logs_bucket_id" {
  description = "Audit bucket."
  value       = module.storage.audit_logs_bucket_id
}

output "rds_endpoint" {
  description = "RDS endpoint."
  value       = module.database.db_endpoint
}

output "sns_alerts_topic_arn" {
  description = "SNS alerts topic."
  value       = module.observability.sns_alerts_topic_arn
}

output "backup_plan_id" {
  description = "AWS Backup plan ID when enabled."
  value       = module.observability.backup_plan_id
}
