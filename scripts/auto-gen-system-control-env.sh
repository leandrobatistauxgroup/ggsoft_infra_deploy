#!/bin/bash
# =============================================================================
# Gera .env do system-control com domínio HTTPS
# Uso: ./auto-gen-system-control-env.sh <dominio-base>
# Exemplo: ./auto-gen-system-control-env.sh ggsoft-tech.xyz
#   -> NGINX_PUBLIC_URL=https://games.ggsoft-tech.xyz
#      RGS_PUBLIC_URL=https://rgs.ggsoft-tech.xyz/
#      PAGE_URL=https://sc.ggsoft-tech.xyz/
# =============================================================================

set -e

# DOMINIO BASE (sem subdominio): o script prefixa games./rgs./sc. automaticamente.
# Passar "games.ggsoft-tech.xyz" geraria "games.games.ggsoft-tech.xyz" (errado).
DOMAIN="${1:-ggsoft-tech.xyz}"
SYSTEM_CONTROL_DIR="${2:-../ggsoft_system-control}"
ENV_FILE="$SYSTEM_CONTROL_DIR/.env"

echo "=== Gerando .env do system-control ==="
echo "Domínio: $DOMAIN"
echo ""

# Verifica se é domínio (contém letra) ou IP numérico
if echo "$DOMAIN" | grep -qE '[a-zA-Z]'; then
    echo "Detectado: DOMÍNIO (modo HTTPS)"
    
    # Gera URLs HTTPS a partir do domínio base
    cat > "$ENV_FILE" << EOF
# IP/Servidor (para referência interna)
SERVER_IP=$DOMAIN

# URLs externas HTTPS (geradas automaticamente do domínio)
NGINX_PUBLIC_URL=https://games.$DOMAIN
RGS_PUBLIC_URL=https://rgs.$DOMAIN/
PAGE_URL=https://sc.$DOMAIN/
EOF
    
    echo ""
    echo "✅ Gerado modo HTTPS:"
    grep -E "^(SERVER_IP|NGINX|RGS|PAGE)" "$ENV_FILE"
    
else
    echo "Detectado: IP numérico (modo HTTP porta)"
    
    cat > "$ENV_FILE" << EOF
# IP do servidor
SERVER_IP=$DOMAIN

# Modo IP:porta (sem NGINX_PUBLIC_URL definido = usa fallback)
# NGINX_PUBLIC_URL=http://${DOMAIN}:8001
# RGS_PUBLIC_URL=http://${DOMAIN}:43317/
# PAGE_URL=http://${DOMAIN}:2555/
EOF
    
    echo ""
    echo "✅ Gerado modo IP:porta:"
    echo "   SERVER_IP=$DOMAIN"
    echo "   (sem variáveis de URL = usa IP:porta)"
fi

echo ""
echo "Arquivo: $ENV_FILE"
echo ""
echo "Próximo passo:"
echo "   cd $SYSTEM_CONTROL_DIR && docker compose build --no-cache system-control"
