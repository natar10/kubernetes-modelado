

# REST API por Servicio

## 1. API Gateway
```
# Usuarios
GET    /api/users/*           → Subsistema Usuarios
PUT    /api/users/*           → Subsistema Usuarios

# Eventos
POST   /api/eventos           → Subsistema Eventos
GET    /api/eventos           → Subsistema Eventos
GET    /api/eventos/*         → Subsistema Eventos
PUT    /api/eventos/*         → Subsistema Eventos
DELETE /api/eventos/*         → Subsistema Eventos

# Participación
POST   /api/eventos/*/unirse     → Subsistema Participación
DELETE /api/eventos/*/abandonar  → Subsistema Participación
GET    /api/participacion/*      → Subsistema Participación

# Autenticación
POST   /auth/login            → Keycloak
POST   /auth/logout           → Keycloak
GET    /auth/me               → Keycloak (o Subsistema Usuarios)
```

## 2. Subsistema de Usuarios
```
GET    /api/users/{id}          → Obtener perfil de usuario
PUT    /api/users/{id}          → Actualizar perfil
GET    /api/users/{id}/eventos  → Eventos del usuario
GET    /api/users/tienda/{id}   → Usuarios de una tienda
POST   /api/users/sync          → Sincronizar con Keycloak (interno)
```

## 3. Subsistema de Eventos (ahora incluye moderación)
```
# Gestión de Eventos
POST   /api/eventos                    → Crear evento (casual u oficial)
GET    /api/eventos                    → Listar eventos (con filtros)
GET    /api/eventos/{id}               → Detalle de evento
PUT    /api/eventos/{id}               → Actualizar evento
DELETE /api/eventos/{id}               → Cancelar evento
GET    /api/eventos/feed               → Feed de eventos disponibles

# Moderación (solo responsables de tienda)
POST   /api/eventos/{id}/aprobar       → Aprobar evento
POST   /api/eventos/{id}/rechazar      → Rechazar evento
DELETE /api/eventos/{id}/moderar       → Eliminar evento por moderación
GET    /api/eventos/pendientes         → Eventos pendientes de aprobación
POST   /api/eventos/usuarios/{id}/ban  → Banear usuario de crear eventos
GET    /api/eventos/logs               → Registro de acciones
```

## 4. Subsistema de Participación
```
POST   /api/eventos/{id}/unirse        → Unirse a evento
DELETE /api/eventos/{id}/abandonar     → Abandonar evento
GET    /api/eventos/{id}/participantes → Lista de participantes
GET    /api/participacion/mis-eventos  → Eventos donde estoy inscrito
