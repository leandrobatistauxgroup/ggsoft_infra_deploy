#!/bin/bash
# =============================================================================
# Sincroniza arquivos .env do deploy para todos os projetos
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENVS_DIR="${ENVS_DIR:-$SCRIPT_DIR/../envs}"
WORKSPACE_DIR="${WORKSPACE_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Sincronizando .env para todos os projetos ===${NC}"
echo ""

_copy() {
    local src="$1"
    local dest_dir="$2"
    local label="$3"
    if [ -f "$src" ]; then
        mkdir -p "$dest_dir"
        cp "$src" "$dest_dir/.env" && echo -e "   ${GREEN}✓${NC} $label" || echo -e "   ${RED}✗ falha ao copiar $label${NC}"
    else
        echo -e "   ${YELLOW}⚠ $(basename "$src") não encontrado — pulando $label${NC}"
    fi
}

_copy "$ENVS_DIR/mysql.env"        "$WORKSPACE_DIR/ggsoft_infra_mysql"    "mysql.env → ggsoft_infra_mysql/"
_copy "$ENVS_DIR/redis.env"        "$WORKSPACE_DIR/ggsoft_infra_redis"    "redis.env → ggsoft_infra_redis/"
_copy "$ENVS_DIR/wallet-auth.env"  "$WORKSPACE_DIR/ggsoft_wallet-auth"    "wallet-auth.env → ggsoft_wallet-auth/"
_copy "$ENVS_DIR/history.env"      "$WORKSPACE_DIR/ggsoft_history"        "history.env → ggsoft_history/"
_copy "$ENVS_DIR/rgs.env"          "$WORKSPACE_DIR/ggsoft_rgs_slot"       "rgs.env → ggsoft_rgs_slot/"
_copy "$ENVS_DIR/system-control.env" "$WORKSPACE_DIR/ggsoft_system-control" "system-control.env → ggsoft_system-control/"

# Math: valor fixo, sem arquivo de origem
mkdir -p "$WORKSPACE_DIR/ggsoft_math-3x3"
printf 'SERVER_PORT=49235\n' > "$WORKSPACE_DIR/ggsoft_math-3x3/.env" \
    && echo -e "   ${GREEN}✓${NC} math → ggsoft_math-3x3/" \
    || echo -e "   ${RED}✗ falha ao criar math .env${NC}"

# Valida SERVER_IP no system-control
if [ -f "$WORKSPACE_DIR/ggsoft_system-control/.env" ]; then
    server_ip=$(grep "^SERVER_IP=" "$WORKSPACE_DIR/ggsoft_system-control/.env" 2>/dev/null | cut -d'=' -f2 | head -1)
    if [ -z "$server_ip" ]; then
        echo -e "   ${RED}⚠️  SERVER_IP não encontrado em system-control.env${NC}"
    elif [ "$server_ip" = "localhost" ]; then
        echo -e "   ${YELLOW}⚠️  SERVER_IP=localhost — URLs dos jogos podem não funcionar externamente${NC}"
    else
        echo -e "   ${GREEN}✓ SERVER_IP configurado: $server_ip${NC}"
    fi
fi

echo ""
echo -e "${GREEN}=== Sincronização concluída! ===${NC}"
