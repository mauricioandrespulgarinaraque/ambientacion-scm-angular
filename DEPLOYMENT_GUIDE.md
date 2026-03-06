# Guía de Despliegue - ambientacion-2

## 📋 Índice
1. [Visión General](#visión-general)
2. [Cloud Run - Despliegue Manual](#cloud-run---despliegue-manual)
3. [Kubernetes - Despliegue Manual](#kubernetes---despliegue-manual)
4. [Pipelines Azure CI/CD](#pipelines-azure-cicd)
5. [Checklist de Validación](#checklist-de-validación)

---

## Visión General

Este documento describe el proceso para desplegar **ambientacion-2** en dos plataformas:

### 🌐 Cloud Run
- Despliegue más simple y serverless
- Ideal para aplicaciones sin estado
- Auto-escalado automático
- Costo más bajo para baja concurrencia

### ☸️ Kubernetes (GKE)
- Mayor control sobre recursos
- Mejor para aplicaciones complejas
- Persistencia de datos más robusta
- Ideal para producción de alto volumen

---

## Cloud Run - Despliegue Manual

### Requisitos Previos
```bash
# 1. Instalar Google Cloud SDK
# https://cloud.google.com/sdk/docs/install

# 2. Autenticarse
gcloud auth login
gcloud config set project YOUR_PROJECT_ID

# 3. Habilitar APIs
gcloud services enable run.googleapis.com
gcloud services enable artifactregistry.googleapis.com
gcloud services enable cloudbuild.googleapis.com
```

### Paso 1: Construir y Pushear la Imagen

```bash
cd deployments/cloudrun

# Variables
PROJECT_ID="your-gcp-project"
SERVICE_NAME="ambientacion2"
REGION="us-central1"
IMAGE_NAME="gcr.io/${PROJECT_ID}/${SERVICE_NAME}"

# Construir imagen (Backend + Frontend en una sola imagen)
docker build -t ${IMAGE_NAME}:latest \
  -f ../../Dockerfile.cloudrun \
  ../..

# Pushear a Container Registry
docker push ${IMAGE_NAME}:latest
```

### Paso 2: Desplegar en Cloud Run

```bash
# Desplegar servicio
gcloud run deploy ${SERVICE_NAME} \
  --image ${IMAGE_NAME}:latest \
  --platform managed \
  --region ${REGION} \
  --allow-unauthenticated \
  --set-env-vars DATABASE_URL="postgresql://...",\
  --memory 1Gi \
  --cpu 2 \
  --timeout 3600 \
  --max-instances 100

# Obtener URL del servicio
gcloud run services describe ${SERVICE_NAME} --region ${REGION}
```

### Paso 3: Validar Despliegue

```bash
# Obtener URL
SERVICE_URL=$(gcloud run services describe ${SERVICE_NAME} \
  --format='value(status.url)' --region ${REGION})

echo "Acceso: ${SERVICE_URL}"

# Probar frontend
curl ${SERVICE_URL}

# Probar API
curl ${SERVICE_URL}/api/templates
```

---

## Kubernetes - Despliegue Manual

### Requisitos Previos
```bash
# 1. Instalar kubectl
# https://kubernetes.io/docs/tasks/tools/

# 2. Crear cluster GKE
gcloud container clusters create ambientacion2-cluster \
  --zone us-central1-a \
  --num-nodes 2 \
  --machine-type n1-standard-2

# 3. Obtener credenciales
gcloud container clusters get-credentials ambientacion2-cluster \
  --zone us-central1-a

# 4. Habilitar API
gcloud services enable container.googleapis.com
```

### Paso 1: Construir Imágenes Separadas

```bash
cd deployments/kubernetes

# Variables
PROJECT_ID="your-gcp-project"

# Backend
docker build -t gcr.io/${PROJECT_ID}/ambientacion2-backend:latest \
  -f ../../app/backend/Dockerfile \
  ../../app/backend

docker push gcr.io/${PROJECT_ID}/ambientacion2-backend:latest

# Frontend
docker build -t gcr.io/${PROJECT_ID}/ambientacion2-frontend:latest \
  -f ../../app/frontend/Dockerfile \
  ../../app/frontend

docker push gcr.io/${PROJECT_ID}/ambientacion2-frontend:latest

# PostgreSQL (usar imagen pública directamente)
```

### Paso 2: Actualizar Manifests

```bash
# Editar manifests/backend/deployment.yaml
# Cambiar imagen: gcr.io/${PROJECT_ID}/ambientacion2-backend:latest

# Editar manifests/frontend/deployment.yaml
# Cambiar imagen: gcr.io/${PROJECT_ID}/ambientacion2-frontend:latest
```

### Paso 3: Crear Namespace y Desplegar

```bash
# Crear namespace
kubectl apply -f manifests/namespace.yaml

# Crear secretos
kubectl apply -f manifests/secret.yaml

# Desplegar PostgreSQL
kubectl apply -f manifests/postgres/

# Desplegar Backend
kubectl apply -f manifests/backend/

# Desplegar Frontend
kubectl apply -f manifests/frontend/

# Verificar
kubectl get pods -n ambientacion2
kubectl get svc -n ambientacion2
```

### Paso 4: Obtener URLs de Acceso

```bash
# Frontend (LoadBalancer)
kubectl get svc -n ambientacion2 frontend-service

# Acceder a la aplicación
FRONTEND_IP=$(kubectl get svc frontend-service -n ambientacion2 \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo "Frontend: http://${FRONTEND_IP}:3000"
```

### Paso 5: Configurar Ingress (Opcional)

```bash
kubectl apply -f manifests/ingress.yaml

# Obtener IP del Ingress
kubectl get ingress -n ambientacion2
```

---

## Pipelines Azure CI/CD

Una vez validado que funciona el despliegue manual en ambas plataformas, crearemos:

### ✅ Pipeline para Cloud Run
- Trigger: Push a rama `main`
- Construcción de imagen
- Push a Container Registry
- Despliegue automático en Cloud Run

### ✅ Pipeline para Kubernetes
- Trigger: Push a rama `main-k8s`
- Construcción de imágenes (backend + frontend)
- Push a Container Registry
- Actualización de manifests
- Despliegue en GKE

**Ubicación**: `azure-pipelines/cloudrun-pipeline.yml` y `azure-pipelines/kubernetes-pipeline.yml`

---

## Checklist de Validación

### Cloud Run
- [ ] Imagen construida localmente
- [ ] Imagen pusheada a Container Registry
- [ ] Servicio desplegado en Cloud Run
- [ ] Frontend carga correctamente (http://service-url)
- [ ] API responde (/api/templates)
- [ ] CRUD funciona correctamente
- [ ] Base de datos persiste datos

### Kubernetes
- [ ] Cluster GKE creado y accesible
- [ ] Imágenes construidas y pusheadas
- [ ] Namespace creado
- [ ] PostgreSQL corriendo con datos persistentes
- [ ] Backend desplegado y respondiendo
- [ ] Frontend desplegado y accesible
- [ ] Comunicación backend-frontend funciona
- [ ] CRUD completo funciona
- [ ] LoadBalancer/Ingress funciona

### Pipelines
- [ ] Pipeline Cloud Run ejecutable
- [ ] Pipeline Kubernetes ejecutable
- [ ] Despliegues automáticos funcionan
- [ ] Rollbacks automáticos en caso de error
- [ ] Logs capturados correctamente

---

## Estructura de Directorios

```
ambientacion-2/
├── deployments/
│   ├── cloudrun/
│   │   ├── deploy.sh
│   │   ├── cloudbuild.yaml
│   │   └── README.md
│   ├── kubernetes/
│   │   ├── deploy.sh
│   │   ├── manifests/
│   │   │   ├── namespace.yaml
│   │   │   ├── configmap.yaml
│   │   │   ├── secret.yaml
│   │   │   ├── postgres/
│   │   │   ├── backend/
│   │   │   ├── frontend/
│   │   │   └── ingress.yaml
│   │   └── README.md
│   └── azure-pipelines/
│       ├── cloudrun-pipeline.yml
│       ├── kubernetes-pipeline.yml
│       └── README.md
├── Dockerfile.cloudrun (todo en uno)
├── DEPLOYMENT_GUIDE.md (este archivo)
└── ...
```

---

## Próximos Pasos

1. ✅ **Crear estructura de directorios** (este paso)
2. 🔄 **Cloud Run**: Crear Dockerfile optimizado y script de despliegue
3. 🔄 **Kubernetes**: Crear manifests y script de despliegue
4. 🔄 **Validar despliegues manuales** en ambas plataformas
5. 🔄 **Crear pipelines Azure** para automatizar

---

**Versión**: 1.0  
**Última actualización**: Marzo 2026  
**Autor**: DevOps Team
