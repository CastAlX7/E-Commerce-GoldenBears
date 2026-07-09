terraform {
  # Alineado con iac/ (que sí necesita >=1.10 por use_lockfile) para que
  # todo el equipo use el mismo binario de Terraform en ambos módulos.
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Backend intencionalmente local: este módulo crea el bucket S3 y la tabla
  # DynamoDB que usará el backend remoto del módulo raíz (iac/), por lo que no
  # puede depender de sí mismo. Se aplica una única vez, a mano.
}

provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}
