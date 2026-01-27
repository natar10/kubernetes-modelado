#!/bin/sh
# =============================================================================
# Inyecta variables de entorno en el cliente React en runtime
# =============================================================================

# URL del API Gateway (default: http://api.eventos.local)
API_URL=${API_URL:-http://api.eventos.local}

# Crear archivo de configuración que React puede leer
cat > /usr/share/nginx/html/config.js << EOF
window.__API_URL__ = "${API_URL}";
EOF

# Inyectar script en index.html
sed -i 's|</head>|<script src="/config.js"></script></head>|' /usr/share/nginx/html/index.html

echo "Cliente configurado con API_URL=${API_URL}"

# Ejecutar comando original
exec "$@"
