resource "aws_db_subnet_group" "aurora" {
  name       = "${var.project_name}-aurora-subnet-group-${terraform.workspace}"
  subnet_ids = [aws_subnet.private_db_a.id, aws_subnet.private_db_b.id]

  tags = {
    Name        = "${var.project_name}-aurora-subnet-group-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_rds_cluster_parameter_group" "aurora_pg" {
  name   = "${var.project_name}-aurora-pg-${terraform.workspace}"
  family = "aurora-postgresql15"

  parameter {
    name  = "log_statement"
    value = "ddl"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }

  tags = {
    Name        = "${var.project_name}-aurora-pg-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_rds_cluster" "aurora" {
  cluster_identifier                  = "${var.project_name}-aurora-cluster-${terraform.workspace}"
  engine                              = "aurora-postgresql"
  engine_mode                         = "provisioned"
  engine_version                      = "15.10"
  database_name                       = "goldenbearsdb"
  master_username                     = "dbadmin"
  manage_master_user_password         = true
  master_user_secret_kms_key_id       = aws_kms_key.secrets.arn
  iam_database_authentication_enabled = true
  storage_encrypted                   = true
  kms_key_id                          = aws_kms_key.database.arn
  db_cluster_parameter_group_name     = aws_rds_cluster_parameter_group.aurora_pg.name
  db_subnet_group_name                = aws_db_subnet_group.aurora.name
  vpc_security_group_ids              = [aws_security_group.aurora.id]
  enabled_cloudwatch_logs_exports     = ["postgresql"]
  copy_tags_to_snapshot               = true
  # deletion_protection=false en dev/qa para facilitar terraform destroy; en prod debe ser true
  deletion_protection       = var.aurora_deletion_protection
  skip_final_snapshot       = true
  final_snapshot_identifier = "${var.project_name}-aurora-final-snapshot-${terraform.workspace}"

  serverlessv2_scaling_configuration {
    min_capacity = var.aurora_min_capacity
    max_capacity = var.aurora_max_capacity
  }

  tags = {
    Name        = "${var.project_name}-aurora-cluster-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_rds_cluster_instance" "aurora_instances" {
  count                           = var.aurora_instance_count
  identifier                      = "${var.project_name}-aurora-node-${count.index}-${terraform.workspace}"
  cluster_identifier              = aws_rds_cluster.aurora.id
  instance_class                  = "db.serverless"
  engine                          = aws_rds_cluster.aurora.engine
  engine_version                  = aws_rds_cluster.aurora.engine_version
  monitoring_interval             = 60
  monitoring_role_arn             = aws_iam_role.rds_enhanced_monitoring.arn
  performance_insights_enabled    = true
  performance_insights_kms_key_id = aws_kms_key.database.arn
  auto_minor_version_upgrade      = true

  tags = {
    Name        = "${var.project_name}-aurora-node-${count.index}-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}
