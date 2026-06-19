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

