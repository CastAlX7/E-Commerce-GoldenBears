resource "aws_ecr_repository" "backend" {
  name                 = "${var.project_name}-backend-${terraform.workspace}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${var.project_name}-backend-ecr-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_ecr_repository" "prometheus" {
  name                 = "${var.project_name}-prometheus-${terraform.workspace}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${var.project_name}-prometheus-ecr-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}