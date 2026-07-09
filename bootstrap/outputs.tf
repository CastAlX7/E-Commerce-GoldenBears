output "tfstate_bucket_name" {
  description = "Bucket S3 a usar en el backend de iac/backend.tf"
  value       = aws_s3_bucket.tfstate.id
}

output "account_id" {
  description = "ID de la cuenta de AWS donde se creó el backend remoto"
  value       = data.aws_caller_identity.current.account_id
}

output "ci_role_arn" {
  description = "ARN del IAM Role que asume GitHub Actions vía OIDC (usar como vars.AWS_ROLE_ARN, no es secreto)"
  value       = aws_iam_role.ci.arn
}

output "github_oidc_provider_arn" {
  description = "ARN del OIDC provider de GitHub Actions registrado en esta cuenta"
  value       = aws_iam_openid_connect_provider.github_actions.arn
}
