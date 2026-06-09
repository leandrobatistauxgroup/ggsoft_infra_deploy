#!/bin/bash
# Para todos os serviços GGSoft
# Execute: bash _deploy/deploy/stop_all.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE="$SCRIPT_DIR/ggsoft"

docker compose -f "$BASE/ggsoft_infra_nginx_proxy_https/docker-compose.yml" down
docker compose -f "$BASE/ggsoft_infra_nginx/docker-compose.yml" down
docker compose -f "$BASE/ggsoft_core_lounge/docker-compose.yml" down
docker compose -f "$BASE/ggsoft_core_rgs_slot3x3/docker-compose.yml" down
docker compose -f "$BASE/ggsoft_core_math_slot/docker-compose.yml" down
docker compose -f "$BASE/ggsoft_core_history/docker-compose.yml" down
docker compose -f "$BASE/ggsoft_core_cs/cs/docker-compose.yml" down
docker compose -f "$BASE/ggsoft_infra_redis/docker-compose.yml" down
docker compose -f "$BASE/ggsoft_infra_mysql/docker-compose.yml" down

echo "✅ Todos os serviços parados."
