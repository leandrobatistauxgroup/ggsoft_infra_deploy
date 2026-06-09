#!/bin/bash
# =============================================================================
# Script Interativo de Deploy GGSoft
# Pergunta configurações ao usuário e gera os arquivos .env
# =============================================================================

set -e

ENVS_DIR="${ENVS_DIR:-./envs}"
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${GREEN}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║           GGSoft Platform - Deploy Interativo                 ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Verifica se já existe configuração personalizada
if [ -f "$ENVS_DIR/mysql.env" ]; then
    CURRENT_PASSWORD=$(grep "^MYSQL_PASSWORD=" "$ENVS_DIR/mysql.env" 2>/dev/null | cut -d'=' -f2 | tr -d "'\"" || echo "")
    if [ "$CURRENT_PASSWORD" != "ggsoft_password_change_me" ] && [ -n "$CURRENT_PASSWORD" ]; then
        echo -e "${YELLOW}⚠️  Configurações personalizadas detectadas.${NC}"
        read -p "Deseja reconfigurar do zero? (s/N): " REPLY
        if [[ ! "$REPLY" =~ ^[Ss]$ ]]; then
            echo -e "${GREEN}Deploy cancelado. Use 'make start' para iniciar.${NC}"
            exit 0
        fi
    fi
fi

echo -e "${CYAN}Configure os parâmetros do deploy (Enter para aceitar padrão):${NC}"
echo ""

# =============================================================================
# PERGUNTAS INTERATIVAS
# =============================================================================

# Localização
read -p "🌍 Localização [GGSOFT]: " LOCATION
LOCATION=${LOCATION:-GGSOFT}

# MySQL
read -p "🗄️  MySQL - Usuário [ggsoft_user]: " MYSQL_USER
MYSQL_USER=${MYSQL_USER:-ggsoft_user}

while true; do
    read -s -p "🗄️  MySQL - Senha (mín 12 chars, Enter=auto-gera 32 chars forte): " MYSQL_PASSWORD
    echo ""
    if [ -z "$MYSQL_PASSWORD" ]; then
        MYSQL_PASSWORD=$(openssl rand -base64 48 | tr -dc 'a-zA-Z0-9!@#$%^&*' | head -c 32)
        echo -e "${BLUE}   Senha forte auto-gerada (32 chars)${NC}"
        break
    elif [ ${#MYSQL_PASSWORD} -ge 12 ]; then
        read -s -p "   Confirme a senha: " MYSQL_PASSWORD_CONFIRM
        echo ""
        if [ "$MYSQL_PASSWORD" = "$MYSQL_PASSWORD_CONFIRM" ]; then
            break
        else
            echo -e "${YELLOW}   Senhas não conferem. Tente novamente.${NC}"
        fi
    else
        echo -e "${YELLOW}   Senha deve ter no mínimo 12 caracteres.${NC}"
    fi
done

# Redis
while true; do
    read -s -p "🔐 Redis - Senha (mín 12 chars, Enter=auto-gera 24 chars forte): " REDIS_PASSWORD
    echo ""
    if [ -z "$REDIS_PASSWORD" ]; then
        REDIS_PASSWORD=$(openssl rand -base64 36 | tr -dc 'a-zA-Z0-9!@#$%^&*' | head -c 24)
        echo -e "${BLUE}   Senha forte auto-gerada (24 chars)${NC}"
        break
    elif [ ${#REDIS_PASSWORD} -ge 12 ]; then
        read -s -p "   Confirme a senha: " REDIS_PASSWORD_CONFIRM
        echo ""
        if [ "$REDIS_PASSWORD" = "$REDIS_PASSWORD_CONFIRM" ]; then
            break
        else
            echo -e "${YELLOW}   Senhas não conferem. Tente novamente.${NC}"
        fi
    else
        echo -e "${YELLOW}   Senha deve ter no mínimo 12 caracteres.${NC}"
    fi
done

# Wallet-Auth Secret Key
while true; do
    read -s -p "🔑 Wallet-Auth - SECRET_KEY HMAC (mín 32 chars, Enter=auto-gera 64 chars): " WALLET_SECRET
    echo ""
    if [ -z "$WALLET_SECRET" ]; then
        WALLET_SECRET=$(openssl rand -base64 64 | tr -dc 'a-zA-Z0-9!@#$%^&*' | head -c 64)
        echo -e "${BLUE}   Chave forte auto-gerada (64 chars, guarde em local seguro)${NC}"
        break
    elif [ ${#WALLET_SECRET} -ge 32 ]; then
        break
    else
        echo -e "${YELLOW}   Chave deve ter no mínimo 32 caracteres.${NC}"
    fi
done

# History API Secret
while true; do
    read -s -p "🔑 History - API_SECRET_KEY (mín 24 chars, Enter=auto-gera 48 chars): " HISTORY_SECRET
    echo ""
    if [ -z "$HISTORY_SECRET" ]; then
        HISTORY_SECRET=$(openssl rand -base64 48 | tr -dc 'a-zA-Z0-9!@#$%^&*' | head -c 48)
        echo -e "${BLUE}   Chave forte auto-gerada (48 chars)${NC}"
        break
    elif [ ${#HISTORY_SECRET} -ge 24 ]; then
        break
    else
        echo -e "${YELLOW}   Chave deve ter no mínimo 24 caracteres.${NC}"
    fi
done

# Tokens de teste (opcional)
echo ""
echo -e "${CYAN}Tokens de teste (Enter para padrões):${NC}"
read -p "🎮 RGS_TOKEN [TK15]: " RGS_TOKEN
RGS_TOKEN=${RGS_TOKEN:-TK15}
read -p "🎮 CIRCUIT_TOKEN [TK16]: " CIRCUIT_TOKEN
CIRCUIT_TOKEN=${CIRCUIT_TOKEN:-TK16}

# Portas (Enter para manter padrões)
echo ""
echo -e "${CYAN}Portas (Enter para manter padrões):${NC}"
read -p "📡 MySQL Host Port [53306]: " MYSQL_PORT
MYSQL_PORT=${MYSQL_PORT:-53306}
read -p "📡 Redis Port [36380]: " REDIS_PORT
REDIS_PORT=${REDIS_PORT:-36380}
read -p "📡 Wallet-Auth Port [8888]: " WALLET_PORT
WALLET_PORT=${WALLET_PORT:-8888}
read -p "📡 History Port [8890]: " HISTORY_PORT
HISTORY_PORT=${HISTORY_PORT:-8890}
# RGS Port não perguntado - definido no docker-compose.yml (43317)
RGS_PORT=43317
read -p "📡 Panel Port [2555]: " PANEL_PORT
PANEL_PORT=${PANEL_PORT:-2555}
read -p "📡 Nginx Port [8001]: " NGINX_PORT
NGINX_PORT=${NGINX_PORT:-8001}

echo ""
echo -e "${GREEN}✅ Configurações coletadas. Gerando arquivos .env...${NC}"
echo ""

# =============================================================================
# GERAÇÃO DOS ARQUIVOS .ENV
# =============================================================================

mkdir -p "$ENVS_DIR"

# Gerar init.sql dinamicamente para o MySQL (com usuário correto)
cat > "$WORKSPACE_DIR/ggsoft_infra_mysql/init.sql" << EOF
CREATE DATABASE IF NOT EXISTS cs1;
GRANT ALL PRIVILEGES ON cs1.* TO '${MYSQL_USER}'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF
echo -e "${YELLOW}📝 MySQL init.sql gerado com usuário: ${MYSQL_USER}${NC}"

# MySQL
cat > "$ENVS_DIR/mysql.env" << EOF
# =============================================================================
# MySQL - Banco de dados principal
# =============================================================================

MYSQL_IMAGE=mysql:8.4.0
MYSQL_CONTAINER_NAME=mysql_database

# Credenciais
MYSQL_ROOT_PASSWORD='${MYSQL_PASSWORD}_root'
MYSQL_DATABASE=CS1
MYSQL_USER=${MYSQL_USER}
MYSQL_PASSWORD='${MYSQL_PASSWORD}'

# Porta exposta no host
MYSQL_HOST_PORT=${MYSQL_PORT}
EOF

# Redis
cat > "$ENVS_DIR/redis.env" << EOF
# =============================================================================
# Redis - Cache e sessões
# =============================================================================

REDIS_IMAGE=redis:latest
REDIS_CONTAINER_NAME=ggsoft_redis

# Porta exposta no host
REDIS_PORT=${REDIS_PORT}

# Senha do Redis
REDIS_PASSWORD='${REDIS_PASSWORD}'
EOF

# Wallet-Auth
cat > "$ENVS_DIR/wallet-auth.env" << EOF
# =============================================================================
# Wallet-Auth (CS - Credit Server)
# =============================================================================

MODE_ENV=LOCAL

# --- MySQL ---
MYSQL_HOST=mysql_database
MYSQL_PORT=3306
MYSQL_USER=${MYSQL_USER}
MYSQL_PASSWORD='${MYSQL_PASSWORD}'
DATABASE_NAME=CS1

# --- Segurança ---
SECRET_KEY='${WALLET_SECRET}'

# Exige HMAC nos endpoints opt-in (false para compatibilidade)
REQUIRE_HMAC=false

# CORS - Origens permitidas ('*' libera todas)
ALLOWED_ORIGINS=*
EOF

# History
cat > "$ENVS_DIR/history.env" << EOF
# =============================================================================
# History - Histórico de jogadas
# =============================================================================

# Conexão com Redis
REDIS_SERVER=ggsoft_redis
REDIS_PORT=${REDIS_PORT}
REDIS_PASSWORD='${REDIS_PASSWORD}'

# Autenticação da API (header X-API-KEY)
API_SECRET_KEY='${HISTORY_SECRET}'

# CORS - origens permitidas
CORS_ORIGINS=*

# Ambiente (dev = autoreload ativado)
MODE_ENV=dev

# Porta do servidor
PORT=${HISTORY_PORT}
EOF

# Math
cat > "$ENVS_DIR/math.env" << EOF
# =============================================================================
# Math - Motor matemático (ZMQ)
# =============================================================================

# Porta TCP onde o math server faz bind (ZeroMQ ROUTER)
SERVER_PORT=49235
EOF

# RGS
cat > "$ENVS_DIR/rgs.env" << EOF
# =============================================================================
# RGS - Game Server
# =============================================================================

# Ambiente
MODE_ENV=LOCAL
LOCATION=${LOCATION}

# Credit Server (CS) - wallet-auth
SERVER_CS=http://python-app-wallet-auth:${WALLET_PORT}

# Redis (datastore de sessão)
REDIS_SEVER=ggsoft_redis
REDIS_PASSWORD='${REDIS_PASSWORD}'
REDIS_PORT=${REDIS_PORT}

# Math engine (ZMQ)
MATH_SERVER=tcp://ggsoft-zmq-server-slot:49235

# History
HISTORY_SERVER=http://ggsoft_history:${HISTORY_PORT}
HISTORY_SECRET_KEY='${HISTORY_SECRET}'

# Jackpot Service (JPS) - externo
SERVER_JPS_SERVER=titan.cletrix.net
SERVER_JPS_PORT=44888
EOF

# System-Control
cat > "$ENVS_DIR/system-control.env" << EOF
# =============================================================================
# System Control - Painel de controle
# =============================================================================

# Path ABSOLUTO do workspace no host
WORKSPACE_DIR=$(cd "$(dirname "$0")/../.." && pwd)

# Porta do painel (host bind em 127.0.0.1)
PANEL_PORT=${PANEL_PORT}

# Senha do Redis (mesmo valor do redis.env)
REDIS_PASSWORD='${REDIS_PASSWORD}'

# Credenciais do MySQL (para recreditar saldo de teste)
MYSQL_USER=${MYSQL_USER}
MYSQL_PASSWORD='${MYSQL_PASSWORD}'

# Token do usuário de teste (is_test=1) - Pinger
RGS_TOKEN=${RGS_TOKEN}

# Token de segundo usuário de teste - Circuit
CIRCUIT_TOKEN=${CIRCUIT_TOKEN}
EOF

echo -e "${GREEN}✅ Arquivos .env gerados em ${ENVS_DIR}/${NC}"
echo ""

# =============================================================================
# RESUMO
# =============================================================================

echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}📋 RESUMO DA CONFIGURAÇÃO${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}Localização:${NC} ${LOCATION}"
echo -e "${BLUE}MySQL:${NC} ${MYSQL_USER} / porta ${MYSQL_PORT}"
echo -e "${BLUE}Redis:${NC} porta ${REDIS_PORT}"
echo -e "${BLUE}Wallet-Auth:${NC} porta ${WALLET_PORT}"
echo -e "${BLUE}History:${NC} porta ${HISTORY_PORT}"
echo -e "${BLUE}RGS:${NC} porta ${RGS_PORT}"
echo -e "${BLUE}Panel:${NC} porta ${PANEL_PORT} (localhost only)"
echo -e "${BLUE}Nginx:${NC} porta ${NGINX_PORT}"
echo ""
echo -e "${YELLOW}⚠️  ANOTE AS SENHAS GERADAS:${NC}"
echo -e "   MySQL Root: ${MYSQL_PASSWORD}_root"
[ -n "$MYSQL_PASSWORD" ] && echo -e "   MySQL User: ${MYSQL_PASSWORD}"
[ -n "$REDIS_PASSWORD" ] && echo -e "   Redis: ${REDIS_PASSWORD}"
[ -n "$WALLET_SECRET" ] && echo -e "   Wallet SECRET_KEY: ${WALLET_SECRET:0:20}..."
[ -n "$HISTORY_SECRET" ] && echo -e "   History API_SECRET: ${HISTORY_SECRET}"
echo ""
echo -e "${GREEN}══════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Configuração concluída!${NC}"
echo -e "${GREEN}   Continuando com deploy...${NC}"
echo -e "${GREEN}══════════════════════════════════════════════════════════════════${NC}"
