output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets, where EKS nodes and RDS will run"
  value       = module.vpc.private_subnet_ids
}

output "availability_zones" {
  description = "Availability zones the subnets were created in"
  value       = module.vpc.availability_zones
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = module.vpc.internet_gateway_id
}

output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways"
  value       = module.vpc.nat_gateway_ids
}

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for the EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS control plane"
  value       = module.eks.cluster_security_group_id
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider, needed later for IRSA"
  value       = module.eks.oidc_provider_arn
}

output "db_endpoint" {
  description = "RDS connection endpoint (host:port)"
  value       = module.rds.db_endpoint
}

output "db_address" {
  description = "RDS host name only"
  value       = module.rds.db_address
}

output "db_name" {
  description = "Default database name"
  value       = module.rds.db_name
}

output "db_username" {
  description = "Database master username"
  value       = module.rds.db_username
}

output "db_password" {
  description = "Database master password"
  value       = module.rds.db_password
  sensitive   = true
}

output "ecr_repository_urls" {
  description = "Map of ECR repository name -> full repository URL (use for `docker push` and Helm values.yaml image.repository)"
  value       = { for name, repo in aws_ecr_repository.app : name => repo.repository_url }
}

output "app_namespace" {
  description = "Kubernetes namespace the app Helm charts / ArgoCD Applications should target"
  value       = var.app_namespace
}
