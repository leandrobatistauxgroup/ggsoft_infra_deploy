#!/bin/bash
# =============================================================================
# Atualiza URLs no banco MySQL para usar domínios HTTPS
# Lê configuração do .env do system-control ou de variáveis de ambiente
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEPLOY_DIR="$(dirname "$SCRIPT_DIR")"

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=== Atualizando URLs no banco MySQL ===${NC}"
echo ""

# Verificar se está no diretório correto
if [ ! -f "$DEPLOY_DIR/docker-compose.yml" ]; then
    echo -e "${RED}❌ Execute do diretório ggsoft_infra_deploy${NC}"
    exit 1
fi

# Carregar variáveis do .env do system-control se existir
SYSTEM_CONTROL_ENV="$DEPLOY_DIR/../ggsoft_system-control/.env"
if [ -f "$SYSTEM_CONTROL_ENV" ]; then
    echo "📄 Carregando variáveis de: $SYSTEM_CONTROL_ENV"
    export $(grep -E '^(SERVER_IP|NGINX_PUBLIC_URL|RGS_PUBLIC_URL|PAGE_URL)=' "$SYSTEM_CONTROL_ENV" | xargs)
else
    echo -e "${YELLOW}⚠️  .env do system-control não encontrado, usando defaults${NC}"
fi

# Valores default (modo IP - compatibilidade)
SERVER_IP="${SERVER_IP:-10.10.42.144}"
NGINX_PUBLIC_URL="${NGINX_PUBLIC_URL:-http://${SERVER_IP}:8001}"
RGS_PUBLIC_URL="${RGS_PUBLIC_URL:-http://${SERVER_IP}:43317/}"
PAGE_URL="${PAGE_URL:-http://${SERVER_IP}:2555/}"

echo ""
echo "📋 Configuração detectada:"
echo "   SERVER_IP: $SERVER_IP"
echo "   NGINX_PUBLIC_URL: $NGINX_PUBLIC_URL"
echo "   RGS_PUBLIC_URL: $RGS_PUBLIC_URL"
echo "   PAGE_URL: $PAGE_URL"
echo ""

# Usar URLs direto do .env (sem modificar)
GAME_URL="${NGINX_PUBLIC_URL}/games"
PAGE_URL_FINAL="${PAGE_URL}"
RGS_URL_FINAL="${RGS_PUBLIC_URL}"

echo "📝 URLs para o banco:"
echo "   game_url: $GAME_URL"
echo "   page_url: $PAGE_URL_FINAL"
echo "   rgs_url: $RGS_URL_FINAL"
echo ""

# MySQL connection
MYSQL_HOST="${MYSQL_HOST:-mysql_database}"
MYSQL_PORT="${MYSQL_PORT:-3306}"
MYSQL_USER="${MYSQL_USER:-root}"
MYSQL_PASSWORD="${MYSQL_PASSWORD:-${MYSQL_ROOT_PASSWORD:-}}"
MYSQL_DATABASE="${MYSQL_DATABASE:-CS1}"

# Verificar se MySQL está acessível
echo "🔌 Verificando conexão com MySQL..."
if ! docker exec "$MYSQL_HOST" mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "SELECT 1" "$MYSQL_DATABASE" >/dev/null 2>&1; then
    echo -e "${RED}❌ Não foi possível conectar ao MySQL${NC}"
    echo "   Verifique: MYSQL_HOST, MYSQL_USER, MYSQL_PASSWORD"
    exit 1
fi

echo -e "${GREEN}✅ MySQL conectado${NC}"
echo ""

# Atualizar location
echo "🔄 Atualizando tabela 'location'..."
docker exec "$MYSQL_HOST" mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" -e "
UPDATE location 
SET page_url = '$PAGE_URL_FINAL',
    game_url = '$GAME_URL'
WHERE name = 'GGSOFT';"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ location atualizado${NC}"
else
    echo -e "${RED}❌ Falha ao atualizar location${NC}"
    exit 1
fi

# Atualizar game_location
echo "🔄 Atualizando tabela 'game_location'..."
docker exec "$MYSQL_HOST" mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" -e "
UPDATE game_location 
SET rgs_url = '$RGS_URL_FINAL'
WHERE id_location IN (
    SELECT id FROM location WHERE name = 'GGSOFT'
);"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ game_location atualizado${NC}"
else
    echo -e "${RED}❌ Falha ao atualizar game_location${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}=== Banco atualizado com sucesso ===${NC}"
echo ""
echo "📋 Novos valores:"
docker exec "$MYSQL_HOST" mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" -e "
SELECT 'Location' as tabela, name, page_url, game_url 
FROM location WHERE name = 'GGSOFT'
UNION ALL
SELECT 'GameLocation' as tabela, CAST(id_location AS CHAR), rgs_url, '' 
FROM game_location WHERE id_location = 1;"

echo ""
echo "🔄 Reiniciar system-control para aplicar mudanças:"
echo "   docker restart ggsoft_system-control"
