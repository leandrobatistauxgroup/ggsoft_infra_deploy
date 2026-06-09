#!/bin/bash
# =============================================================================
# Script de verificação das variáveis de ambiente
# Verifica se as senhas estão sincronizadas entre serviços
# =============================================================================

set -e

ENVS_DIR="${ENVS_DIR:-./envs}"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo -e "${GREEN}=== Verificação de Configurações ===${NC}"
echo ""

# Função para extrair valor de .env
get_env_value() {
    local file="$1"
    local key="$2"
    grep "^$key=" "$file" 2>/dev/null | cut -d'=' -f2- | tr -d "'\"" || echo ""
}

errors=0

# Verificar REDIS_PASSWORD
echo -e "${YELLOW}Verificando REDIS_PASSWORD...${NC}"
redis_pass=$(get_env_value "$ENVS_DIR/redis.env" "REDIS_PASSWORD")

for file in "$ENVS_DIR/history.env" "$ENVS_DIR/rgs.env" "$ENVS_DIR/system-control.env"; do
    if [ -f "$file" ]; then
        other_pass=$(get_env_value "$file" "REDIS_PASSWORD")
        if [ "$redis_pass" != "$other_pass" ]; then
            echo -e "  ${RED}✗ Diferença em $(basename $file): REDIS_PASSWORD${NC}"
            errors=$((errors + 1))
        else
            echo -e "  ${GREEN}✓ $(basename $file)${NC}"
        fi
    fi
done

# Verificar MYSQL_PASSWORD
echo ""
echo -e "${YELLOW}Verificando MYSQL_PASSWORD...${NC}"
mysql_pass=$(get_env_value "$ENVS_DIR/mysql.env" "MYSQL_PASSWORD")

for file in "$ENVS_DIR/wallet-auth.env" "$ENVS_DIR/system-control.env"; do
    if [ -f "$file" ]; then
        other_pass=$(get_env_value "$file" "MYSQL_PASSWORD")
        if [ "$mysql_pass" != "$other_pass" ]; then
            echo -e "  ${RED}✗ Diferença em $(basename $file): MYSQL_PASSWORD${NC}"
            errors=$((errors + 1))
        else
            echo -e "  ${GREEN}✓ $(basename $file)${NC}"
        fi
    fi
done

# Verificar HISTORY_SECRET_KEY
echo ""
echo -e "${YELLOW}Verificando HISTORY_SECRET_KEY...${NC}"
history_key=$(get_env_value "$ENVS_DIR/history.env" "API_SECRET_KEY")
rgs_history_key=$(get_env_value "$ENVS_DIR/rgs.env" "HISTORY_SECRET_KEY")

if [ "$history_key" != "$rgs_history_key" ]; then
    echo -e "  ${RED}✗ API_SECRET_KEY (history) ≠ HISTORY_SECRET_KEY (rgs)${NC}"
    errors=$((errors + 1))
else
    echo -e "  ${GREEN}✓ Sincronizado${NC}"
fi

# Verificar senhas padrão (não alteradas)
echo ""
echo -e "${YELLOW}Verificando senhas padrão...${NC}"

check_default_password() {
    local file="$1"
    local key="$2"
    local default="$3"
    local name="$4"
    
    value=$(get_env_value "$file" "$key")
    if [ "$value" = "$default" ]; then
        echo -e "  ${YELLOW}⚠ $name ainda usa senha padrão${NC}"
    else
        echo -e "  ${GREEN}✓ $name alterado${NC}"
    fi
}

check_default_password "$ENVS_DIR/redis.env" "REDIS_PASSWORD" "redis_password_change_me" "Redis"
check_default_password "$ENVS_DIR/mysql.env" "MYSQL_ROOT_PASSWORD" "root_password_change_me" "MySQL Root"
check_default_password "$ENVS_DIR/mysql.env" "MYSQL_PASSWORD" "ggsoft_password_change_me" "MySQL User"
check_default_password "$ENVS_DIR/wallet-auth.env" "SECRET_KEY" "wallet_auth_secret_key_change_me" "Wallet-Auth SECRET_KEY"
check_default_password "$ENVS_DIR/history.env" "API_SECRET_KEY" "history_api_secret_change_me" "History API_SECRET_KEY"

# Resumo
echo ""
if [ $errors -eq 0 ]; then
    echo -e "${GREEN}=== Verificação concluída: OK ===${NC}"
    exit 0
else
    echo -e "${RED}=== Verificação concluída: $errors problema(s) encontrado(s) ===${NC}"
    exit 1
fi
