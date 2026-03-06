#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════════
# Kubernetes Deployment Script - ambientacion-2
# ═══════════════════════════════════════════════════════════════════════════════

set -e

# ─────────────────────────────────────────────────────────────────────────────
# Configuration
# ─────────────────────────────────────────────────────────────────────────────

PROJECT_ID="${GCP_PROJECT_ID:-your-gcp-project}"
REGION="${GKE_REGION:-us-central1}"
ZONE="${GKE_ZONE:-us-central1-a}"
CLUSTER_NAME="${GKE_CLUSTER:-ambientacion2-cluster}"
NAMESPACE="ambientacion2"
DOCKER_REGISTRY="gcr.io"
SERVICE_BACKEND="ambientacion2-backend"
SERVICE_FRONTEND="ambientacion2-frontend"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ─────────────────────────────────────────────────────────────────────────────
# Functions
# ─────────────────────────────────────────────────────────────────────────────

print_header() {
    echo -e "\n${BLUE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC} $1"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}\n"
}

print_step() {
    echo -e "${YELLOW}→ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

check_prerequisites() {
    print_header "Verificando Requisitos Previos"

    local missing=0

    if ! command -v gcloud &> /dev/null; then
        print_error "gcloud CLI no está instalado"
        missing=1
    else
        print_success "gcloud CLI disponible"
    fi

    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl no está instalado"
        missing=1
    else
        print_success "kubectl disponible"
    fi

    if ! command -v docker &> /dev/null; then
        print_error "Docker no está instalado"
        missing=1
    else
        print_success "Docker disponible"
    fi

    if [[ $missing -eq 1 ]]; then
        exit 1
    fi

    if [[ "$PROJECT_ID" == "your-gcp-project" ]]; then
        print_error "GCP_PROJECT_ID no está configurado"
        echo "Ejecuta: export GCP_PROJECT_ID='your-actual-project'"
        exit 1
    fi
    print_success "PROJECT_ID: $PROJECT_ID"
}

enable_gcp_apis() {
    print_header "Habilitando APIs de GCP"

    print_step "Habilitando Kubernetes Engine API..."
    gcloud services enable container.googleapis.com --project=$PROJECT_ID

    print_step "Habilitando Container Registry..."
    gcloud services enable artifactregistry.googleapis.com --project=$PROJECT_ID

    print_step "Habilitando Cloud Build..."
    gcloud services enable cloudbuild.googleapis.com --project=$PROJECT_ID

    print_success "APIs habilitadas"
}

create_gke_cluster() {
    print_header "Creando Cluster GKE"

    # Verificar si el cluster ya existe
    if gcloud container clusters describe "$CLUSTER_NAME" \
        --zone="$ZONE" \
        --project="$PROJECT_ID" &> /dev/null; then
        print_success "Cluster '${CLUSTER_NAME}' ya existe"
        return
    fi

    print_step "Creando cluster GKE '${CLUSTER_NAME}'..."
    gcloud container clusters create "$CLUSTER_NAME" \
        --zone "$ZONE" \
        --project "$PROJECT_ID" \
        --num-nodes 2 \
        --machine-type n1-standard-2 \
        --enable-autoscaling \
        --min-nodes 1 \
        --max-nodes 10 \
        --enable-stackdriver-kubernetes \
        --enable-ip-alias \
        --network "default" \
        --cluster-secondary-range-name pods \
        --services-secondary-range-name services \
        --addons HorizontalPodAutoscaling,HttpLoadBalancing,GcePersistentDiskCsiDriver \
        --workload-pool="${PROJECT_ID}.svc.id.goog"

    print_success "Cluster creado exitosamente"
}

get_cluster_credentials() {
    print_header "Obteniendo Credenciales del Cluster"

    print_step "Configurando kubectl..."
    gcloud container clusters get-credentials "$CLUSTER_NAME" \
        --zone "$ZONE" \
        --project "$PROJECT_ID"

    print_success "kubectl configurado para el cluster"

    print_step "Verificando conexión..."
    kubectl cluster-info
}

configure_docker_auth() {
    print_header "Configurando Autenticación de Docker"

    print_step "Configurando Docker para GCR..."
    gcloud auth configure-docker gcr.io --quiet

    print_success "Docker configurado"
}

build_and_push_images() {
    print_header "Construyendo y Pusheando Imágenes"

    local root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"

    # Backend
    print_step "Construyendo imagen del Backend..."
    docker build \
        -t "${DOCKER_REGISTRY}/${PROJECT_ID}/${SERVICE_BACKEND}:latest" \
        -f "${root_dir}/app/backend/Dockerfile" \
        "${root_dir}/app/backend"

    print_step "Pusheando imagen del Backend..."
    docker push "${DOCKER_REGISTRY}/${PROJECT_ID}/${SERVICE_BACKEND}:latest"
    print_success "Backend: ${DOCKER_REGISTRY}/${PROJECT_ID}/${SERVICE_BACKEND}:latest"

    # Frontend
    print_step "Construyendo imagen del Frontend..."
    docker build \
        -t "${DOCKER_REGISTRY}/${PROJECT_ID}/${SERVICE_FRONTEND}:latest" \
        -f "${root_dir}/app/frontend/Dockerfile" \
        "${root_dir}/app/frontend"

    print_step "Pusheando imagen del Frontend..."
    docker push "${DOCKER_REGISTRY}/${PROJECT_ID}/${SERVICE_FRONTEND}:latest"
    print_success "Frontend: ${DOCKER_REGISTRY}/${PROJECT_ID}/${SERVICE_FRONTEND}:latest"
}

update_manifests() {
    print_header "Actualizando Manifests con Imágenes"

    local manifests_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/manifests" && pwd)"

    # Actualizar backend
    sed -i.bak "s|gcr.io/YOUR_PROJECT_ID/${SERVICE_BACKEND}:latest|${DOCKER_REGISTRY}/${PROJECT_ID}/${SERVICE_BACKEND}:latest|g" \
        "${manifests_dir}/backend/deployment.yaml"

    # Actualizar frontend
    sed -i.bak "s|gcr.io/YOUR_PROJECT_ID/${SERVICE_FRONTEND}:latest|${DOCKER_REGISTRY}/${PROJECT_ID}/${SERVICE_FRONTEND}:latest|g" \
        "${manifests_dir}/frontend/deployment.yaml"

    print_success "Manifests actualizados"
}

deploy_to_kubernetes() {
    print_header "Desplegando en Kubernetes"

    local manifests_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/manifests" && pwd)"

    print_step "Creando namespace..."
    kubectl apply -f "${manifests_dir}/namespace.yaml"

    print_step "Creando secretos y configuración..."
    kubectl apply -f "${manifests_dir}/secret.yaml"

    print_step "Desplegando PostgreSQL..."
    kubectl apply -f "${manifests_dir}/postgres/statefulset.yaml"

    print_step "Esperando a que PostgreSQL esté listo..."
    kubectl wait --for=condition=ready pod \
        -l app=postgres \
        -n $NAMESPACE \
        --timeout=300s 2>/dev/null || true

    sleep 10

    print_step "Desplegando Backend..."
    kubectl apply -f "${manifests_dir}/backend/deployment.yaml"

    print_step "Desplegando Frontend..."
    kubectl apply -f "${manifests_dir}/frontend/deployment.yaml"

    print_success "Recursos desplegados"
}

verify_deployment() {
    print_header "Verificando Despliegue"

    print_step "Esperando a que los deployments estén listos..."
    sleep 10

    # Verificar postgre
    print_step "Status de PostgreSQL:"
    kubectl get pods -n $NAMESPACE -l app=postgres

    print_step "Status del Backend:"
    kubectl get pods -n $NAMESPACE -l app=backend

    print_step "Status del Frontend:"
    kubectl get pods -n $NAMESPACE -l app=frontend

    print_step "Servicios disponibles:"
    kubectl get svc -n $NAMESPACE

    # Esperar a que los deployments estén listos
    print_step "Esperando deployments (esto puede tomar algunos minutos)..."
    kubectl rollout status deployment/backend -n $NAMESPACE --timeout=300s || true
    kubectl rollout status deployment/frontend -n $NAMESPACE --timeout=300s || true

    print_success "Despliegue verificado"
}

get_access_urls() {
    print_header "URLs de Acceso"

    print_step "Obteniendo IP del LoadBalancer del Frontend..."
    local frontend_ip=$(kubectl get svc frontend-service -n $NAMESPACE \
        -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "PENDING")

    echo ""
    echo -e "${GREEN}Frontend:${NC}"
    if [[ "$frontend_ip" == "PENDING" ]]; then
        echo "  Esperando asignación de IP (puede tardar 1-5 minutos)..."
        echo "  Ver estado: kubectl get svc -n $NAMESPACE -w"
    else
        echo "  URL: http://${frontend_ip}"
    fi

    echo ""
    echo -e "${GREEN}Backend (interno):${NC}"
    echo "  URL: http://backend:8001"
    echo "  Docs: http://backend:8001/docs"

    echo ""
    echo -e "${GREEN}Comandos útiles:${NC}"
    echo "  Ver lbses de Frontend:    kubectl logs -f -l app=frontend -n $NAMESPACE"
    echo "  Ver logs de Backend:      kubectl logs -f -l app=backend -n $NAMESPACE"
    echo "  Ver logs de PostgreSQL:   kubectl logs -f -l app=postgres -n $NAMESPACE"
    echo "  Port-forward al Backend:  kubectl port-forward svc/backend 8001:8001 -n $NAMESPACE"
    echo "  Port-forward al Frontend: kubectl port-forward svc/frontend-service 3000:3000 -n $NAMESPACE"
    echo "  Monitorear recursos:      kubectl top nodes && kubectl top pods -n $NAMESPACE"
}

# ─────────────────────────────────────────────────────────────────────────────
# Main Execution
# ─────────────────────────────────────────────────────────────────────────────

main() {
    echo -e "${BLUE}"
    cat << "EOF"
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║  Kubernetes Deployment Script - ambientacion-2                            ║
    ║  Deployed services: PostgreSQL + Backend + Frontend                       ║
    ║  Platform: Google Kubernetes Engine (GKE)                                 ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"

    check_prerequisites
    enable_gcp_apis
    create_gke_cluster
    get_cluster_credentials
    configure_docker_auth
    build_and_push_images
    update_manifests
    deploy_to_kubernetes
    verify_deployment
    get_access_urls

    print_header "Despliegue Completado ✓"
    echo -e "${GREEN}La aplicación está desplegada en Kubernetes${NC}\n"
}

# Error handler
trap 'print_error "Script interrupted"; exit 1' INT TERM

# Run main function
main "$@"
