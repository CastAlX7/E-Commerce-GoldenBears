variable "region" {
  type        = string
  description = "Región AWS principal"
  default     = "us-east-1"
}

variable "project_name" {
  type        = string
  description = "Nombre del proyecto, usado como prefijo en recursos"
  default     = "golden-bears"
}

variable "domain_name" {
  type        = string
  description = "Dominio principal del marketplace"
  default     = "goldenbears.com"
}

variable "vpc_cidr" {
  type        = string
  description = "Bloque CIDR de la VPC"
  default     = "10.0.0.0/16"
}

# --- Variables por entorno (sin default, se inyectan por .tfvars) ---

variable "aurora_min_capacity" {
  type        = number
  description = "Capacidad mínima de Aurora Serverless v2 (ACU)"
}

variable "aurora_max_capacity" {
  type        = number
  description = "Capacidad máxima de Aurora Serverless v2 (ACU)"
}

variable "aurora_instance_count" {
  type        = number
  description = "Número de instancias en el clúster Aurora"
}

variable "aurora_deletion_protection" {
  type        = bool
  description = "Protección contra borrado del clúster Aurora"
}

variable "redis_node_type" {
  type        = string
  description = "Tipo de nodo de ElastiCache Redis"
}

variable "redis_num_cache_clusters" {
  type        = number
  description = "Número de nodos en el grupo de replicación de Redis"
}

variable "redis_multi_az_enabled" {
  type        = bool
  description = "Habilitar Multi-AZ en Redis"
}

variable "redis_automatic_failover_enabled" {
  type        = bool
  description = "Habilitar failover automático en Redis"
}

variable "ecs_desired_count" {
  type        = number
  description = "Número deseado de tareas ECS"
}

variable "ecs_cpu" {
  type        = number
  description = "CPU asignada a la tarea ECS (unidades)"
}

variable "ecs_memory" {
  type        = number
  description = "Memoria asignada a la tarea ECS (MiB)"
}

variable "log_retention_days" {
  type        = number
  description = "Días de retención en CloudWatch Logs"
}

# --- Sensibles: inyectar vía -var o TF_VAR_ ---

variable "redis_auth_token" {
  type        = string
  sensitive   = true
  description = "Token de autenticación para Redis (TLS)"
}

# --- Recursos externos pre-existentes en AWS (no gestionados por este código) ---

variable "log_bucket_name" {
  type        = string
  description = "Bucket S3 externo para logs de acceso (pre-existente)"
}

variable "event_queue_arn" {
  type        = string
  description = "ARN de cola SQS externa para notificaciones S3 (pre-existente)"
}

variable "replica_bucket_arn" {
  type        = string
  description = "ARN del bucket S3 réplica en región secundaria (pre-existente)"
}

variable "replication_role_arn" {
  type        = string
  description = "ARN del rol IAM de replicación S3 cross-region (pre-existente)"
}

variable "acm_certificate_arn" {
  type        = string
  description = "ARN del certificado ACM en us-east-1 para CloudFront (pre-existente)"
}

variable "route53_query_log_group_arn" {
  type        = string
  description = "ARN del log group de CloudWatch en us-east-1 para Route53 query logs"
}

# variables.tf
variable "alb_deletion_protection" {
  description = "Enable deletion protection for the ALB"
  type        = bool
  default     = false
}

variable "documental_replica_bucket_arn" {
  type        = string
  description = "ARN del bucket S3 réplica del documental en región secundaria (pre-existente)"
}

variable "documental_replication_role_arn" {
  type        = string
  description = "ARN del rol IAM de replicación S3 cross-region para documental (pre-existente)"
}