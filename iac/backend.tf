# Backend remoto: el tfstate se guarda en S3 en vez de en disco local.
# El bucket lo crea bootstrap/ (módulo Terraform aparte, con su propio
# estado local, aplicado una sola vez a mano). Un bloque "backend" no
# admite variables, así que este valor va literal (= output
# tfstate_bucket_name de bootstrap/).
#
# El lock usa el lockfile nativo de S3 (use_lockfile, Terraform >=1.10)
# en vez de una tabla DynamoDB aparte: un solo recurso menos que mantener,
# mismo resultado (un lock por operación, vía un objeto ".tflock" en el
# propio bucket).
#
# Una sola cuenta de AWS compartida por todo el equipo (developers entran
# vía IAM Identity Center, no cada quien con su propia cuenta), así que no
# hace falta -backend-config por desarrollador: el bucket es el mismo
# para todos.
#
# Con workspaces, cada uno (dev/qa/prod) queda en su propia ruta dentro
# del mismo bucket automáticamente (env:/<workspace>/<key>).
terraform {
  backend "s3" {
    bucket       = "e-comerce-golden-bears-tfstate"
    key          = "e-comerce-golden-bears/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}
