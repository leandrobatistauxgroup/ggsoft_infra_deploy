#!/bin/bash
# Script para build com BuildKit garantido
# Uso: ./build-with-buildkit.sh [servicos...]

set -e

# Cores
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}=== Build com BuildKit ===${NC}"

# Exportar variáveis BuildKit
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1
export BUILDKIT_PROGRESS=plain

# Verificar se buildx está disponível
if docker buildx version &>/dev/null; then
    echo -e "${GREEN}✓ Buildx disponível${NC}"
    
    # Criar builder se não existir
    if ! docker buildx inspect ggsoft-builder &>/dev/null 2>&1; then
        echo -e "${BLUE}Criando builder ggsoft-builder...${NC}"
        docker buildx create --name ggsoft-builder --use 2>/dev/null || true
    else
        docker buildx use ggsoft-builder 2>/dev/null || true
    fi
fi

# Build com docker compose
echo -e "${BLUE}Executando build...${NC}"
cd "$(dirname "$0")/.."
docker compose build --progress plain "$@" 2>&1 || {
    echo -e "${RED}✗ Build falhou, tentando método alternativo...${NC}"
    docker compose build "$@" 2>&1
}

echo -e "${GREEN}✓ Build concluído${NC}"
