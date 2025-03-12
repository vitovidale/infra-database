provider "aws" {
  region = "us-east-1"
}

# ✅ Check if the DB Subnet Group Already Exists
data "aws_db_subnet_group" "existing_db_subnet" {
  name = "fastfood-db-subnet"
}

# ✅ Use the Existing Subnet Group If It Exists, Otherwise Create One
resource "aws_db_subnet_group" "fastfood_db_subnet" {
  count       = length(data.aws_db_subnet_group.existing_db_subnet.id) > 0 ? 0 : 1
  name        = "fastfood-db-subnet"
  subnet_ids  = [data.aws_subnet.existing_subnet_1.id, data.aws_subnet.existing_subnet_2.id]
  description = "Managed by Terraform"

  tags = {
    Name = "fastfood-db-subnet-group"
  }
}

# ✅ Check If the Secret Already Exists
data "aws_secretsmanager_secret" "existing_db_password_secret" {
  name = "fastfood-db-password"
}

# ✅ Use Existing Secret If It Exists, Otherwise Create One
resource "aws_secretsmanager_secret" "db_password_secret" {
  count = length(data.aws_secretsmanager_secret.existing_db_password_secret.id) > 0 ? 0 : 1
  name  = "fastfood-db-password"
}

resource "aws_secretsmanager_secret_version" "db_password_version" {
  secret_id     = aws_secretsmanager_secret.db_password_secret[0].id
  secret_string = var.db_password
}

# ✅ Ensure RDS Uses the Existing Subnet Group
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
  db_subnet_group_name   = coalesce(data.aws_db_subnet_group.existing_db_subnet.id, "fastfood-db-subnet")
}
