provider "aws" {
  region = "us-east-1"
}

# ✅ Use Existing VPC
data "aws_vpc" "existing_vpc" {
  id = "vpc-035823898b0432060"
}

# ✅ Use Existing Subnets
data "aws_subnet" "existing_subnet_1" {
  id = "subnet-0e8a9c57e24921ad2"
}

data "aws_subnet" "existing_subnet_2" {
  id = "subnet-054f5e7046e524dc7"
}

# ✅ Create Security Group for RDS
resource "aws_security_group" "db_sg" {
  vpc_id = data.aws_vpc.existing_vpc.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # ⚠️ Change this to restrict access later
    description = "Allow PostgreSQL access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "fastfood-db-security-group"
  }
}

# ✅ Create RDS Database
resource "aws_db_instance" "fastfood_db" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine              = "postgres"
  engine_version      = "16"
  instance_class      = "db.t3.micro"
  identifier          = "fastfood-db"
  db_name             = var.db_name
  username           = var.db_username
  password           = var.db_password
  publicly_accessible = false
  skip_final_snapshot = true

  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.fastfood_db_subnet.name
}

# ✅ Create Subnet Group for RDS
resource "aws_db_subnet_group" "fastfood_db_subnet" {
  name       = "fastfood-db-subnet"
  subnet_ids = [
    data.aws_subnet.existing_subnet_1.id,
    data.aws_subnet.existing_subnet_2.id
  ]

  tags = {
    Name = "fastfood-db-subnet-group"
  }
}

# ✅ Store Database Password in AWS Secrets Manager
resource "aws_secretsmanager_secret" "db_password_secret" {
  name = "fastfood-db-password"
}

resource "aws_secretsmanager_secret_version" "db_password_version" {
  secret_id     = aws_secretsmanager_secret.db_password_secret.id
  secret_string = var.db_password
}

# ✅ Variables for Database Credentials
variable "db_username" {
  description = "Database username"
  type        = string
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Database name"
  type        = string
}
