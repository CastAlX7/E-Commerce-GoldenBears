# Golden Bears E-Commerce

Plataforma de e-commerce full-stack con panel de administración.

## Tecnologías

**Backend**
- Python + FastAPI
- SQLAlchemy (async) + PostgreSQL
- Alembic (migraciones)
- JWT (autenticación)

**Frontend**
- React 18 + Vite
- React Router v6
- Axios

---

## Requisitos previos

- Python 3.11+
- Node.js 18+
- PostgreSQL corriendo en `localhost:5432`

---

## Instalación

### 1. Clonar el repositorio y entrar a la carpeta

```bash
cd golden-bears
```

### 2. Crear la base de datos en PostgreSQL

```sql
CREATE DATABASE golden_bears;
```

### 3. Crear el entorno virtual e instalar dependencias del backend

```bash
python -m venv venv
venv\Scripts\activate
python -m pip install -r backend\requirements.txt
```

### 4. Configurar variables de entorno

Copiar el archivo de ejemplo y editar con tus credenciales:

```bash
copy backend\.env.example backend\.env
```

Contenido del `.env`:

```
DATABASE_URL=postgresql+asyncpg://postgres:1234@localhost:5432/golden_bears
SECRET_KEY=BRE@ososdelmileniodorado123
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60
REFRESH_TOKEN_EXPIRE_DAYS=7
```

### 5. Instalar dependencias del frontend

```bash
cd frontend
npm install
cd ..
```

---

## Ejecución

Abrir **dos terminales** desde la raíz del proyecto:

**Terminal 1 — Backend:**

```bash
venv\Scripts\activate
cd backend
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

**Terminal 2 — Frontend:**

```bash
cd frontend
npm run dev
```

### Cargar datos de prueba (opcional)

Con el backend ya corriendo, en una tercera terminal:

```bash
venv\Scripts\activate
cd backend
python seed.py
```

Esto crea un usuario administrador y productos de ejemplo:
- **Admin:** `admin@goldenbears.com` / `Admin1234!`

---

## URLs

| Servicio | URL |
|---|---|
| Frontend | http://localhost:5173 |
| API | http://localhost:8000 |
| Documentación Swagger | http://localhost:8000/docs |

---

## Estructura del proyecto

```
golden-bears/
├── backend/
│   ├── app/
│   │   ├── models/        # Modelos SQLAlchemy
│   │   ├── routers/       # Endpoints FastAPI
│   │   ├── schemas/       # Schemas Pydantic
│   │   ├── services/      # Lógica de negocio
│   │   ├── config.py      # Variables de entorno
│   │   ├── database.py    # Conexión a la base de datos
│   │   ├── dependencies.py# Autenticación y permisos
│   │   └── main.py        # Entrada de la aplicación
│   ├── alembic/           # Migraciones
│   ├── requirements.txt
│   └── seed.py
├── frontend/
│   ├── src/
│   │   ├── api/           # Cliente HTTP (axios)
│   │   ├── components/    # Componentes reutilizables
│   │   ├── contexts/      # Auth y Cart context
│   │   └── pages/         # Páginas de la app
│   └── package.json
├── venv/                  # Entorno virtual Python
├── .gitignore
└── README.md
```

---

## Endpoints principales

### Autenticación
| Método | Ruta | Descripción |
|---|---|---|
| POST | `/api/auth/register` | Registrar usuario |
| POST | `/api/auth/login` | Iniciar sesión |
| POST | `/api/auth/refresh` | Renovar token |

### Productos
| Método | Ruta | Descripción |
|---|---|---|
| GET | `/api/products` | Listar productos |
| GET | `/api/products/{id}` | Detalle de producto |
| POST | `/api/products` | Crear producto (admin) |
| PUT | `/api/products/{id}` | Editar producto (admin) |
| DELETE | `/api/products/{id}` | Eliminar producto (admin) |

### Carrito
| Método | Ruta | Descripción |
|---|---|---|
| GET | `/api/cart` | Ver carrito |
| POST | `/api/cart` | Agregar producto |
| PUT | `/api/cart/{id}` | Actualizar cantidad |
| DELETE | `/api/cart/{id}` | Eliminar item |

### Pedidos
| Método | Ruta | Descripción |
|---|---|---|
| POST | `/api/orders/checkout/initiate` | Reservar stock (15 min) |
| POST | `/api/orders/checkout/confirm` | Confirmar compra |
| GET | `/api/orders` | Mis pedidos |
| GET | `/api/orders/{id}` | Detalle de pedido |

### Admin
| Método | Ruta | Descripción |
|---|---|---|
| GET | `/api/admin/dashboard` | Estadísticas generales |
| GET | `/api/admin/orders` | Todos los pedidos |
| GET | `/api/admin/clients` | Todos los clientes |
| GET | `/api/admin/analytics` | Analítica de ventas |

---

## Roles de usuario

| Rol | Permisos |
|---|---|
| `customer` | Comprar, ver sus pedidos, gestionar su carrito |
| `admin` | Todo lo anterior + gestión de productos y panel admin |
