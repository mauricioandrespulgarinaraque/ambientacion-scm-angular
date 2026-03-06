#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════════
# Cloud Run Deployment Script - ambientacion-2
# ═══════════════════════════════════════════════════════════════════════════════

set -e  # Exit on error

# ─────────────────────────────────────────────────────────────────────────────
# Configuration
# ─────────────────────────────────────────────────────────────────────────────

PROJECT_ID="${GCP_PROJECT_ID:-your-gcp-project}"
SERVICE_BACKEND="ambientacion2-backend"
SERVICE_FRONTEND="ambientacion2-frontend"
SERVICE_DB="ambientacion2-db"
REGION="${GCP_REGION:-us-central1}"
DOCKER_REGISTRY="gcr.io"
IMAGE_BACKEND="${DOCKER_REGISTRY}/${PROJECT_ID}/${SERVICE_BACKEND}"
IMAGE_FRONTEND="${DOCKER_REGISTRY}/${PROJECT_ID}/${SERVICE_FRONTEND}"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

    if ! command -v gcloud &> /dev/null; then
        print_error "gcloud CLI no está instalado"
        echo "Instálalo desde: https://cloud.google.com/sdk/docs/install"
        exit 1
    fi
    print_success "gcloud CLI disponible"

    if ! command -v docker &> /dev/null; then
        print_error "Docker no está instalado"
        echo "Instálalo desde: https://www.docker.com/products/docker-desktop"
        exit 1
    fi
    print_success "Docker disponible"

    # Verificar autenticación
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" &> /dev/null; then
        print_error "No hay sesión activa de gcloud"
        echo "Ejecuta: gcloud auth login"
        exit 1
    fi
    print_success "Usuario autenticado en gcloud"

    # Verificar que PROJECT_ID esté configurado
    if [[ "$PROJECT_ID" == "your-gcp-project" ]]; then
        print_error "PROJECT_ID no está configurado"
        echo "Usa: export GCP_PROJECT_ID='your-actual-project'"
        exit 1
    fi
    print_success "PROJECT_ID: $PROJECT_ID"
}

enable_gcp_apis() {
    print_header "Habilitando APIs de GCP"

    print_step "Habilitando Cloud Run API..."
    gcloud services enable run.googleapis.com --project=$PROJECT_ID

    print_step "Habilitando Container Registry API..."
    gcloud services enable artifactregistry.googleapis.com --project=$PROJECT_ID

    print_step "Habilitando Cloud Build API..."
    gcloud services enable cloudbuild.googleapis.com --project=$PROJECT_ID

    print_step "Habilitando Cloud SQL Admin API..."
    gcloud services enable sqladmin.googleapis.com --project=$PROJECT_ID

    print_success "APIs habilitadas"
}

build_and_push_images() {
    print_header "Construyendo y Pusheando Imágenes Docker"

    local root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"

    # Backend
    print_step "Construyendo imagen del Backend..."
    docker build \
        -t "${IMAGE_BACKEND}:latest" \
        -f "${root_dir}/app/backend/Dockerfile" \
        "${root_dir}/app/backend"

    print_step "Pusheando imagen del Backend..."
    docker push "${IMAGE_BACKEND}:latest"
    print_success "Backend pusheado: ${IMAGE_BACKEND}:latest"

    # Frontend
    print_step "Construyendo imagen del Frontend..."
    docker build \
        -t "${IMAGE_FRONTEND}:latest" \
        -f "${root_dir}/app/frontend/Dockerfile" \
        "${root_dir}/app/frontend"

    print_step "Pusheando imagen del Frontend..."
    docker push "${IMAGE_FRONTEND}:latest"
    print_success "Frontend pusheado: ${IMAGE_FRONTEND}:latest"
}

deploy_backend() {
    print_header "Desplegando Backend en Cloud Run"

    print_step "Obteniendo URL del Backend anterior (si existe)..."
    local backend_url=$(gcloud run services describe "${SERVICE_BACKEND}" \
        --region="${REGION}" \
        --format='value(status.url)' 2>/dev/null || echo "")

    # Leer variables de entorno desde archivo .env si existe
    local db_url=${DATABASE_URL:-"postgresql://admin:password@cloudsql-proxy:5432/ambientacion2"}

    print_step "Desplegando servicio Backend..."
    gcloud run deploy "${SERVICE_BACKEND}" \
        --image="${IMAGE_BACKEND}:latest" \
        --platform=managed \
        --region="${REGION}" \
        --allow-unauthenticated \
        --set-env-vars="DATABASE_URL=${db_url},CORS_ORIGINS=https://*" \
        --memory=1Gi \
        --cpu=2 \
        --timeout=3600 \
        --max-instances=100 \
        --min-instances=1 \
        --project="${PROJECT_ID}"

    # Obtener URL del servicio
    local backend_service_url=$(gcloud run services describe "${SERVICE_BACKEND}" \
        --region="${REGION}" \
        --format='value(status.url)' \
        --project="${PROJECT_ID}")

    print_success "Backend desplegado: ${backend_service_url}"
    echo "export BACKEND_URL='${backend_service_url}'" >> /tmp/deployment_vars.env
}

deploy_frontend() {
    print_header "Desplegando Frontend en Cloud Run"

    # Leer URL del backend del archivo anterior
    if [[ -f /tmp/deployment_vars.env ]]; then
        source /tmp/deployment_vars.env
    fi

    print_step "Desplegando servicio Frontend..."
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

    # Obtener URL del servicio
    local frontend_service_url=$(gcloud run services describe "${SERVICE_FRONTEND}" \
        --region="${REGION}" \
        --format='value(status.url)' \
        --project="${PROJECT_ID}")

    print_success "Frontend desplegado: ${frontend_service_url}"
    echo "export FRONTEND_URL='${frontend_service_url}'" >> /tmp/deployment_vars.env
}

validate_deployment() {
    print_header "Validando Despliegue"

    if [[ ! -f /tmp/deployment_vars.env ]]; then
        print_error "No se encontró archivo de variables"
        return 1
    fi

    source /tmp/deployment_vars.env

    print_step "Testing Backend API..."
    local backend_status=$(curl -s -o /dev/null -w "%{http_code}" "${BACKEND_URL}/api/templates")
    if [[ "$backend_status" == "200" ]]; then
        print_success "Backend responde correctamente (HTTP $backend_status)"
    else
        print_error "Backend retorna HTTP $backend_status"
        return 1
    fi

    print_step "Testing Frontend..."
    local frontend_status=$(curl -s -o /dev/null -w "%{http_code}" "${FRONTEND_URL}")
    if [[ "$frontend_status" == "200" ]]; then
        print_success "Frontend carga correctamente (HTTP $frontend_status)"
    else
        print_error "Frontend retorna HTTP $frontend_status"
        return 1
    fi

    print_success "Despliegue validado"
}

show_summary() {
    print_header "Resumen del Despliegue"

    if [[ -f /tmp/deployment_vars.env ]]; then
        source /tmp/deployment_vars.env
        echo -e "${GREEN}Servicio Backend:${NC}"
        echo "  URL: ${BACKEND_URL}"
        echo "  API Docs: ${BACKEND_URL}/docs"
        echo ""
        echo -e "${GREEN}Servicio Frontend:${NC}"
        echo "  URL: ${FRONTEND_URL}"
        echo ""
        echo -e "${GREEN}Comandos útiles:${NC}"
        echo "  Ver logs backend:   gcloud run logs read ${SERVICE_BACKEND} --region=${REGION} --limit=50"
        echo "  Ver logs frontend:  gcloud run logs read ${SERVICE_FRONTEND} --region=${REGION} --limit=50"
        echo "  Ver detalles:       gcloud run services describe ${SERVICE_BACKEND} --region=${REGION}"
        echo "  Escalar:            gcloud run deploy ${SERVICE_BACKEND} --min-instances=2 --region=${REGION}"
        echo ""
    fi
}

cleanup() {
    print_step "Limpiando archivos temporales..."
    rm -f /tmp/deployment_vars.env
}

# ─────────────────────────────────────────────────────────────────────────────
# Main Execution
# ─────────────────────────────────────────────────────────────────────────────

main() {
    echo -e "${BLUE}"
    cat << "EOF"
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║  Cloud Run Deployment Script - ambientacion-2                             ║
    ║  Deployed services: Backend + Frontend + Database                          ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"

    check_prerequisites
    enable_gcp_apis
    build_and_push_images
    deploy_backend
    deploy_frontend
    validate_deployment
    show_summary
    cleanup

    print_header "Despliegue Completado ✓"
    echo -e "${GREEN}La aplicación está lista en Cloud Run${NC}\n"
}

# Error handler
trap 'print_error "Script interrupted"; exit 1' INT TERM

# Run main function
main "$@"
