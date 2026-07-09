variable "region" {
  description = "Región de AWS donde se crea el backend remoto"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nombre del proyecto, usado como prefijo de los recursos"
  type        = string
  default     = "e-comerce-golden-bears"
}

variable "github_repository" {
  description = "Repositorio de GitHub (owner/repo) autorizado a asumir el rol de CI vía OIDC"
  type        = string
  default     = "GoldenBears-ECommerce/E-Commerce-GoldenBears"
}
