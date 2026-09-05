# Conftest policies for `terraform show -json` / `terraform plan -json` output.
# Evaluated in the manual OIDC plan workflow after a real plan.
# Unit fixtures under tests/unit/fixtures use policies/conftest/*.rego (package main).

package main

deny[msg] {
  rc := input.resource_changes[_]
  rc.type == "aws_db_instance"
  rc.change.after.publicly_accessible == true
  msg := sprintf("RDS %v must not be publicly accessible", [rc.address])
}

deny[msg] {
  rc := input.resource_changes[_]
  rc.type == "aws_s3_bucket_public_access_block"
  after := rc.change.after
  after.block_public_acls == false
  msg := sprintf("S3 public access block incomplete on %v", [rc.address])
}

deny[msg] {
  rc := input.resource_changes[_]
  rc.type == "aws_vpc_security_group_ingress_rule"
  after := rc.change.after
  after.cidr_ipv4 == "0.0.0.0/0"
  sensitive := {22, 3389, 5432, 3306, 6379, 27017}
  after.from_port <= port
  after.to_port >= port
  sensitive[port]
  msg := sprintf("%v opens sensitive port %v to 0.0.0.0/0", [rc.address, port])
}
