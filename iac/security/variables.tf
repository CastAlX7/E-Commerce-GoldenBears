variable "project_name" {
  type        = string
  description = "Nombre del proyecto (golden-bears)"
}

variable "redis_auth_token" {
  type        = string
  sensitive   = true
  description = "Token de autenticación sensible para Redis recuperado del módulo de base de datos"
}