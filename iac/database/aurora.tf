resource "aws_db_subnet_group" "aurora" {
  name       = "${var.project_name}-aurora-subnet-group"
  subnet_ids = var.private_db_subnet_ids
  tags       = { Name = "${var.project_name}-aurora-subnet-group" }
}