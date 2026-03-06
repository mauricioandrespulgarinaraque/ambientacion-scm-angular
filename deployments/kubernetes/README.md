# Kubernetes Deployment Guide

## 📋 Contenido
- [Visión General](#visión-general)
- [Requisitos Previos](#requisitos-previos)
- [Despliegue Manual Rápido](#despliegue-manual-rápido)
- [Despliegue Paso a Paso](#despliegue-paso-a-paso)
- [Verificación y Testing](#verificación-y-testing)
- [Monitoreo](#monitoreo)
- [Escalado](#escalado)
- [Troubleshooting](#troubleshooting)

---

## Visión General

**Kubernetes** es un orquestador de contenedores de nivel empresarial. Usaremos **Google Kubernetes Engine (GKE)** para desplegar ambientacion-2.

### Ventajas de Kubernetes
- ✅ **Control total**: Máxima flexibilidad en configuración
- ✅ **Escalabilidad**: Escalado automático de pods
- ✅ **Resilencia**: Auto-recuperación de fallos
- ✅ **Persistencia**: Volúmenes persistentes para datos
- ✅ **Observabilidad**: Logs y métricas integrados
- ✅ **Producción-ready**: Estándar de la industria

### Arquitectura en Kubernetes

```
┌───────────────────────────────────────────────────────────────┐
│                   Google Kubernetes Engine (GKE)              │
├───────────────────────────────────────────────────────────────┤
│                                                                │
│  ┌──────────────────────────────────────────┐                │
│  │         Nodes (Máquinas virtuales)       │                │
│  │  ┌────────────────────────────────────┐  │                │
│  │  │  Pod (Backend)                      │  │                │
│  │  │  ├─ FastAPI container              │  │                │
│  │  │  └─ Port 8001                      │  │                │
│  │  └────────────────────────────────────┘  │                │
│  │  ┌────────────────────────────────────┐  │                │
│  │  │  Pod (Frontend)                     │  │                │
│  │  │  ├─ Nginx container                │  │                │
│  │  │  └─ Port 3000                      │  │                │
│  │  └────────────────────────────────────┘  │                │
│  │  ┌────────────────────────────────────┐  │                │
│  │  │  Pod (PostgreSQL)                   │  │                │
│  │  │  ├─ PostgreSQL container           │  │                │
│  │  │  └─ Port 5432                      │  │                │
│  │  │  └─ PersistentVolume (10GB)        │  │                │
│  │  └────────────────────────────────────┘  │                │
│  └──────────────────────────────────────────┘                │
│                                                                │
│  ┌──────────────────────────────────────────┐                │
│  │   Services (Load Balancing interno)      │                │
│  │  ├─ backend (ClusterIP)                  │                │
│  │  ├─ frontend (LoadBalancer)              │                │
│  │  └─ postgres (ClusterIP)                 │                │
│  └──────────────────────────────────────────┘                │
│                                                                │
└───────────────────────────────────────────────────────────────┘
```

---

## Requisitos Previos

### 1. Cuenta y Proyecto GCP

```bash
# Crear proyecto
gcloud projects create ambientacion2-k8s --name="Ambientacion 2 K8s"
gcloud config set project ambientacion2-k8s

# Verificar
gcloud config get-value project
```

### 2. Instalar Herramientas Necesarias

```bash
# Google Cloud SDK
# https://cloud.google.com/sdk/docs/install
gcloud --version

# kubectl (se incluye con gcloud, pero puedes instalarlo por separado)
# https://kubernetes.io/docs/tasks/tools/
kubectl version --client

# Docker
# https://www.docker.com/products/docker-desktop
docker --version

# Helm (opcional, para gestión avanzada)
# https://helm.sh/docs/intro/install/
# helm version
```

### 3. Autenticación

```bash
# Login en Google Cloud
gcloud auth login

# Configurar Docker para GCR
gcloud auth configure-docker gcr.io

# Verificar autenticación
gcloud auth list
```

### 4. Habilitar APIs Necesarias

```bash
export PROJECT_ID="your-gcp-project"

# Kubernetes Engine
gcloud services enable container.googleapis.com --project=$PROJECT_ID

# Container Registry
gcloud services enable artifactregistry.googleapis.com --project=$PROJECT_ID

# Cloud Build
gcloud services enable cloudbuild.googleapis.com --project=$PROJECT_ID

# Compute Engine (para nodes)
gcloud services enable compute.googleapis.com --project=$PROJECT_ID

# Verificar
gcloud services list --enabled --project=$PROJECT_ID
```

---

## Despliegue Manual Rápido

### Opción 1: Usar el Script (Recomendado)

```bash
# Configurar variables
export GCP_PROJECT_ID="your-gcp-project"
export GKE_ZONE="us-central1-a"
export GKE_REGION="us-central1"
export GKE_CLUSTER="ambientacion2-cluster"

# Hacer ejecutable
chmod +x deploy.sh

# Ejecutar
./deploy.sh
```

El script automatiza:
1. ✅ Verificación de requisitos
2. ✅ Habilitación de APIs
3. ✅ Creación de cluster GKE
4. ✅ Obtención de credenciales
5. ✅ Construcción de imágenes Docker
6. ✅ Push a Container Registry
7. ✅ Despliegue de manifests Kubernetes
8. ✅ Verificación de despliegue
9. ✅ Obtención de URLs de acceso

### Opción 2: Despliegue Manual Paso a Paso

Ver sección [Despliegue Paso a Paso](#despliegue-paso-a-paso)

---

## Despliegue Paso a Paso

### Paso 1: Crear Cluster GKE

```bash
# Variables
export PROJECT_ID="your-gcp-project"
export CLUSTER_NAME="ambientacion2-cluster"
export ZONE="us-central1-a"
export REGION="us-central1"
export NUM_NODES=2
export MACHINE_TYPE="n1-standard-2"

# Crear cluster
gcloud container clusters create $CLUSTER_NAME \
    --zone $ZONE \
    --project $PROJECT_ID \
    --num-nodes $NUM_NODES \
    --machine-type $MACHINE_TYPE \
    --enable-autoscaling \
    --min-nodes 1 \
    --max-nodes 10 \
    --enable-stackdriver-kubernetes \
    --enable-ip-alias \
    --enable-autorepair \
    --enable-autoupgrade

# Esto puede tardar 5-10 minutos
```

### Paso 2: Obtener Credenciales del Cluster

```bash
# Configurar kubectl
gcloud container clusters get-credentials $CLUSTER_NAME \
    --zone $ZONE \
    --project $PROJECT_ID

# Verificar conexión
kubectl cluster-info
kubectl get nodes
```

### Paso 3: Construir y Pushear Imágenes

```bash
# Configurar Docker
gcloud auth configure-docker gcr.io

# Variables
export IMAGE_BACKEND="gcr.io/${PROJECT_ID}/ambientacion2-backend:latest"
export IMAGE_FRONTEND="gcr.io/${PROJECT_ID}/ambientacion2-frontend:latest"

# Backend
cd ../../app/backend
docker build -t $IMAGE_BACKEND .
docker push $IMAGE_BACKEND

# Frontend
cd ../frontend
docker build -t $IMAGE_FRONTEND .
docker push $IMAGE_FRONTEND

# Verificar
gcloud container images list --project=$PROJECT_ID
```

### Paso 4: Actualizar Manifests

Editar `manifests/backend/deployment.yaml` y `manifests/frontend/deployment.yaml`:

```yaml
# ANTES:
image: gcr.io/YOUR_PROJECT_ID/ambientacion2-backend:latest

# DESPUÉS:
image: gcr.io/your-actual-project/ambientacion2-backend:latest
```

### Paso 5: Crear Namespace

```bash
kubectl apply -f manifests/namespace.yaml

# Verificar
kubectl get namespaces
```

### Paso 6: Crear Secretos y Configuración

```bash
# Secretos (credenciales de BD)
kubectl apply -f manifests/secret.yaml

# Configuración (variables de entorno)
# Ya incluido en secret.yaml

# Verificar
kubectl get secrets -n ambientacion2
kubectl get configmap -n ambientacion2
```

### Paso 7: Desplegar PostgreSQL

```bash
kubectl apply -f manifests/postgres/statefulset.yaml

# Verificar
kubectl get pods -n ambientacion2 -l app=postgres
kubectl get pvc -n ambientacion2

# Esperar a que esté listo (Ready 1/1)
kubectl wait --for=condition=ready pod -l app=postgres -n ambientacion2 --timeout=300s

# Ver logs
kubectl logs -f -l app=postgres -n ambientacion2
```

### Paso 8: Desplegar Backend

```bash
kubectl apply -f manifests/backend/deployment.yaml

# Verificar
kubectl get pods -n ambientacion2 -l app=backend
kubectl logs -f -l app=backend -n ambientacion2

# Esperar a Ready 1/1
kubectl rollout status deployment/backend -n ambientacion2
```

### Paso 9: Desplegar Frontend

```bash
kubectl apply -f manifests/frontend/deployment.yaml

# Verificar
kubectl get pods -n ambientacion2 -l app=frontend
kubectl logs -f -l app=frontend -n ambientacion2

# Esperar a Ready 1/1
kubectl rollout status deployment/frontend -n ambientacion2
```

### Paso 10: Obtener IP Pública

```bash
# Ver ServiceLB está usando frontend
kubectl get svc -n ambientacion2 frontend-service

# Obtener IP (puede tardar 1-5 minutos)
kubectl get svc -n ambientacion2 -w

# Una vez tenga IP:
export FRONTEND_IP=$(kubectl get svc frontend-service \
    -n ambientacion2 \
    -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo "Frontend: http://${FRONTEND_IP}"
```

---

## Verificación y Testing

### 1. Verificar Pods

```bash
# Ver todos los pods
kubectl get pods -n ambientacion2

# Ver detalles
kubectl describe pod <pod-name> -n ambientacion2

# Ver logs
kubectl logs <pod-name> -n ambientacion2
kubectl logs -f <pod-name> -n ambientacion2  # Tiempo real

# Acceder a un pod
kubectl exec -it <pod-name> -n ambientacion2 -- /bin/bash
```

### 2. Verificar Servicios

```bash
# Ver servicios
kubectl get svc -n ambientacion2

# Detalles de un servicio
kubectl describe svc <service-name> -n ambientacion2

# Port-forward para testing
kubectl port-forward svc/backend 8001:8001 -n ambientacion2
kubectl port-forward svc/frontend-service 3000:3000 -n ambientacion2
```

### 3. Testing de Conectividad

```bash
# Dentro del cluster (usando port-forward)
kubectl port-forward svc/backend 8001:8001 -n ambientacion2

# En otra terminal
curl http://localhost:8001/api/templates
curl http://localhost:8001/docs
```

### 4. Testing CRUD Completo

```bash
# Port-forward al backend
kubectl port-forward svc/backend 8001:8001 -n ambientacion2

# En otra terminal, testing
# 1. Crear template
curl -X POST http://localhost:8001/api/templates \
    -H "Content-Type: application/json" \
    -d '{
        "name": "Test K8s",
        "provider": "GCP",
        "resource_type": "KUBERNETES",
        "content": "Test content"
    }'

# 2. Listar
curl http://localhost:8001/api/templates

# 3. Generar ticket
curl -X POST http://localhost:8001/api/generate-ticket \
    -H "Content-Type: application/json" \
    -d '{
        "resource_type": "KUBERNETES"
    }'

# 4. Acceder a UI
kubectl port-forward svc/frontend-service 3000:3000 -n ambientacion2
# Abrir: http://localhost:3000
```

---

## Monitoreo

### Ver Logs en Tiempo Real

```bash
# Logs de un pod
kubectl logs -f deployment/backend -n ambientacion2

# Logs de múltiples pods
kubectl logs -f -l app=backend -n ambientacion2 --all-containers

# Logs desde hace 1 hora
kubectl logs --since=1h -l app=backend -n ambientacion2

# Últimas 100 líneas
kubectl logs --tail=100 -l app=backend -n ambientacion2
```

### Monitoreo de Recursos

```bash
# Uso de CPU y memoria de nodes
kubectl top nodes

# Uso de CPU y memoria de pods
kubectl top pods -n ambientacion2

# Pod específico
kubectl top pod <pod-name> -n ambientacion2

# Con límites
kubectl top pods -n ambientacion2 --containers
```

### Google Cloud Console

```bash
# Abrir Cloud Console
# https://console.cloud.google.com/kubernetes/clusters

# Métricas disponibles en Console:
# - CPU usage
# - Memory usage
# - Network I/O
# - Request count
# - Error rate
# - Pod distribution
```

### Integración con Google Cloud Monitoring

```bash
# Verificar que Stackdriver está habilitado (creamos el cluster con --enable-stackdriver-kubernetes)
gcloud container clusters describe $CLUSTER_NAME --zone $ZONE | grep monitoring

# Ver logs en Cloud Logging
# https://console.cloud.google.com/logs
```

---

## Escalado

### Auto-escalado Horizontal (Pods)

```bash
# Ver Horizontal Pod Autoscaler (si existe)
kubectl get hpa -n ambientacion2

# Crear HPA para Backend
kubectl autoscale deployment backend \
    --cpu-percent=70 \
    --min=2 \
    --max=10 \
    -n ambientacion2

# Crear HPA para Frontend
kubectl autoscale deployment frontend \
    --cpu-percent=80 \
    --min=2 \
    --max=5 \
    -n ambientacion2

# Ver HPAs
kubectl get hpa -n ambientacion2

# Ver actividad de scaling
kubectl describe hpa backend -n ambientacion2
```

### Escalado Manual

```bash
# Escalar Backend a 3 replicas
kubectl scale deployment backend --replicas=3 -n ambientacion2

# Verificar
kubectl get pods -n ambientacion2 -l app=backend

# Escalar Frontend a 4 replicas
kubectl scale deployment frontend --replicas=4 -n ambientacion2
```

### Cluster Escalado (Nodes)

El cluster fue creado con auto-escalado:
```bash
# Ver estado
gcloud container clusters describe $CLUSTER_NAME --zone $ZONE

# Node Pool details
gcloud container node-pools list --cluster $CLUSTER_NAME --zone $ZONE

# Escalar manualmente
gcloud container clusters resize $CLUSTER_NAME --num-nodes 5 --zone $ZONE
```

---

## Troubleshooting

### Pod stuck en Pending

```bash
# Ver por qué
kubectl describe pod <pod-name> -n ambientacion2

# Causas comunes:
# - Sin recursos disponibles: escalar cluster
# - Imagen no encontrada: verificar imagen en GCR
# - Persistent Volume issues: ver volúmenes

kubectl get pvc -n ambientacion2
kubectl describe pvc <pvc-name> -n ambientacion2
```

### Imagen no encontrada

```bash
# Verificar que la imagen existe
gcloud container images list --project=$PROJECT_ID
gcloud container images list-tags \
    gcr.io/${PROJECT_ID}/ambientacion2-backend

# Si no existe, reconstruir
docker build -t gcr.io/${PROJECT_ID}/ambientacion2-backend:latest .
docker push gcr.io/${PROJECT_ID}/ambientacion2-backend:latest

# Actualizar manifests y reapply
kubectl rollout restart deployment/backend -n ambientacion2
```

### Backend no se conecta a PostgreSQL

```bash
# Test de conectividad desde pod
kubectl exec -it <backend-pod> -n ambientacion2 -- /bin/bash

# Dentro del pod:
telnet postgres 5432
psql postgresql://admin:password123@postgres:5432/ambientacion2

# Ver variables de entorno
env | grep DATABASE
```

### Frontend no se conecta a Backend

```bash
# Port-forward para testing
kubectl port-forward svc/backend 8001:8001 -n ambientacion2

# En pod frontend:
kubectl exec -it <frontend-pod> -n ambientacion2 -- /bin/bash

# Dentro del pod:
curl http://backend:8001/api/templates
curl http://localhost:3000
```

### Espacio en disco lleno

```bash
# Ver uso de volúmenes
kubectl get pvc -n ambientacion2
kubectl top nodes
df -h

# Aumentar PVC (se necesita apagar pod)
kubectl patch pvc postgres-pvc-postgres-0 \
    -n ambientacion2 \
    -p '{"spec":{"resources":{"requests":{"storage":"20Gi"}}}}'
```

### Limpieza Completa

```bash
# Eliminar despliegue completo
kubectl delete namespace ambientacion2

# Eliminar cluster GKE
gcloud container clusters delete $CLUSTER_NAME --zone $ZONE --project $PROJECT_ID
```

---

## Comandos Útiles

```bash
# Información del cluster
gcloud container clusters describe $CLUSTER_NAME --zone $ZONE

# Conectar a cluster
gcloud container clusters get-credentials $CLUSTER_NAME --zone $ZONE

# Ver contextos
kubectl config get-contexts
kubectl config current-context

# Cambiar contexto
kubectl config use-context $CONTEXT_NAME

# Listar todos los recursos en namespace
kubectl api-resources -n ambientacion2

# Obtener YAML de recurso
kubectl get pod <pod-name> -n ambientacion2 -o yaml

# Editar recurso
kubectl edit deployment backend -n ambientacion2

# Aplicar cambios sin recrear
kubectl set image deployment/backend \
    backend=gcr.io/${PROJECT_ID}/ambientacion2-backend:new-tag \
    -n ambientacion2

# Rollback a versión anterior
kubectl rollout history deployment/backend -n ambientacion2
kubectl rollout undo deployment/backend -n ambientacion2

# Eventos del cluster
kubectl get events -n ambientacion2 --sort-by='.lastTimestamp'

# Información general
kubectl cluster-info
kubectl get all -n ambientacion2
```

---

## Próximos Pasos

1. ✅ Despliegue manual en Kubernetes completado
2. 🔄 Validar que ambos despliegues (Cloud Run + K8s) funcionan
3. 🔄 Crear pipelines Azure para automatizar ambos

---

**Versión**: 1.0  
**Última actualización**: Marzo 2026  
**Mantenedor**: DevOps Team
