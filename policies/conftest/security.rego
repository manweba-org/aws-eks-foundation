package main

# Deny insecure transport missing on S3 bucket policies — evaluated against fixture JSON.

deny[msg] {
  input.resource_type == "aws_s3_bucket"
  not input.encryption_enabled
  msg := sprintf("S3 bucket %v must have encryption enabled", [input.name])
}

deny[msg] {
  input.resource_type == "aws_s3_bucket"
  input.public_access_blocked == false
  msg := sprintf("S3 bucket %v must block public access", [input.name])
}

deny[msg] {
  input.resource_type == "aws_security_group_rule"
  input.cidr == "0.0.0.0/0"
  sensitive_ports := {22, 3389, 5432, 3306, 6379, 27017}
  input.from_port <= port
  input.to_port >= port
  sensitive_ports[port]
  msg := sprintf("SG rule on %v must not expose sensitive port %v to 0.0.0.0/0", [input.name, port])
}

deny[msg] {
  input.resource_type == "aws_db_instance"
  input.publicly_accessible == true
  msg := sprintf("RDS instance %v must not be publicly accessible", [input.name])
}

deny[msg] {
  input.resource_type == "tagged_resource"
  required := {"Project", "Environment", "ManagedBy"}
  missing := required - {t | t := input.tags[_]}
  count(missing) > 0
  msg := sprintf("Resource %v missing required tags: %v", [input.name, missing])
}
