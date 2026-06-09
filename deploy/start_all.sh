#!/bin/bash
# Sobe todos os serviços GGSoft na ordem correta
# Execute: bash _deploy/deploy/start_all.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE="$SCRIPT_DIR/ggsoft"
set -e

echo "==> [1/9] Criando .env de todos os projetos..."
bash "$SCRIPT_DIR/setup_envs.sh" "$BASE"

echo ""
echo "==> [2/9] Subindo MySQL (cria rede rede-ggsoft automaticamente)..."
docker compose -f "$BASE/ggsoft_infra_mysql/docker-compose.yml" up -d
echo "    Aguardando MySQL ficar pronto..."
sleep 15

echo ""
echo "==> [3/9] Subindo Redis..."
docker compose -f "$BASE/ggsoft_infra_redis/docker-compose.yml" up -d

echo ""
echo "==> [4/9] Subindo Math (ZMQ)..."
docker compose -f "$BASE/ggsoft_core_math_slot/docker-compose.yml" up -d

echo ""
echo "==> [5/9] Subindo History..."
docker compose -f "$BASE/ggsoft_core_history/docker-compose.yml" up -d

echo ""
echo "==> [6/9] Subindo CS (Credit Server)..."
docker compose -f "$BASE/ggsoft_core_cs/cs/docker-compose.yml" up -d
echo "    Aguardando CS ficar pronto..."
sleep 5

echo ""
echo "==> [7/9] Subindo RGS Slot (solid + fruits)..."
docker compose -f "$BASE/ggsoft_core_rgs_slot3x3/docker-compose.yml" up -d

echo ""
echo "==> [8/9] Subindo Lounge..."
docker compose -f "$BASE/ggsoft_core_lounge/docker-compose.yml" up -d

echo ""
echo "==> [9/9] Subindo Nginx e Nginx Proxy HTTPS..."
docker compose -f "$BASE/ggsoft_infra_nginx/docker-compose.yml" up -d
docker compose -f "$BASE/ggsoft_infra_nginx_proxy_https/docker-compose.yml" up -d

echo ""
echo "✅ Todos os serviços no ar!"
echo ""
echo "   Lounge:     http://localhost:23458"
echo "   Nginx:      http://localhost:8001"
echo "   CS API:     http://localhost:8888"
echo "   RGS solid:  http://localhost:43319"
echo "   RGS fruits: http://localhost:43316"
echo "   MySQL:      localhost:53306"
