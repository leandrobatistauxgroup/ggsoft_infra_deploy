#!/bin/bash
# =============================================================================
# Deploy com Gate de Qualidade - Só libera se testes passarem
# =============================================================================
# Se testes falharem, gera relatório de evidências e aborta deploy
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="${WORKSPACE_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
ENVS_DIR="${ENVS_DIR:-$SCRIPT_DIR/../envs}"

# Atualiza todos os repositórios (clone se ausente, pull se existente)
echo -e "\033[0;34m🔄 Atualizando repositórios...\033[0m"
"$SCRIPT_DIR/setup-repos.sh"

# Verificações obrigatórias antes do deploy

# Garantir que pem/private.pem existe no wallet-auth (gera se não existir)
WALLET_PEM="$WORKSPACE_DIR/ggsoft_wallet-auth/pem/private.pem"
if [ ! -f "$WALLET_PEM" ]; then
    echo -e "\033[0;33m⚠️  $WALLET_PEM não encontrado — gerando chave RSA...\033[0m"
    mkdir -p "$WORKSPACE_DIR/ggsoft_wallet-auth/pem"
    # Gera chave RSA 2048 bits
    openssl genrsa -out "$WALLET_PEM" 2048 2>/dev/null || \
    (echo -e "\033[0;31m❌ Falha ao gerar chave RSA. Instale openssl ou forneça a chave manualmente.\033[0m"; exit 1)
    echo -e "\033[0;32m✅ Chave RSA gerada: $WALLET_PEM\033[0m"
fi

# Sincroniza .env para todos os repos antes do build
"$SCRIPT_DIR/sync-envs.sh"

REPORTS_DIR="./reports"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_FILE="${REPORTS_DIR}/deploy_failure_${TIMESTAMP}.md"

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║     Deploy GGSoft com Gate de Qualidade                          ║"
echo "║     Testes devem passar para liberar deploy                      ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

mkdir -p "$REPORTS_DIR"

# =============================================================================
# FASE 1: EXECUTAR TESTES
# =============================================================================

echo -e "${BLUE}=== FASE 1/4: Executando Testes de Qualidade ===${NC}"
echo ""

TEST_OUTPUT="${REPORTS_DIR}/test_output_${TIMESTAMP}.log"
TEST_FAILED=0

echo -e "${YELLOW}🧪 Testando wallet-auth...${NC}"

# Sobe MySQL de teste
if ! docker-compose up -d mysql-test 2>&1 | tee -a "$TEST_OUTPUT"; then
    echo -e "${RED}❌ Falha ao subir MySQL de teste${NC}"
    TEST_FAILED=1
fi

# Aguarda MySQL estar pronto para aceitar conexões
echo -e "${YELLOW}Aguardando MySQL de teste aceitar conexões...${NC}"
for i in $(seq 1 20); do
    if docker-compose exec -T mysql-test mysqladmin ping -h localhost -uroot -proot_test --silent 2>/dev/null; then
        echo -e "   ${GREEN}✓ MySQL pronto${NC}"
        break
    fi
    sleep 3
done

# Executa testes wallet-auth
echo -e "${YELLOW}Running: docker-compose run --rm wallet-auth-tests${NC}" | tee -a "$TEST_OUTPUT"
if ! docker-compose run --rm wallet-auth-tests 2>&1 | tee -a "$TEST_OUTPUT"; then
    echo -e "${RED}❌ Testes do wallet-auth falharam${NC}"
    TEST_FAILED=1
fi

# Verifica containers rodando e derruba automaticamente
RUNNING=$(docker-compose ps --status running --format '{{.Name}} (porta: {{.Ports}})' 2>/dev/null | grep -v '^$' || true)
if [ -n "$RUNNING" ]; then
    echo ""
    echo -e "${YELLOW}⚠️  Containers em execução detectados:${NC}"
    echo "$RUNNING" | while read -r line; do echo "   • $line"; done
    echo ""
    echo -e "${BLUE}Derrubando containers automaticamente...${NC}"
    docker-compose down 2>/dev/null || true
    docker-compose --profile test down 2>/dev/null || true
    docker-compose --profile integration-test down 2>/dev/null || true
fi

# =============================================================================
# FASE 2: TESTES DE INTEGRAÇÃO END-TO-END (infra_deploy)
# =============================================================================

echo ""
echo -e "${BLUE}=== FASE 2/4: Testes de Integração End-to-End ===${NC}"
echo ""

# Limpa todos os containers que possam conflitar com as portas antes de subir integração
echo -e "${YELLOW}Liberando portas para testes de integração...${NC}"
docker-compose down 2>/dev/null || true
docker-compose --profile test down 2>/dev/null || true
for port in 53306 8888 8890 43317 8001 2555; do
    cname=$(docker ps --filter "publish=$port" --format '{{.Names}}' 2>/dev/null | head -1)
    if [ -n "$cname" ]; then
        echo -e "   ${YELLOW}⚠ Parando $cname (porta $port)${NC}"
        docker stop "$cname" 2>/dev/null || true
        docker rm "$cname" 2>/dev/null || true
    fi
done
echo -e "   ${GREEN}✓ Portas liberadas${NC}"

echo -e "${YELLOW}🧪 Testando integração de serviços...${NC}"
echo -e "${YELLOW}Running: docker-compose --profile integration-test run --rm integration-tests${NC}" | tee -a "$TEST_OUTPUT"

# Os serviços são subidos automaticamente pelo depends_on do integration-tests
sleep 5

# Executa testes de integração
if ! docker-compose --profile integration-test run --rm integration-tests 2>&1 | tee -a "$TEST_OUTPUT"; then
    echo -e "${RED}❌ Testes de integração falharam${NC}"
    TEST_FAILED=1
else
    echo -e "${GREEN}✅ Testes de integração passaram!${NC}"
fi

# Limpa recursos de teste
docker-compose down 2>/dev/null || true

# =============================================================================
# FASE 3: ANÁLISE DE RESULTADOS
# =============================================================================

echo ""
echo -e "${BLUE}=== FASE 3/4: Analisando Resultados ===${NC}"
echo ""

if [ $TEST_FAILED -eq 0 ]; then
    # Verificar se há falhas na saída (mesmo com exit code 0, pode ter falhas)
    if grep -qE "^FAILED |^ERROR | [0-9]+ failed| [0-9]+ error" "$TEST_OUTPUT" 2>/dev/null; then
        TEST_FAILED=1
    fi
fi

if [ $TEST_FAILED -eq 1 ]; then
    echo -e "${RED}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  ❌ DEPLOY BLOQUEADO - Testes Falharam                             ║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Gerar relatório de falha
    cat > "$REPORT_FILE" << EOF
# Relatório de Falha no Deploy

## Informações Gerais

- **Data/Hora:** $(date "+%Y-%m-%d %H:%M:%S")
- **Status:** ❌ BLOQUEADO - Testes Falharam
- **Arquivo de Log:** $TEST_OUTPUT

## Resumo

O deploy foi **ABORTADO** porque os testes automatizados não passaram.
Nenhum serviço foi iniciado em produção.

## Evidências

### Comando Executado
\`\`\`bash
docker-compose --profile test run --rm wallet-auth-tests
\`\`\`

### Saída dos Testes

\`\`\`
$(cat "$TEST_OUTPUT")
\`\`\`

### Estatísticas

EOF
    
    # Extrair estatísticas se disponível
    if grep -q "passed\|failed\|error" "$TEST_OUTPUT"; then
        PASSED=$(grep -oE "[0-9]+ passed" "$TEST_OUTPUT" | grep -oE "[0-9]+" || echo "0")
        FAILED=$(grep -oE "[0-9]+ failed" "$TEST_OUTPUT" | grep -oE "[0-9]+" || echo "0")
        ERRORS=$(grep -oE "[0-9]+ error" "$TEST_OUTPUT" | grep -oE "[0-9]+" || echo "0")
        
        echo "- Testes Passados: $PASSED" >> "$REPORT_FILE"
        echo "- Testes Falhos: $FAILED" >> "$REPORT_FILE"
        echo "- Erros: $ERRORS" >> "$REPORT_FILE"
    fi
    
    cat >> "$REPORT_FILE" << EOF

## Possíveis Causas

1. **Código com regressão** - Alterações recentes quebraram funcionalidade existente
2. **Dependências alteradas** - Mudanças em pyproject.toml/uv.lock não testadas
3. **Ambiente de teste corrompido** - Limpar e tentar novamente
4. **Flaky tests** - Testes intermitentes (executar novamente)

## Ações Recomendadas

### Opção 1: Corrigir e Tentar Novamente
\`\`\`bash
# Corrija o código nos repos originais
cd ../ggsoft_wallet-auth
# Faça as correções necessárias

# Teste localmente primeiro
make test

# Retorne ao deploy
cd ../ggsoft_infra_deploy
make deploy-safe
\`\`\`

### Opção 2: Investigar Falha
\`\`\`bash
# Veja o log completo
cat $TEST_OUTPUT

# Rode testes interativamente
cd ../ggsoft_wallet-auth
make test
\`\`\`

### Opção 3: Forçar Deploy (Não Recomendado)
⚠️ **AVISO:** Isso ignora os testes e pode quebrar produção.

\`\`\`bash
make deploy  # Deploy sem gate de qualidade
\`\`\`

## Arquivos Gerados

- Relatório: \`$REPORT_FILE\`
- Log de Testes: \`$TEST_OUTPUT\`

---

**Deploy Abortado em:** $(date "+%Y-%m-%d %H:%M:%S")
EOF

    echo -e "${YELLOW}📄 Relatório de falha gerado:${NC}"
    echo -e "   ${CYAN}$REPORT_FILE${NC}"
    echo ""
    echo -e "${YELLOW}📄 Log completo:${NC}"
    echo -e "   ${CYAN}$TEST_OUTPUT${NC}"
    echo ""
    echo -e "${RED}❌ Deploy abortado. Corrija os testes antes de prosseguir.${NC}"
    echo ""
    exit 1
fi

# =============================================================================
# FASE 3: DEPLOY AUTORIZADO
# =============================================================================

echo -e "${GREEN}✅ Todos os testes passaram!${NC}"
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ TESTES APROVADOS - Deploy Autorizado                          ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Resumo dos testes
if [ -f "$TEST_OUTPUT" ]; then
    echo -e "${BLUE}Resumo da execução:${NC}"
    grep -E "passed|failed|error|coverage" "$TEST_OUTPUT" | tail -5 || echo "   Verifique o log em $TEST_OUTPUT"
    echo ""
fi

echo -e "${GREEN}🚀 Iniciando deploy...${NC}"
echo ""

# =============================================================================
# FASE 3: VERIFICAR SE ENV JÁ EXISTE
# =============================================================================

ENV_EXISTS=0
if [ -f "$ENVS_DIR/wallet-auth.env" ] && [ -f "$ENVS_DIR/mysql.env" ]; then
    ENV_EXISTS=1
fi

if [ $ENV_EXISTS -eq 1 ]; then
    echo -e "${BLUE}=== Configurações existentes detectadas ===${NC}"
    echo ""
    echo -e "${YELLOW}Arquivos .env já existem em $ENVS_DIR/${NC}"
    echo ""
    
    # Mostra resumo rápido
    LOCATION=$(grep "^LOCATION=" "$ENVS_DIR/rgs.env" 2>/dev/null | cut -d= -f2 || echo "GGSOFT")
    MYSQL_USER=$(grep "^MYSQL_USER=" "$ENVS_DIR/mysql.env" 2>/dev/null | cut -d= -f2 || echo "ggsoft_user")
    
    echo -e "${CYAN}Configurações atuais:${NC}"
    echo "  Localização: $LOCATION"
    echo "  MySQL User: $MYSQL_USER"
    echo ""
    
    echo -e "${GREEN}✅ Usando configurações existentes automaticamente...${NC}"
    
    echo ""
    echo -e "${BLUE}=== Pulando configuração, usando .env existentes ===${NC}"
    echo ""
    
    # Sincroniza e inicia direto
    echo -e "${BLUE}Sincronizando .env para projetos...${NC}"
    ./scripts/sync-envs.sh
    
    echo ""
    echo -e "${BLUE}Iniciando serviços...${NC}"
    make start
    
    exit 0
fi

# Se chegou aqui, faz deploy interativo normal
echo -e "${BLUE}=== Configuração interativa ===${NC}"
echo ""
./scripts/deploy-interactive.sh

# =============================================================================
# FASE 4: TESTES DE INTEGRAÇÃO RGS/HISTORY/WALLET
# =============================================================================

echo ""
echo -e "${BLUE}=== FASE 4/4: Testes de Integração de Serviços ===${NC}"
echo ""

# Testa se History aceita GET /matches
echo -e "${YELLOW}Testando History API (GET /matches)...${NC}"
HISTORY_GET_TEST=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:8890/matches?user_id=test&game=fruits&limit=1&offset=0" 2>/dev/null || echo "000")
if [ "$HISTORY_GET_TEST" = "200" ] || [ "$HISTORY_GET_TEST" = "405" ]; then
    if [ "$HISTORY_GET_TEST" = "405" ]; then
        echo -e "${RED}❌ History retorna 405 para GET /matches - API incompatível${NC}"
        echo -e "${YELLOW}   Verificar se History espera POST em vez de GET${NC}"
    else
        echo -e "${GREEN}✅ History API respondendo: $HISTORY_GET_TEST${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  History API resposta: $HISTORY_GET_TEST${NC}"
fi

# Testa se RGS tem GAME_NAME configurado
echo -e "${YELLOW}Verificando configuração RGS (GAME_NAME)...${NC}"
RGS_GAME_NAME=$(docker exec rgs-fruit env | grep GAME_NAME | cut -d= -f2 2>/dev/null || echo "")
if [ "$RGS_GAME_NAME" = "fruits" ]; then
    echo -e "${GREEN}✅ RGS GAME_NAME configurado: $RGS_GAME_NAME${NC}"
else
    echo -e "${RED}❌ RGS GAME_NAME incorreto ou não definido: '$RGS_GAME_NAME' (esperado: fruits)${NC}"
    echo -e "${YELLOW}   Verificar docker-compose.yml - environment: GAME_NAME${NC}"
fi

# Testa conectividade RGS -> History
echo -e "${YELLOW}Testando conectividade RGS -> History...${NC}"
if docker exec rgs-fruit wget -qO- http://ggsoft_history:8890/ > /dev/null 2>&1; then
    echo -e "${GREEN}✅ RGS consegue comunicar com History${NC}"
else
    echo -e "${RED}❌ RGS não consegue comunicar com History${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Deploy completo!${NC}"
echo ""
echo -e "${CYAN}Acessos disponíveis:${NC}"
echo "  • System Control: http://localhost:2555"
echo "  • Wallet-Auth:  http://localhost:8888"
echo "  • History:      http://localhost:8890"
echo "  • RGS Fruit:    http://localhost:43317"
echo "  • Nginx:        http://localhost:8001"
echo ""

exit 0
