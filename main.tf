###########################################################
# 1. Terraform & Provider
###########################################################
terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

###########################################################
# 2. Variáveis injetadas via pipeline (para DB)
###########################################################
variable "db_name" {
  type        = string
  description = "Nome do banco de dados RDS."
  default     = "fastfooddb"
}

variable "db_username" {
  type        = string
  description = "Usuário do banco de dados RDS."
  default     = "admin"
}

variable "db_password" {
  type        = string
  description = "Senha do banco de dados RDS."
  sensitive   = true
  default     = "AlterarSenhaAqui"
}

###########################################################
# 3. HARDCODE: VPC, Security Group e Subnets
#    Ajuste estes IDs conforme seu ambiente
###########################################################
locals {
  vpc_id     = "vpc-035823898b0432060"
  sg_id      = "sg-0b32fbeb948914196"
  subnet_ids = [
    "subnet-0e8a9c57e24921ad2",
    "subnet-054f5e7046e524dc7"
  ]
}

###########################################################
# 4. Verifica se Subnet Group "fastfood-db-subnet" já existe
###########################################################
data "aws_db_subnet_group" "existing_db_subnet" {
  name = "fastfood-db-subnet"
}

###########################################################
# 5. Cria Subnet Group se não existir
###########################################################
resource "aws_db_subnet_group" "fastfood_db_subnet" {
  count       = length(data.aws_db_subnet_group.existing_db_subnet.id) > 0 ? 0 : 1
  name        = "fastfood-db-subnet"
  subnet_ids  = local.subnet_ids
  description = "Managed by Terraform"

  tags = {
    Name = "fastfood-db-subnet-group"
  }
}

###########################################################
# 6. Verifica se Secret "fastfood-db-password" já existe
###########################################################
data "aws_secretsmanager_secret" "existing_db_password_secret" {
  name = "fastfood-db-password"
}

###########################################################
# 7. Cria Secret somente se não existir
###########################################################
resource "aws_secretsmanager_secret" "db_password_secret" {
  count = length(data.aws_secretsmanager_secret.existing_db_password_secret.id) > 0 ? 0 : 1
  name  = "fastfood-db-password"
}

###########################################################
# 8. Locals para SubnetGroup/Secret (já existe vs criado)
###########################################################
locals {
  db_subnet_name = length(data.aws_db_subnet_group.existing_db_subnet.id) > 0 ? data.aws_db_subnet_group.existing_db_subnet.id : aws_db_subnet_group.fastfood_db_subnet[0].name
  secret_id      = length(data.aws_secretsmanager_secret.existing_db_password_secret.id) > 0 ? data.aws_secretsmanager_secret.existing_db_password_secret.id : aws_secretsmanager_secret.db_password_secret[0].id
}

###########################################################
# 9. Cria a versão do Secret (armazena db_password)
###########################################################
resource "aws_secretsmanager_secret_version" "db_password_version" {
  secret_id     = local.secret_id
  secret_string = var.db_password
}

###########################################################
# 10. Cria a Instância RDS (PostgreSQL)
###########################################################
resource "aws_db_instance" "fastfood_db" {
  allocated_storage     = 20
  storage_type          = "gp2"
  engine                = "postgres"
  engine_version        = "16"
  instance_class        = "db.t3.micro"
  identifier            = "fastfood-db"

  db_name               = var.db_name
  username              = var.db_username
  password              = var.db_password

  publicly_accessible   = true
  skip_final_snapshot   = true

  # Security Group e Subnet Group hardcoded
  vpc_security_group_ids = [ local.sg_id ]
  db_subnet_group_name   = local.db_subnet_name

  tags = {
    Project     = "FastFood"
    Environment = "DEV"
  }
}

###########################################################
# 11. Output do Endpoint
###########################################################
output "db_endpoint" {
  description = "Endpoint do RDS"
  value       = aws_db_instance.fastfood_db.endpoint
}
