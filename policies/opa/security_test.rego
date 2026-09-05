package terraform.security

test_deny_unencrypted_s3 {
  deny_unencrypted_s3[_] with input as {
    "resource_type": "aws_s3_bucket",
    "name": "bad",
    "encryption_enabled": false,
    "public_access_blocked": true
  }
}

test_allow_encrypted_s3 {
  count(deny_unencrypted_s3) == 0 with input as {
    "resource_type": "aws_s3_bucket",
    "name": "good",
    "encryption_enabled": true,
    "public_access_blocked": true
  }
}

test_deny_ssh_open {
  deny_open_admin_ports[_] with input as {
    "resource_type": "aws_security_group_rule",
    "name": "ssh",
    "cidr": "0.0.0.0/0",
    "from_port": 22,
    "to_port": 22
  }
}

test_allow_https_open {
  count(deny_open_admin_ports) == 0 with input as {
    "resource_type": "aws_security_group_rule",
    "name": "https",
    "cidr": "0.0.0.0/0",
    "from_port": 443,
    "to_port": 443
  }
}

test_deny_public_rds {
  deny_public_rds[_] with input as {
    "resource_type": "aws_db_instance",
    "name": "db",
    "publicly_accessible": true
  }
}
