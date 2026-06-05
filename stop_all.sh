#!/bin/bash
# Para todos os serviços GGSoft
# Execute: bash _deploy/stop_all.sh

BASE="/Users/leandrobatista/Desktop/ggsoft"

docker compose -f "$BASE/ggsoft_infra_nginx/docker-compose.yml" down
docker compose -f "$BASE/ggsoft_core_lounge/docker-compose.yml" down
docker compose -f "$BASE/ggsoft_core_cs/cs/docker-compose.yml" down
docker compose -f "$BASE/ggsoft_infra_redis/docker-compose.yml" down
docker compose -f "$BASE/ggsoft_infra_mysql/docker-compose.yml" down

echo "✅ Todos os serviços parados."
