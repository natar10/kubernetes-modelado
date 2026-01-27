# Cluster Kubernetes - Plataforma de Eventos

Este directorio contiene todos los manifiestos de Kubernetes necesarios para desplegar la **Plataforma de Gestión de Eventos** como un sistema distribuido.

## Arquitectura del Sistema

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              INGRESS LAYER                                   │
│                     (Expuesto Públicamente vía LoadBalancer)                 │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                         NGINX Ingress Controller                      │    │
│  │   api.eventos.local          keycloak.eventos.local                   │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                    ┌─────────────────┼─────────────────┐
                    ▼                 ▼                 ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        APPLICATION SERVICES (ClusterIP)                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │   Usuarios   │  │   Eventos    │  │Participación │  │   Keycloak   │    │
│  │   Service    │  │   Service    │  │   Service    │  │    (IdP)     │    │
│  │   :8080      │  │   :8080      │  │   :8080      │  │   :8080      │    │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘    │
└─────────┼─────────────────┼─────────────────┼─────────────────┼────────────┘
          │                 │                 │                 │
          ▼                 ▼                 ▼                 ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        DATABASE LAYER (ClusterIP)                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │ PostgreSQL   │  │ PostgreSQL   │  │ PostgreSQL   │  │ PostgreSQL   │    │
│  │  Usuarios    │  │   Eventos    │  │Participación │  │  Keycloak    │    │
│  │   :5432      │  │   :5432      │  │   :5432      │  │   :5432      │    │
│  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘    │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Estructura de Directorios

```
k8s/
├── namespace.yaml              # Namespace del sistema
├── deploy.sh                   # Script de despliegue (Linux/Mac)
├── deploy.ps1                  # Script de despliegue (Windows)
├── README.md                   # Esta documentación
│
├── configmaps/
│   ├── secrets.yaml            # Secrets para credenciales
│   └── api-gateway-config.yaml # ConfigMap y NetworkPolicies
│
├── databases/
│   ├── postgres-usuarios.yaml      # BD para Subsistema Usuarios
│   ├── postgres-eventos.yaml       # BD para Subsistema Eventos
│   ├── postgres-participacion.yaml # BD para Subsistema Participación
│   └── postgres-keycloak.yaml      # BD para Keycloak
│
├── services/
│   ├── keycloak.yaml               # Identity Provider (OAuth2/OIDC)
│   ├── usuarios-service.yaml       # Microservicio de Usuarios
│   ├── eventos-service.yaml        # Microservicio de Eventos
│   └── participacion-service.yaml  # Microservicio de Participación
│
└── ingress/
    └── ingress.yaml            # Ingress rules y API Gateway
```

## Requisitos Previos

### Software Necesario

1. **Kubernetes Cluster** (una de las siguientes opciones):
   - [Minikube](https://minikube.sigs.k8s.io/) (recomendado para desarrollo local)
   - [Docker Desktop con Kubernetes](https://docs.docker.com/desktop/kubernetes/)
   - [Kind](https://kind.sigs.k8s.io/)
   - [K3s](https://k3s.io/)

2. **kubectl** - CLI de Kubernetes
   ```bash
   # Verificar instalación
   kubectl version --client
   ```

3. **NGINX Ingress Controller**
   ```bash
   # Instalar en Minikube
   minikube addons enable ingress

   # O instalar manualmente
   kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.4/deploy/static/provider/cloud/deploy.yaml
   ```

### Recursos Mínimos del Cluster

| Recurso | Mínimo Recomendado |
|---------|-------------------|
| CPU     | 4 cores           |
| RAM     | 8 GB              |
| Disco   | 20 GB             |

## Despliegue Rápido

### Linux/Mac

```bash
# Dar permisos de ejecución
chmod +x deploy.sh

# Desplegar todo el sistema
./deploy.sh apply

# Ver estado
./deploy.sh status

# Ver logs de un servicio
./deploy.sh logs keycloak
```

### Windows (PowerShell)

```powershell
# Desplegar todo el sistema
.\deploy.ps1 -Action apply

# Ver estado
.\deploy.ps1 -Action status

# Ver logs de un servicio
.\deploy.ps1 -Action logs -ServiceName keycloak
```

### Despliegue Manual (paso a paso)

```bash
# 1. Crear namespace
kubectl apply -f namespace.yaml

# 2. Crear secrets y configmaps
kubectl apply -f configmaps/

# 3. Desplegar bases de datos
kubectl apply -f databases/

# 4. Esperar a que las BDs estén listas
kubectl wait --for=condition=ready pod -l app.kubernetes.io/component=database -n eventos-system --timeout=120s

# 5. Desplegar servicios
kubectl apply -f services/

# 6. Configurar Ingress
kubectl apply -f ingress/
```

## Acceso a los Servicios

### Configurar hosts locales

Añadir al archivo hosts:

**Linux/Mac:** `/etc/hosts`
**Windows:** `C:\Windows\System32\drivers\etc\hosts`

```
127.0.0.1 api.eventos.local keycloak.eventos.local
```

### URLs de Acceso

| Servicio | URL | Descripción |
|----------|-----|-------------|
| API Gateway | http://api.eventos.local | Punto de entrada principal |
| Keycloak Admin | http://keycloak.eventos.local | Consola de administración |

### Endpoints de la API

```bash
# Autenticación
POST   http://api.eventos.local/auth/login
POST   http://api.eventos.local/auth/logout

# Usuarios
GET    http://api.eventos.local/api/users/{id}
PUT    http://api.eventos.local/api/users/{id}

# Eventos
POST   http://api.eventos.local/api/eventos
GET    http://api.eventos.local/api/eventos
GET    http://api.eventos.local/api/eventos/{id}
PUT    http://api.eventos.local/api/eventos/{id}
DELETE http://api.eventos.local/api/eventos/{id}

# Participación
POST   http://api.eventos.local/api/eventos/{id}/unirse
DELETE http://api.eventos.local/api/eventos/{id}/abandonar
GET    http://api.eventos.local/api/participacion/mis-eventos
```

### Acceso con Minikube

```bash
# Obtener IP de Minikube
minikube ip

# O usar tunnel para acceder vía localhost
minikube tunnel
```

### Port-Forward (alternativa sin Ingress)

```bash
# Acceder a Keycloak directamente
kubectl port-forward svc/keycloak 8080:8080 -n eventos-system

# Acceder a un servicio específico
kubectl port-forward svc/eventos-service 8081:8080 -n eventos-system
```

## Comandos Útiles

### Monitorización

```bash
# Ver todos los recursos del namespace
kubectl get all -n eventos-system

# Ver pods con más detalle
kubectl get pods -n eventos-system -o wide

# Describir un pod específico
kubectl describe pod <nombre-pod> -n eventos-system

# Ver logs de un pod
kubectl logs <nombre-pod> -n eventos-system

# Logs en tiempo real
kubectl logs -f <nombre-pod> -n eventos-system

# Ver eventos del namespace
kubectl get events -n eventos-system --sort-by='.lastTimestamp'
```

### Debugging

```bash
# Ejecutar shell en un pod
kubectl exec -it <nombre-pod> -n eventos-system -- /bin/sh

# Verificar conectividad entre servicios
kubectl run test-pod --rm -it --image=busybox -n eventos-system -- wget -qO- http://eventos-service:8080/health

# Verificar DNS interno
kubectl run test-dns --rm -it --image=busybox -n eventos-system -- nslookup keycloak.eventos-system.svc.cluster.local

# Ver configuración de un servicio
kubectl get svc eventos-service -n eventos-system -o yaml
```

### Escalado

```bash
# Escalar un deployment
kubectl scale deployment eventos-service --replicas=3 -n eventos-system

# Ver el estado del escalado
kubectl get deployment eventos-service -n eventos-system
```

## Componentes Detallados

### 1. Namespace (`eventos-system`)

Aislamiento lógico de todos los recursos del sistema. Facilita:
- Gestión de recursos (ResourceQuotas)
- Control de acceso (RBAC)
- Limpieza del entorno

### 2. Bases de Datos (PostgreSQL 15)

Cada microservicio tiene su propia base de datos para garantizar el aislamiento de datos:

| Base de Datos | Servicio | Puerto |
|---------------|----------|--------|
| db-usuarios | usuarios-service | 5432 |
| db-eventos | eventos-service | 5432 |
| db-participacion | participacion-service | 5432 |
| db-keycloak | keycloak | 5432 |

**Características:**
- PersistentVolumeClaims para persistencia
- Health checks (liveness/readiness probes)
- Secrets para credenciales

### 3. Keycloak (Identity Provider)

- **Versión:** 23.0
- **Función:** OAuth2/OIDC provider
- **Modo:** Development (start-dev)

**Configuración inicial:**
1. Acceder a http://keycloak.eventos.local
2. Login: admin / admin_password_dev
3. Crear Realm "eventos"
4. Configurar clients para cada servicio

### 4. Microservicios

**Implementación actual (prototipo):**
- Nginx como mock server
- Respuestas JSON simuladas
- Health checks funcionales

**Para producción:**
- Reemplazar imagen nginx por la aplicación real
- Configurar variables de entorno según el framework
- Implementar lógica de negocio

### 5. Ingress (API Gateway)

**Funcionalidades:**
- Enrutamiento basado en paths
- CORS habilitado
- Rate limiting básico (100 rps)
- Proxy timeouts configurados

**Rutas configuradas:**
```
/auth/*              → keycloak:8080
/api/users/*         → usuarios-service:8080
/api/eventos/*       → eventos-service:8080
/api/participacion/* → participacion-service:8080
```

### 6. NetworkPolicies

Políticas de red que restringen la comunicación entre pods:
- Los servicios solo pueden acceder a sus bases de datos
- Solo el Ingress puede acceder a los servicios de aplicación
- Comunicación permitida entre participacion-service y eventos-service

## Seguridad

### Credenciales por Defecto (SOLO DESARROLLO)

| Componente | Usuario | Contraseña |
|------------|---------|------------|
| Keycloak Admin | admin | admin_password_dev |
| DB Usuarios | usuarios_user | usuarios_password_dev |
| DB Eventos | eventos_user | eventos_password_dev |
| DB Participación | participacion_user | participacion_password_dev |
| DB Keycloak | keycloak_user | keycloak_password_dev |

> **IMPORTANTE:** Cambiar todas las credenciales antes de usar en producción.

### Recomendaciones de Producción

1. **Secrets:**
   - Usar Kubernetes Secrets con cifrado en reposo
   - Considerar HashiCorp Vault o soluciones cloud-native

2. **TLS:**
   - Habilitar HTTPS en Ingress con cert-manager
   - Usar Let's Encrypt para certificados

3. **RBAC:**
   - Configurar ServiceAccounts específicos
   - Limitar permisos según el principio de mínimo privilegio

## Troubleshooting

### Pod en estado CrashLoopBackOff

```bash
# Ver logs del pod
kubectl logs <pod-name> -n eventos-system

# Ver logs del contenedor anterior
kubectl logs <pod-name> -n eventos-system --previous

# Describir el pod para ver eventos
kubectl describe pod <pod-name> -n eventos-system
```

### Pod en estado Pending

```bash
# Verificar recursos disponibles
kubectl describe node

# Verificar PVC si usa volúmenes
kubectl get pvc -n eventos-system
kubectl describe pvc <pvc-name> -n eventos-system
```

### Servicio no accesible

```bash
# Verificar endpoints del servicio
kubectl get endpoints <service-name> -n eventos-system

# Verificar que los pods están Ready
kubectl get pods -l app=<app-label> -n eventos-system

# Probar conectividad interna
kubectl run debug --rm -it --image=busybox -n eventos-system -- wget -qO- http://<service-name>:8080/health
```

### Ingress no funciona

```bash
# Verificar estado del Ingress Controller
kubectl get pods -n ingress-nginx

# Ver logs del Ingress Controller
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx

# Verificar reglas del Ingress
kubectl describe ingress api-gateway -n eventos-system
```

## Limpieza

```bash
# Eliminar todos los recursos
./deploy.sh delete   # Linux/Mac
.\deploy.ps1 -Action delete   # Windows

# O manualmente
kubectl delete namespace eventos-system
```

## Referencias

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
- [Keycloak Documentation](https://www.keycloak.org/documentation)
- [PostgreSQL Docker Image](https://hub.docker.com/_/postgres)

---

**Versión:** 1.0.0-prototype
**Última actualización:** Enero 2026
**Contexto:** Práctica académica - Sistemas Distribuidos UVA
