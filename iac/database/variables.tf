variable "project_name" {
  type        = string
  description = "Nombre del proyecto, usado para el etiquetado y nombres de los recursos"
}

variable "environment" {
  type        = string
  description = "Entorno de despliegue (dev, stg, prod)"
}