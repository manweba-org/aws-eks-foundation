output "sns_alerts_topic_arn" {
  description = "SNS alerts topic ARN."
  value       = aws_sns_topic.alerts.arn
}

output "dashboard_name" {
  description = "CloudWatch dashboard name."
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "application_log_group_name" {
  description = "Application CloudWatch log group name."
  value       = aws_cloudwatch_log_group.application.name
}

output "cloudtrail_arn" {
  description = "CloudTrail ARN when enabled."
  value       = try(aws_cloudtrail.this[0].arn, null)
}

output "backup_vault_name" {
  description = "AWS Backup vault name when enabled."
  value       = try(aws_backup_vault.this[0].name, null)
}

output "backup_plan_id" {
  description = "AWS Backup plan ID when enabled."
  value       = try(aws_backup_plan.this[0].id, null)
}

output "backup_selection_id" {
  description = "AWS Backup RDS selection ID when enabled."
  value       = try(aws_backup_selection.rds[0].id, null)
}

output "config_recorder_name" {
  description = "AWS Config recorder name when enabled."
  value       = try(aws_config_configuration_recorder.this[0].name, null)
}

output "flow_log_id" {
  description = "VPC Flow Log ID when enabled."
  value       = try(aws_flow_log.this[0].id, null)
}
