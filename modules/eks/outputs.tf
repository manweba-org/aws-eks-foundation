output "cluster_name" {
  description = "EKS cluster name."
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "EKS API server endpoint."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 CA data for kubeconfig (sensitive)."
  value       = aws_eks_cluster.this.certificate_authority[0].data
  sensitive   = true
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL for IRSA."
  value       = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

output "oidc_provider_arn" {
  description = "IAM OIDC provider ARN for IRSA."
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "node_group_name" {
  description = "Managed node group name."
  value       = aws_eks_node_group.default.node_group_name
}

output "ebs_csi_role_arn" {
  description = "IRSA role ARN for the EBS CSI driver."
  value       = try(aws_iam_role.ebs_csi[0].arn, null)
}

output "load_balancer_controller_role_arn" {
  description = "IRSA role ARN for AWS Load Balancer Controller."
  value       = try(aws_iam_role.lbc[0].arn, null)
}

output "app_irsa_role_arn" {
  description = "Sample app IRSA role ARN (artifacts S3 read)."
  value       = try(aws_iam_role.app[0].arn, null)
}

output "cluster_admin_access_entry_arns" {
  description = "Principal ARNs with cluster-admin access entries."
  value       = [for e in aws_eks_access_entry.admin : e.principal_arn]
}
