# Arquitectura de Despliegue - ambientacion-2

## 🎯 Visión General de Opciones de Despliegue

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          AMBIENTACION-2                                     │
│                     (FastAPI + Angular + PostgreSQL)                        │
└────────────────────────┬──────────────────────────────────────┬─────────────┘
                         │                                      │
                    ┌────▼────┐                          ┌─────▼──────┐
                    │          │                         │             │
                 Opción 1:   Opción 2:               Opción 3:       Opción 4:
                 Cloud Run   Kubernetes              Local Dev      Docker Compose
                 Simple      Enterprise              Direct          Dev/Test
                    │          │                         │             │
                    │          │                         │             │
                    └──────┬───┴─────────┬───────────┐   │             │
                           │             │           │   │             │
                        Build          Build      Build  │           Build
                      Imágenes       Imágenes   Imágenes │         Imágenes
                           │             │           │   │             │
                           ├─────────────┼───────────┤   │             │
                           │             │           │   │             │
                      Despliegue      Deploy        Test └──────┬──────┘
                    Automático      Manual           │          │
                      (Prod)         (Prod)         Dev      No Prod
                           │             │           ▲          │
                           └─────┬───────┴───────────┘          │
                                 │                              │
                           ┌──────▼────────────────────┐        │
                           │   Azure DevOps Pipelines │        │
                           │   (CI/CD Automático)     │        │
                           └──────────────────────────┘        │
                                   ▲                            │
                                   │                            │
                        ┌──────────┴──────────────┐            │
                        │                         │             │
                    Trigger: main             Trigger: main-k8s  │
                    (Cloud Run)           (Kubernetes)           │
                                                                 │
                               Manual Dev/Test on Local
```

---

## 🏗️ Cloud Run Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│           Google Cloud Run (Managed Serverless)                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────────────┐         ┌──────────────────────┐     │
│  │   Frontend Service   │         │   Backend Service    │     │
│  │                      │         │                      │     │
│  │  ┌────────────────┐  │         │  ┌────────────────┐  │     │
│  │  │ Angular App    │  │         │  │ FastAPI Server │  │     │
│  │  │ (Nginx)        │  │         │  │ (Uvicorn)      │  │     │
│  │  │ Port: 3000     │  │         │  │ Port: 8001     │  │     │
│  │  └────────────────┘  │         │  └────────────────┘  │     │
│  │                      │         │         │             │     │
│  │  URL: https://...    │         │         ├─────────────┼────→│
│  └──────────────────────┘         │         │  (API)      │     │
│           ▲                        │         ▼             │     │
│           │                        │  ┌──────────────┐    │     │
│           │                        │  │ CloudSQL     │    │     │
│           └────────────────────────┤→ │ PostgreSQL   │    │     │
│     (HTTP requests via proxy)      │  │ (Managed)    │    │     │
│                                    │  └──────────────┘    │     │
│                                    │                      │     │
│       Auto-Scaling: 1-100          └──────────────────────┘     │
│       instances                                                   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Características
- **Serverless**: No gesionar infraestructura
- **Auto-escalado**: Automático 1-100 instancias
- **Rápido**: Despliegue en segundos
- **Económico**: Pago por uso (bueno para baja carga)
- **Ideal para**: Prototipos, startups, bajo tráfico

---

## ☸️ Kubernetes (GKE) Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│                 Google Kubernetes Engine (GKE)                       │
│                     (2-10 nodes, auto-scaling)                       │
├──────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌─────────────────────────────────┐  ┌──────────────────────────┐  │
│  │      Node 1                     │  │      Node 2              │  │
│  │  ┌──────────────────────────┐   │  │  ┌────────────────────┐  │  │
│  │  │ Pod: Frontend (Nginx)    │   │  │  │ Pod: Backend       │  │  │
│  │  │ - Port 3000              │   │  │  │ - Port 8001        │  │  │
│  │  │ - 2 replicas             │   │  │  │ - 2 replicas       │  │  │
│  │  └──────────────────────────┘   │  │  └────────────────────┘  │  │
│  │                                  │  │          ▲               │  │
│  │  ┌──────────────────────────┐   │  │          │               │  │
│  │  │ Pod: PostgreSQL          │   │  │  ┌──────▼──────┐        │  │
│  │  │ (StatefulSet)            │   │  │  │  Database  │        │  │
│  │  │ - Port 5432              │   │  │  │  Service   │        │  │
│  │  │ - 1 replica              │   │  │  │ (ClusterIP)│        │  │
│  │  │ - Persistent Volume: 10GB│   │  │  └────────────┘        │  │
│  │  └──────────────────────────┘   │  │                         │  │
│  └─────────────────────────────────┘  └──────────────────────────┘  │
│           │                                                          │
│  ┌────────▼──────────────────────────────────────────┐              │
│  │     Services (Load Balancing)                     │              │
│  │  ├─ frontend-service (LoadBalancer)               │              │
│  │  │   └─ External IP (usuarios)                    │              │
│  │  ├─ backend (ClusterIP)                           │              │
│  │  │   └─ Solo acceso interno                       │              │
│  │  └─ postgres (Headless)                           │              │
│  │      └─ StatefulSet DNS                           │              │
│  └───────────────────────────────────────────────────┘              │
│           │                                                          │
│  ┌────────▼──────────────────────────────────────────┐              │
│  │     Persistent Storage                            │              │
│  │  └─ PersistentVolumeClaim (10GB SSD)              │              │
│  │     └─ Data persiste entre restarts               │              │
│  └───────────────────────────────────────────────────┘              │
│                                                                      │
│  Monitoring: Google Cloud Monitoring                                │
│  Logging: Google Cloud Logging (Stackdriver)                        │
│  Auto-repair: Reemplaza nodes dañados automáticamente               │
│  Auto-upgrade: Updates automáticos de versiones                     │
└──────────────────────────────────────────────────────────────────────┘
```

### Características
- **Control Total**: Máxima flexibilidad
- **Escalable**: Producción empresarial
- **Resiliente**: Auto-recuperación, redundancia
- **Persistente**: Base de datos con volúmenes
- **Observabilidad**: Logs y métricas integrados
- **Ideal para**: Producción, alta carga, multi-tenante

---

## 🚀 CI/CD Pipeline Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│                      AZURE DEVOPS PIPELINES                          │
├──────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │                  Git Repository                             │    │
│  │  (main, develop para Cloud Run)                             │    │
│  │  (main-k8s, develop-k8s para Kubernetes)                   │    │
│  └────┬────────────────────────────────────────────────────────┘    │
│       │                                                              │
│       ├─→ Push a 'main' ─────→ Trigger Pipeline Cloud Run        │
│       │                       ├─→ Build & Push Images             │
│       │                       ├─→ Deploy Prod (Cloud Run)         │
│       │                       └─→ Smoke Tests                      │
│       │                                                              │
│       ├─→ Push a 'develop' ──→ Trigger Pipeline Cloud Run        │
│       │                       ├─→ Build & Push Images             │
│       │                       ├─→ Deploy Dev (Cloud Run)          │
│       │                       └─→ Smoke Tests                      │
│       │                                                              │
│       ├─→ Push a 'main-k8s' ─→ Trigger Pipeline Kubernetes      │
│       │                       ├─→ Build & Push Images             │
│       │                       ├─→ Deploy Prod (GKE)               │
│       │                       └─→ Health Checks                    │
│       │                                                              │
│       └─→ Push a 'develop-k8s'→ Trigger Pipeline Kubernetes      │
│                               ├─→ Build & Push Images             │
│                               ├─→ Deploy Dev (GKE)                │
│                               └─→ Health Checks                    │
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │                Stage: BUILD                                 │    │
│  │  ├─ Checkout código                                          │    │
│  │  ├─ Build Docker: Backend                                    │    │
│  │  ├─ Build Docker: Frontend                                   │    │
│  │  ├─ Push a GCR: gcr.io/PROJECT/backend:tag                  │    │
│  │  └─ Push a GCR: gcr.io/PROJECT/frontend:tag                 │    │
│  └────────────────┬──────────────────────────────────────────────┘    │
│                  │                                                    │
│  ┌───────────────▼──────────────────────────────────────────┐        │
│  │              Stage: DEPLOY DEV                            │        │
│  │  Cloud Run: ├─ Backend (min 1, max 50 instances)         │        │
│  │             └─ Frontend (min 1, max 30 instances)        │        │
│  │  K8s:       ├─ Deploy to Dev cluster                     │        │
│  │             ├─ Run smoke tests                           │        │
│  │             └─ Get service URLs                          │        │
│  └────────────────┬────────────────────────────────────────┘         │
│                  │                                                    │
│  ┌───────────────▼──────────────────────────────────────────┐        │
│  │              Stage: DEPLOY PROD                           │        │
│  │  (Trigger solo cuando branch == main o main-k8s)         │        │
│  │  Cloud Run: ├─ Backend (min 2, max 100 instances)       │        │
│  │             └─ Frontend (min 2, max 50 instances)       │        │
│  │  K8s:       ├─ Deploy to Prod cluster                   │        │
│  │             ├─ Health checks                            │        │
│  │             └─ Verify all pods ready                    │        │
│  └────────────────┬────────────────────────────────────────┘         │
│                  │                                                    │
│  ┌───────────────▼──────────────────────────────────────────┐        │
│  │              Stage: TESTING                               │        │
│  │  ├─ Smoke Tests (HTTP 200 checks)                        │        │
│  │  ├─ API Response Tests                                    │        │
│  │  └─ Service Availability Checks                           │        │
│  └──────────────────────────────────────────────────────────┘        │
│                                                                       │
│  ┌──────────────────────────────────────────────────────────┐        │
│  │              Notifications & Reporting                    │        │
│  │  ├─ Email en Success/Failure                              │        │
│  │  ├─ Slack/Teams (opcional)                                │        │
│  │  └─ Build artifacts y logs                                │        │
│  └──────────────────────────────────────────────────────────┘        │
│                                                                       │
└──────────────────────────────────────────────────────────────────────┘
```

---

## 📊 Flujo de Trabajo Completo

### Escenario 1: Cambio en Dev (Cloud Run)

```
1. Developer hace cambios en código
   └─ git add, git commit, git push origin develop

2. Azure DevOps detecta push
   └─ Trigger: Cloud Run Pipeline

3. Build Stage
   ├─ Checkout código
   ├─ Build imagen Backend
   ├─ Build imagen Frontend
   └─ Push a GCR

4. Deploy Dev Stage
   ├─ Deploy Backend en Cloud Run Dev
   ├─ Deploy Frontend en Cloud Run Dev
   └─ Obtiene URLs de acceso

5. Testing Stage
   ├─ curl /api/templates
   ├─ curl frontend URL
   └─ Verifica HTTP 200

6. Notificación
   └─ Email: "Despliegue exitoso en Dev"

7. QA puede acceder a
   └─ https://ambientacion2-frontend-dev-xxxxx.run.app
```

### Escenario 2: Release a Prod (Kubernetes)

```
1. Developer prepara release
   └─ git checkout main-k8s
   └─ git merge develop-k8s
   └─ git push origin main-k8s

2. Azure DevOps detecta push
   └─ Trigger: Kubernetes Pipeline

3. Build Stage
   ├─ Build Backend image
   ├─ Build Frontend image
   ├─ Push a GCR con BUILD_ID
   └─ Update manifests K8s

4. Deploy Prod Stage (con aprobación manual)
   ├─ Deploy a GKE cluster Prod
   ├─ Crear/update Namespace
   ├─ Desplegar PostgreSQL
   ├─ Desplegar Backend (2-10 replicas)
   ├─ Desplegar Frontend (2-5 replicas)
   └─ Esperar a que todos estén ready

5. Health Checks Stage
   ├─ Verificar pods status
   ├─ Verificar servicios
   ├─ Verificar endpoints
   └─ Top nodes/pods

6. Notificación
   └─ Email: "Release a Producción completado"

7. Usuarios acceden a
   └─ http://EXTERNAL_IP (LoadBalancer IP)
```

---

## 🔄 Decisión: ¿Qué Opción Usar?

### Usa Cloud Run si:
- ✅ Aplicación stateless
- ✅ Tráfico variable/impredecible
- ✅ Equipo pequeño sin expertise Kubernetes
- ✅ Presupuesto bajo (pago por uso)
- ✅ Despliegues muy rápidos
- ✅ No necesitas control fino de recursos

### Usa Kubernetes si:
- ✅ Aplicación con estado (sesiones, datos)
- ✅ Tráfico predecible y voluminoso
- ✅ Equipo con experiencia DevOps
- ✅ Necesitas máximo control
- ✅ Multi-tenante o micro-servicios
- ✅ Compliance/regulaciones estrictas
- ✅ Costo total importante

### Usa Ambos si:
- ✅ Cloud Run para APIs simples
- ✅ Kubernetes para datos complejos
- ✅ Multi-región con Cloud Run
- ✅ Canary deployments

---

## 📈 Escalado y Performance

### Cloud Run
```
Carga baja (100 req/s)       → 1-5 instancias ($)
Carga media (1000 req/s)    → 10-50 instancias ($$)
Carga alta (10000 req/s)    → 100 instancias ($$$)
```

### Kubernetes
```
Carga baja (100 req/s)       → 2-4 pods en 1 node
Carga media (1000 req/s)    → 4-8 pods en 2-3 nodes
Carga alta (10000 req/s)    → 10+ pods en 5+ nodes
```

---

## 🔐 Seguridad: Niveles de Madurez

```
NIVEL 1: Dev Local
└─ Credenciales en .env (NO REPO)
└─ HTTPS en localhost[:venv-only]
└─ Debug mode ON

NIVEL 2: Cloud Run Dev
├─ Secrets in Cloud Run env vars
├─ HTTPS automático
├─ Debug mode OFF
└─ Smoke tests

NIVEL 3: Cloud Run Prod
├─ Secrets en Secret Manager
├─ HTTPS + TLS 1.3
├─ WAF + Cloud Armor
├─ VPC Service Controls
├─ Audit logging
└─ Backup diarios

NIVEL 4: Kubernetes Prod
├─ Secrets en Google Secret Manager
├─ Network Policies (firewall)
├─ RBAC + Service Accounts
├─ Pod Security Policies
├─ ETCD encryption
├─ Audit logging
├─ Backup/Restore automation
└─ Disaster recovery plan
```

---

## 📚 Próximo Paso

Selecciona tu ruta:

1. **Principiante**: [Cloud Run Manual](./cloudrun/README.md)
2. **Intermedio**: [Kubernetes Manual](./kubernetes/README.md)
3. **Avanzado**: [Azure Pipelines](./azure-pipelines/README.md)

---

**Última actualización**: Marzo 2026  
**Versión**: 1.0
