variable "project_name" {
  description = "Name prefix applied to RDS resources"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC the database will run in"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs to place the RDS instance in"
  type        = list(string)
}

variable "node_security_group_id" {
  description = "Security group ID shared by EKS worker nodes, allowed to reach the database"
  type        = string
}

variable "db_name" {
  description = "Name of the default database created on the instance"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Master username for the database"
  type        = string
  default     = "appuser"
}

variable "db_port" {
  description = "Port Postgres listens on"
  type        = number
  default     = 5432
}

variable "engine_version" {
  description = "Postgres engine version"
  type        = string
  default     = "16"
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t4g.micro"
}

variable "allocated_storage" {
  description = "Allocated storage in GiB"
  type        = number
  default     = 20
}

variable "multi_az" {
  description = "Whether to run a standby replica in a second AZ (extra cost)"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Number of days to retain automated backups"
  type        = number
  default     = 1
}
