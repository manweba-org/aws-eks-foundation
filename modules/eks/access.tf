# Day-2 cluster access via EKS Access Entries (API mode) — no aws-auth ConfigMap edits.

resource "aws_eks_access_entry" "admin" {
  for_each = var.enable_access_entries ? toset(var.cluster_admin_principal_arns) : toset([])

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = each.value
  type          = "STANDARD"

  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-access-admin"
    Purpose = "cluster-admin"
  })
}

resource "aws_eks_access_policy_association" "admin" {
  for_each = aws_eks_access_entry.admin

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = each.value.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}
