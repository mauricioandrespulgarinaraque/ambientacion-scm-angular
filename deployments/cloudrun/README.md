# Cloud Run Deployment Guide

## 📋 Contenido
- [Visión General](#visión-general)
- [Requisitos Previos](#requisitos-previos)
- [Despliegue Manual Rápido](#despliegue-manual-rápido)
- [Despliegue Paso a Paso](#despliegue-paso-a-paso)
- [Verificación y Testing](#verificación-y-testing)
- [Monitoreo y Logs](#monitoreo-y-logs)
- [Escalado](#escalado)
- [Troubleshooting](#troubleshooting)

---

## Visión General

**Cloud Run** es un servicio serverless de Google Cloud que permite ejecutar contenedores sin gestionar infraestructura.

### Ventajas
- ✅ **Serverless**: No gestiones servidores
- ✅ **Auto-escalado**: Automático según la demanda
- ✅ **Pago por uso**: Solo pagas lo que usas
- ✅ **Rápido**: Despliegues en segundos
- ✅ **Seguro**: Aislamiento de contenedores

### Arquitectura en Cloud Run
```
┌─────────────────────────────────────────────────────────┐
│              Google Cloud Run (Managed)                  │
├─────────────────────────────────────────────────────────┤
│  ┌──────────────┐              ┌──────────────┐         │
│  │  Frontend    │              │   Backend    │         │
│  │  Service     │────────────▶ │   Service    │         │
│  │  (Port 3000) │              │  (Port 8001) │         │
│  └──────────────┘              └──────────────┘         │
│         ▲                              │                 │
│         │                              ▼                 │
│      Users                     ┌──────────────┐         │
│                                │   Database   │         │
│                                │  (Cloud SQL) │         │
│                                │  (Postgres)  │         │
│                                └──────────────┘         │
└─────────────────────────────────────────────────────────┘
```

---

## Requisitos Previos

### 1. Cuenta y Proyecto GCP

```bash
# Crear cuenta si no tienes una
# https://cloud.google.com/

# Crear proyecto
gcloud projects create ambientacion2-prod --name="Ambientacion 2 Production"

# Establecer como proyecto activo
gcloud config set project ambientacion2-prod

# Verificar
gcloud config get-value project
```

### 2. Instalar Google Cloud SDK

```bash
# Windows (usar WSL2 o PowerShell)
# https://cloud.google.com/sdk/docs/install-sdk

# Linux/Mac
curl https://sdk.cloud.google.com | bash
exec -l $SHELL

# Verificar
gcloud --version
```

### 3. Autenticación

```bash
# Iniciar sesión
gcloud auth login

# Configurar credenciales de Docker
gcloud auth configure-docker gcr.io
```

### 4. Instalar Docker

```bash
# Windows: https://www.docker.com/products/docker-desktop
# Mac: https://www.docker.com/products/docker-desktop
# Linux: sudo apt-get install docker.io

# Verificar
docker --version
```

### 5. Habilitar APIs

```bash
# Cloud Run API
gcloud services enable run.googleapis.com

# Container Registry
gcloud services enable artifactregistry.googleapis.com

# Cloud Build
gcloud services enable cloudbuild.googleapis.com

# Cloud SQL
gcloud services enable sqladmin.googleapis.com
```

---

## Despliegue Manual Rápido

### Opción 1: Usar el Script (Recomendado)

```bash
# Configurar variables
export GCP_PROJECT_ID="your-gcp-project"
export GCP_REGION="us-central1"

# Hacer ejecutable
chmod +x deploy.sh

# Ejecutar
./deploy.sh
```

### Opción 2: Despliegue Paso a Paso Manual

Ver sección [Despliegue Paso a Paso](#despliegue-paso-a-paso)

---

## Despliegue Paso a Paso

### Paso 1: Autenticación en Docker

```bash
# Configurar autenticación de Docker para GCR
gcloud auth configure-docker gcr.io

# Verificar
gcloud auth list
```

### Paso 2: Variables de Proyecto

```bash
# Establecer variables
export PROJECT_ID="your-gcp-project"
export SERVICE_BACKEND="ambientacion2-backend"
export SERVICE_FRONTEND="ambientacion2-frontend"
export REGION="us-central1"
export IMAGE_BACKEND="gcr.io/${PROJECT_ID}/${SERVICE_BACKEND}"
export IMAGE_FRONTEND="gcr.io/${PROJECT_ID}/${SERVICE_FRONTEND}"
```

### Paso 3: Construir Imagen del Backend

```bash
cd ../../app/backend

docker build \
    -t "${IMAGE_BACKEND}:latest" \
    -f Dockerfile \
    .

# Ver imagen construida
docker images | grep ambientacion2-backend
```

### Paso 4: Pushear Backend a Container Registry

```bash
docker push "${IMAGE_BACKEND}:latest"

# Verificar en GCP
gcloud container images list --project="${PROJECT_ID}"
gcloud container images list-tags "gcr.io/${PROJECT_ID}/${SERVICE_BACKEND}"
```

### Paso 5: Construir Imagen del Frontend

```bash
cd ../frontend

docker build \
    -t "${IMAGE_FRONTEND}:latest" \
    -f Dockerfile \
    .

# Ver imagen construida
docker images | grep ambientacion2-frontend
```

### Paso 6: Pushear Frontend a Container Registry

```bash
docker push "${IMAGE_FRONTEND}:latest"

# Verificar
gcloud container images list-tags "gcr.io/${PROJECT_ID}/${SERVICE_FRONTEND}"
```

### Paso 7: Desplegar Backend en Cloud Run

```bash
gcloud run deploy "${SERVICE_BACKEND}" \
    --image="${IMAGE_BACKEND}:latest" \
    --platform=managed \
    --region="${REGION}" \
    --allow-unauthenticated \
    --set-env-vars=\
"DATABASE_URL=postgresql://admin:password@cloud-sql-proxy:5432/ambientacion2,\
CORS_ORIGINS=https://*" \
    --memory=1Gi \
    --cpu=2 \
    --timeout=3600 \
    --max-instances=100 \
    --min-instances=1 \
    --project="${PROJECT_ID}"
```

### Paso 8: Obtener URL del Backend

```bash
BACKEND_URL=$(gcloud run services describe "${SERVICE_BACKEND}" \
    --region="${REGION}" \
    --format='value(status.url)' \
    --project="${PROJECT_ID}")

echo "Backend URL: ${BACKEND_URL}"
```

### Paso 9: Desplegar Frontend en Cloud Run

```bash
gcloud run deploy "${SERVICE_FRONTEND}" \
    --image="${IMAGE_FRONTEND}:latest" \
    --platform=managed \
    --region="${REGION}" \
    --allow-unauthenticated \
    --set-env-vars="BACKEND_URL=${BACKEND_URL}" \
    --memory=512Mi \
    --cpu=1 \
    --timeout=3600 \
    --max-instances=50 \
    --min-instances=1 \
    --project="${PROJECT_ID}"
```

### Paso 10: Obtener URL del Frontend

```bash
FRONTEND_URL=$(gcloud run services describe "${SERVICE_FRONTEND}" \
    --region="${REGION}" \
    --format='value(status.url)' \
    --project="${PROJECT_ID}")

echo "Frontend URL: ${FRONTEND_URL}"
```

---

## Verificación y Testing

### 1. Verificar que los Servicios están Corriendo

```bash
# Listar servicios
gcloud run services list --region="${REGION}"

# Ver estado del servicio
gcloud run services describe "${SERVICE_BACKEND}" --region="${REGION}"
gcloud run services describe "${SERVICE_FRONTEND}" --region="${REGION}"
```

### 2. Testing del Backend

```bash
# GET /api/templates
curl "${BACKEND_URL}/api/templates"

# Response esperado: [] (array vacío)
```

### 3. Testing del Frontend

```bash
# Acceder a la interfaz web
echo "Abre en navegador: ${FRONTEND_URL}"

# O desde CLI
curl -s "${FRONTEND_URL}" | head -20
```

### 4. Testing CRUD Completo

```bash
# 1. Crear template
curl -X POST "${BACKEND_URL}/api/templates" \
    -H "Content-Type: application/json" \
    -d '{
        "name": "Test Template",
        "provider": "GCP",
        "resource_type": "COMPUTE_ENGINE",
        "content": "Test content"
    }'

# 2. Listar templates
curl "${BACKEND_URL}/api/templates"

# 3. Crear ticket
curl -X POST "${BACKEND_URL}/api/generate-ticket" \
    -H "Content-Type: application/json" \
    -d '{
        "resource_type": "COMPUTE_ENGINE"
    }'

# 4. Verificar en UI
open "${FRONTEND_URL}"
```

---

## Monitoreo y Logs

### Ver Logs del Servicio

```bash
# Últimos 50 logs
gcloud run logs read "${SERVICE_BACKEND}" \
    --region="${REGION}" \
    --limit=50

# Logs en tiempo real
gcloud run logs read "${SERVICE_BACKEND}" \
    --region="${REGION}" \
    --follow

# Solo errores
gcloud run logs read "${SERVICE_BACKEND}" \
    --region="${REGION}" \
    | grep ERROR
```

### Métricas en Google Cloud Console

```bash
# Abrir Cloud Run Dashboard
echo "https://console.cloud.google.com/run?project=${PROJECT_ID}"

# Métricas disponibles:
# - Request count
# - Latency
# - Error rate
# - Memory usage
# - CPU usage
# - Concurrent requests
```

### Alertas

```bash
# Ver alertas
gcloud alpha monitoring policies list

# Crear alerta (requiere Cloud Monitoring)
gcloud alpha monitoring policies create \
    --notification-channels=CHANNEL_ID \
    --display-name="Cloud Run - High Error Rate" \
    --condition-display-name="Error Rate > 5%" \
    --condition-threshold-value=5 \
    --condition-threshold-duration=300s
```

---

## Escalado

### Auto-escalado

Cloud Run escala automáticamente según la demanda. Parameters principales:

```bash
# Ver configuración actual
gcloud run services describe "${SERVICE_BACKEND}" \
    --region="${REGION}" \
    --format='value(spec.template.spec.containerConcurrency)'

# Actualizar instancias mínimas
gcloud run deploy "${SERVICE_BACKEND}" \
    --min-instances=2 \
    --region="${REGION}"

# Actualizar instancias máximas
gcloud run deploy "${SERVICE_BACKEND}" \
    --max-instances=200 \
    --region="${REGION}"

# Actualizar concurrencia por instancia
gcloud run deploy "${SERVICE_BACKEND}" \
    --concurrency=80 \
    --region="${REGION}"
```

### Monitoreo de Escalado

```bash
# Ver evolución de instancias
watch -n 5 'gcloud run services describe '"${SERVICE_BACKEND}"' \
    --region='"${REGION}"' \
    --format=json | jq .status'
```

---

## Troubleshooting

### Error: "Permission denied: Could not push to repository"

**Causa**: Autenticación no configurada  
**Solución**:
```bash
gcloud auth configure-docker gcr.io
docker login -u _json_key --password-stdin gcr.io < ~/.config/gcloud/legacy_credentials/*/adc.json
```

### Error: "Cannot find image"

**Causa**: Imagen no existe o no fue pusheada  
**Solución**:
```bash
# Verificar imagen existe
docker images | grep ambientacion2

# Si no, reconstruir
docker build -t gcr.io/${PROJECT_ID}/ambientacion2-backend .

# Pushear
docker push gcr.io/${PROJECT_ID}/ambientacion2-backend
```

### Error: "Connection refused" desde Frontend a Backend

**Causa**: CORS o variable de entorno incorrecta  
**Solución**:
```bash
# Verificar CORS
gcloud run services describe "${SERVICE_BACKEND}" \
    --region="${REGION}" \
    --filter='spec.template.spec.containers[0].env[name=="CORS_ORIGINS"]' \
    --format='value(spec.template.spec.containers[0].env[name=="CORS_ORIGINS"].value)'

# Actualizar con URL correcta del frontend
gcloud run deploy "${SERVICE_BACKEND}" \
    --update-env-vars="CORS_ORIGINS=${FRONTEND_URL}" \
    --region="${REGION}"
```

### Error: "Service is not responding"

**Causa**: Aplicación crashea o timeout  
**Solución**:
```bash
# Ver logs de error
gcloud run logs read "${SERVICE_BACKEND}" --region="${REGION}" | grep ERROR

# Aumentar timeout
gcloud run deploy "${SERVICE_BACKEND}" \
    --timeout=3600 \
    --region="${REGION}"

# Aumentar memoria/CPU
gcloud run deploy "${SERVICE_BACKEND}" \
    --memory=2Gi \
    --cpu=4 \
    --region="${REGION}"
```

### Error: "Quota exceeded"

**Causa**: Límites de proyecto alcanzados  
**Solución**:
```bash
# Ver cuotas
gcloud compute project-info describe --project=${PROJECT_ID} | grep QUOTA

# Solicitar incremento en Google Cloud Console
# Console > APIs & Services > Quotas
```

---

## Próximos Pasos

1. ✅ Despliegue manual en Cloud Run completado
2. 🔄 Crear despliegue manual en Kubernetes
3. 🔄 Validar ambos funcionan correctamente
4. 🔄 Crear pipelines Azure para automatizar

---

**Versión**: 1.0  
**Última actualización**: Marzo 2026  
**Mantenedor**: DevOps Team
