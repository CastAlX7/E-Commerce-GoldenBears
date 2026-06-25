variable "project_name" {
  type        = string
  description = "Nombre del proyecto"
}

variable "environment" {
  type        = string
  description = "Entorno de despliegue (dev, stg, prod)"
}

variable "region" {
  type        = string
  description = "Región de AWS donde se desplegarán los recursos"
  default     = "us-east-1"
}

variable "private_lambda_subnet_id" {
  type        = string
  description = "ID de la subred privada aislada donde vive la Lambda de Inventario"
}

variable "lambda_inv_sg_id" {
  type        = string
  description = "ID del Security Group asignado a la Lambda de Inventario"
}

variable "rds_proxy_resource_id" {
  type        = string
  description = "Resource ID del RDS Proxy, necesario para construir el ARN de IAM auth"
}

variable "nubefact_secret_arn" {
  type        = string
  sensitive   = true
  description = "ARN del secreto de NubeFact en Secrets Manager, proveniente del módulo security"
}

variable "logs_kms_key_arn" {
  type        = string
  description = "ARN de la llave KMS CMK para cifrado de CloudWatch Log Groups"
}

variable "vpc_id" {
  type        = string
  description = "ID de la VPC donde opera la Lambda de inventario"
}
