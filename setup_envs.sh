#!/bin/bash
# Cria todos os .env dos projetos GGSoft
# Uso: bash setup_envs.sh [BASE_DIR]
# BASE_DIR: pasta raiz onde os repos estao clonados (default: ../ggsoft relativo ao script)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE="${1:-$SCRIPT_DIR/ggsoft}"

echo "Usando BASE: $BASE"

echo "==> Criando .env: ggsoft_core_cs/cs/"
cat > "$BASE/ggsoft_core_cs/cs/.env" << 'EOF'
MODE_ENV=LOCAL

MYSQL_HOST=mysql_ggsoft_test
MYSQL_PORT=3306
MYSQL_PASSWORD=ggsoft_test_2025
MYSQL_USER=ggsoft_test

SECRET_KEY=mfx%tka!hm##tkd4#dn5+y9y+02r^w&4@rar9(0p!0119r7udc
EOF

echo "==> Criando .env: ggsoft_core_lounge"
cat > "$BASE/ggsoft_core_lounge/.env" << 'EOF'
MODE_ENV=LOCAL
LOCATION=GGSoft
PORT=23458
HOST=0.0.0.0

NAME_DB=CS1
HOST_DB=mysql_ggsoft_test
PORT_DB=3306
USER_DB=ggsoft_test
PASSWORD_DB=ggsoft_test_2025

GA_MEASUREMENT_ID=
EOF

echo "==> Criando .env: ggsoft_core_rgs_slot3x3 (slot/incas)"
cat > "$BASE/ggsoft_core_rgs_slot3x3/.env" << 'EOF'
MODE_ENV=LOCAL
LOCATION=GGSoft
SERVER_CS=http://python-app-cs:8888

REDIS_SEVER=ggsoft_infra_redis-redis-1
REDIS_PASSWORD=astrolopitecus34y384535sgdjhgdxvc
REDIS_PORT=36380

MATH_SERVER=tcp://zmq-server-slot:49235

HISTORY_SERVER=http://ggsoft_core_history-save-matches-uuid-1:8890
HISTORY_SECRET_KEY=API0v8RZvgJI0X3rGvE4XelxI4NwLkygqFxjPCyqMea6udsgdksdsdv8VR1jpFFj9jDfSsOdn1kLBAsQXa6g5Gk7UcpA
EOF

echo "==> Criando .env: ggsoft_core_math_slot"
cat > "$BASE/ggsoft_core_math_slot/.env" << 'EOF'
SERVER_PORT=49235
EOF

echo ""
echo "✅ Todos os .env criados com sucesso!"
