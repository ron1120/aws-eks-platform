# Copy to terraform.tfvars and adjust for your environment:
#   cp example.tfvars terraform.tfvars

project_name = "aws-eks-platform"

aws_region = "us-east-1"

vpc_cidr = "10.0.0.0/16"

availability_zones = [
  "us-east-1a",
  "us-east-1b"
]

public_subnets = [
  "10.0.1.0/24",
  "10.0.2.0/24"
]

private_subnets = [
  "10.0.10.0/24",
  "10.0.20.0/24"
]
