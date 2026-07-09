terraform {
  # >=1.10 porque iac/backend.tf usa use_lockfile (lockfile nativo de S3).
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# CRÍTICO: WAFv2 SCOPE=CLOUDFRONT Y ACM PARA CLOUDFRONT REQUIEREN OBLIGATORIAMENTE us-east-1
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

# Proveedor secundario para las réplicas s3
provider "aws" {
  alias  = "replica"
  region = "us-west-2" # Región de contingencia
}

data "aws_caller_identity" "current" {}
data "aws_elb_service_account" "main" {}
