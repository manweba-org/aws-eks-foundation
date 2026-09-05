data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  kms_services = var.enable_encryption ? toset(["s3", "rds", "eks", "logs", "cloudtrail", "secrets", "sns", "backup"]) : toset([])
  account_id   = data.aws_caller_identity.current.account_id
  region       = data.aws_region.current.name
}

# --- EKS IAM roles (defined before KMS so the EKS CMK can grant the cluster role) ---

data "aws_iam_policy_document" "eks_cluster_assume" {
  statement {
    sid     = "EKSClusterAssume"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eks_cluster" {
  name               = "${var.name_prefix}-eks-cluster"
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

data "aws_iam_policy_document" "eks_node_assume" {
  statement {
    sid     = "EKSNodeAssume"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eks_nodes" {
  name               = "${var.name_prefix}-eks-nodes"
  assume_role_policy = data.aws_iam_policy_document.eks_node_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "eks_worker_node" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_ecr_readonly" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# --- KMS CMKs (service-specific policies) ---

data "aws_iam_policy_document" "kms_root_admin" {
  statement {
    sid    = "EnableRootAccountAdmin"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }
}

# S3 / RDS / Secrets Manager — ViaService scoped service principals
data "aws_iam_policy_document" "kms_via_service" {
  for_each = toset([for s in local.kms_services : s if contains(["s3", "rds", "secrets"], s)])

  source_policy_documents = [data.aws_iam_policy_document.kms_root_admin.json]

  statement {
    sid    = "AllowServiceUse"
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = (
        each.key == "s3" ? ["s3.amazonaws.com"] :
        each.key == "rds" ? ["rds.amazonaws.com"] :
        ["secretsmanager.amazonaws.com"]
      )
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:CreateGrant"
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values = (
        each.key == "s3" ? ["s3.${local.region}.amazonaws.com"] :
        each.key == "rds" ? ["rds.${local.region}.amazonaws.com"] :
        ["secretsmanager.${local.region}.amazonaws.com"]
      )
    }
  }
}

# EKS secrets encryption — cluster IAM role must Encrypt/Decrypt/CreateGrant
data "aws_iam_policy_document" "kms_eks" {
  count = contains(local.kms_services, "eks") ? 1 : 0

  source_policy_documents = [data.aws_iam_policy_document.kms_root_admin.json]

  statement {
    sid    = "AllowEKSClusterCrypto"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.eks_cluster.arn]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AllowEKSClusterCreateGrant"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.eks_cluster.arn]
    }
    actions   = ["kms:CreateGrant"]
    resources = ["*"]
    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["true"]
    }
  }
}

# CloudWatch Logs — EncryptionContext required by the Logs service
data "aws_iam_policy_document" "kms_logs" {
  count = contains(local.kms_services, "logs") ? 1 : 0

  source_policy_documents = [data.aws_iam_policy_document.kms_root_admin.json]

  statement {
    sid    = "AllowCloudWatchLogs"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["logs.${local.region}.amazonaws.com"]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]
    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:aws:logs:${local.region}:${local.account_id}:*"]
    }
  }
}

# CloudTrail — service encrypt with trail encryption context; decrypt for consumers
data "aws_iam_policy_document" "kms_cloudtrail" {
  count = contains(local.kms_services, "cloudtrail") ? 1 : 0

  source_policy_documents = [data.aws_iam_policy_document.kms_root_admin.json]

  statement {
    sid    = "AllowCloudTrailEncrypt"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["kms:GenerateDataKey*"]
    resources = ["*"]
    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:cloudtrail:arn"
      values   = ["arn:aws:cloudtrail:*:${local.account_id}:trail/*"]
    }
  }

  statement {
    sid    = "AllowCloudTrailDescribe"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["kms:DescribeKey"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowCloudTrailDecrypt"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.account_id}:root"]
    }
    actions   = ["kms:Decrypt", "kms:DescribeKey"]
    resources = ["*"]
    condition {
      test     = "Null"
      variable = "kms:EncryptionContext:aws:cloudtrail:arn"
      values   = ["false"]
    }
  }
}

# SNS — dedicated CMK with sns.amazonaws.com + caller account for publish/subscribe
data "aws_iam_policy_document" "kms_sns" {
  count = contains(local.kms_services, "sns") ? 1 : 0

  source_policy_documents = [data.aws_iam_policy_document.kms_root_admin.json]

  statement {
    sid    = "AllowSNSService"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey*"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AllowCloudWatchAlarms"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudwatch.amazonaws.com"]
    }
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey*"
    ]
    resources = ["*"]
  }
}

# AWS Backup vault encryption
data "aws_iam_policy_document" "kms_backup" {
  count = contains(local.kms_services, "backup") ? 1 : 0

  source_policy_documents = [data.aws_iam_policy_document.kms_root_admin.json]

  statement {
    sid    = "AllowBackupService"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:CreateGrant"
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["backup.${local.region}.amazonaws.com"]
    }
  }
}

locals {
  kms_policy_json = {
    for svc in local.kms_services : svc => (
      contains(["s3", "rds", "secrets"], svc) ? data.aws_iam_policy_document.kms_via_service[svc].json :
      svc == "eks" ? data.aws_iam_policy_document.kms_eks[0].json :
      svc == "logs" ? data.aws_iam_policy_document.kms_logs[0].json :
      svc == "cloudtrail" ? data.aws_iam_policy_document.kms_cloudtrail[0].json :
      svc == "sns" ? data.aws_iam_policy_document.kms_sns[0].json :
      svc == "backup" ? data.aws_iam_policy_document.kms_backup[0].json :
      data.aws_iam_policy_document.kms_root_admin.json
    )
  }
}

resource "aws_kms_key" "this" {
  for_each = local.kms_services

  description             = "${var.name_prefix} ${each.key} CMK"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy                  = local.kms_policy_json[each.key]

  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-kms-${each.key}"
    Purpose = each.key
  })
}

resource "aws_kms_alias" "this" {
  for_each = local.kms_services

  name          = "alias/${var.name_prefix}-${each.key}"
  target_key_id = aws_kms_key.this[each.key].key_id
}

# --- Security groups (least privilege) ---

resource "aws_security_group" "alb" {
  name        = "${var.name_prefix}-alb"
  description = "Internet-facing ALB: HTTPS/HTTP from internet; admin 8443 from approved CIDRs."
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-alb-sg"
    Purpose = "alb"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTPS from internet (public web only — not admin SSH)"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTP from internet for TLS redirect at ALB"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "alb_admin_https" {
  for_each = toset(var.allowed_admin_cidrs)

  security_group_id = aws_security_group.alb.id
  description       = "Admin HTTPS from approved CIDR"
  cidr_ipv4         = each.value
  from_port         = 8443
  to_port           = 8443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "alb_egress" {
  security_group_id = aws_security_group.alb.id
  description       = "ALB to targets within VPC"
  cidr_ipv4         = data.aws_vpc.this.cidr_block
  ip_protocol       = "-1"
}

data "aws_vpc" "this" {
  id = var.vpc_id
}

resource "aws_security_group" "eks_cluster" {
  name        = "${var.name_prefix}-eks-cluster"
  description = "EKS control plane security group"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-eks-cluster-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "eks_cluster_from_nodes" {
  security_group_id            = aws_security_group.eks_cluster.id
  description                  = "Nodes to control plane"
  referenced_security_group_id = aws_security_group.eks_nodes.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "eks_cluster_egress" {
  security_group_id = aws_security_group.eks_cluster.id
  description       = "Control plane egress"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_security_group" "eks_nodes" {
  name        = "${var.name_prefix}-eks-nodes"
  description = "EKS managed node group security group"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-eks-nodes-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "eks_nodes_self" {
  security_group_id            = aws_security_group.eks_nodes.id
  description                  = "Node-to-node"
  referenced_security_group_id = aws_security_group.eks_nodes.id
  ip_protocol                  = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "eks_nodes_from_cluster" {
  security_group_id            = aws_security_group.eks_nodes.id
  description                  = "Control plane to nodes (kubelet)"
  referenced_security_group_id = aws_security_group.eks_cluster.id
  from_port                    = 1025
  to_port                      = 65535
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "eks_nodes_from_alb" {
  security_group_id            = aws_security_group.eks_nodes.id
  description                  = "ALB to NodePorts"
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = 30000
  to_port                      = 32767
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "eks_nodes_from_alb_http" {
  security_group_id            = aws_security_group.eks_nodes.id
  description                  = "ALB to pod/HTTP ports (IP-mode targets)"
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "eks_nodes_from_alb_https" {
  security_group_id            = aws_security_group.eks_nodes.id
  description                  = "ALB to pod/HTTPS ports (IP-mode targets)"
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "eks_nodes_egress" {
  security_group_id = aws_security_group.eks_nodes.id
  description       = "Nodes egress (pull images, APIs via NAT)"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_security_group" "database" {
  name        = "${var.name_prefix}-database"
  description = "PostgreSQL from EKS nodes only — not publicly reachable"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-database-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "database_from_nodes" {
  security_group_id            = aws_security_group.database.id
  description                  = "PostgreSQL from EKS nodes"
  referenced_security_group_id = aws_security_group.eks_nodes.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "database_egress" {
  security_group_id = aws_security_group.database.id
  description       = "DB egress limited to VPC"
  cidr_ipv4         = data.aws_vpc.this.cidr_block
  ip_protocol       = "-1"
}

# --- Optional GuardDuty / Security Hub (account-local; org features are a separate layer) ---

resource "aws_guardduty_detector" "this" {
  count = var.enable_guardduty ? 1 : 0

  enable                       = true
  finding_publishing_frequency = "SIX_HOURS"

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-guardduty"
  })
}

resource "aws_securityhub_account" "this" {
  count = var.enable_security_hub ? 1 : 0

  enable_default_standards = true
}
