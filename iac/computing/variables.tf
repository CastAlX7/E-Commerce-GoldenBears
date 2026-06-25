variable "project_name" {
  type        = string
  description = "Nombre del proyecto"
}

variable "environment" {
  type        = string
  description = "Entorno de despliegue"
}

variable "vpc_id" {
  type        = string
  description = "ID de la VPC"
}

variable "private_subnets" {
  type        = list(string)
  description = "Lista de IDs de subredes privadas"
}

variable "ecs_sg_id" {
  type        = string
  description = "ID del Security Group para ECS"
}

variable "alb_sg_id" {
  type        = string
  description = "ID del Security Group para ALB"
}

variable "vpc_link_sg_id" {
  type        = string
  description = "ID del Security Group para VPC Link"
}

variable "app_db_secret_arn" {
  type        = string
  description = "ARN del secreto de credenciales de base de datos"
}

variable "secrets_kms_key_arn" {
  type        = string
  description = "ARN de la llave KMS para descifrar secretos"
}

variable "alb_logs_bucket" {
  type        = string
  description = "Nombre del bucket S3 para access logs del ALB"
}
