# 🚀 Quick Start - 5 Minutos o Menos

## 1️⃣ Cloud Run Despliegue Rápido

```bash
# Configurar
export GCP_PROJECT_ID="your-gcp-project"
export GCP_REGION="us-central1"

# Desplegar
cd deployments/cloudrun
chmod +x deploy.sh
./deploy.sh

# Resultado en 5-10 minutos:
# ✅ Frontend en: https://ambientacion2-frontend-xxxxx.run.app
# ✅ Backend en: https://ambientacion2-backend-xxxxx.run.app/docs
```

**Documentación completa**: [Cloud Run README](./cloudrun/README.md)

---

## 2️⃣ Kubernetes Despliegue Rápido

```bash
# Configurar
export GCP_PROJECT_ID="your-gcp-project"
export GKE_ZONE="us-central1-a"

# Desplegar
cd deployments/kubernetes
chmod +x deploy.sh
./deploy.sh

# Resultado en 10-15 minutos:
# ✅ Cluster GKE creado
# ✅ Frontend en: http://EXTERNAL_IP
# ✅ Backend accesible internamente
```

**Documentación completa**: [Kubernetes README](./kubernetes/README.md)

---

## 3️⃣ Azure DevOps Pipelines

```bash
# 1. En Azure DevOps, crear Service Connection a GCP
#    Project Settings > Service Connections > Google Cloud

# 2. Crear Variable Groups
#    Pipelines > Library > Variable Groups
#    Agregar: gcp-config, cloudrun-config, kubernetes-config

# 3. Agregar archivos al repo
#    - azure-pipelines/cloudrun-pipeline.yml
#    - azure-pipelines/kubernetes-pipeline.yml

# 4. Hacer push
git push origin main develop

# 5. Ver despliegue automático
#    Pipelines > Runs > (verá ejecución automática)
```

**Documentación completa**: [Azure Pipelines README](./azure-pipelines/README.md)

---

## 📊 Comparación Rápida

| | Cloud Run | Kubernetes |
|---|---|---|
| **Setup** | 5 min | 15 min |
| **Costo bajo** | ✅ | 💰 |
| **Costo alto** | 💰 | ✅ |
| **Complejidad** | ⭐ | ⭐⭐⭐ |
| **Control** | Limitado | Total |
| **Producción** | ✅ | ✅✅ |

---

## 🎯 Próximos Pasos

**Opción 1: Solo Cloud Run**
1. Ejecutar script de Cloud Run
2. Configurar Azure Pipeline Cloud Run
3. Listo para producción

**Opción 2: Solo Kubernetes**
1. Ejecutar script de Kubernetes
2. Configurar Azure Pipeline Kubernetes
3. Listo para producción

**Opción 3: Ambos (Recomendado)**
1. Ejecutar ambos scripts manualmente
2. Validar que funcionan
3. Configurar ambos pipelines Azure
4. Documentar diferencias operacionales

---

## 🆘 Troubleshooting Rápido

### Cloud Run falla
```bash
# Ver error
./deploy.sh 2>&1 | tail -50

# Si falla en auth
gcloud auth login
gcloud auth configure-docker gcr.io

# Si falla en APIs
gcloud services enable run.googleapis.com \
  artifactregistry.googleapis.com \
  cloudbuild.googleapis.com
```

### Kubernetes falla
```bash
# Ver error
./deploy.sh 2>&1 | tail -50

# Si ya existe cluster
gcloud container clusters delete ambientacion2-cluster \
  --zone us-central1-a

# Ver estado
kubectl get all -n ambientacion2
```

### Validar despliegue
```bash
# Cloud Run
gcloud run services list --region=us-central1

# Kubernetes
kubectl get pods -n ambientacion2
kubectl get svc -n ambientacion2
```

---

## 📚 Docs Completa

| Tema | Link |
|---|---|
| 📋 Arquitectura | [ARCHITECTURE.md](./ARCHITECTURE.md) |
| 🌐 Cloud Run | [cloudrun/README.md](./cloudrun/README.md) |
| ☸️ Kubernetes | [kubernetes/README.md](./kubernetes/README.md) |
| 🤖 Azure Pipelines | [azure-pipelines/README.md](./azure-pipelines/README.md) |
| 📄 Índice General | [README.md](./README.md) |

---

## ⏱️ Tiempos Estimados

| Tarea | Tiempo |
|---|---|
| Setup inicial (primero) | 15 min |
| Cloud Run deploy | 10 min |
| Kubernetes deploy | 15 min |
| Azure Pipeline setup | 20 min |
| Validación completa | 10 min |
|  **Total First Time** | ~70 min |
| Deploy subsecuentes | 5 min |

---

## ✅ Checklist Esencial

- [ ] Repos Git creados en Azure DevOps
- [ ] GCP project creado
- [ ] Service Account con permisos Editor
- [ ] gcloud CLI instalado
- [ ] Docker instalado
- [ ] kubectl instalado (para K8s)
- [ ] Ejecutó script de despliegue al menos una vez
- [ ] Ambos despliegues (Cloud Run + K8s) validados
- [ ] Azure Pipelines configurados
- [ ] Pipelines ejecutados exitosamente

---

**¡Listo para comenzar!** 🎉

Selecciona tu camino:
- 👉 [Quick Cloud Run](./cloudrun/README.md#despliegue-manual-rápido)
- 👉 [Quick Kubernetes](./kubernetes/README.md#despliegue-manual-rápido)
- 👉 [Quick Pipelines](./azure-pipelines/README.md)
