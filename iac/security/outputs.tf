output "secrets_kms_key_arn" {
  value       = aws_kms_key.secrets_key.arn
  description = "ARN de la llave KMS de seguridad para inyectar en roles IAM"
}

output "app_db_secret_arn" {
  value       = aws_secretsmanager_secret.app_db_credentials.arn
  description = "ARN del secreto de base de datos de la aplicación"
}

output "nubefact_secret_arn" {
  value       = aws_secretsmanager_secret.nubefact_credentials.arn
  description = "ARN del secreto de NubeFact"
}

output "redis_secret_arn" {
  value       = aws_secretsmanager_secret.redis_credentials.arn
  description = "ARN del secreto que almacena el token de Redis"
}