#!/bin/bash
# =============================================================================
# SCRIPT DE DESPLIEGUE - Cluster Kubernetes Eventos Platform
# =============================================================================
# Este script despliega todos los componentes del sistema en orden correcto
# Uso: ./deploy.sh [apply|delete|status]
# =============================================================================

set -e

NAMESPACE="eventos-system"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "\n${BLUE}============================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}============================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Verificar que kubectl está disponible
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl no está instalado o no está en el PATH"
        exit 1
    fi
    print_success "kubectl encontrado"
}

# Verificar conexión al cluster
check_cluster() {
    if ! kubectl cluster-info &> /dev/null; then
        print_error "No se puede conectar al cluster de Kubernetes"
        exit 1
    fi
    print_success "Conexión al cluster establecida"
}

# Aplicar manifiestos
apply_manifests() {
    print_header "DESPLEGANDO EVENTOS PLATFORM"

    check_kubectl
    check_cluster

    # 1. Namespace
    print_header "1. Creando Namespace"
    kubectl apply -f "$SCRIPT_DIR/namespace.yaml"
    print_success "Namespace '$NAMESPACE' creado"

    # 2. Secrets y ConfigMaps
    print_header "2. Aplicando Secrets y ConfigMaps"
    kubectl apply -f "$SCRIPT_DIR/configmaps/"
    print_success "Secrets y ConfigMaps aplicados"

    # 3. Bases de datos
    print_header "3. Desplegando Bases de Datos"
    kubectl apply -f "$SCRIPT_DIR/databases/"
    print_success "Bases de datos desplegadas"

    echo "Esperando a que las bases de datos estén listas..."
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/component=database -n $NAMESPACE --timeout=120s || true
    print_success "Bases de datos listas"

    # 4. Servicios de aplicación (incluye Keycloak)
    print_header "4. Desplegando Servicios de Aplicación"
    kubectl apply -f "$SCRIPT_DIR/services/"
    print_success "Servicios desplegados"

    echo "Esperando a que los servicios estén listos..."
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/component=application -n $NAMESPACE --timeout=180s || true
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/component=identity -n $NAMESPACE --timeout=180s || true
    print_success "Servicios listos"

    # 5. Ingress
    print_header "5. Configurando Ingress"
    kubectl apply -f "$SCRIPT_DIR/ingress/"
    print_success "Ingress configurado"

    print_header "DESPLIEGUE COMPLETADO"
    echo -e "\nPara verificar el estado: ${YELLOW}./deploy.sh status${NC}"
    echo -e "Para acceder a los servicios, añade a /etc/hosts:"
    echo -e "  ${YELLOW}127.0.0.1 api.eventos.local keycloak.eventos.local${NC}"
}

# Eliminar todos los recursos
delete_manifests() {
    print_header "ELIMINANDO EVENTOS PLATFORM"

    check_kubectl
    check_cluster

    print_warning "¿Estás seguro de que quieres eliminar todos los recursos? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "Operación cancelada"
        exit 0
    fi

    echo "Eliminando recursos..."
    kubectl delete -f "$SCRIPT_DIR/ingress/" --ignore-not-found
    kubectl delete -f "$SCRIPT_DIR/services/" --ignore-not-found
    kubectl delete -f "$SCRIPT_DIR/databases/" --ignore-not-found
    kubectl delete -f "$SCRIPT_DIR/configmaps/" --ignore-not-found
    kubectl delete -f "$SCRIPT_DIR/namespace.yaml" --ignore-not-found

    print_success "Todos los recursos eliminados"
}

# Mostrar estado
show_status() {
    print_header "ESTADO DEL CLUSTER - EVENTOS PLATFORM"

    check_kubectl
    check_cluster

    echo -e "\n${YELLOW}Namespace:${NC}"
    kubectl get namespace $NAMESPACE 2>/dev/null || echo "Namespace no existe"

    echo -e "\n${YELLOW}Pods:${NC}"
    kubectl get pods -n $NAMESPACE -o wide 2>/dev/null || echo "No hay pods"

    echo -e "\n${YELLOW}Services:${NC}"
    kubectl get services -n $NAMESPACE 2>/dev/null || echo "No hay services"

    echo -e "\n${YELLOW}Ingress:${NC}"
    kubectl get ingress -n $NAMESPACE 2>/dev/null || echo "No hay ingress"

    echo -e "\n${YELLOW}PersistentVolumeClaims:${NC}"
    kubectl get pvc -n $NAMESPACE 2>/dev/null || echo "No hay PVCs"

    echo -e "\n${YELLOW}Eventos recientes:${NC}"
    kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp' 2>/dev/null | tail -10 || echo "No hay eventos"
}

# Logs de un servicio
show_logs() {
    local service=$1
    if [ -z "$service" ]; then
        echo "Uso: ./deploy.sh logs <nombre-servicio>"
        echo "Servicios disponibles: usuarios-service, eventos-service, participacion-service, keycloak"
        exit 1
    fi
    kubectl logs -l app=$service -n $NAMESPACE --tail=100 -f
}

# Ayuda
show_help() {
    echo "Uso: ./deploy.sh [comando]"
    echo ""
    echo "Comandos disponibles:"
    echo "  apply   - Despliega todos los recursos"
    echo "  delete  - Elimina todos los recursos"
    echo "  status  - Muestra el estado del cluster"
    echo "  logs    - Muestra logs de un servicio (ej: ./deploy.sh logs keycloak)"
    echo "  help    - Muestra esta ayuda"
}

# Main
case "${1:-apply}" in
    apply)
        apply_manifests
        ;;
    delete)
        delete_manifests
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs "$2"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Comando desconocido: $1"
        show_help
        exit 1
        ;;
esac
