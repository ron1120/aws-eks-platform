# Password is generated once and stored in Terraform state (state is
# gitignored). For a real production setup, prefer AWS Secrets Manager with
# a rotation policy instead of a static Terraform-managed password.
resource "random_password" "db" {
  length  = 20
  special = false
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.private_subnet_ids
}

# Only allow traffic from EKS worker nodes, on the Postgres port.
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Allow Postgres access from EKS worker nodes only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Postgres from EKS nodes"
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = [var.node_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "this" {
  identifier     = "${var.project_name}-db"
  engine         = "postgres"
  engine_version = var.engine_version

  instance_class    = var.instance_class
  allocated_storage = var.allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db.result
  port     = var.db_port

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  # Keep this false for a learning project: no public endpoint.
  publicly_accessible = false

  multi_az            = var.multi_az
  skip_final_snapshot = true
  deletion_protection = false

  backup_retention_period = var.backup_retention_period
}
