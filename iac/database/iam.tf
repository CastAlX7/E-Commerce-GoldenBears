resource "aws_iam_role" "rds_proxy_role" {
  name        = "${var.project_name}-${var.environment}-rds-proxy-role"
  description = "Rol asumido por el RDS Proxy para leer el secreto de Aurora"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "rds.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# La política lee dinámicamente el ARN del secreto que Aurora generará.
# Nota: No requiere kms:Decrypt porque usamos la llave administrada de AWS.
resource "aws_iam_policy" "rds_proxy_policy" {
  name        = "${var.project_name}-${var.environment}-rds-proxy-policy"
  description = "Permite al RDS Proxy acceder a la credencial autogenerada de Aurora"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ReadDBCredentials"
        Effect   = "Allow"
        Action   = "secretsmanager:GetSecretValue"
        Resource = aws_rds_cluster.aurora.master_user_secret[0].secret_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_proxy_attach" {
  role       = aws_iam_role.rds_proxy_role.name
  policy_arn = aws_iam_policy.rds_proxy_policy.arn
}