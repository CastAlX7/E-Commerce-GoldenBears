resource "aws_db_subnet_group" "aurora" {
  name       = "${var.project_name}-aurora-subnet-group"
  subnet_ids = var.private_db_subnet_ids
  tags       = { Name = "${var.project_name}-aurora-subnet-group" }
}

resource "aws_rds_cluster" "aurora" {
  cluster_identifier = "${var.project_name}-aurora-cluster"
  engine             = "aurora-postgresql"
  engine_mode        = "provisioned"
  engine_version     = "15.4"
  database_name      = "goldenbearsdb"
  master_username    = "dbadmin"
  manage_master_user_password = true
  storage_encrypted = true
  db_subnet_group_name   = aws_db_subnet_group.aurora.name
  vpc_security_group_ids = [var.aurora_sg_id]
  enabled_cloudwatch_logs_exports = ["postgresql"]
  deletion_protection       = false  #En una situación real tendría q ser true, pero como tenemos que hacer varios destroy, es preferible dejarlo así
  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.project_name}-aurora-final-snapshot"

  # Configuración Serverless v2
  serverlessv2_scaling_configuration {
    min_capacity = 1.0
    max_capacity = 4.0
  }
}