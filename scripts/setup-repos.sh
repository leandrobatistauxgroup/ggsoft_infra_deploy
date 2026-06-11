#!/bin/bash
# =============================================================================
# Clona todos os repositórios da plataforma GGSoft como irmãos do _deploy
# Uso: ./scripts/setup-repos.sh
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="${WORKSPACE_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Clonando repositórios GGSoft em: $WORKSPACE_DIR ===${NC}"
echo ""

declare -A REPOS
REPOS["ggsoft_wallet-auth"]="git@github.com:GGSoftBR/ggsoft_wallet-auth.git"
REPOS["ggsoft_history"]="git@github-ggsoft:GGSoftBR/ggsoft_history.git"
REPOS["ggsoft_math-3x3"]="git@github.com:GGSoftBR/ggsoft_math-3x3.git"
REPOS["ggsoft_rgs_slot"]="git@github-ggsoft:GGSoftBR/ggsoft_rgs_slot.git"
REPOS["ggsoft_system-control"]="git@github.com:GGSoftBR/ggsoft_system-control.git"
REPOS["ggsoft_infra_mysql"]="git@github-ggsoft:GGSoftBR/ggsoft_infra_mysql.git"
REPOS["ggsoft_infra_redis"]="git@github-ggsoft:GGSoftBR/ggsoft_infra_redis.git"
REPOS["ggsoft_infra_nginx"]="git@github-ggsoft:GGSoftBR/ggsoft_infra_nginx.git"
REPOS["ggsoft_game_slot3x3"]="git@github-ggsoft:GGSoftBR/ggsoft_game_slot3x3.git"
REPOS["landf_haxe_libs"]="git@github-ggsoft:GGSoftBR/landf_haxe_libs.git"
# NOTA: ggsoft_game_slot3x3 não é clonado no deploy - jogo compilado fica em nginx/games/

for folder in "${!REPOS[@]}"; do
    url="${REPOS[$folder]}"
    dest="$WORKSPACE_DIR/$folder"

    if [ -d "$dest/.git" ]; then
        echo -e "${YELLOW}↺  $folder já existe, atualizando...${NC}"
        git -C "$dest" pull --ff-only 2>/dev/null || echo -e "   ${YELLOW}⚠ pull ignorado (sem upstream ou conflito)${NC}"
    else
        echo -e "${BLUE}⬇  Clonando $folder...${NC}"
        git clone "$url" "$dest"
        echo -e "   ${GREEN}✓ $folder clonado${NC}"
    fi
done

echo ""
echo -e "${GREEN}=== Todos os repositórios prontos em $WORKSPACE_DIR ===${NC}"
