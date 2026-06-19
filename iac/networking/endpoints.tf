# Interface VPC Endpoints (Acceso privado a servicios AWS sin pasar por Internet)
# 1. Endpoint para SQS (Colas de Mensajería)
resource "aws_vpc_endpoint" "sqs" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.sqs"
  vpc_endpoint_type = "Interface"

  subnet_ids = [
    aws_subnet.private_app_a.id,
    aws_subnet.private_app_b.id
  ]

  security_group_ids = [
    aws_security_group.vpc_endpoints.id
  ]

  private_dns_enabled = true
  tags                = { Name = "${var.project_name}-vpce-sqs" }
}

# 2. Endpoint para SNS (Notificaciones y Eventos)
resource "aws_vpc_endpoint" "sns" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.sns"
  vpc_endpoint_type = "Interface"

  subnet_ids = [
    aws_subnet.private_app_a.id,
    aws_subnet.private_app_b.id
  ]

  security_group_ids = [
    aws_security_group.vpc_endpoints.id
  ]

  private_dns_enabled = true
  tags                = { Name = "${var.project_name}-vpce-sns" }
}

# 3. Endpoint para Secrets Manager (Lectura de credenciales de Base de Datos)
resource "aws_vpc_endpoint" "secrets" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type = "Interface"

  subnet_ids = [
    aws_subnet.private_app_a.id,
    aws_subnet.private_app_b.id
  ]

  security_group_ids = [
    aws_security_group.vpc_endpoints.id
  ]

  private_dns_enabled = true
  tags                = { Name = "${var.project_name}-vpce-secrets" }
}