variable "region" {
  type        = string
  description = "Región de AWS donde se desplegarán los recursos"
  default     = "us-east-1"
}

variable "project_name" {
  type        = string
  description = "Golden-bears / marketplace"
  default     = "marketplace"
}

variable "environment" {
  type        = string
  description = "Entorno de despliegue (dev, stg, prod)"
  default     = "dev"
}

variable "vpc_cidr" {
  type        = string
  description = "Bloque CIDR principal para la VPC"
  default     = "10.0.0.0/16"
}

variable "redis_auth_token" {
  type        = string
  sensitive   = true
  description = "Token de autenticación para el clúster de Redis"
}

variable "domain_name" {
  type        = string
  description = "Dominio principal del proyecto"
  default     = "goldenbears.com"
}

variable "log_bucket_name" {
  type        = string
  description = "Nombre del bucket destinado a guardar logs de acceso"
}

variable "event_queue_arn" {
  type        = string
  description = "ARN de la cola SQS para recibir notificaciones de eventos"
}

variable "replication_role_arn" {
  type        = string
  description = "ARN del rol IAM con permisos para la replicación entre regiones"
}

variable "replica_bucket_arn" {
  type        = string
  description = "ARN del bucket de destino en la región secundaria"
}

variable "acm_certificate_arn" {
  type        = string
  description = "ARN del certificado SSL en AWS Certificate Manager para CloudFront"
}