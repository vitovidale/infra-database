###########################################################
# Definir locals que escolhem qual ID usar
###########################################################
locals {
  # Se o data encontrar, length(...) > 0, então vamos usar o ID do data.
  # Caso contrário, usamos o resource criado pelo Terraform.
  db_subnet_name = length(data.aws_db_subnet_group.existing_db_subnet.id) > 0 ?
    data.aws_db_subnet_group.existing_db_subnet.id :
    aws_db_subnet_group.fastfood_db_subnet[0].name

  secret_id = length(data.aws_secretsmanager_secret.existing_db_password_secret.id) > 0 ?
    data.aws_secretsmanager_secret.existing_db_password_secret.id :
    aws_secretsmanager_secret.db_password_secret[0].id
}

###########################################################
# resource "aws_secretsmanager_secret_version" "db_password_version"
###########################################################
resource "aws_secretsmanager_secret_version" "db_password_version" {
  secret_id     = local.secret_id
  secret_string = var.db_password
}

###########################################################
# resource "aws_db_instance" "fastfood_db"
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
  publicly_accessible  = false
  skip_final_snapshot  = true

  vpc_security_group_ids = ["sg-xxxxxx"]
  db_subnet_group_name   = local.db_subnet_name

  tags = {
    Project     = "FastFood"
    Environment = "DEV"
  }
}
