variable "project_name" {
  type        = string
  description = "Nombre del proyecto, usado para el etiquetado y nombres de los recursos"
}

variable "environment" {
  type        = string
  description = "Entorno de despliegue (dev, stg, prod)"
}

variable "private_db_subnet_ids" {
  type        = list(string)
  description = "Lista de IDs de las subredes aisladas destinadas para el clúster de Aurora"
}

variable "private_app_subnet_ids" {
  type        = list(string)
  description = "Lista de IDs de las subredes privadas de aplicación (Para ElastiCache)"
}

variable "aurora_sg_id" {
  type        = string
  description = "ID del Security Group exclusivo para la base de datos Aurora"
}

variable "rds_proxy_sg_id" {
  type        = string
  description = "ID del Security Group para el proxy de la base de datos"
}

variable "elasticache_sg_id" {
  type        = string
  description = "ID del Security Group para el clúster de Redis"
}