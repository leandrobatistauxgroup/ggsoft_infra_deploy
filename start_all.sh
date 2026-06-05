#!/bin/bash
# Sobe todos os serviços GGSoft na ordem correta
# Execute: bash _deploy/start_all.sh

BASE="/Users/leandrobatista/Desktop/ggsoft"
set -e

echo "==> [1/5] Criando .env de todos os projetos..."
bash "$BASE/_deploy/setup_envs.sh"

echo ""
echo "==> [2/5] Subindo MySQL (cria rede rede-ggsoft automaticamente)..."
docker compose -f "$BASE/ggsoft_infra_mysql/docker-compose.yml" up -d
echo "    Aguardando MySQL ficar pronto..."
sleep 15

echo ""
echo "==> [3/5] Subindo Redis..."
docker compose -f "$BASE/ggsoft_infra_redis/docker-compose.yml" up -d

echo ""
echo "==> [4/5] Subindo CS (Credit Server)..."
docker compose -f "$BASE/ggsoft_core_cs/cs/docker-compose.yml" up -d
echo "    Aguardando CS ficar pronto..."
sleep 5

echo ""
echo "==> [5/5] Subindo Lounge e Nginx..."
docker compose -f "$BASE/ggsoft_core_lounge/docker-compose.yml" up -d
docker compose -f "$BASE/ggsoft_infra_nginx/docker-compose.yml" up -d

echo ""
echo "✅ Todos os serviços no ar!"
echo ""
echo "   Lounge:  http://localhost:23458"
echo "   Nginx:   http://localhost:8001"
echo "   CS API:  http://localhost:8888"
echo "   MySQL:   localhost:53306"
