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
# Hardcoded: VPC, SG e Subnets
###########################################################
locals {
  vpc_id       = "vpc-035823898b0432060"           # Sua VPC
  sg_id        = "sg-0b32fbeb948914196"             # Seu Security Group (deve permitir a porta 5432)
  subnet_ids   = ["subnet-0e8a9c57e24921ad2", "subnet-054f5e7046e524dc7"]
  # Seleciona o DB Subnet Group existente ou o criado
  db_subnet_name = length(data.aws_db_subnet_group.existing_db_subnet.id) > 0 ? data.aws_db_subnet_group.existing_db_subnet.id : aws_db_subnet_group.fastfood_db_subnet[0].name
  # Seleciona o Secret existente ou o criado
  secret_id      = length(data.aws_secretsmanager_secret.existing_db_password_secret.id) > 0 ? data.aws_secretsmanager_secret.existing_db_password_secret.id : aws_secretsmanager_secret.db_password_secret[0].id
}

###########################################################
# DB Subnet Group
###########################################################
data "aws_db_subnet_group" "existing_db_subnet" {
  name = "fastfood-db-subnet"
}

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
# Secret para o DB
###########################################################
data "aws_secretsmanager_secret" "existing_db_password_secret" {
  name = "fastfood-db-password"
}

resource "aws_secretsmanager_secret" "db_password_secret" {
  count = length(data.aws_secretsmanager_secret.existing_db_password_secret.id) > 0 ? 0 : 1
  name  = "fastfood-db-password"
}

resource "aws_secretsmanager_secret_version" "db_password_version" {
  secret_id     = local.secret_id
  secret_string = var.db_password
}

###########################################################
# Internet Gateway e IGW efetivo
###########################################################
# Consulta se já existe um IGW na VPC
data "aws_internet_gateway" "existing_igw" {
  filter {
    name   = "attachment.vpc-id"
    values = [local.vpc_id]
  }
}

# Cria um novo IGW se não existir
resource "aws_internet_gateway" "new_igw" {
  count  = length(data.aws_internet_gateway.existing_igw.id) > 0 ? 0 : 1
  vpc_id = local.vpc_id
  tags = {
    Name = "fastfood-new-igw"
  }
}

locals {
  effective_igw_id = length(data.aws_internet_gateway.existing_igw.id) > 0 ? data.aws_internet_gateway.existing_igw.id : aws_internet_gateway.new_igw[0].id
}

###########################################################
# Atualizar a tabela de rotas padrão com uma rota para o IGW
###########################################################
data "aws_route_table" "default" {
  default = true
  vpc_id  = local.vpc_id
}

resource "aws_route" "default_route_to_igw" {
  route_table_id         = data.aws_route_table.default.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = local.effective_igw_id
}

###########################################################
# Instância RDS (PostgreSQL) PUBLICAMENTE ACESSÍVEL
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
  vpc_security_group_ids = [local.sg_id]
  db_subnet_group_name   = local.db_subnet_name
  tags = {
    Project     = "FastFood"
    Environment = "DEV"
  }
  depends_on = [
    aws_internet_gateway.new_igw,
    aws_route.default_route_to_igw
  ]
}

###########################################################
# Output: Endpoint do RDS
###########################################################
output "db_endpoint" {
  description = "Endpoint do RDS (PostgreSQL)"
  value       = aws_db_instance.fastfood_db.endpoint
}
