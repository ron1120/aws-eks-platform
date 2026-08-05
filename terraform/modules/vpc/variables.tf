variable "project_name" {
  description = "Name prefix applied to the VPC and its resources"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "availability_zones" {
  description = "Availability zones to spread the subnets across"
  type        = list(string)
}

variable "public_subnets" {
  description = "CIDR blocks for the public subnets, one per availability zone"
  type        = list(string)
}

variable "private_subnets" {
  description = "CIDR blocks for the private subnets, one per availability zone"
  type        = list(string)
}

variable "single_nat_gateway" {
  description = "Route all private subnets through one NAT Gateway instead of one per availability zone"
  type        = bool
  default     = true
}
