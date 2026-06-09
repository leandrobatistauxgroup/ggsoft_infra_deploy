# =============================================================================
# GGSoft Platform - Makefile
# =============================================================================
# Orquestração unificada de todos os serviços GGSoft
# 
# ORDEM DE SUBIDA (gerenciada automaticamente pelo docker-compose):
#   1. Infra: mysql, redis
#   2. Apps: wallet-auth, history, math
#   3. Game: rgs-fruit
#   4. Frontend: nginx, system-control
# =============================================================================

.PHONY: help setup init-build start start-infra start-apps start-rgs stop restart logs status wait-health test clean verify envs

# Diretórios
ENVS_DIR := ./envs

# Cores para output
GREEN := '\033[0;32m'
YELLOW := '\033[0;33m'
RED := '\033[0;31m'
BLUE := '\033[0;34m'
NC := '\033[0m' # No Color

# Services groups
INFRA_SERVICES := mysql redis
APPS_SERVICES := wallet-auth history math
GAME_SERVICES := rgs-fruit
FRONTEND_SERVICES := nginx system-control

help: ## Mostra esta ajuda
	@echo "GGSoft Platform - Comandos disponíveis:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'

deploy: ## Deploy completo - testes + envs + sync + start (padrão)
	@echo "$(GREEN)=== Deploy GGSoft Completo ===$(NC)"
	@./scripts/deploy-with-tests.sh
	@echo "$(BLUE)=== Sincronizando .env para todos os projetos ===${NC}"
	@./scripts/sync-envs.sh
	@echo "$(GREEN)=== Iniciando todos os serviços ===${NC}"
	@make start

deploy-quick: ## Deploy rápido sem testes - envs + sync + start
	@echo "$(YELLOW)=== Deploy GGSoft SEM testes ===${NC}"
	@echo "$(RED)⚠️  AVISO: Pulando testes de qualidade!${NC}"
	@./scripts/deploy-interactive.sh
	@./scripts/sync-envs.sh
	@echo "$(GREEN)=== Iniciando todos os serviços ===${NC}"
	@make start

sync: ## Sincroniza .env do deploy para todos os projetos
	@echo "$(BLUE)=== Sincronizando .env para todos os projetos ===${NC}"
	@./scripts/sync-envs.sh

clone: ## Clona todos os repositórios da plataforma como irmãos deste diretório
	@echo "$(BLUE)=== Clonando repositórios GGSoft ===$(NC)"
	@./scripts/setup-repos.sh

setup: ## Setup inicial - cria rede Docker, verifica envs e garante .build
	@echo "$(GREEN)=== Setup inicial da plataforma GGSoft ===$(NC)"
	@echo "$(BLUE)1. Criando rede Docker 'rede-ggsoft'...$(NC)"
	@docker network create rede-ggsoft 2>/dev/null || echo "   Rede já existe"
	@echo "$(BLUE)2. Verificando arquivos .env...$(NC)"
	@for env in mysql redis wallet-auth history math rgs system-control; do \
		if [ -f $(ENVS_DIR)/$$env.env ]; then \
			echo "   ✓ $$env.env"; \
		else \
			echo "   $(RED)✗ $$env.env não encontrado$(NC)"; \
		fi; \
	done
	@make init-build
	@echo "$(YELLOW)3. IMPORTANTE: Edite os arquivos em $(ENVS_DIR)/ com suas senhas!$(NC)"
	@echo "$(GREEN)=== Setup concluído. Execute 'make start' para iniciar ===$(NC)"

init-build: ## Garante que .build é arquivo (não pasta) - necessário para RGS
	@if [ -d .build ]; then \
		rm -rf .build && printf '0\n' > .build && echo "   📝 .build era pasta → recriado como arquivo"; \
	elif [ ! -e .build ]; then \
		printf '0\n' > .build && echo "   📝 Criado .build"; \
	else \
		echo "   ✓ .build OK"; \
	fi

start: ## Inicia todos os serviços (ordem: infra → apps → game → frontend)
	@echo "$(GREEN)=== Iniciando plataforma GGSoft (4 fases) ===$(NC)"
	@make init-build
	@echo "$(BLUE)Criando rede Docker rede-ggsoft...$(NC)"
	@docker network create rede-ggsoft 2>/dev/null || echo "   Rede já existe"
	@echo "$(BLUE)Fase 1/4: Infraestrutura (mysql, redis)...$(NC)"
	@docker-compose up -d $(INFRA_SERVICES)
	@echo "$(BLUE)Aguardando healthcheck da infra...$(NC)"
	@sleep 5
	@echo "$(BLUE)Fase 2/4: Build das aplicações...$(NC)"
	@docker-compose build $(APPS_SERVICES)
	@echo "$(BLUE)Fase 3/4: Subindo aplicações...$(NC)"
	@docker-compose up -d $(APPS_SERVICES)
	@echo "$(BLUE)Aguardando healthcheck das aplicações...$(NC)"
	@sleep 10
	@echo "$(BLUE)Fase 4/4: Game Server (RGS)...$(NC)"
	@docker-compose up -d $(GAME_SERVICES)
	@echo "$(BLUE)Aguardando RGS...$(NC)"
	@sleep 5
	@echo "$(BLUE)Subindo Frontend (nginx, system-control)...$(NC)"
	@docker-compose up -d $(FRONTEND_SERVICES)
	@echo "$(GREEN)=== Todos os serviços iniciados ===$(NC)"
	@make status

start-infra: ## Inicia só a infraestrutura (mysql, redis)
	@echo "$(BLUE)=== Iniciando infraestrutura ===$(NC)"
	docker-compose up -d $(INFRA_SERVICES)

start-apps: ## Inicia aplicações (dependem da infra)
	@echo "$(BLUE)=== Iniciando aplicações ===$(NC)"
	docker-compose up -d $(APPS_SERVICES)

start-rgs: ## Inicia game server (depende das apps)
	@echo "$(BLUE)=== Iniciando RGS ===$(NC)"
	@make init-build
	docker-compose up -d $(GAME_SERVICES)

wait-health: ## Aguarda todos os healthchecks passarem
	@echo "$(BLUE)=== Aguardando healthchecks ===$(NC)"
	@docker-compose ps --format "table {{.Name}}\t{{.Status}}"

stop: ## Para todos os serviços
	@echo "$(YELLOW)=== Parando plataforma GGSoft ===$(NC)"
	docker-compose down

restart: ## Reinicia todos os serviços
	@echo "$(YELLOW)=== Reiniciando plataforma GGSoft ===$(NC)"
	docker-compose restart

logs: ## Mostra logs de todos os serviços
	docker-compose logs -f

status: ## Mostra status dos serviços
	@echo "$(GREEN)=== Status dos serviços ===$(NC)"
	@docker-compose ps

health: ## Mostra status dos healthchecks
	@echo "$(GREEN)=== Healthchecks ===$(NC)"
	@docker-compose ps

test: ## Executa testes do wallet-auth
	@echo "$(GREEN)=== Executando testes ===$(NC)"
	docker-compose up -d mysql-test
	@sleep 5
	docker-compose run --rm wallet-auth-tests

clean: ## Remove containers, volumes e rede (⚠️ Dados serão perdidos!)
	@echo "$(RED)=== ATENÇÃO: Isso removerá TODOS os dados! ===$(NC)"
	@read -p "Digite 'SIM' para confirmar: " confirm && \
	if [ "$${confirm}" = "SIM" ]; then \
		docker-compose down -v; \
		docker network rm rede-ggsoft 2>/dev/null || true; \
		echo "$(GREEN)Limpeza concluída$(NC)"; \
	else \
		echo "$(YELLOW)Operação cancelada$(NC)"; \
	fi

reset-rgs: ## Reseta o arquivo .build do RGS (útil para forçar rebuild)
	@echo "$(YELLOW)=== Resetando .build ===$(NC)"
	@rm -f .build && printf '0\n' > .build
	@echo "$(GREEN).build resetado$(NC)"

envs: ## Lista os arquivos .env e suas descrições
	@echo "$(GREEN)=== Arquivos de configuração (.env) ===$(NC)"
	@echo "  mysql.env        - Configurações do MySQL"
	@echo "  redis.env        - Configurações do Redis"
	@echo "  wallet-auth.env  - Serviço de autenticação/crédito (CS)"
	@echo "  history.env      - Serviço de histórico"
	@echo "  math.env         - Motor matemático (ZMQ)"
	@echo "  rgs.env          - Game server (RGS)"
	@echo "  system-control.env - Painel de controle"
	@echo ""
	@echo "$(YELLOW)Local: $(ENVS_DIR)/$(NC)"

verify: ## Verifica se as senhas estão sincronizadas entre serviços
	@./scripts/verify-envs.sh

update-envs: ## Sincroniza senhas entre arquivos .env (após edição manual)
	@echo "$(YELLOW)=== Dica: Mantenha as mesmas senhas em: ===$(NC)"
	@echo "  - redis.env: REDIS_PASSWORD"
	@echo "  - wallet-auth.env: REDIS_PASSWORD (se usar Redis lá)"
	@echo "  - history.env: REDIS_PASSWORD"
	@echo "  - rgs.env: REDIS_PASSWORD"
	@echo "  - system-control.env: REDIS_PASSWORD"
	@echo ""
	@echo "  - mysql.env: MYSQL_PASSWORD"
	@echo "  - wallet-auth.env: MYSQL_PASSWORD"
	@echo "  - system-control.env: MYSQL_PASSWORD"
	@echo ""
	@echo "  - history.env: API_SECRET_KEY"
	@echo "  - rgs.env: HISTORY_SECRET_KEY"
