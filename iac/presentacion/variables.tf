variable "bucket_name" {
  type        = string
  description = "Nombre del bucket S3 para el frontend"
}

variable "domain_name" {
  type        = string
  description = "Dominio principal del proyecto"
}

variable "log_bucket_name" {
  type        = string
  description = "Nombre del bucket destinado a guardar logs de acceso"
}

variable "event_queue_arn" {
  type        = string
  description = "ARN de la cola SQS para recibir notificaciones de eventos"
}