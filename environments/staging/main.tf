data "aws_availability_zones" "available" {
  state = "available"
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  # Reserved for future multi-region wiring (documented; unused for resources).
  planned_dr_region = var.dr_region
  azs = length(var.availability_zones) > 0 ? var.availability_zones : slice(
    data.aws_availability_zones.available.names,
    0,
    min(var.az_count, length(data.aws_availability_zones.available.names))
  )
  az_count              = length(local.azs)
  public_subnet_cidrs   = [for i in range(local.az_count) : cidrsubnet(var.vpc_cidr, 4, i)]
  private_subnet_cidrs  = [for i in range(local.az_count) : cidrsubnet(var.vpc_cidr, 4, i + 4)]
  database_subnet_cidrs = [for i in range(local.az_count) : cidrsubnet(var.vpc_cidr, 4, i + 8)]
  common_tags = merge({
    Project            = var.project_name
    Environment        = var.environment
    ManagedBy          = "terraform"
    Owner              = var.owner
    CostCenter         = var.cost_center
    DataClassification = var.data_classification
    Compliance         = join(",", var.compliance_frameworks)
    NamePrefix         = local.name_prefix
    DrRegionPlanned    = local.planned_dr_region
  }, var.additional_tags)
}

module "networking" {
  source = "../../modules/networking"

  name_prefix           = local.name_prefix
  vpc_cidr              = var.vpc_cidr
  availability_zones    = local.azs
  public_subnet_cidrs   = local.public_subnet_cidrs
  private_subnet_cidrs  = local.private_subnet_cidrs
  database_subnet_cidrs = local.database_subnet_cidrs
  single_nat_gateway    = var.single_nat_gateway
  tags                  = local.common_tags
}

module "security" {
  source = "../../modules/security"

  name_prefix         = local.name_prefix
  enable_encryption   = var.enable_encryption
  enable_guardduty    = var.enable_guardduty
  enable_security_hub = var.enable_security_hub
  vpc_id              = module.networking.vpc_id
  allowed_admin_cidrs = var.allowed_admin_cidrs
  tags                = local.common_tags
}

module "storage" {
  source = "../../modules/storage"

  name_prefix       = local.name_prefix
  enable_encryption = var.enable_encryption
  kms_key_arn       = module.security.s3_kms_key_arn
  tags              = local.common_tags
}

module "database" {
  source = "../../modules/database"

  name_prefix                = local.name_prefix
  database_subnet_ids        = module.networking.database_subnet_ids
  database_security_group_id = module.security.database_security_group_id
  kms_key_arn                = module.security.rds_kms_key_arn
  secrets_kms_key_arn        = module.security.secrets_kms_key_arn
  enable_encryption          = var.enable_encryption
  enable_backup              = var.enable_backup
  backup_retention_days      = var.backup_retention_days
  instance_class             = var.rds_instance_class
  engine_version             = var.rds_engine_version
  multi_az                   = var.rds_multi_az
  deletion_protection        = var.rds_deletion_protection
  tags                       = local.common_tags
}

module "eks" {
  source = "../../modules/eks"

  name_prefix                   = local.name_prefix
  cluster_version               = var.eks_kubernetes_version
  private_subnet_ids            = module.networking.private_subnet_ids
  cluster_security_group_id     = module.security.eks_cluster_security_group_id
  node_security_group_id        = module.security.eks_node_security_group_id
  cluster_role_arn              = module.security.eks_cluster_role_arn
  node_role_arn                 = module.security.eks_node_role_arn
  kms_key_arn                   = module.security.eks_kms_key_arn
  logs_kms_key_arn              = module.security.logs_kms_key_arn
  enable_encryption             = var.enable_encryption
  cluster_iam_attachment_ids    = [module.security.eks_cluster_iam_attachment_id]
  node_iam_attachment_ids       = module.security.eks_node_iam_attachment_ids
  node_instance_types           = var.eks_node_instance_types
  desired_size                  = var.eks_desired_size
  min_size                      = var.eks_min_size
  max_size                      = var.eks_max_size
  enable_irsa                   = var.enable_irsa
  enable_addons                 = var.enable_addons
  enable_access_entries         = var.enable_access_entries
  cluster_admin_principal_arns  = var.cluster_admin_principal_arns
  artifacts_bucket_arn          = module.storage.artifacts_bucket_arn
  app_service_account_namespace = var.app_service_account_namespace
  app_service_account_name      = var.app_service_account_name
  tags                          = local.common_tags
}

module "alb" {
  count  = var.enable_alb ? 1 : 0
  source = "../../modules/alb"

  name_prefix       = local.name_prefix
  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids
  security_group_id = module.security.alb_security_group_id
  certificate_arn   = var.alb_certificate_arn
  target_port       = var.alb_target_port
  health_check_path = var.alb_health_check_path
  tags              = local.common_tags
}

module "observability" {
  source = "../../modules/observability"

  name_prefix            = local.name_prefix
  enable_cloudtrail      = var.enable_cloudtrail
  enable_config          = var.enable_config
  enable_backup          = var.enable_backup
  backup_retention_days  = var.backup_retention_days
  enable_flow_logs       = var.enable_flow_logs
  alert_email            = var.alert_email
  vpc_id                 = module.networking.vpc_id
  audit_bucket_arn       = module.storage.audit_logs_bucket_arn
  audit_bucket_id        = module.storage.audit_logs_bucket_id
  audit_bucket_policy_id = module.storage.audit_logs_bucket_policy_id
  cloudtrail_kms_arn     = module.security.cloudtrail_kms_key_arn
  logs_kms_key_arn       = module.security.logs_kms_key_arn
  sns_kms_key_arn        = module.security.sns_kms_key_arn
  backup_kms_key_arn     = module.security.backup_kms_key_arn
  eks_cluster_name       = module.eks.cluster_name
  rds_instance_id        = module.database.db_instance_id
  rds_instance_arn       = module.database.db_instance_arn
  tags                   = local.common_tags
}
