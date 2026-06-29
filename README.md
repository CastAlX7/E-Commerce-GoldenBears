# Marketplace Golden Bears

Marketplace Golden Bears es una plataforma de comercio electrónico que opera bajo el modelo de marketplace con fulfillment centralizado, permitiendo a los usuarios explorar y adquirir productos de múltiples marcas aliadas en un solo entorno digital. El sistema atiende tanto a usuarios no autenticados como a clientes registrados, con alcance a nivel nacional incluyendo provincias.

Actualmente se encuentra en una etapa inicial de crecimiento, gestionando entre 5,000 y 7,000 visitas mensuales con picos de actividad entre las 16:00 y 20:00 horas. Frente a limitaciones de escalabilidad en la infraestructura tradicional, se propone la migración a una solución en la nube diseñada para garantizar alta disponibilidad, resiliencia y capacidad de respuesta ante eventos de alta concurrencia como campañas tipo Black Friday.

## Descripcion General

La plataforma permite a usuarios registrados y no registrados explorar productos de múltiples marcas aliadas. Entre sus capacidades principales:

- Navegación de catálogo sin autenticación
- Registro, autenticación y gestión de cuenta de cliente
- Carrito de compras y proceso de checkout con múltiples métodos de pago
- Gestión de órdenes y comprobantes
- Panel de administración para gestión de productos, marcas, categorías y usuarios

## Arquitectura

![Diagrama de Infraestructura](diagrams/Diagrama-15-06-26.jpeg)

La plataforma implementa una arquitectura de monolito modular desplegada en AWS, diseñada para soportar picos de tráfico de hasta 10,000 visitas durante campañas de alta demanda.

### Componentes por Capa

**Distribución y Seguridad**
- Route 53 para resolución DNS
- CloudFront como CDN y punto de entrada
- WAF para protección contra ataques y rate limiting
- S3 para hosting del frontend estático

**API y Balanceo**
- API Gateway con VPC Link V2
- Application Load Balancer (ALB)

**Cómputo**
- ECS Fargate con Auto Scaling (Monolito Modular) en dos zonas de disponibilidad
- Lambda para procesamiento de comprobantes y validaciones

**Base de Datos**
- Aurora PostgreSQL Principal + Standby (Multi-AZ)
- Amazon RDS Proxy
- ElastiCache Redis para caché

**Mensajería**
- SNS + SQS + Dead Letter Queue para procesamiento asíncrono de órdenes y comprobantes

**Seguridad y Configuración**
- Secrets Manager para gestión de credenciales
- IAM para control de acceso

## Tecnologías de Infraestructura y DevOps

| Herramienta | Propósito |
|---|---|
| **Terraform** `>= 1.0.11` | Provisión de infraestructura AWS como código (IaC) |
| **Ansible** | Automatización de pipelines: build, push a ECR, despliegue y gestión de secretos |
| **SonarCloud** | Análisis estático de calidad y seguridad del código (branch `sonarqube`) |
| **Docker** | Contenedores del backend, frontend y empaquetado de Lambdas |
| **AWS CLI** | Autenticación y operaciones contra AWS desde local |

---

## Requisitos Previos

### Ejecución local

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) instalado y corriendo
- [Git](https://git-scm.com/)

### Despliegue en AWS (infraestructura)

- [Terraform](https://developer.hashicorp.com/terraform/install) `>= 1.0.11`
- [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) configurado con credenciales (`aws configure`)
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/index.html) con la colección `community.aws`:
  ```bash
  ansible-galaxy collection install community.aws community.general
  ```
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (para build y push de imágenes a ECR)

---

## Levantar el proyecto localmente

### 1. Clonar el repositorio

```bash
git clone https://github.com/CastAlX7/E-Commerce-GoldenBears.git
cd E-Commerce-GoldenBears
git checkout develop
```

### 2. Configurar variables de entorno
**Windows:**

```bash
copy backend\.env.example backend\.env
```

**Mac/Linux:**

```bash
cp backend/.env.example backend/.env
```

### 3. Levantar los contenedores

```bash
docker compose up --build -d
```
> La primera vez tarda ~2-3 minutos descargando imágenes y construyendo los contenedores.

### 4. Cargar datos de prueba

```bash
docker compose exec backend python seed.py
```

### 5. Abrir en el navegador

http://localhost

| Acción | Comando |
|---|---|
| Detener contenedores | `docker compose down` |
| Reset completo (borra todos los datos) | `docker compose down -v` |

---

## Despliegue en AWS con Terraform

La infraestructura se define en el directorio `iac/` y se gestiona mediante **Terraform Workspaces** para separar los entornos `dev`, `qa` y `prod`. Cada entorno tiene su propio archivo de variables (`dev.tfvars`, `qa.tfvars`, `prod.tfvars`).

### Entornos disponibles

| Workspace | Archivo de variables | Uso |
|---|---|---|
| `dev` | `iac/dev.tfvars` | Desarrollo y pruebas rápidas — recursos mínimos |
| `qa` | `iac/qa.tfvars` | Integración y QA — recursos intermedios |
| `prod` | `iac/prod.tfvars` | Producción — alta disponibilidad, Multi-AZ |

### 1. Posicionarse en el directorio de infraestructura

```bash
cd iac
```

### 2. Inicializar Terraform

Descarga los providers y módulos necesarios:

```bash
terraform init
```

### 3. Gestionar Workspaces

```bash
# Ver todos los workspaces existentes
terraform workspace list

# Crear un workspace nuevo (primera vez)
terraform workspace new dev
terraform workspace new qa
terraform workspace new prod

# Seleccionar el workspace activo
terraform workspace select dev
# o
terraform workspace select qa
# o
terraform workspace select prod

# Ver el workspace activo en cualquier momento
terraform workspace show
```

### 4. Validar la configuración

```bash
terraform validate
```

### 5. Planificar el despliegue

Revisa qué recursos se crearán, modificarán o destruirán sin aplicar cambios:

```bash
# Para dev
terraform plan -var-file="dev.tfvars"

# Para qa
terraform plan -var-file="qa.tfvars"

# Para prod (redis_auth_token se inyecta por variable de entorno)
export TF_VAR_redis_auth_token="tu_token_secreto"
terraform plan -var-file="prod.tfvars"
```

### 6. Aplicar la infraestructura

```bash
# Para dev (el token está en el propio dev.tfvars)
terraform apply -var-file="dev.tfvars"

# Para qa
export TF_VAR_redis_auth_token="tu_token_secreto"
terraform apply -var-file="qa.tfvars"

# Para prod
export TF_VAR_redis_auth_token="tu_token_secreto"
terraform apply -var-file="prod.tfvars"
```

> Terraform pedirá confirmación. Escribe `yes` para proceder. Usa `-auto-approve` solo en pipelines CI/CD.

### 7. Ver outputs tras el despliegue

```bash
terraform output
```

Outputs disponibles:

| Output | Descripción |
|---|---|
| `api_gateway_endpoint` | URL del API Gateway HTTP |
| `cloudfront_domain_name` | Dominio de la distribución CloudFront |
| `alb_dns_name` | DNS del Application Load Balancer interno |
| `rds_proxy_endpoint` | Endpoint del RDS Proxy para Aurora |
| `redis_primary_endpoint` | Endpoint primario de ElastiCache Redis |
| `vpc_id` | ID de la VPC principal |
| `route53_zone_id` | ID de la zona hosted en Route53 |

---

## Destruir la infraestructura

> **Advertencia:** Este comando elimina **todos** los recursos del workspace activo en AWS. En `prod`, Aurora tiene `deletion_protection = true` — desactivarlo primero en `prod.tfvars` antes de destruir.

```bash
# Asegurarse de estar en el workspace correcto
terraform workspace show

# Para dev / qa
terraform destroy -var-file="dev.tfvars"
# o
terraform destroy -var-file="qa.tfvars"

# Para prod (desactivar deletion_protection antes)
export TF_VAR_redis_auth_token="tu_token_secreto"
terraform destroy -var-file="prod.tfvars"
```

Terraform listará todos los recursos a eliminar y pedirá confirmación con `yes`.

---

## Automatización con Ansible

El directorio `ansible/` contiene playbooks que automatizan el ciclo completo de despliegue. Los inventarios en `ansible/inventory/` definen las variables por entorno (`dev.yml`, `qa.yml`, `prod.yml`).

### Playbooks disponibles

| Playbook | Descripción |
|---|---|
| `setup_env.yml` | Obtiene secretos de AWS Secrets Manager y genera el `backend/.env` |
| `generate_tfvars.yml` | Genera el archivo `.tfvars` para Terraform desde plantillas |
| `populate_secrets.yml` | Pobla AWS Secrets Manager con los valores reales (NubeFact, Redis) |
| `build_and_push.yml` | Construye imágenes Docker, las sube a ECR y empaqueta las Lambdas |
| `deploy.yml` | Ejecuta `terraform init`, selecciona/crea el workspace y aplica la infraestructura |

### Ejecutar un playbook

```bash
cd ansible

# Generar variables de Terraform para el entorno dev
ansible-playbook -i inventory/dev.yml playbooks/generate_tfvars.yml

# Poblar secretos en AWS Secrets Manager
export REDIS_AUTH_TOKEN="tu_token_secreto"
export NUBEFACT_TOKEN="tu_token_nubefact"
ansible-playbook -i inventory/dev.yml playbooks/populate_secrets.yml

# Build y push de imágenes a ECR + empaquetar Lambdas
ansible-playbook -i inventory/dev.yml playbooks/build_and_push.yml

# Despliegue completo de infraestructura con Terraform
export REDIS_AUTH_TOKEN="tu_token_secreto"
ansible-playbook -i inventory/dev.yml playbooks/deploy.yml

# Generar backend/.env desde Secrets Manager (post-despliegue)
ansible-playbook -i inventory/dev.yml playbooks/setup_env.yml
```

> Reemplaza `inventory/dev.yml` por `inventory/qa.yml` o `inventory/prod.yml` según el entorno objetivo.

---

## Análisis de Calidad con SonarCloud

El proyecto integra **SonarCloud** para análisis estático automático de código, infraestructura (`iac/`) y configuración Ansible. El workflow de GitHub Actions se encuentra en el branch `sonarqube`.

Para activarlo en un fork o copia del repositorio:

1. Crear una cuenta en [SonarCloud](https://sonarcloud.io) y vincular el repositorio de GitHub.
2. Configurar los secretos en GitHub Actions:
   - `SONAR_TOKEN` — token generado en SonarCloud.
3. El análisis se ejecuta automáticamente en cada push al branch `sonarqube` y en Pull Requests.
