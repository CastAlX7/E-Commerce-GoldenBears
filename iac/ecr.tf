resource "aws_ecr_repository" "backend" {
  name                 = "${var.project_name}-backend-${terraform.workspace}"
  image_tag_mutability = "IMMUTABLE"

  encryption_configuration {
    encryption_type = "KMS"
  }

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
  image_tag_mutability = "IMMUTABLE"

  encryption_configuration {
    encryption_type = "KMS"
  }

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

# Imagen propia (grafana/grafana + provisioning/ ya horneado) en vez de la
# imagen pública directo — así el datasource de CloudWatch/Prometheus queda
# provisionado automáticamente al arrancar el contenedor.
resource "aws_ecr_repository" "grafana" {
  name                 = "${var.project_name}-grafana-${terraform.workspace}"
  image_tag_mutability = "IMMUTABLE"

  encryption_configuration {
    encryption_type = "KMS"
  }

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${var.project_name}-grafana-ecr-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}