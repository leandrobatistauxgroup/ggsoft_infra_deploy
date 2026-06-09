#!/bin/bash
# =============================================================================
# Sincroniza arquivos .env do deploy para todos os projetos
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENVS_DIR="${ENVS_DIR:-$SCRIPT_DIR/../envs}"
WORKSPACE_DIR="${WORKSPACE_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Sincronizando .env para todos os projetos ===${NC}"
echo ""

# MySQL
echo -e "${YELLOW}🗄️  MySQL → ggsoft_infra_mysql/${NC}"
mkdir -p "$WORKSPACE_DIR/ggsoft_infra_mysql"
cp "$ENVS_DIR/mysql.env" "$WORKSPACE_DIR/ggsoft_infra_mysql/.env"
echo -e "   ${GREEN}✓${NC} Copiado mysql.env"

# Redis
echo -e "${YELLOW}🔐 Redis → ggsoft_infra_redis/${NC}"
mkdir -p "$WORKSPACE_DIR/ggsoft_infra_redis"
cp "$ENVS_DIR/redis.env" "$WORKSPACE_DIR/ggsoft_infra_redis/.env"
echo -e "   ${GREEN}✓${NC} Copiado redis.env"

# Wallet-Auth (CS)
echo -e "${YELLOW}💰 Wallet-Auth (CS) → ggsoft_wallet-auth/${NC}"
mkdir -p "$WORKSPACE_DIR/ggsoft_wallet-auth"
cp "$ENVS_DIR/wallet-auth.env" "$WORKSPACE_DIR/ggsoft_wallet-auth/.env"
echo -e "   ${GREEN}✓${NC} Copiado wallet-auth.env"

# History
echo -e "${YELLOW}📜 History → ggsoft_history/${NC}"
mkdir -p "$WORKSPACE_DIR/ggsoft_history"
cp "$ENVS_DIR/history.env" "$WORKSPACE_DIR/ggsoft_history/.env"
echo -e "   ${GREEN}✓${NC} Copiado history.env"

# Math
echo -e "${YELLOW}🔢 Math → ggsoft_math_3x3/${NC}"
mkdir -p "$WORKSPACE_DIR/ggsoft_math_3x3"
cat > "$WORKSPACE_DIR/ggsoft_math_3x3/.env" << EOF
SERVER_PORT=49235
EOF
echo -e "   ${GREEN}✓${NC} Criado math.env (SERVER_PORT=49235)"

# RGS
echo -e "${YELLOW}🎮 RGS → ggsoft_rgs_3x3/${NC}"
mkdir -p "$WORKSPACE_DIR/ggsoft_rgs_3x3"
cp "$ENVS_DIR/rgs.env" "$WORKSPACE_DIR/ggsoft_rgs_3x3/.env"
echo -e "   ${GREEN}✓${NC} Copiado rgs.env"

# System-Control
echo -e "${YELLOW}🎛️  System-Control → ggsoft_system-control/${NC}"
mkdir -p "$WORKSPACE_DIR/ggsoft_system-control"
cp "$ENVS_DIR/system-control.env" "$WORKSPACE_DIR/ggsoft_system-control/.env"
echo -e "   ${GREEN}✓${NC} Copiado system-control.env"


# Nginx (não precisa de .env, config via docker-compose)
echo -e "${YELLOW}🌐 Nginx → sem .env (config via docker-compose)${NC}"

# Slot 3x3 (não precisa de .env, é só assets)
echo -e "${YELLOW}🎰 Slot 3x3 → sem .env (só assets)${NC}"

echo ""
echo -e "${GREEN}=== Sincronização concluída! ===${NC}"
echo ""
echo -e "${BLUE}Projetos configurados:${NC}"
echo "   • ggsoft_infra_mysql/.env"
echo "   • ggsoft_infra_redis/.env"
echo "   • ggsoft_wallet-auth/.env"
echo "   • ggsoft_history/.env"
echo "   • ggsoft_math_3x3/.env"
echo "   • ggsoft_rgs_3x3/.env"
echo "   • ggsoft_system-control/.env"
echo ""
echo -e "${YELLOW}Nota:${NC} Cada projeto agora pode ser rodado individualmente com 'make up'"
