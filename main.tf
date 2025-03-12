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

locals {
  # Hardcode dos IDs da VPC, Security Group e Subnets
  vpc_id     = "vpc-035823898b0432060"
  sg_id      = "sg-0b32fbeb948914196"
  subnet_ids = ["subnet-0e8a9c57e24921ad2", "subnet-054f5e7046e524dc7"]

  # Se já existir um DB Subnet Group chamado "fastfood-db-subnet", usa-o; caso contrário, usa o recurso criado
  db_subnet_name = length(data.aws_db_subnet_group.existing_db_subnet.id) > 0 ? data.aws_db_subnet_group.existing_db_subnet.id : aws_db_subnet_group.fastfood_db_subnet[0].name

  # Se já existir o Secret "fastfood-db-password", usa-o; caso contrário, usa o recurso criado
  secret_id = length(data.aws_secretsmanager_secret.existing_db_password_secret.id) > 0 ? data.aws_secretsmanager_secret.existing_db_password_secret.id : aws_secretsmanager_secret.db_password_secret[0].id
}

# Verifica se já existe um DB Subnet Group chamado "fastfood-db-subnet"
data "aws_db_subnet_group" "existing_db_subnet" {
  name = "fastfood-db-subnet"
}

# Cria o DB Subnet Group se não existir
resource "aws_db_subnet_group" "fastfood_db_subnet" {
  count       = length(data.aws_db_subnet_group.existing_db_subnet.id) > 0 ? 0 : 1
  name        = "fastfood-db-subnet"
  subnet_ids  = local.subnet_ids
  description = "Managed by Terraform"
  tags = {
    Name = "fastfood-db-subnet-group"
  }
}

# Verifica se já existe o Secret "fastfood-db-password"
data "aws_secretsmanager_secret" "existing_db_password_secret" {
  name = "fastfood-db-password"
}

# Cria o Secret se não existir
resource "aws_secretsmanager_secret" "db_password_secret" {
  count = length(data.aws_secretsmanager_secret.existing_db_password_secret.id) > 0 ? 0 : 1
  name  = "fastfood-db-password"
}

# Cria a versão do Secret (guarda o db_password)
resource "aws_secretsmanager_secret_version" "db_password_version" {
  secret_id     = local.secret_id
  secret_string = var.db_password
}

###########################################################
# Cria um novo Internet Gateway para a VPC (IGW)
###########################################################
resource "aws_internet_gateway" "new_igw" {
  vpc_id = local.vpc_id
  tags = {
    Name = "fastfood-new-igw"
  }
}

###########################################################
# Cria uma Tabela de Rotas Pública
###########################################################
resource "aws_route_table" "public_rt" {
  vpc_id = local.vpc_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.new_igw.id
  }
  tags = {
    Name = "fastfood-public-rt"
  }
}

###########################################################
# Associa a Tabela de Rotas Pública a cada Subnet
###########################################################
resource "aws_route_table_association" "public_subnet_association" {
  count          = length(local.subnet_ids)
  subnet_id      = local.subnet_ids[count.index]
  route_table_id = aws_route_table.public_rt.id
}

###########################################################
# Cria a Instância RDS (PostgreSQL) PUBLICAMENTE ACESSÍVEL
###########################################################
resource "aws_db_instance" "fastfood_db" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "postgres"
  engine_version       = "16"
  instance_class       = "db.t3.micro"
  identifier           = "fastfood-db"
  db_name              = var.db_name
  username             = var.db_username
  password             = var.db_password
  publicly_accessible  = true
  skip_final_snapshot  = true
  vpc_security_group_ids = [ local.sg_id ]
  db_subnet_group_name   = local.db_subnet_name
  tags = {
    Project     = "FastFood"
    Environment = "DEV"
  }
}

###########################################################
# Output: Endpoint do RDS
###########################################################
output "db_endpoint" {
  description = "Endpoint do RDS (PostgreSQL)"
  value       = aws_db_instance.fastfood_db.endpoint
}
