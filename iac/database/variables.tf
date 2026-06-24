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