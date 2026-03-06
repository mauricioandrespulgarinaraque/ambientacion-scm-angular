# Índice de Despliegue - ambientacion-2

## 🎯 Demanda Rápida

**¿Quieres desplegar en Cloud Run?**
→ Ir a [Cloud Run Deployment Guide](./deployments/cloudrun/README.md)

**¿Quieres desplegar en Kubernetes?**
→ Ir a [Kubernetes Deployment Guide](./deployments/kubernetes/README.md)

**¿Quieres automatizar con Azure DevOps?**
→ Ir a [Azure Pipelines Guide](./deployments/azure-pipelines/README.md)

---

## 📚 Estructura Completa

```
ambientacion-2/
├── deployments/
│   ├── cloudrun/
│   │   ├── README.md                      ← Guía completa Cloud Run
│   │   ├── deploy.sh                      ← Script automatizado de despliegue
│   │   └── cloudbuild.yaml                ← Configuración de Cloud Build (futuro)
│   │
│   ├── kubernetes/
│   │   ├── README.md                      ← Guía completa Kubernetes
│   │   ├── deploy.sh                      ← Script automatizado de despliegue
│   │   └── manifests/
│   │       ├── namespace.yaml             ← Namespace de K8s
│   │       ├── secret.yaml                ← Credenciales (base64 encoded)
│   │       ├── postgres/
│   │       │   └── statefulset.yaml       ← PostgreSQL deployment
│   │       ├── backend/
│   │       │   └── deployment.yaml        ← Backend + Service
│   │       └── frontend/
│   │           └── deployment.yaml        ← Frontend + Service
│   │
│   └── azure-pipelines/
│       ├── README.md                      ← Guía de pipelines Azure DevOps
│       ├── cloudrun-pipeline.yml          ← Pipeline CI/CD para Cloud Run
│       └── kubernetes-pipeline.yml        ← Pipeline CI/CD para Kubernetes
│
├── DEPLOYMENT_GUIDE.md                    ← Este archivo
└── app/
    ├── backend/
    │   └── Dockerfile
    └── frontend/
        └── Dockerfile
```

---

## 🚀 Guía Rápida - Variables Necesarias

### Para Cloud Run

```bash
export GCP_PROJECT_ID="your-gcp-project"
export GCP_REGION="us-central1"
export DATABASE_URL="postgresql://admin:password@cloud-sql-proxy:5432/ambientacion2"
```

### Para Kubernetes

```bash
export GCP_PROJECT_ID="your-gcp-project"
export GKE_ZONE="us-central1-a"
export GKE_CLUSTER="ambientacion2-cluster"
```

### Para Azure DevOps

```bash
# En Azure DevOps UI:
# Pipelines > Library > Variable Groups
# - gcp-config
# - cloudrun-config
# - kubernetes-config
```

---

## 📖 Despliegue Manual Detallado

### Opción 1: Cloud Run (5-10 minutos)

```bash
cd deployments/cloudrun

# Ejecutar script automatizado
chmod +x deploy.sh
export GCP_PROJECT_ID="your-project"
./deploy.sh

# O desplegar paso a paso
# Ver: deployments/cloudrun/README.md
```

**Resultado**:
- ✅ Backend en Cloud Run (http://service-url/api)
- ✅ Frontend en Cloud Run (http://service-url)
- ✅ Auto-escalado automático
- ✅ Menor costo para baja concurrencia

### Opción 2: Kubernetes (10-15 minutos)

```bash
cd deployments/kubernetes

# Ejecutar script automatizado
chmod +x deploy.sh
export GCP_PROJECT_ID="your-project"
export GKE_ZONE="us-central1-a"
./deploy.sh

# O desplegar paso a paso
# Ver: deployments/kubernetes/README.md
```

**Resultado**:
- ✅ Cluster GKE creado (2 nodes, auto-scaling)
- ✅ PostgreSQL desplegado con persistencia
- ✅ Backend + Frontend en K8s
- ✅ LoadBalancer asignado al Frontend
- ✅ Health checks y restart políticas configuradas

---

## 🤖 Automatización con Azure DevOps

### Configuración Previa

1. **Crear repositorio Git en Azure DevOps**
   ```
   https://dev.azure.com/your-org/ambientacion-2
   ```

2. **Setup GCP Service Account**
   ```bash
   gcloud iam service-accounts create azure-devops
   gcloud projects add-iam-policy-binding PROJECT_ID \
       --member=serviceAccount:azure-devops@PROJECT_ID.iam.gserviceaccount.com \
       --role=roles/editor
   ```

3. **Crear Variable Groups en Azure DevOps**
   ```
   Pipelines > Library > Variable Groups
   ```

4. **Crear Service Connection**
   ```
   Project Settings > Service Connections > Google Cloud
   ```

### Despliegue Automático

#### Cloud Run Pipeline
```bash
# Trigger automático:
git checkout develop
git commit -m "New changes"
git push origin develop
# → Pipeline ejecuta automáticamente
# → Deploy a Cloud Run Dev
```

#### Kubernetes Pipeline
```bash
# Trigger automático:
git checkout develop-k8s
git commit -m "New changes"
git push origin develop-k8s
# → Pipeline ejecuta automáticamente
# → Deploy a Kubernetes Dev
```

**Ver progreso**:
```
Azure DevOps > Pipelines > Runs
```

---

## ✅ Checklist de Validación

### Cloud Run
- [ ] Imágenes construidas localmente (`docker build`)
- [ ] Imágenes pusheadas a GCR (`docker push`)
- [ ] Servicio Backend desplegado en Cloud Run
- [ ] Servicio Frontend desplegado en Cloud Run
- [ ] Frontend carga en navegador (si es LoadBalancer)
- [ ] API responde: `curl BACKEND_URL/api/templates`
- [ ] CRUD funciona completo (crear, leer, actualizar, eliminar)

### Kubernetes
- [ ] Cluster GKE creado y accesible
- [ ] `kubectl` configurado
- [ ] Imágenes construidas y pusheadas
- [ ] Namespace creado (`ambientacion2`)
- [ ] PostgreSQL corriendo y accesible
- [ ] Backend desplegado y respondiendo
- [ ] Frontend desplegado y accesible
- [ ] Comunicación Backend ↔ Frontend funciona
- [ ] LoadBalancer/Ingress asignado correctamente
- [ ] CRUD funciona completo

### Azure Pipelines
- [ ] Variable Groups creados y linkados
- [ ] Service Connection funciona
- [ ] Pipeline Cloud Run se ejecuta sin errores
- [ ] Pipeline Kubernetes se ejecuta sin errores
- [ ] Despliegues en Dev automáticos después de push
- [ ] Despliegues en Prod con aprobación manual (opcional)
- [ ] Notificaciones configuradas

---

## 📊 Comparación de Opciones

| Característica | Cloud Run | Kubernetes |
|---|---|---|
| **Complejidad** | Muy simple | Moderada |
| **Curva de aprendizaje** | Baja | Media |
| **Control** | Limitado | Total |
| **Escalado** | Automático | Automático (configurable) |
| **Persistencia** | Cloud SQL | Volúmenes persistentes |
| **Costo (baja carga)** | Muy bajo | Mínimo cluster cost |
| **Costo (alta carga)** | Alto | Más económico |
| **Producción** | Bueno | Excelente |
| **Multi-región** | Fácil | Complejo |
| **Networking** | Automático | Manual |
| **Observabilidad** | Nativa | Necesita integración |
| **DevOps workflow** | Muy ágil | Robusto |

---

## 🎓 Flujo de Aprendizaje Recomendado

**Día 1**: Cloud Run Manual
```bash
1. Leer: deployments/cloudrun/README.md
2. Ejecutar: deploy.sh
3. Testing: Verificar que funciona
4. Cleanup: gcloud run delete SERVICE
```

**Día 2**: Kubernetes Manual
```bash
1. Leer: deployments/kubernetes/README.md
2. Ejecutar: deploy.sh
3. Testing: kubectl port-forward
4. Entender: manifests YAML
```

**Día 3**: Azure DevOps Setup
```bash
1. Crear Service Connection en Azure
2. Crear Variable Groups
3. Agregar pipelines al repo
4. Ejecutar primera pipeline
```

**Día 4**: Producción
```bash
1. Configurar environments (Dev/Prod)
2. Agregar approvals manuales
3. Configurar alertas
4. Documented runbooks
```

---

## 🔐 Seguridad en Producción

### Antes de Desplegar en Prod

1. **Credenciales**
   - [ ] Cambiar contraseña de BD por defecto
   - [ ] Usar Secret Manager en lugar de env vars
   - [ ] Rotar credenciales regularmente

2. **Networking**
   - [ ] Habilitar HTTPS/TLS
   - [ ] Configurar firewall rules
   - [ ] IP allowlists si es necesario

3. **RBAC**
   - [ ] Implementar roles de IAM mínimos
   - [ ] Service Accounts con permisos específicos
   - [ ] Audit logging habilitado

4. **Backups**
   - [ ] Automated PostgreSQL backups (diarios)
   - [ ] Verificar restauración periódicamente
   - [ ] Offsite backup storage

5. **Monitoreo**
   - [ ] Alertas configuradas
   - [ ] Logs centralizados
   - [ ] Métricas de salud

6. **Compliance**
   - [ ] Datos encriptados en tránsito (TLS)
   - [ ] Datos encriptados en reposo
   - [ ] PII protection implementado
   - [ ] Cumplimiento GDPR/CCPA

---

## 📞 Support y Troubleshooting

### Por Tema

| Tema | Ubicación |
|---|---|
| Cloud Run issues | [deployments/cloudrun/README.md](./deployments/cloudrun/README.md#troubleshooting) |
| Kubernetes issues | [deployments/kubernetes/README.md](./deployments/kubernetes/README.md#troubleshooting) |
| Pipeline issues | [deployments/azure-pipelines/README.md](./deployments/azure-pipelines/README.md#troubleshooting) |
| Código issues | Contactar al team |

### Logs Útiles

```bash
# Cloud Run
gcloud run logs read SERVICE_NAME --region=us-central1 --limit=100

# Kubernetes
kubectl logs -l app=backend -n ambientacion2 --tail=100
kubectl logs -l app=frontend -n ambientacion2 --tail=100

# Azure Pipeline
# Ver en: Azure DevOps > Pipelines > Runs > Job logs
```

---

## 🆘 Contacto y Escalación

- **DevOps Team**: devops@example.com
- **GCP Specialist**: gcp-team@example.com
- **Kubernetes Expert**: k8s-team@example.com
- **Azure DevOps Admin**: azure-admin@example.com

---

## 📝 Changelog

### v1.0 (Marzo 2026)
- ✅ Cloud Run deployment guide
- ✅ Kubernetes deployment guide
- ✅ Azure DevOps pipelines (Cloud Run + K8s)
- ✅ Automated deployment scripts
- ✅ Comprehensive documentation

### Próximas Versiones
- [ ] Multi-región Cloud Run
- [ ] GKE Autopilot
- [ ] ArgoCD Integration
- [ ] Helm Charts
- [ ] Terraform IaC

---

**Última actualización**: Marzo 2026  
**Versión**: 1.0  
**Estado**: ✅ Listo para Producción
