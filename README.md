# Ambientación 2 - FastAPI + Angular + PostgreSQL

**Gestor de Plantillas y Generador de Tickets** para recursos cloud (GCP/Azure) con backend FastAPI, frontend Angular y base de datos PostgreSQL.

## 📋 Características

- ✅ **Gestión de Plantillas**: Crear, editar, eliminar plantillas por proveedor cloud (GCP/Azure) y tipo de recurso
- ✅ **Selección de Recursos**: Navegador de recursos cloud con vista por proveedor
- ✅ **Generación de Tickets**: Crear tickets consolidados con contenido de plantillas
- ✅ **Interfaz Limpia**: Angular 17 + CSS puro (sin dependencias UI externas)
- ✅ **Persistencia**: PostgreSQL 15 con SQLAlchemy ORM

## 🛠 Stack Tecnológico

| Componente | Tecnología | Versión |
|-----------|-----------|---------|
| Backend | FastAPI | 0.110.1 |
| ORM | SQLAlchemy | 2.0.23 |
| Frontend | Angular | 17 |
| Base de Datos | PostgreSQL | 15 |
| Orquestación | Docker Compose | 3.9 |
| Python | - | 3.10+ |
| Node.js | - | 18+ |

## 📁 Estructura del Proyecto

```
ambientacion-2/
├── app/
│   ├── backend/                   # FastAPI + SQLAlchemy
│   │   ├── server.py              # Aplicación principal
│   │   ├── requirements.txt       # Dependencias Python
│   │   ├── .env                   # Configuración (BD, CORS)
│   │   ├── Dockerfile            # Imagen Python 3.10
│   │   └── .dockerignore         # Patrones a ignorar
│   └── frontend/                  # Angular + Nginx
│       ├── src/
│       │   ├── main.ts            # Bootstrap Angular
│       │   ├── index.html         # Punto de entrada
│       │   ├── styles.css         # Estilos globales
│       │   └── app/
│       │       ├── app.component.* # Layout principal
│       │       ├── app.config.ts  # Inyección de dependencias
│       │       ├── app.routes.ts  # Rutas
│       │       ├── services/
│       │       │   └── api.service.ts # Cliente HTTP
│       │       └── pages/
│       │           ├── templates/ # CRUD plantillas
│       │           ├── resources/ # Seleccionar recursos
│       │           └── tickets/   # Ver tickets
│       ├── package.json           # Dependencias NPM
│       ├── angular.json           # Configuración CLI
│       ├── tsconfig.json          # Configuración TypeScript
│       ├── Dockerfile            # Imagen multietapa
│       ├── nginx.conf            # Configuración Nginx
│       └── .dockerignore         # Patrones a ignorar
├── docker-compose.yml             # Orquestación 3 servicios
└── README.md                      # Esta documentación
```

---

## 🚀 Inicio Rápido (Docker - Recomendado)

**Prerrequisitos:**
- Docker Desktop instalado ([descargar](https://www.docker.com/products/docker-desktop))
- Git instalado

### Paso 1: Clonar el repositorio

```bash
git clone <repository-url>
cd ambientacion-2
```

### Paso 2: Iniciar con Docker Compose

```bash
docker-compose up --build
```

Espera a que compile (3-5 minutos en primera ejecución). Una vez listo, deberías ver:

```
ambientacion2-backend  | INFO:     Uvicorn running on http://0.0.0.0:8001
ambientacion2-postgres | database system is ready to accept connections
ambientacion2-frontend | Configuration complete; ready for start up
```

### Paso 3: Acceder a la aplicación

Abre en tu navegador:
- **Interfaz**: http://localhost:3000
- **API**: http://localhost:8001/api

### Paso 4: Detener

```bash
docker-compose down
```

Para resetear la base de datos (eliminar todos los datos):

```bash
docker-compose down -v
```

---

## 💻 Instalación Local (Desarrollo)

Si prefieres trabajar sin Docker:

### Requisitos Previos

**Windows/Mac/Linux:**
- Python 3.10 o superior: [python.org](https://www.python.org/downloads/)
- Node.js 18+ (incluye npm): [nodejs.org](https://nodejs.org)
- PostgreSQL 15: [postgresql.org](https://www.postgresql.org/download/)
- Git

**Verificar instalaciones:**

```bash
python --version     # Debe ser 3.10+
node --version       # Debe ser 18+
npm --version        # Debe ser 8+
psql --version       # Debe ser PostgreSQL 15
```

### Paso 1: Configurar Base de Datos

Abre **pgAdmin** o línea de comandos psql:

```sql
CREATE DATABASE ambientacion2;
CREATE USER admin WITH PASSWORD 'password';
ALTER ROLE admin SET client_encoding TO 'utf8';
ALTER ROLE admin SET default_transaction_isolation TO 'read committed';
ALTER ROLE admin SET default_transaction_deferrable TO on;
ALTER ROLE admin SET timezone TO 'UTC';
GRANT ALL PRIVILEGES ON DATABASE ambientacion2 TO admin;
\c ambientacion2
GRANT ALL ON SCHEMA public TO admin;
```

O desde línea de comandos bash:

```bash
psql -U postgres -c "CREATE DATABASE ambientacion2;"
psql -U postgres -c "CREATE USER admin WITH PASSWORD 'password';"
psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE ambientacion2 TO admin;"
```

### Paso 2: Backend (FastAPI)

En una terminal:

```bash
cd app/backend

# Crear entorno virtual
python -m venv venv

# Activar entorno (elige según tu SO)
# Windows:
venv\Scripts\activate
# Linux/Mac:
source venv/bin/activate

# Instalar dependencias
pip install -r requirements.txt

# Configurar variables de entorno
# Editar .env y asegurar:
# DATABASE_URL=postgresql://admin:password@localhost:5432/ambientacion2
# CORS_ORIGINS=http://localhost:3000

# Iniciar servidor
python -m uvicorn server:app --reload --port 8001
```

Deberías ver:
```
INFO:     Uvicorn running on http://127.0.0.1:8001 (Press CTRL+C to quit)
INFO:     Started server process [1234]
```

✅ **Backend listo en:** http://localhost:8001/api/

### Paso 3: Frontend (Angular)

En **otra terminal**:

```bash
cd app/frontend

# Instalar dependencias
npm install

# Iniciar servidor de desarrollo
npm start
```

Después de compilar (~30 segundos), verás:
```
✔ Compiled successfully.
```

✅ **Frontend listo en:** http://localhost:4200

Navega a http://localhost:4200 en tu navegador. Deberías ver:
- Sidebar oscuro a la izquierda
- Botones: **Templates**, **Resources**, **Tickets**
- Área principal blanca

---

## 📖 Guía de Uso

### 1. Crear una Plantilla

1. Click en pestaña **Templates**
2. Rellena el formulario:
   - **Nombre**: "Mi Plantilla GCP"
   - **Proveedor**: GCP
   - **Tipo de Recurso**: VM
   - **Contenido**: "Instrucciones de configuración..."
3. Click **Create**
4. Verifica que aparece en la lista

### 2. Generar un Ticket

1. Click en pestaña **Resources**
2. Selecciona recursos (checkbox):
   - ☑ Compute Engine (VM)
   - ☑ Cloud SQL
3. Click **Generate Ticket**
4. Se redirige automáticamente a **Tickets**
5. Verás el ticket generado con contenido consolidado

### 3. Ver Tickets

1. Click en pestaña **Tickets**
2. Click en ticket para expandir
3. Click **Copy Content** para copiar al portapapeles

---

## 🔌 API REST Endpoints

**Base URL Local:** `http://localhost:8001/api`  
**Base URL Docker:** `http://backend:8001/api`

### Plantillas

```bash
# Listar todas
GET /api/templates

# Crear nueva
POST /api/templates
Content-Type: application/json
{
  "name": "Template 1",
  "provider": "GCP",
  "resource_type": "VM",
  "content": "Content here"
}

# Actualizar
PUT /api/templates/{id}

# Eliminar
DELETE /api/templates/{id}
```

### Recursos

```bash
# Listar recursos disponibles
GET /api/resources
# Respuesta:
[
  {"id": "gcp-vm", "name": "Compute Engine (VM)", "provider": "GCP"},
  {"id": "azure-vm", "name": "Virtual Machines", "provider": "Azure"},
  ...
]
```

### Tickets

```bash
# Generar ticket
POST /api/tickets/generate
Content-Type: application/json
{
  "resource_ids": ["gcp-vm", "gcp-sql"]
}

# Listar todos
GET /api/tickets

# Obtener detalle
GET /api/tickets/{id}
```

---

## 🗄 Modelos de Base de Datos

### Tabla: templates

| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | UUID | Clave primaria |
| name | String | Nombre de la plantilla |
| provider | String | "GCP" \| "AZURE" |
| resource_type | String | "VM", "STORAGE", "SQL", etc. |
| content | Text | Contenido de la plantilla |
| created_at | DateTime | Timestamp UTC |

### Tabla: tickets

| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | UUID | Clave primaria |
| resources_json | String | JSON array de recursos seleccionados |
| consolidated_content | Text | Contenido combinado de plantillas |
| created_at | DateTime | Timestamp UTC |

---

## 📊 Recursos Cloud Disponibles

### GCP

- **Compute Engine (VM)** - Máquinas virtuales
- **Google Kubernetes Engine (GKE)** - Kubernetes administrado
- **Artifact Registry (AR)** - Registro de artefactos
- **Cloud Storage** - Almacenamiento de objetos
- **Cloud SQL** - Base de datos SQL administrada

### Azure

- **Virtual Machines** - Máquinas virtuales
- **Azure Kubernetes Service (AKS)** - Kubernetes administrado
- **Container Registry (ACR)** - Registro de contenedores
- **Blob Storage** - Almacenamiento de objetos
- **Azure SQL Database** - Base de datos SQL administrado

---

## 🔧 Solución de Problemas

### ❌ Error: `docker-compose: command not found`

**Solución:** Instala el plugin Docker Compose v2

```bash
# Ubuntu/Debian
sudo apt-get update && sudo apt-get install docker-compose-plugin

# Mac (con Homebrew)
brew install docker-compose

# Verifica
docker compose version
```

Luego usa `docker compose` (con espacio) en lugar de `docker-compose` (con guión).

---

### ❌ Error: `database "admin" does not exist`

**Causa:** PostgreSQL intenta conectarse a base de datos que no existe.

**Solución:**

```bash
# Si usas Docker, está automatizado. Si es local:
psql -U postgres

# Dentro de psql:
CREATE DATABASE ambientacion2 OWNER admin;
\l  # Verifica que exista
```

---

### ❌ Error: "Error al cargar recursos" en la web

**Causa:** Frontend no puede contactar al backend API.

**Verificación:**

```bash
# 1. Backend corriendo
curl http://localhost:8001/api/

# 2. Si usas Docker, verifica red
docker network ls
docker inspect ambientacion-2_default

# 3. Logs del contenedor
docker-compose logs -f backend
```

**Solución:** Reinicia completamente

```bash
docker-compose down -v  # Incluye volúmenes
docker-compose up --build
```

---

### ❌ Error: Compilación Angular lenta o error de memoria

**Solución:**

```bash
cd app/frontend
rm -rf node_modules dist .angular
npm install
npm run build
```

---

### ❌ Nota: `KeyError: 'id'` en logs de Docker

**Esto NO es un error en la aplicación.** Es un problema menor del cliente `docker-compose` v1.x antiguo al procesar eventos de Docker.

**Solución:** Usa `docker compose` v2 como se describe arriba.

---

## 💡 Consejos de Desarrollo

### Cambios en Tiempo Real

**Backend:**
- FastAPI auto-recarga cuando editas `server.py`
- No necesitas reiniciar

**Frontend:**
- Angular dev server recarga automáticamente
- Abre http://localhost:4200 para ver cambios al instante

### Limpiar Base de Datos

```bash
# Con Docker
docker-compose down -v  # Elimina volumen postgres_data

# Local
# Dentro de psql:
DROP DATABASE ambientacion2;
CREATE DATABASE ambientacion2 OWNER admin;
```

### Ver Base de Datos

**Con Docker:**

```bash
docker-compose exec postgres psql -U admin -d ambientacion2

# Dentro:
\dt              # Lista tablas
SELECT * FROM templates;
SELECT * FROM tickets;
\q               # Salir
```

**Local:**

```bash
psql -U admin -d ambientacion2 -h localhost
```

### Resetear Todo

```bash
# Docker
docker-compose down -v --remove-orphans
docker system prune -f
docker-compose up --build

# Local
deactivate  # Si estás en venv
# Elimina venv y node_modules
rm -rf app/backend/venv app/frontend/node_modules app/frontend/dist
# Reinicia desde Paso 1
```

---

## 📝 Variables de Entorno

### Backend (.env)

```bash
# Conexión a PostgreSQL
DATABASE_URL=postgresql://admin:password@localhost:5432/ambientacion2

# CORS (quién puede acceder a la API)
CORS_ORIGINS=http://localhost:3000

# Para Docker
DATABASE_URL=postgresql://admin:password@postgres:5432/ambientacion2
CORS_ORIGINS=http://frontend:3000
```

### Frontend

No requiere `.env` — se conecta automáticamente via `/api` (proxy nginx en Docker)

---

## 🐳 Docker Compose Servicios

| Servicio | Puerto | URL |
|----------|--------|-----|
| **postgres** | 5432 | localhost:5432 |
| **backend** | 8001 | http://localhost:8001/api |
| **frontend** | 3000 | http://localhost:3000 |

Dentro de la red Docker, usa nombres en lugar de localhost:
- `http://postgres:5432`
- `http://backend:8001`
- `http://frontend:3000`

---

## 📦 Dependencias Principales

**Backend:**
- FastAPI: Framework web
- SQLAlchemy: ORM para base de datos
- psycopg2: Driver PostgreSQL
- python-dotenv: Variables de entorno

**Frontend:**
- Angular: Framework web
- RxJS: Programación reactiva
- Zone.js: Soporte async/await
- Typescript: Tipado estático

---

## 🔐 Notas de Seguridad

**Desarrollo:** Configuración por defecto es segura para localhost.

**Producción:**

1. **Cambiar credenciales por defecto:**
   ```bash
   POSTGRES_USER=<usuario-seguro>
   POSTGRES_PASSWORD=<contraseña-fuerte-32-caracteres>
   ```

2. **CORS restrictivos:**
   ```bash
   CORS_ORIGINS=https://tudominio.com
   ```

3. **HTTPS obligatorio:**
   - Configura certificados SSL en nginx.conf
   - Redirige HTTP → HTTPS

4. **Backup de base de datos:**
   ```bash
   pg_dump -U admin -d ambientacion2 > backup.sql
   ```

---

## 📚 Recursos Adicionales

- [FastAPI Docs](https://fastapi.tiangolo.com/)
- [Angular Docs](https://angular.io/docs)
- [PostgreSQL Docs](https://www.postgresql.org/docs/)
- [Docker Compose Docs](https://docs.docker.com/compose/)

---

## 📄 Licencia

Propietario - Softtek

---

## ✅ Checklist Inicial

Después de instalar, verifica:

- [ ] `http://localhost:3000` muestra la interfaz Angular
- [ ] Puedes crear una plantilla en "Templates"  
- [ ] Puedes seleccionar recursos en "Resources"
- [ ] Puedes generar un ticket
- [ ] El ticket aparece en "Tickets"
- [ ] `curl http://localhost:8001/api/` retorna JSON

¿Problemas? Abre un issue o contacta al equipo de desarrollo.
