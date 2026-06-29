variable "region" {
  type        = string
  description = "Región AWS principal"
}

variable "project_name" {
  type        = string
  description = "Nombre del proyecto, usado como prefijo en recursos"
}

variable "domain_name" {
  type        = string
  description = "Dominio principal del marketplace"
}

variable "vpc_cidr" {
  type        = string
  description = "Bloque CIDR de la VPC"
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

variable "redis_auth_token" {
  type        = string
  sensitive   = true
  description = "Token de autenticación para Redis (TLS)"
}