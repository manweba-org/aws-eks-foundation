# Single log group — EKS writes all enabled control-plane log types here.
resource "aws_cloudwatch_log_group" "eks" {
  name              = "/aws/eks/${var.name_prefix}-eks/cluster"
  retention_in_days = 30
  kms_key_id        = var.enable_encryption ? var.logs_kms_key_arn : null

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-eks-logs"
  })
}

# Anchor IAM attachment IDs so cluster/node group wait for policy attachment.
resource "terraform_data" "cluster_iam_ready" {
  input = var.cluster_iam_attachment_ids
}

resource "terraform_data" "node_iam_ready" {
  input = var.node_iam_attachment_ids
}

resource "aws_eks_cluster" "this" {
  name     = "${var.name_prefix}-eks"
  role_arn = var.cluster_role_arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    endpoint_private_access = true
    # Private-only API by default — reach via VPN/SSM bastion after apply.
    endpoint_public_access = false
    security_group_ids     = [var.cluster_security_group_id]
  }

  # API access entries for day-2 kubectl; CONFIG_MAP kept for bootstrap compatibility.
  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  dynamic "encryption_config" {
    for_each = var.enable_encryption && var.kms_key_arn != null ? [1] : []
    content {
      provider {
        key_arn = var.kms_key_arn
      }
      resources = ["secrets"]
    }
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-eks"
  })

  depends_on = [
    aws_cloudwatch_log_group.eks,
    terraform_data.cluster_iam_ready,
  ]
}

resource "aws_launch_template" "nodes" {
  name_prefix = "${var.name_prefix}-eks-nodes-"

  # Include the EKS-created cluster SG plus our least-privilege node SG.
  vpc_security_group_ids = [
    aws_eks_cluster.this.vpc_config[0].cluster_security_group_id,
    var.node_security_group_id,
  ]

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = "${var.name_prefix}-eks-node"
    })
  }

  tags = var.tags
}

resource "aws_eks_node_group" "default" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.name_prefix}-default"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.private_subnet_ids
  instance_types  = var.node_instance_types

  scaling_config {
    desired_size = var.desired_size
    min_size     = var.min_size
    max_size     = var.max_size
  }

  update_config {
    max_unavailable = 1
  }

  launch_template {
    id      = aws_launch_template.nodes.id
    version = aws_launch_template.nodes.latest_version
  }

  labels = {
    workload = "general"
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-eks-nodes"
  })

  depends_on = [terraform_data.node_iam_ready]
}

data "tls_certificate" "eks" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-eks-oidc"
  })
}
