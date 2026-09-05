output "artifacts_bucket_id" {
  description = "Artifacts bucket name."
  value       = aws_s3_bucket.artifacts.id
}

output "artifacts_bucket_arn" {
  description = "Artifacts bucket ARN."
  value       = aws_s3_bucket.artifacts.arn
}

output "audit_logs_bucket_id" {
  description = "Audit logs bucket name."
  value       = aws_s3_bucket.audit.id
}

output "audit_logs_bucket_arn" {
  description = "Audit logs bucket ARN."
  value       = aws_s3_bucket.audit.arn
}

output "audit_logs_bucket_policy_id" {
  description = "Audit bucket policy ID (use for CloudTrail depends_on)."
  value       = aws_s3_bucket_policy.audit.id
}
