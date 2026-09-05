package terraform.security

# OPA policy library (same rules as conftest) for local `opa test`.

deny_unencrypted_s3[msg] {
  input.resource_type == "aws_s3_bucket"
  not input.encryption_enabled
  msg := sprintf("S3 bucket %v must have encryption enabled", [input.name])
}

deny_public_s3[msg] {
  input.resource_type == "aws_s3_bucket"
  input.public_access_blocked == false
  msg := sprintf("S3 bucket %v must block public access", [input.name])
}

deny_open_admin_ports[msg] {
  input.resource_type == "aws_security_group_rule"
  input.cidr == "0.0.0.0/0"
  sensitive_ports := {22, 3389, 5432, 3306, 6379, 27017}
  input.from_port <= port
  input.to_port >= port
  sensitive_ports[port]
  msg := sprintf("Sensitive port %v open to the world on %v", [port, input.name])
}

deny_public_rds[msg] {
  input.resource_type == "aws_db_instance"
  input.publicly_accessible == true
  msg := sprintf("RDS %v is publicly accessible", [input.name])
}
