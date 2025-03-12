###########################################################
# Bloqueio de Versão do Terraform e Providers
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

###########################################################
# Provider
###########################################################
provider "aws" {
  region = "us-east-1"
}

###########################################################
# Variáveis
###########################################################
variable "db_name" {
  type        = string
  description = "Nome do banco de dados RDS."
}

variable "db_username" {
  type        = string
  description = "Usuário do banco de dados RDS."
}

variable "db_password" {
  type        = string
  description = "Senha do banco de dados RDS."
  sensitive   = true
}

###########################################################
# Verifica se Subnet Group existente já existe (fastfood-db-subnet)
###########################################################
data "aws_db_subnet_group" "existing_db_subnet" {
  name = "fastfood-db-subnet"
}

###########################################################
# Cria Subnet Group somente se não existir
###########################################################
resource "aws_db_subnet_group" "fastfood_db_subnet" {
  count       = length(data.aws_db_subnet_group.existing_db_subnet.id) > 0 ? 0 : 1
  name        = "fastfood-db-subnet"
  # Exemplo: substitua pelas Subnets reais ou use var.subnet_ids
  subnet_ids  = [
    "subnet-abc123",
    "subnet-def456"
  ]
  description = "Managed by Terraform"

  tags = {
    Name = "fastfood-db-subnet-group"
  }
}

###########################################################
# Verifica se Secret existente (fastfood-db-password) já existe
###########################################################
data "aws_secretsmanager_secret" "existing_db_password_secret" {
  name = "fastfood-db-password"
}

###########################################################
# Cria Secret somente se não existir
###########################################################
resource "aws_secretsmanager_secret" "db_password_secret" {
  count = length(data.aws_secretsmanager_secret.existing_db_password_secret.id) > 0 ? 0 : 1
  name  = "fastfood-db-password"
}

###########################################################
# Locals para escolher o valor correto (já existente vs. criado)
###########################################################
locals {
  db_subnet_name = length(data.aws_db_subnet_group.existing_db_subnet.id) > 0 ? data.aws_db_subnet_group.existing_db_subnet.id : aws_db_subnet_group.fastfood_db_subnet[0].name
  secret_id      = length(data.aws_secretsmanager_secret.existing_db_password_secret.id) > 0 ? data.aws_secretsmanager_secret.existing_db_password_secret.id : aws_secretsmanager_secret.db_password_secret[0].id
}

###########################################################
# Cria a versão do Secret (grava a senha do banco)
###########################################################
resource "aws_secretsmanager_secret_version" "db_password_version" {
  secret_id     = local.secret_id
  secret_string = var.db_password
}

###########################################################
# Cria a Instância RDS (PostgreSQL)
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
  publicly_accessible   = false
  skip_final_snapshot   = true

  # Substitua por seu Security Group real
  vpc_security_group_ids = ["sg-xxxxxxxx"]

  db_subnet_group_name   = local.db_subnet_name

  tags = {
    Project     = "FastFood"
    Environment = "DEV"
  }
}
