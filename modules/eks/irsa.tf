# IRSA roles (OIDC federation) — least-privilege examples for common EKS patterns.
# ServiceAccounts are annotated by operators/Helm; this module creates the IAM side.

locals {
  oidc_provider = replace(aws_iam_openid_connect_provider.eks.url, "https://", "")
}

# --- EBS CSI driver ---

data "aws_iam_policy_document" "ebs_csi_assume" {
  count = var.enable_irsa ? 1 : 0

  statement {
    sid     = "EBSCSIAssume"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }
  }
}

resource "aws_iam_role" "ebs_csi" {
  count = var.enable_irsa ? 1 : 0

  name               = "${var.name_prefix}-ebs-csi"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_assume[0].json
  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-ebs-csi"
    Purpose = "irsa-ebs-csi"
  })
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  count = var.enable_irsa ? 1 : 0

  role       = aws_iam_role.ebs_csi[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# --- AWS Load Balancer Controller (scoped custom policy) ---

data "aws_iam_policy_document" "lbc_assume" {
  count = var.enable_irsa ? 1 : 0

  statement {
    sid     = "LBCAssume"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }
  }
}

resource "aws_iam_role" "lbc" {
  count = var.enable_irsa ? 1 : 0

  name               = "${var.name_prefix}-lbc"
  assume_role_policy = data.aws_iam_policy_document.lbc_assume[0].json
  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-lbc"
    Purpose = "irsa-aws-load-balancer-controller"
  })
}

# Focused ELB/EC2 permissions for LBC. Expand from AWS sample policy if you need
# WAF, Cognito, or ACM Private CA features: https://kubernetes-sigs.github.io/aws-load-balancer-controller/
data "aws_iam_policy_document" "lbc" {
  count = var.enable_irsa ? 1 : 0

  statement {
    sid    = "ELBReadWrite"
    effect = "Allow"
    actions = [
      "elasticloadbalancing:AddListenerCertificates",
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:CreateListener",
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:CreateRule",
      "elasticloadbalancing:CreateTargetGroup",
      "elasticloadbalancing:DeleteListener",
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:DeleteRule",
      "elasticloadbalancing:DeleteTargetGroup",
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:Describe*",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:ModifyLoadBalancerAttributes",
      "elasticloadbalancing:ModifyRule",
      "elasticloadbalancing:ModifyTargetGroup",
      "elasticloadbalancing:ModifyTargetGroupAttributes",
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:RemoveListenerCertificates",
      "elasticloadbalancing:RemoveTags",
      "elasticloadbalancing:SetIpAddressType",
      "elasticloadbalancing:SetSecurityGroups",
      "elasticloadbalancing:SetSubnets",
      "elasticloadbalancing:SetWebAcl"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "EC2ReadAndSG"
    effect = "Allow"
    actions = [
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:CreateSecurityGroup",
      "ec2:CreateTags",
      "ec2:DeleteSecurityGroup",
      "ec2:Describe*",
      "ec2:RevokeSecurityGroupIngress"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ACMAndWAFv2Read"
    effect = "Allow"
    actions = [
      "acm:DescribeCertificate",
      "acm:ListCertificates",
      "wafv2:GetWebACL",
      "wafv2:GetWebACLForResource",
      "wafv2:AssociateWebACL",
      "wafv2:DisassociateWebACL",
      "wafv2:ListWebACLs",
      "shield:GetSubscriptionState",
      "shield:DescribeProtection",
      "shield:CreateProtection",
      "shield:DeleteProtection"
    ]
    resources = ["*"]
  }

  statement {
    sid       = "CognitoIdPRead"
    effect    = "Allow"
    actions   = ["cognito-idp:DescribeUserPoolClient"]
    resources = ["*"]
  }

  statement {
    sid    = "IAMCreateServiceLinked"
    effect = "Allow"
    actions = [
      "iam:CreateServiceLinkedRole"
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "iam:AWSServiceName"
      values   = ["elasticloadbalancing.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "lbc" {
  count = var.enable_irsa ? 1 : 0

  name   = "${var.name_prefix}-lbc"
  policy = data.aws_iam_policy_document.lbc[0].json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "lbc" {
  count = var.enable_irsa ? 1 : 0

  role       = aws_iam_role.lbc[0].name
  policy_arn = aws_iam_policy.lbc[0].arn
}

# --- Sample app IRSA (read artifacts bucket) ---

data "aws_iam_policy_document" "app_assume" {
  count = var.enable_irsa && var.artifacts_bucket_arn != null ? 1 : 0

  statement {
    sid     = "AppAssume"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider}:sub"
      values   = ["system:serviceaccount:${var.app_service_account_namespace}:${var.app_service_account_name}"]
    }
  }
}

resource "aws_iam_role" "app" {
  count = var.enable_irsa && var.artifacts_bucket_arn != null ? 1 : 0

  name               = "${var.name_prefix}-app-irsa"
  assume_role_policy = data.aws_iam_policy_document.app_assume[0].json
  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-app-irsa"
    Purpose = "irsa-sample-app"
  })
}

data "aws_iam_policy_document" "app_s3" {
  count = var.enable_irsa && var.artifacts_bucket_arn != null ? 1 : 0

  statement {
    sid    = "ArtifactsRead"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      var.artifacts_bucket_arn,
      "${var.artifacts_bucket_arn}/*"
    ]
  }
}

resource "aws_iam_policy" "app_s3" {
  count = var.enable_irsa && var.artifacts_bucket_arn != null ? 1 : 0

  name   = "${var.name_prefix}-app-artifacts-read"
  policy = data.aws_iam_policy_document.app_s3[0].json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "app_s3" {
  count = var.enable_irsa && var.artifacts_bucket_arn != null ? 1 : 0

  role       = aws_iam_role.app[0].name
  policy_arn = aws_iam_policy.app_s3[0].arn
}
