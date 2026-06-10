# =============================================================================
# GGSoft Platform - Makefile
# =============================================================================
# Orquestração unificada de todos os serviços GGSoft
# 
# ORDEM DE SUBIDA (gerenciada automaticamente pelo docker compose):
#   1. Infra: mysql, redis
#   2. Apps: wallet-auth, history, math
#   3. Game: rgs-fruit
#   4. Frontend: nginx, system-control
# =============================================================================

.PHONY: help setup init-build start start-infra start-apps start-rgs stop restart logs status wait-health test clean verify envs set-server-ip set-server-ip-manual

# Diretórios
ENVS_DIR := ./envs

# WORKSPACE_DIR: pasta pai do _deploy (onde ficam todos os repos)
WORKSPACE_DIR ?= $(shell cd .. && pwd)
export WORKSPACE_DIR

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

deploy: ## Deploy completo - atualiza _deploy + testes + envs + sync + start
	@echo "$(GREEN)=== Deploy GGSoft Completo ===$(NC)"
	@echo "$(BLUE)1. Atualizando repositório de deploy...$(NC)"
	@MAKEFILE_HASH_BEFORE=$$(md5sum $(MAKEFILE_LIST) 2>/dev/null | md5sum | cut -d' ' -f1); \
	git pull 2>/dev/null || echo "$(YELLOW)⚠️ Não foi possível atualizar _deploy (sem git ou sem remote)$(NC)"; \
	MAKEFILE_HASH_AFTER=$$(md5sum $(MAKEFILE_LIST) 2>/dev/null | md5sum | cut -d' ' -f1); \
	if [ "$$MAKEFILE_HASH_BEFORE" != "$$MAKEFILE_HASH_AFTER" ]; then \
		echo "$(YELLOW)🔄 Makefile atualizado! Recarregando...$(NC)"; \
		exec $(MAKE) deploy; \
	fi
	@echo "$(BLUE)2. Verificando SERVER_IP...$(NC)"
	@CURRENT_IP=$$(grep "^SERVER_IP=" $(ENVS_DIR)/system-control.env 2>/dev/null | cut -d'=' -f2 | head -1); \
	if [ -z "$$CURRENT_IP" ] || [ "$$CURRENT_IP" = "localhost" ] || [ "$$CURRENT_IP" = "$${SERVER_IP:-localhost}" ]; then \
		HOSTNAME=$$(hostname | tr '[:upper:]' '[:lower:]'); \
		if echo "$$HOSTNAME" | grep -q "local"; then \
			echo "$(GREEN)✓ Hostname '$$HOSTNAME' contém 'local' — usando SERVER_IP=localhost$(NC)"; \
			sed -i "s/^SERVER_IP=.*/SERVER_IP=localhost/" $(ENVS_DIR)/system-control.env; \
		else \
			echo "$(YELLOW)⚠️  SERVER_IP não configurado$(NC)"; \
			echo "$(YELLOW)   Execute: make set-server-ip$(NC)"; \
			exit 1; \
		fi; \
	else \
		echo "$(GREEN)✓ SERVER_IP configurado: $$CURRENT_IP$(NC)"; \
	fi
	@echo "$(BLUE)3. Configuração interativa (senhas, usuários)...$(NC)"
	@./scripts/deploy-interactive.sh || true
	@./scripts/deploy-with-tests.sh
	@echo "$(BLUE)=== Sincronizando .env para todos os projetos ===${NC}"
	@./scripts/sync-envs.sh
	@echo "$(GREEN)=== Iniciando todos os serviços ===${NC}"
	@make start

deploy-quick: ## Deploy rápido sem testes - atualiza _deploy + envs + sync + start
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

set-server-ip: ## Detecta ambiente e configura SERVER_IP (local=auto, remoto=pergunta)
	@echo "$(BLUE)=== Configurando SERVER_IP ===$(NC)"
	@# Detecta se é ambiente local (tem interface gráfica ou usuário local)
	@IS_LOCAL="no"; \
	if [ -n "$${DISPLAY:-}" ] || [ "$$(whoami)" = "$${USER:-}" ] && [ -z "$${SSH_CLIENT:-}" ]; then \
		IS_LOCAL="yes"; \
	fi; \
	if [ "$$IS_LOCAL" = "yes" ]; then \
		echo "$(GREEN)✓ Ambiente local detectado — usando localhost$(NC)"; \
		sed -i "s/^SERVER_IP=.*/SERVER_IP=localhost/" $(ENVS_DIR)/system-control.env; \
		echo "$(GREEN)✓ SERVER_IP=localhost configurado$(NC)"; \
	else \
		echo "$(YELLOW)⚠️  Ambiente remoto/SSH detectado$(NC)"; \
		DETECTED_IP=$$(hostname -I 2>/dev/null | awk '{print $$1}' || echo ""); \
		if [ -z "$$DETECTED_IP" ]; then \
			DETECTED_IP=$$(ip route get 1 2>/dev/null | head -1 | sed -n 's/.*src \([0-9.]*\).*/\1/p' || echo ""); \
		fi; \
		if [ -z "$$DETECTED_IP" ]; then \
			DETECTED_IP=$$(ifconfig 2>/dev/null | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | head -1 || echo ""); \
		fi; \
		if [ -n "$$DETECTED_IP" ]; then \
			echo "$(BLUE)IP detectado: $$DETECTED_IP$(NC)"; \
			read -p "Usar este IP? [Y/n] ou digite outro IP/dominio: " CONFIRM; \
			if [ -z "$$CONFIRM" ] || [ "$$CONFIRM" = "Y" ] || [ "$$CONFIRM" = "y" ]; then \
				FINAL_IP="$$DETECTED_IP"; \
			else \
				FINAL_IP="$$CONFIRM"; \
			fi; \
		else \
			read -p "Digite o IP ou dominio do servidor: " FINAL_IP; \
		fi; \
		if [ -n "$$FINAL_IP" ]; then \
			sed -i "s/^SERVER_IP=.*/SERVER_IP=$$FINAL_IP/" $(ENVS_DIR)/system-control.env; \
			echo "$(GREEN)✓ SERVER_IP=$$FINAL_IP configurado$(NC)"; \
		else \
			echo "$(RED)❌ IP não informado — SERVER_IP permanece inalterado$(NC)"; \
		fi; \
	fi

set-server-ip-manual: ## Configura IP manualmente (use: make set-server-ip IP=192.168.1.100)
	@if [ -z "$(IP)" ]; then \
		echo "$(RED)❌ Especifique o IP: make set-server-ip IP=192.168.1.100$(NC)"; \
		exit 1; \
	fi; \
	sed -i "s/^SERVER_IP=.*/SERVER_IP=$(IP)/" $(ENVS_DIR)/system-control.env; \
	echo "$(GREEN)✓ SERVER_IP configurado: $(IP)$(NC)"

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
	@echo "$(BLUE)3. Verificando SERVER_IP no system-control.env...$(NC)"
	@CURRENT_IP=$$(grep "^SERVER_IP=" $(ENVS_DIR)/system-control.env 2>/dev/null | cut -d'=' -f2 | head -1); \
	if [ -z "$$CURRENT_IP" ] || [ "$$CURRENT_IP" = "localhost" ] || [ "$$CURRENT_IP" = "$${SERVER_IP:-localhost}" ]; then \
		echo "   $(YELLOW)⚠️  SERVER_IP não configurado ou é localhost$(NC)"; \
		echo "   $(YELLOW)   Execute: make set-server-ip$(NC)"; \
	else \
		echo "   ✓ SERVER_IP configurado: $$CURRENT_IP"; \
	fi
	@make init-build
	@echo "$(YELLOW)4. IMPORTANTE: Edite os arquivos em $(ENVS_DIR)/ com suas senhas!$(NC)"
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
	@PORTS="53306 8888 8890 43317 8001 2555"; \
	CONFLITOS=""; \
	for port in $$PORTS; do \
		cname=$$(docker ps --filter "publish=$$port" --format '{{.Names}}' 2>/dev/null | head -1); \
		if [ -n "$$cname" ]; then \
			CONFLITOS="$$CONFLITOS\n   • $$cname (porta $$port)"; \
		fi; \
	done; \
	if [ -n "$$CONFLITOS" ]; then \
		echo "$(YELLOW)⚠️  Containers usando portas da plataforma:$(NC)"; \
		printf "$$CONFLITOS\n"; \
		read -p "Parar todos antes de iniciar? [Y/n]: " CONFIRM; \
		CONFIRM=$${CONFIRM:-Y}; \
		if echo "$$CONFIRM" | grep -qi "^y"; then \
			for port in $$PORTS; do \
				cname=$$(docker ps --filter "publish=$$port" --format '{{.Names}}' 2>/dev/null | head -1); \
				[ -n "$$cname" ] && docker stop "$$cname" && docker rm "$$cname" 2>/dev/null || true; \
			done; \
			docker compose down 2>/dev/null || true; \
			docker compose --profile test down 2>/dev/null || true; \
			docker compose --profile integration-test down 2>/dev/null || true; \
		fi; \
	fi
	@echo "$(BLUE)Criando rede Docker rede-ggsoft...$(NC)"
	@docker network create rede-ggsoft 2>/dev/null || echo "   Rede já existe"
	@echo "$(BLUE)Fase 1/4: Infraestrutura (mysql, redis)...$(NC)"
	@docker compose up -d $(INFRA_SERVICES)
	@echo "$(BLUE)Aguardando healthcheck da infra...$(NC)"
	@sleep 5
	@echo "$(BLUE)Fase 2/4: Build das aplicações...$(NC)"
	@docker compose build $(APPS_SERVICES)
	@echo "$(BLUE)Fase 3/4: Subindo aplicações...$(NC)"
	@docker compose up -d $(APPS_SERVICES)
	@echo "$(BLUE)Aguardando healthcheck das aplicações...$(NC)"
	@sleep 10
	@echo "$(BLUE)Fase 4/4: Game Server (RGS)...$(NC)"
	@docker compose up -d $(GAME_SERVICES)
	@echo "$(BLUE)Aguardando RGS...$(NC)"
	@sleep 5
	@echo "$(BLUE)Subindo Frontend (nginx, system-control)...$(NC)"
	@docker compose up -d $(FRONTEND_SERVICES)
	@echo "$(GREEN)=== Todos os serviços iniciados ===$(NC)"
	@make status

start-infra: ## Inicia só a infraestrutura (mysql, redis)
	@echo "$(BLUE)=== Iniciando infraestrutura ===$(NC)"
	docker compose up -d $(INFRA_SERVICES)

start-apps: ## Inicia aplicações (dependem da infra)
	@echo "$(BLUE)=== Iniciando aplicações ===$(NC)"
	docker compose up -d $(APPS_SERVICES)

start-rgs: ## Inicia game server (depende das apps)
	@echo "$(BLUE)=== Iniciando RGS ===$(NC)"
	@make init-build
	docker compose up -d $(GAME_SERVICES)

wait-health: ## Aguarda todos os healthchecks passarem
	@echo "$(BLUE)=== Aguardando healthchecks ===$(NC)"
	@docker compose ps --format "table {{.Name}}\t{{.Status}}"

stop: ## Para todos os serviços
	@echo "$(YELLOW)=== Parando plataforma GGSoft ===$(NC)"
	docker compose down

restart: ## Reinicia todos os serviços
	@echo "$(YELLOW)=== Reiniciando plataforma GGSoft ===$(NC)"
	docker compose restart

logs: ## Mostra logs de todos os serviços
	docker compose logs -f

status: ## Mostra status dos serviços
	@echo "$(GREEN)=== Status dos serviços ===$(NC)"
	@docker compose ps

health: ## Mostra status dos healthchecks
	@echo "$(GREEN)=== Healthchecks ===$(NC)"
	@docker compose ps

test: ## Executa testes do wallet-auth
	@echo "$(GREEN)=== Executando testes ===$(NC)"
	docker compose up -d mysql-test
	@sleep 5
	docker compose run --rm wallet-auth-tests

clean: ## Remove containers, volumes e rede (⚠️ Dados serão perdidos!)
	@echo "$(RED)=== ATENÇÃO: Isso removerá TODOS os dados! ===$(NC)"
	@read -p "Digite 'SIM' para confirmar: " confirm && \
	if [ "$${confirm}" = "SIM" ]; then \
		docker compose down -v; \
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
