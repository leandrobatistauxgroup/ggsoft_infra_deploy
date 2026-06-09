#!/bin/bash
# Cria todos os .env dos projetos GGSoft a partir do arquivo ggsoft.env
# Uso: bash setup_envs.sh [BASE_DIR]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE="${1:-$SCRIPT_DIR/ggsoft}"
ENV_FILE="$SCRIPT_DIR/ggsoft.env"

# --- Verificar se ggsoft.env existe ---
if [ ! -f "$ENV_FILE" ]; then
    echo ""
    echo "❌ ERRO: arquivo ggsoft.env não encontrado!"
    echo ""
    echo "   Copie o template e preencha com os seus valores:"
    echo ""
    echo "   cp ggsoft.env.example ggsoft.env"
    echo "   nano ggsoft.env"
    echo ""
    exit 1
fi

# --- Verificar se ainda tem valores de exemplo não preenchidos ---
if grep -q "ALTERE_" "$ENV_FILE"; then
    echo ""
    echo "❌ ERRO: ggsoft.env ainda tem valores padrão não preenchidos (ALTERE_*)!"
    echo "   Edite o arquivo e substitua todos os valores ALTERE_* antes de continuar."
    echo ""
    exit 1
fi

# --- Carregar variáveis ---
set -a
source "$ENV_FILE"
set +a

echo "Usando BASE: $BASE"

echo "==> Criando .env: ggsoft_core_cs/cs/"
cat > "$BASE/ggsoft_core_cs/cs/.env" << EOF
MODE_ENV=LOCAL

MYSQL_HOST=mysql_ggsoft_test
MYSQL_PORT=3306
MYSQL_PASSWORD=$MYSQL_PASSWORD
MYSQL_USER=$MYSQL_USER

SECRET_KEY=$CS_SECRET_KEY
EOF

echo "==> Criando .env: ggsoft_core_lounge"
cat > "$BASE/ggsoft_core_lounge/.env" << EOF
MODE_ENV=LOCAL
LOCATION=$LOCATION
PORT=23458
HOST=0.0.0.0

NAME_DB=CS1
HOST_DB=mysql_ggsoft_test
PORT_DB=3306
USER_DB=$MYSQL_USER
PASSWORD_DB=$MYSQL_PASSWORD

GA_MEASUREMENT_ID=
EOF

echo "==> Criando .env: ggsoft_core_rgs_slot3x3"
cat > "$BASE/ggsoft_core_rgs_slot3x3/.env" << EOF
MODE_ENV=LOCAL
LOCATION=$LOCATION
SERVER_CS=http://python-app-cs:8888

REDIS_SERVER=ggsoft_infra_redis-redis-1
REDIS_PASSWORD=$REDIS_PASSWORD
REDIS_PORT=$REDIS_PORT

MATH_SERVER=tcp://zmq-server-slot:49235

HISTORY_SERVER=http://ggsoft_core_history-save-matches-uuid-1:8890
HISTORY_SECRET_KEY=$HISTORY_SECRET_KEY
EOF

echo "==> Criando .env: ggsoft_core_math_slot"
cat > "$BASE/ggsoft_core_math_slot/.env" << EOF
SERVER_PORT=49235
EOF

echo "==> Criando .env: ggsoft_core_history"
cat > "$BASE/ggsoft_core_history/.env" << EOF
REDIS_SERVER=ggsoft_infra_redis-redis-1
REDIS_PASSWORD=$REDIS_PASSWORD
REDIS_PORT=$REDIS_PORT
API_SECRET_KEY=$HISTORY_SECRET_KEY
EOF

echo ""
echo "✅ Todos os .env criados com sucesso!"
