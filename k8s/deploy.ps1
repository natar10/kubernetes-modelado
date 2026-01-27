# =============================================================================
# SCRIPT DE DESPLIEGUE - Cluster Kubernetes Eventos Platform (PowerShell)
# =============================================================================
# Este script despliega todos los componentes del sistema en orden correcto
# Uso: .\deploy.ps1 [-Action apply|delete|status]
# =============================================================================

param(
    [Parameter(Position=0)]
    [ValidateSet("apply", "delete", "status", "logs", "help")]
    [string]$Action = "apply",

    [Parameter(Position=1)]
    [string]$ServiceName
)

$NAMESPACE = "eventos-system"
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path

function Write-Header {
    param([string]$Message)
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Blue
    Write-Host $Message -ForegroundColor Blue
    Write-Host "============================================" -ForegroundColor Blue
    Write-Host ""
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[!] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[X] $Message" -ForegroundColor Red
}

function Test-Kubectl {
    try {
        $null = kubectl version --client 2>&1
        Write-Success "kubectl encontrado"
        return $true
    }
    catch {
        Write-Error "kubectl no esta instalado o no esta en el PATH"
        return $false
    }
}

function Test-Cluster {
    try {
        $null = kubectl cluster-info 2>&1
        Write-Success "Conexion al cluster establecida"
        return $true
    }
    catch {
        Write-Error "No se puede conectar al cluster de Kubernetes"
        return $false
    }
}

function Invoke-Apply {
    Write-Header "DESPLEGANDO EVENTOS PLATFORM"

    if (-not (Test-Kubectl)) { exit 1 }
    if (-not (Test-Cluster)) { exit 1 }

    # 1. Namespace
    Write-Header "1. Creando Namespace"
    kubectl apply -f "$SCRIPT_DIR\namespace.yaml"
    Write-Success "Namespace '$NAMESPACE' creado"

    # 2. Secrets y ConfigMaps
    Write-Header "2. Aplicando Secrets y ConfigMaps"
    kubectl apply -f "$SCRIPT_DIR\configmaps\"
    Write-Success "Secrets y ConfigMaps aplicados"

    # 3. Bases de datos
    Write-Header "3. Desplegando Bases de Datos"
    kubectl apply -f "$SCRIPT_DIR\databases\"
    Write-Success "Bases de datos desplegadas"

    Write-Host "Esperando a que las bases de datos esten listas..."
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/component=database -n $NAMESPACE --timeout=120s 2>$null
    Write-Success "Bases de datos listas"

    # 4. Servicios de aplicacion (incluye Keycloak)
    Write-Header "4. Desplegando Servicios de Aplicacion"
    kubectl apply -f "$SCRIPT_DIR\services\"
    Write-Success "Servicios desplegados"

    Write-Host "Esperando a que los servicios esten listos..."
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/component=application -n $NAMESPACE --timeout=180s 2>$null
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/component=identity -n $NAMESPACE --timeout=180s 2>$null
    Write-Success "Servicios listos"

    # 5. Ingress
    Write-Header "5. Configurando Ingress"
    kubectl apply -f "$SCRIPT_DIR\ingress\"
    Write-Success "Ingress configurado"

    Write-Header "DESPLIEGUE COMPLETADO"
    Write-Host ""
    Write-Host "Para verificar el estado: " -NoNewline
    Write-Host ".\deploy.ps1 -Action status" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Para acceder a los servicios, añade a C:\Windows\System32\drivers\etc\hosts:"
    Write-Host "  127.0.0.1 api.eventos.local keycloak.eventos.local" -ForegroundColor Yellow
}

function Invoke-Delete {
    Write-Header "ELIMINANDO EVENTOS PLATFORM"

    if (-not (Test-Kubectl)) { exit 1 }
    if (-not (Test-Cluster)) { exit 1 }

    $response = Read-Host "Estas seguro de que quieres eliminar todos los recursos? (y/N)"
    if ($response -ne "y" -and $response -ne "Y") {
        Write-Host "Operacion cancelada"
        exit 0
    }

    Write-Host "Eliminando recursos..."
    kubectl delete -f "$SCRIPT_DIR\ingress\" --ignore-not-found 2>$null
    kubectl delete -f "$SCRIPT_DIR\services\" --ignore-not-found 2>$null
    kubectl delete -f "$SCRIPT_DIR\databases\" --ignore-not-found 2>$null
    kubectl delete -f "$SCRIPT_DIR\configmaps\" --ignore-not-found 2>$null
    kubectl delete -f "$SCRIPT_DIR\namespace.yaml" --ignore-not-found 2>$null

    Write-Success "Todos los recursos eliminados"
}

function Show-Status {
    Write-Header "ESTADO DEL CLUSTER - EVENTOS PLATFORM"

    if (-not (Test-Kubectl)) { exit 1 }
    if (-not (Test-Cluster)) { exit 1 }

    Write-Host "`nNamespace:" -ForegroundColor Yellow
    kubectl get namespace $NAMESPACE 2>$null
    if ($LASTEXITCODE -ne 0) { Write-Host "Namespace no existe" }

    Write-Host "`nPods:" -ForegroundColor Yellow
    kubectl get pods -n $NAMESPACE -o wide 2>$null
    if ($LASTEXITCODE -ne 0) { Write-Host "No hay pods" }

    Write-Host "`nServices:" -ForegroundColor Yellow
    kubectl get services -n $NAMESPACE 2>$null
    if ($LASTEXITCODE -ne 0) { Write-Host "No hay services" }

    Write-Host "`nIngress:" -ForegroundColor Yellow
    kubectl get ingress -n $NAMESPACE 2>$null
    if ($LASTEXITCODE -ne 0) { Write-Host "No hay ingress" }

    Write-Host "`nPersistentVolumeClaims:" -ForegroundColor Yellow
    kubectl get pvc -n $NAMESPACE 2>$null
    if ($LASTEXITCODE -ne 0) { Write-Host "No hay PVCs" }

    Write-Host "`nEventos recientes:" -ForegroundColor Yellow
    kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp' 2>$null | Select-Object -Last 10
}

function Show-Logs {
    param([string]$Service)

    if ([string]::IsNullOrEmpty($Service)) {
        Write-Host "Uso: .\deploy.ps1 -Action logs -ServiceName <nombre-servicio>"
        Write-Host "Servicios disponibles: usuarios-service, eventos-service, participacion-service, keycloak"
        exit 1
    }
    kubectl logs -l app=$Service -n $NAMESPACE --tail=100 -f
}

function Show-Help {
    Write-Host "Uso: .\deploy.ps1 [-Action comando]"
    Write-Host ""
    Write-Host "Comandos disponibles:"
    Write-Host "  apply   - Despliega todos los recursos"
    Write-Host "  delete  - Elimina todos los recursos"
    Write-Host "  status  - Muestra el estado del cluster"
    Write-Host "  logs    - Muestra logs de un servicio (ej: .\deploy.ps1 -Action logs -ServiceName keycloak)"
    Write-Host "  help    - Muestra esta ayuda"
}

# Main
switch ($Action) {
    "apply" { Invoke-Apply }
    "delete" { Invoke-Delete }
    "status" { Show-Status }
    "logs" { Show-Logs -Service $ServiceName }
    "help" { Show-Help }
    default {
        Write-Error "Comando desconocido: $Action"
        Show-Help
        exit 1
    }
}
