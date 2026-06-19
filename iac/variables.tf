variable "private_lambda_subnet_id" {
  description = "Subnet ID de Private Lambda Subnet (10.0.40.0/24) — output del módulo de networking"
  type        = string
  default     = ""
}

variable "lambda_inv_sg_id" {
  description = "Security Group ID de LambdaInv-SG — output del módulo de networking"
  type        = string
  default     = ""
}

variable "rds_proxy_resource_id" {
  description = "Resource ID del RDS Proxy (formato prx-XXXXXXXXXXXXXXXXX) — output del módulo de base de datos"
  type        = string
  default     = ""
}
