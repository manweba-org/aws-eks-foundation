variable "name_prefix" {
  description = "Naming prefix for networking resources."
  type        = string
}

variable "vpc_cidr" {
  description = "VPC IPv4 CIDR block."
  type        = string
}

variable "availability_zones" {
  description = "Availability zones for subnets."
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (one per AZ)."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private application subnets (one per AZ)."
  type        = list(string)
}

variable "database_subnet_cidrs" {
  description = "CIDR blocks for database subnets (one per AZ)."
  type        = list(string)
}

variable "single_nat_gateway" {
  description = "When true, create one NAT gateway (lower cost, less HA). Prefer false in prod."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to networking resources."
  type        = map(string)
  default     = {}
}
