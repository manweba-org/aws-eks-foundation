output "alb_arn" {
  description = "Application Load Balancer ARN."
  value       = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "ALB DNS name (point Route53 / clients here)."
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "ALB Route53 zone ID for alias records."
  value       = aws_lb.this.zone_id
}

output "target_group_arn" {
  description = "Default app target group ARN (for TargetGroupBinding / controller)."
  value       = aws_lb_target_group.app.arn
}

output "http_listener_arn" {
  description = "HTTP listener ARN."
  value       = aws_lb_listener.http.arn
}

output "https_listener_arn" {
  description = "HTTPS listener ARN when a certificate is provided."
  value       = try(aws_lb_listener.https[0].arn, null)
}

output "https_enabled" {
  description = "Whether HTTPS listener is active."
  value       = local.https_enabled
}
