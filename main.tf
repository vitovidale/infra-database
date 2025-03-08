provider "aws" {
  region = "us-east-1"
}

resource "aws_db_instance" "fastfood-db" {
  allocated_storage    = 20
  engine                = "postgres"
  engine_version        = "16"
  instance_class        = "db.t3.micro"
  username              = "postgres"
  password              = "SuaSenhaSegura123"
  skip_final_snapshot   = true
}
