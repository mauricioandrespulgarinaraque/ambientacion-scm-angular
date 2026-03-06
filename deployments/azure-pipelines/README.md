# Azure DevOps Pipelines - CI/CD

## 📋 Contenido
- [Visión General](#visión-general)
- [Configuración Previa](#configuración-previa)
- [Cloud Run Pipeline](#cloud-run-pipeline)
- [Kubernetes Pipeline](#kubernetes-pipeline)
- [Variables y Secretos](#variables-y-secretos)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)

---

## Visión General

Están disponibles dos pipelines CI/CD completamente automatizados:

### 🌐 Cloud Run Pipeline
- **Archivo**: `cloudrun-pipeline.yml`
- **Trigger**: Push a ramas `main` y `develop`
- **Stages**: Build → Deploy Dev → Deploy Prod → Testing
- **Ambiente**: Dos entornos separados (Dev y Prod)

### ☸️ Kubernetes Pipeline
- **Archivo**: `kubernetes-pipeline.yml`
- **Trigger**: Push a ramas `main-k8s` y `develop-k8s`
- **Stages**: Build → Deploy Dev → Deploy Prod → Health Checks
- **Ambiente**: Dos entornos separados (Dev y Prod)

---

## Configuración Previa

### 1. Requisitos en Azure DevOps

```bash
# 1. Crear organización en Azure DevOps
# https://dev.azure.com

# 2. Crear proyecto
# Nombre: ambientacion-2
# Visibilidad: Private (Privado)

# 3. Conectar repositorio
# Crear variable group en Pipelines > Library > Variable Groups
# Nombre: gcp-credentials
# Variables:
#   - GCP_PROJECT_ID
#   - GCP_SERVICE_ACCOUNT_JSON
```

### 2. Setup de Conexión GCP

```bash
# Opción A: Service Account Key (más fácil)
# 1. En GCP Console:
#    IAM & Admin > Service Accounts > Create
#    Nombre: azure-devops
#    Roles: Editor (o roles específicos)

# 2. Crear JSON key:
#    Service Account > Keys > Add Key > JSON

# 3. En Azure DevOps:
#    Project Settings > Service Connections > New > Google Cloud
#    Pegar contenido del JSON

# Opción B: Federated Identity (más seguro)
# 1. En GCP: Workload Identity Federation
# 2. En Azure: Use Workload Identity
```

### 3. Crear Variable Groups

En Azure DevOps, ir a **Pipelines > Library > Variable Groups**:

#### Variable Group: `gcp-config`
```
GCP_PROJECT_ID = your-gcp-project
GCP_REGION = us-central1
GCP_ZONE = us-central1-a
GKE_CLUSTER = ambientacion2-cluster
```

#### Variable Group: `cloudrun-config`
```
DATABASE_URL_DEV = postgresql://admin:password@host/db-dev
DATABASE_URL_PROD = postgresql://admin:password@host/db-prod
CORS_ORIGINS = https://*.example.com,https://app.example.com
```

#### Variable Group: `kubernetes-config`
```
K8S_NAMESPACE = ambientacion2
K8S_MIN_INSTANCES = 1
K8S_MAX_INSTANCES = 10
```

### 4. Service Connections

En **Project Settings > Service Connections**:

1. **Google Cloud Connection**
   - Nombre: `gcp-connection`
   - Tipo: Google Cloud
   - Método: Service Account key / Federated Identity

2. **Kubernetes Connections** (opcional)
   - Para cada ambiente (Dev y Prod)

---

## Cloud Run Pipeline

### Flujo Automático

```
Push a rama
    ↓
    ├─ main → Build → Deploy Prod → Tests
    └─ develop → Build → Deploy Dev → Tests
```

### Variables de Pipeline

```yaml
# Configuración en el archivo
variables:
  GCP_PROJECT_ID: '$(GCP_PROJECT_ID)'
  GCP_REGION: 'us-central1'
  SERVICE_BACKEND: 'ambientacion2-backend'
  SERVICE_FRONTEND: 'ambientacion2-frontend'
```

### Stages

#### 1. Build Stage
```
✓ Construye imagen del Backend
✓ Construye imagen del Frontend
✓ Pushea a Google Container Registry
✓ Publica artefactos
```

#### 2. DeployDev Stage (rama develop)
```
✓ Autentica en GCP
✓ Habilita APIs necesarias
✓ Despliega Backend en Cloud Run
✓ Despliega Frontend en Cloud Run
✓ Obtiene URLs de acceso
```

#### 3. DeployProd Stage (rama main)
```
✓ Mismo que DeployDev pero con:
  - Instancias mínimas/máximas aumentadas
  - Más memoria y CPU
  - Variables de entorno producción
```

#### 4. Testing Stage
```
✓ Ejecuta smoke tests
✓ Verifica APIs responden
✓ Valida salud de servicios
```

### Ejecución Manual

```bash
# En Azure DevOps Pipeline Editor
# Click en "Run" para ejecutar manualmente

# Seleccionar rama: main o develop
# Click "Run pipeline"
```

### Monitoreo

```bash
# Ver logs del pipeline
# Azure DevOps > Pipelines > Build > Job logs

# Ver logs del servicio Cloud Run
gcloud run logs read SERVICE_NAME --region=us-central1

# Ver historial de despliegues
gcloud run services list --region=us-central1
gcloud run services describe SERVICE_NAME --region=us-central1
```

---

## Kubernetes Pipeline

### Flujo Automático

```
Push a rama
    ↓
    ├─ main-k8s → Build → Deploy Prod → Health Checks
    └─ develop-k8s → Build → Deploy Dev → Health Checks
```

### Variables de Pipeline

```yaml
variables:
  GCP_PROJECT_ID: '$(GCP_PROJECT_ID)'
  GKE_CLUSTER: 'ambientacion2-cluster'
  GKE_ZONE: 'us-central1-a'
  NAMESPACE: 'ambientacion2'
```

### Stages

#### 1. Build Stage
```
✓ Construye imagen del Backend
✓ Construye imagen del Frontend
✓ Pushea a Google Container Registry
✓ Actualiza manifests Kubernetes con nuevas tags
✓ Publica manifests como artefactos
```

#### 2. DeployDev Stage (rama develop-k8s)
```
✓ Obtiene credenciales del cluster GKE
✓ Crea/actualiza Namespace
✓ Despliega Secrets y ConfigMaps
✓ Despliega PostgreSQL
✓ Espera a que PostgreSQL esté listo
✓ Despliega Backend
✓ Despliega Frontend
✓ Espera a que deployments estén listos
```

#### 3. DeployProd Stage (rama main-k8s)
```
✓ Mismo que DeployDev
✓ Usa configuración de producción
```

#### 4. Testing Stage
```
✓ Verifica estado de pods
✓ Verifica servicios disponibles
✓ Monitorea recursos (CPU, memoria)
✓ Verifica endpoints
```

### Ramas Especiales

Para Kubernetes usamos ramas separadas de Cloud Run:

```bash
# Cloud Run (main) vs Kubernetes (main-k8s)
git checkout -b main-k8s develop

# Cloud Run (develop) vs Kubernetes (develop-k8s)
git checkout -b develop-k8s develop
```

### Monitoreo

```bash
# Ver logs en tiempo real
kubectl logs -f deployment/backend -n ambientacion2

# Ver estado de pods
kubectl get pods -n ambientacion2 -w

# Port-forward para testing
kubectl port-forward svc/backend 8001:8001 -n ambientacion2

# Ver eventos del cluster
kubectl get events -n ambientacion2 --sort-by='.lastTimestamp'
```

---

## Variables y Secretos

### Mejores Prácticas

1. **No committear secretos a Git**
   ```bash
   # Usar Azure DevOps Secret Variables (enmascaradas)
   # No aparecen en logs
   ```

2. **Variable Groups para Reutilización**
   ```
   Pipelines > Library > Variable Groups
   ```

3. **Environment Secrets**
   ```
   Environments > Approvals
   Variables específicas por ambiente
   ```

### Estructura de Variables

```yaml
# gcp-config (público)
GCP_PROJECT_ID: ambientacion2-prod
GCP_REGION: us-central1
GKE_CLUSTER: ambientacion2-cluster

# database-secrets (secreto - enmascarado)
DATABASE_URL: postgresql://admin:***@cloudsql-proxy:5432/db
DATABASE_USER: admin
DATABASE_PASSWORD: ***
```

### Referencia en Pipeline

```yaml
variables:
  - group: gcp-config          # Publica
  - group: database-secrets    # Secreta
  
steps:
  - script: echo $(DATABASE_PASSWORD)  # Aparece como ***
```

---

## Monitoring

### Azure DevOps Dashboard

```
Pipelines > Runs
├─ Status actual
├─ Historial de ejecuciones
├─ Logs completosó
├─ Tiempo de ejecución
└─ Artefactos publicados
```

### Integraciones

#### Cloud Run Logs
```bash
gcloud run logs read SERVICE_NAME \
    --region=us-central1 \
    --limit=100
```

#### Kubernetes Logs
```bash
kubectl logs -l app=backend -n ambientacion2 --tail=100
```

#### Google Cloud Monitoring
```
Console > Monitoring > Dashboards
Alertas > Crear política de alertas
```

### Email Notifications

En Azure DevOps:
```
Pipeline > More > Triggers > Notifications
├─ Build failed
├─ Build succeeded  
├─ Deployment failed
└─ Deployment succeeded
```

---

## Troubleshooting

### Pipeline Falla en Build

**Error**: `docker build failed`

**Causa**: Dockerfile errors, dependencias faltantes

**Solución**:
```bash
# En local, probar build
docker build -f app/backend/Dockerfile app/backend

# Subir cambios si está bien
git add -A
git commit -m "fix: dockerfile errors"
git push
```

### Pipeline Falla en Autenticación GCP

**Error**: `Permission denied` o `Unauthorized`

**Causa**: Service Account credentials inválidas

**Solución**:
```bash
# 1. Verificar Service Account tiene permisos:
#    - Cloud Run Admin
#    - Kubernetes Engine Admin
#    - Container Registry Editor

# 2. En Azure DevOps:
#    Project Settings > Service Connections
#    Editar GCP connection > Verificar credenciales

# 3. Regenerar JSON key si es necesario
```

### Despliegue se queda en Pending

**Error**: `Deployment stuck in pending`

**Causa**: Insuficientes recursos, timeout

**Solución**:
```bash
# Cloud Run:
gcloud run deploy SERVICE \
    --memory=2Gi \
    --cpu=4 \
    --timeout=3600

# Kubernetes:
kubectl describe pod POD_NAME -n ambientacion2
kubectl logs POD_NAME -n ambientacion2
# Aumentar limits en deployment.yaml
```

### Variables no se resuelven

**Error**: `$(VARIABLE_NAME) aparece sin resolver`

**Causa**: Variable group no linkada

**Solución**:
```yaml
# En el pipeline, agregar explícitamente:
variables:
  - group: nombre-variable-group    # Link al group
```

### Test Falla Después de Deploy

**Error**: `Smoke test failed - HTTP 500`

**Causa**: Aplicación crashea, falta conectividad

**Solución**:
```bash
# Ver logs detallados
gcloud run logs read SERVICE --limit=50

# Para Kubernetes
kubectl logs deployment/backend -n ambientacion2 --tail=50

# Verificar variables de entorno
kubectl exec -it POD -n ambientacion2 -- env | grep DATABASE
```

---

## Próximas Mejoras

- [ ] Agregar tests automatizados (unit, integration)
- [ ] Implementar canary deployments
- [ ] Agregar rollback automático
- [ ] Artefactos de Docker con vulnerabilidad scanning
- [ ] Aprovación manual para Prod
- [ ] Notificaciones a Slack/Teams

---

## Comandos Útiles

```bash
# Ver historial de runs
az pipelines runs list --project "ambientacion-2" --pipeline-name "cloudrun"

# Triggerear pipeline manualmente
az pipelines run --project "ambientacion-2" --pipeline-name "cloudrun"

# Ver variables de un run
az pipelines runs show --project "ambientacion-2" --id RUN_ID

# Cancelar un run
az pipelines runs delete --project "ambientacion-2" --id RUN_ID
```

---

**Versión**: 1.0  
**Última actualización**: Marzo 2026  
**Mantenedor**: DevOps Team
