resource "aws_db_subnet_group" "this" {
  name       = "${var.name_prefix}-db"
  subnet_ids = var.database_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-db-subnet-group"
  })
}

resource "aws_db_parameter_group" "postgres15" {
  name   = "${var.name_prefix}-postgres15"
  family = "postgres15"

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-postgres15-params"
  })
}

resource "aws_db_instance" "this" {
  identifier = "${var.name_prefix}-postgres"

  engine                = "postgres"
  engine_version        = var.engine_version
  instance_class        = var.instance_class
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = var.enable_encryption
  kms_key_id            = var.enable_encryption ? var.kms_key_arn : null

  db_name  = "app"
  username = "dbadmin"

  # AWS-managed master password in Secrets Manager — no plaintext in tfvars.
  manage_master_user_password   = true
  master_user_secret_kms_key_id = var.secrets_kms_key_arn

  db_subnet_group_name      = aws_db_subnet_group.this.name
  vpc_security_group_ids    = [var.database_security_group_id]
  parameter_group_name      = aws_db_parameter_group.postgres15.name
  publicly_accessible       = false
  multi_az                  = var.multi_az
  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = !var.deletion_protection
  final_snapshot_identifier = var.deletion_protection ? "${var.name_prefix}-postgres-final" : null

  backup_retention_period = var.enable_backup ? var.backup_retention_days : 0
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"
  copy_tags_to_snapshot   = true

  auto_minor_version_upgrade = true
  apply_immediately          = false

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-postgres"
  })
}
