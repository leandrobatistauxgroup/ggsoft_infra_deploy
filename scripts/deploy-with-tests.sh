#!/bin/bash
# =============================================================================
# Gate de Qualidade — executa testes e bloqueia deploy se falharem
# Responsabilidade: SOMENTE testar. Não inicia serviços, não configura .env.
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="${WORKSPACE_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
ENVS_DIR="${ENVS_DIR:-$SCRIPT_DIR/../envs}"

DC="$(docker compose version >/dev/null 2>&1 && echo 'docker compose' || echo 'docker-compose')"

# Garante limpeza de containers de teste mesmo em caso de CTRL+C ou erro
_cleanup_tests() {
    $DC down 2>/dev/null || true
    $DC --profile test down 2>/dev/null || true
    $DC --profile integration-test down 2>/dev/null || true
}
trap _cleanup_tests EXIT INT TERM

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║     GGSoft — Gate de Qualidade                                   ║"
echo "║     Testes devem passar para liberar o deploy                    ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# =============================================================================
# PRÉ-REQUISITO: chave RSA do wallet-auth
# =============================================================================

WALLET_PEM="$WORKSPACE_DIR/ggsoft_wallet-auth/pem/private.pem"
if [ ! -f "$WALLET_PEM" ]; then
    echo -e "${YELLOW}⚠️  $WALLET_PEM não encontrado — gerando chave RSA...${NC}"
    mkdir -p "$(dirname "$WALLET_PEM")"
    openssl genrsa -out "$WALLET_PEM" 2048 2>/dev/null || {
        echo -e "${RED}❌ Falha ao gerar chave RSA. Instale openssl ou forneça a chave manualmente.${NC}"
        exit 1
    }
    echo -e "${GREEN}✅ Chave RSA gerada: $WALLET_PEM${NC}"
fi

# =============================================================================
# SETUP
# =============================================================================

REPORTS_DIR="./reports"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
TEST_OUTPUT="${REPORTS_DIR}/test_output_${TIMESTAMP}.log"
TEST_FAILED=0

mkdir -p "$REPORTS_DIR"

# =============================================================================
# FASE 1/2: TESTES UNITÁRIOS (wallet-auth)
# =============================================================================

echo ""
echo -e "${BLUE}=== FASE 1/2: Testes Unitários ===${NC}"
echo ""

echo -e "${YELLOW}🧪 Subindo MySQL de teste...${NC}"
if ! $DC up -d mysql-test 2>&1 | tee -a "$TEST_OUTPUT"; then
    echo -e "${RED}❌ Falha ao subir MySQL de teste${NC}"
    TEST_FAILED=1
fi

if [ "$TEST_FAILED" -eq 0 ]; then
    echo -e "${YELLOW}Aguardando MySQL de teste aceitar conexões (max 60s)...${NC}"
    MYSQL_READY=0
    for i in $(seq 1 20); do
        if $DC exec -T mysql-test mysqladmin ping -h localhost -uroot -proot_test --silent 2>/dev/null; then
            echo -e "   ${GREEN}✓ MySQL pronto${NC}"
            MYSQL_READY=1
            break
        fi
        echo -e "   aguardando... (${i}/20)"
        sleep 3
    done
    if [ "$MYSQL_READY" -eq 0 ]; then
        echo -e "   ${RED}✗ MySQL não respondeu em 60s${NC}"
        TEST_FAILED=1
    fi

    echo -e "${YELLOW}🧪 Executando testes wallet-auth...${NC}"
    if ! $DC run --rm wallet-auth-tests 2>&1 | tee -a "$TEST_OUTPUT"; then
        echo -e "${RED}❌ Testes do wallet-auth falharam${NC}"
        TEST_FAILED=1
    fi
fi

# Limpa containers de teste unitário (trap também faz isso no exit)
$DC --profile test down 2>/dev/null || true

# =============================================================================
# FASE 2/2: TESTES DE INTEGRAÇÃO
# =============================================================================

echo ""
echo -e "${BLUE}=== FASE 2/2: Testes de Integração ===${NC}"
echo ""

# Libera portas que possam conflitar
echo -e "${YELLOW}Liberando portas para testes de integração...${NC}"
for port in 53306 8888 8890 43317 8001 2555; do
    cname=$(docker ps --filter "publish=$port" --format '{{.Names}}' 2>/dev/null | head -1)
    if [ -n "$cname" ]; then
        echo -e "   ${YELLOW}⚠ Parando $cname (porta $port)${NC}"
        docker stop "$cname" 2>/dev/null || true
        docker rm "$cname" 2>/dev/null || true
    fi
done
echo -e "   ${GREEN}✓ Portas liberadas${NC}"

if [ "$TEST_FAILED" -eq 0 ]; then
    # Sobe mysql, redis e wallet-auth (com dependências); aguarda antes de subir o resto
    echo -e "${YELLOW}Subindo mysql, redis e wallet-auth...${NC}"
    $DC --profile integration-test up -d wallet-auth 2>&1 | tee -a "$TEST_OUTPUT" || true

    # Aguarda banco CS1 existir (init.sql pode ainda estar rodando)
    MYSQL_ROOT_PASS=$(grep "^MYSQL_ROOT_PASSWORD=" "$ENVS_DIR/mysql.env" 2>/dev/null | cut -d'=' -f2 | head -1)
    DB_NAME=$(grep "^MYSQL_DATABASE=" "$ENVS_DIR/wallet-auth.env" 2>/dev/null | cut -d'=' -f2 | head -1)
    DB_NAME="${DB_NAME:-CS1}"
    echo -e "${YELLOW}Aguardando banco '$DB_NAME' no MySQL (max 60s)...${NC}"
    DB_READY=0
    for i in $(seq 1 20); do
        if docker exec mysql_database mysql -uroot -p"$MYSQL_ROOT_PASS" -e "USE $DB_NAME;" 2>/dev/null; then
            DB_READY=1
            echo -e "   ${GREEN}✓ Database $DB_NAME pronto${NC}"
            break
        fi
        echo -e "   aguardando init.sql... [$i/20]"
        sleep 3
    done
    if [ "$DB_READY" -eq 0 ]; then
        echo -e "   ${YELLOW}⚠ Database $DB_NAME não confirmado em 60s — continuando mesmo assim${NC}"
    fi

    # Aguarda wallet-auth ficar healthy (max 150s) e captura logs se falhar
    echo -e "${YELLOW}Aguardando wallet-auth ficar healthy (max 150s)...${NC}"
    WALLET_HEALTHY=0
    for i in $(seq 1 30); do
        STATUS=$(docker inspect --format='{{.State.Health.Status}}' python-app-wallet-auth 2>/dev/null)
        if [ "$STATUS" = "healthy" ]; then
            WALLET_HEALTHY=1
            echo -e "   ${GREEN}✓ wallet-auth healthy${NC}"
            break
        elif [ "$STATUS" = "unhealthy" ]; then
            echo -e "   ${RED}✗ wallet-auth unhealthy — capturando logs${NC}"
            printf "\n=== LOGS wallet-auth ===\n" | tee -a "$TEST_OUTPUT"
            docker logs python-app-wallet-auth 2>&1 | tee -a "$TEST_OUTPUT"
            break
        fi
        echo -e "   aguardando... [$i/30] ($STATUS)"
        sleep 5
    done

    if [ "$WALLET_HEALTHY" -eq 0 ]; then
        echo -e "${RED}❌ wallet-auth não ficou healthy${NC}"
        TEST_FAILED=1
    fi
fi

if [ "$TEST_FAILED" -eq 0 ]; then
    # Sobe serviços restantes (rgs-fruit, nginx, history, math)
    echo -e "${YELLOW}Subindo demais serviços de integração...${NC}"
    $DC --profile integration-test up -d history math rgs-fruit nginx 2>&1 | tee -a "$TEST_OUTPUT" || true
    sleep 10

    echo -e "${YELLOW}🧪 Executando testes de integração...${NC}"
    if ! $DC --profile integration-test run --rm integration-tests 2>&1 | tee -a "$TEST_OUTPUT"; then
        echo -e "${RED}❌ Testes de integração falharam${NC}"
        TEST_FAILED=1
    else
        echo -e "${GREEN}✅ Testes de integração passaram!${NC}"
    fi
fi

# Limpa containers de integração
$DC --profile integration-test down 2>/dev/null || true
$DC down 2>/dev/null || true

# =============================================================================
# RESULTADO
# =============================================================================

echo ""

# Também falha se o log tiver marcadores de erro mesmo com exit 0
if [ "$TEST_FAILED" -eq 0 ] && grep -qE "^FAILED |^ERROR | [0-9]+ failed| [0-9]+ error" "$TEST_OUTPUT" 2>/dev/null; then
    TEST_FAILED=1
fi

if [ "$TEST_FAILED" -eq 1 ]; then
    REPORT_FILE="${REPORTS_DIR}/deploy_failure_${TIMESTAMP}.md"

    echo -e "${RED}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  ❌ DEPLOY BLOQUEADO — Testes Falharam                           ║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    cat > "$REPORT_FILE" << EOF
# Relatório de Falha no Deploy

## Informações Gerais

- **Data/Hora:** $(date "+%Y-%m-%d %H:%M:%S")
- **Status:** ❌ BLOQUEADO — Testes Falharam
- **Log:** $TEST_OUTPUT

## Resumo

O deploy foi **ABORTADO** porque os testes automatizados não passaram.
Nenhum serviço foi iniciado em produção.

## Saída dos Testes

\`\`\`
$(cat "$TEST_OUTPUT")
\`\`\`

## Ações Recomendadas

### Corrigir e tentar novamente
\`\`\`bash
cd ../ggsoft_wallet-auth && make test
cd ../ggsoft_infra_deploy && make deploy
\`\`\`

### Forçar rebuild completo (apaga volumes e senhas)
\`\`\`bash
make deploy-n
\`\`\`

---
**Deploy Abortado em:** $(date "+%Y-%m-%d %H:%M:%S")
EOF

    echo -e "${YELLOW}📄 Relatório: ${CYAN}$REPORT_FILE${NC}"
    echo -e "${YELLOW}📄 Log:       ${CYAN}$TEST_OUTPUT${NC}"
    echo ""
    echo -e "${RED}❌ Corrija os testes antes de prosseguir.${NC}"
    echo ""
    exit 1
fi

echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ TESTES APROVADOS — Deploy Autorizado                         ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ -f "$TEST_OUTPUT" ]; then
    echo -e "${BLUE}Resumo:${NC}"
    grep -E "passed|failed|error|coverage" "$TEST_OUTPUT" | tail -5 || true
    echo ""
fi

exit 0
