variable "project_name" {
  type        = string
  description = "Nombre del proyecto"
}

variable "environment" {
  type        = string
  description = "Entorno de despliegue (dev, stg, prod)"
}

variable "vpc_cidr" {
  type        = string
  description = "Bloque CIDR principal para la VPC"
  default     = "10.0.0.0/16"
}

variable "region" {
  type        = string
  description = "Región de AWS"
}

variable "aws_region" {
  type        = string
  description = "Región de AWS (alias para region)"
}