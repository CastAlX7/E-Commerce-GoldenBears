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

El directorio `ansible/` contiene los playbooks que conectan la app con la infraestructura de `iac/`. Todo corre contra `localhost` (`ansible_connection: local` en los inventarios) — Ansible no se conecta por SSH a nada, ejecuta comandos AWS CLI/Terraform en la misma máquina donde se invoca `ansible-playbook`.

### Estructura

```
ansible/
├── ansible.cfg
├── group_vars/
│   └── all.yml           # project_name, aws_region
├── inventory/
│   ├── dev.yml            # fuente real de variables por entorno (workspace, sizing)
│   ├── qa.yml
│   └── prod.yml
└── playbooks/
    ├── populate_secrets.yml
    ├── deploy.yml
    ├── deploy_ecs.yml
    ├── setup_env.yml
    └── templates/
        ├── env.j2
        └── task-definition.json.j2
```

Todos los paths que apuntan fuera de `ansible/` (`iac/`, `backend/`) usan `{{ playbook_dir }}` como prefijo, así que cada playbook funciona igual sin importar desde qué directorio se invoque `ansible-playbook`.

### Playbooks disponibles

| Playbook | Descripción |
|---|---|
| `populate_secrets.yml` | Pobla AWS Secrets Manager con los valores reales (NubeFact, Redis) |
| `deploy.yml` | Ejecuta `terraform init`, selecciona/crea el workspace y aplica la infraestructura (`iac/`) |
| `deploy_ecs.yml` | Renderiza una nueva task definition con la imagen ya publicada en ECR (`image_tag`), la registra y actualiza el servicio ECS a esa revisión |
| `setup_env.yml` | Obtiene secretos de AWS Secrets Manager y genera el `backend/.env` (desarrollo local) |

`deploy_ecs.yml` es el único playbook que toca la app en ejecución, y no construye nada — asume que la imagen ya está publicada en ECR (la publica el CI/CD). Renderiza `templates/task-definition.json.j2` (family, cpu/memoria, roles IAM —obtenidos con `terraform output`—, y la imagen con el tag recibido), registra esa revisión (`aws ecs register-task-definition`), apunta el servicio a ella (`aws ecs update-service`) y espera con `aws ecs wait services-stable`. El tag inmutable por deploy (en vez de reusar siempre `:latest`) permite rollback real: basta con reapuntar el servicio a la revisión anterior de la misma family.

Para que Ansible pueda registrar esas revisiones sin que el siguiente `terraform apply` las revierta, `iac/ecs.tf` tiene `lifecycle { ignore_changes = [task_definition] }` en `aws_ecs_service.main` — Terraform sigue gestionando el resto del servicio (red, load balancer, tags), pero deja de forzar cuál revisión de la task definition está activa. Los ARNs de los roles IAM que necesita el template se exponen como outputs de Terraform: `ecs_task_execution_role_arn` y `ecs_task_role_arn` (`iac/outputs.tf`).

### Ejecutar un playbook

```bash
cd ansible

# Poblar secretos en AWS Secrets Manager
export REDIS_AUTH_TOKEN="tu_token_secreto"
export NUBEFACT_TOKEN="tu_token_nubefact"
ansible-playbook -i inventory/dev.yml playbooks/populate_secrets.yml

# Despliegue completo de infraestructura con Terraform
export REDIS_AUTH_TOKEN="tu_token_secreto"
ansible-playbook -i inventory/dev.yml playbooks/deploy.yml

# Generar backend/.env desde Secrets Manager (post-despliegue)
ansible-playbook -i inventory/dev.yml playbooks/setup_env.yml

# Desplegar una imagen ya publicada en ECR (build/push lo hace CI/CD)
ansible-playbook -i inventory/dev.yml playbooks/deploy_ecs.yml -e "image_tag=<git-sha-o-tag>"
```

> Reemplaza `inventory/dev.yml` por `inventory/qa.yml` o `inventory/prod.yml` según el entorno objetivo.

### Requisitos para el CI/CD (GitHub Actions)

Para que el pipeline de CI/CD sea compatible con estos playbooks sin duplicar ni pisar responsabilidades:

1. **Build + push de la imagen del backend a ECR** es responsabilidad exclusiva del CI/CD, tageada con el **SHA del commit** (no solo `latest` ni el nombre del workspace) — `deploy_ecs.yml` necesita ese tag como `image_tag` para registrar la nueva revisión.
2. **Build del frontend (`npm run build`) y `aws s3 sync` al bucket** también es responsabilidad del CI/CD — no vive en ningún playbook.
3. **Empaquetado de las Lambdas** (`backend/lambdas/inventario`, `backend/lambdas/comprobantes` → `.zip`) tampoco vive en Ansible — `iac/lambda.tf` lee esos `.zip` como archivos locales al momento de `terraform apply`, así que el CI/CD debe generarlos **antes** de cualquier `terraform apply`, para no partir el despliegue en dos corridas.
4. Después de publicar la imagen, el job de CD debe invocar `ansible-playbook -i inventory/<env>.yml playbooks/deploy_ecs.yml -e "image_tag=<sha>"`.
5. Las credenciales de AWS que use el CI/CD necesitan, como mínimo: push a ECR, `ecs:DescribeTaskDefinition`, `ecs:RegisterTaskDefinition`, `ecs:UpdateService`, `ecs:DescribeServices` (para el `wait services-stable`), y `sts:GetCallerIdentity`.
6. El runner necesita `aws` CLI y Ansible instalados (en `ubuntu-latest` de GitHub Actions, `aws` ya viene preinstalado; Ansible se instala con `pip install ansible`).
7. `deploy_ecs.yml` asume que Terraform ya corrió al menos una vez para ese workspace (la task definition family y los outputs `ecs_task_execution_role_arn`/`ecs_task_role_arn` deben existir). Orden de un primer despliegue: Lambdas empaquetadas → `terraform apply` → primer push de imagen a ECR (con el tag que Terraform puso en `ecs.tf`) → recién ahí `deploy_ecs.yml` tiene sentido para deploys subsecuentes.

### Advertencia sobre código desactualizado

`populate_secrets.yml` crea/actualiza secretos con nombres `golden-bears-nubefact-credentials-{{workspace}}` y `golden-bears-redis-credentials-{{workspace}}`. Los nombres reales en `iac/secrets_manager.tf` son jerárquicos con el project_name actual (p. ej. `e-comerce-golden-bears/{{workspace}}/billing/nubefact`). Este playbook apunta a secretos que no existen — necesita actualizarse antes de usarse.

---

## Análisis de Calidad con SonarCloud

El proyecto integra **SonarCloud** para análisis estático automático de código, infraestructura (`iac/`) y configuración Ansible. El workflow de GitHub Actions se encuentra en el branch `sonarqube`.

Para activarlo en un fork o copia del repositorio:

1. Crear una cuenta en [SonarCloud](https://sonarcloud.io) y vincular el repositorio de GitHub.
2. Configurar los secretos en GitHub Actions:
   - `SONAR_TOKEN` — token generado en SonarCloud.
3. El análisis se ejecuta automáticamente en cada push al branch `sonarqube` y en Pull Requests.
