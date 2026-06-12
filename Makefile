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

.PHONY: help setup init-build start start-infra start-apps start-rgs stop restart logs status wait-health test clean verify envs set-server-ip set-server-ip-manual deploy-https deploy-edge reload-nginx

# Detecta docker compose V2 (plugin) ou docker-compose V1 (binário legado)
DOCKER_COMPOSE := $(shell docker compose version >/dev/null 2>&1 && echo "docker compose" || echo "docker-compose")

# Portable: sed -i (Linux) vs sed -i '' (Mac)
ifeq ($(shell uname -s),Darwin)
  SED_I := sed -i ''
else
  SED_I := sed -i
endif

# Diretórios
ENVS_DIR := ./envs

# WORKSPACE_DIR: pasta pai do _deploy (onde ficam todos os repos)
WORKSPACE_DIR ?= $(shell cd .. && pwd)
export WORKSPACE_DIR

# Edge HTTPS (camada opcional por cima do HTTP) — repo irmão, clonado pelo
# setup-repos.sh junto com os demais (make clone).
EDGE_DIR ?= $(WORKSPACE_DIR)/ggsoft_infra_nginx-proxy-https

# Nginx de assets (HTTP) — repo irmão
ASSETS_DIR ?= $(WORKSPACE_DIR)/ggsoft_infra_nginx

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
	@MAKEFILE_HASH_BEFORE=$$(cat $(MAKEFILE_LIST) | (md5sum 2>/dev/null || md5 2>/dev/null) | cut -d' ' -f1); \
	if ls $(ENVS_DIR)/*.env 2>/dev/null | grep -q .; then \
		mkdir -p /tmp/.ggsoft_env_backup && cp $(ENVS_DIR)/*.env /tmp/.ggsoft_env_backup/; \
	fi; \
	git checkout -- $(ENVS_DIR)/ 2>/dev/null || true; \
	git pull 2>/dev/null || echo "$(YELLOW)⚠️ Não foi possível atualizar _deploy (sem git ou sem remote)$(NC)"; \
	if [ -d /tmp/.ggsoft_env_backup ]; then \
		mkdir -p $(ENVS_DIR) && cp /tmp/.ggsoft_env_backup/*.env $(ENVS_DIR)/ 2>/dev/null || true; \
		rm -rf /tmp/.ggsoft_env_backup; \
	fi; \
	MAKEFILE_HASH_AFTER=$$(cat $(MAKEFILE_LIST) | (md5sum 2>/dev/null || md5 2>/dev/null) | cut -d' ' -f1); \
	if [ "$$MAKEFILE_HASH_BEFORE" != "$$MAKEFILE_HASH_AFTER" ]; then \
		echo "$(YELLOW)🔄 Makefile atualizado! Recarregando $(MAKECMDGOALS)...$(NC)"; \
		exec $(MAKE) $(MAKECMDGOALS) FLAGS="$(FLAGS)"; \
	fi
	@echo "$(BLUE)2. Atualizando repositórios...$(NC)"
	@./scripts/setup-repos.sh
	@echo "$(BLUE)3. Verificando SERVER_IP...$(NC)"
	@export SERVER_IP_DETECTED=""; \
	CURRENT_IP=$$(grep "^SERVER_IP=" $(ENVS_DIR)/system-control.env 2>/dev/null | cut -d'=' -f2 | head -1); \
	if [ -z "$$CURRENT_IP" ] || [ "$$CURRENT_IP" = "localhost" ] || [ "$$CURRENT_IP" = "$${SERVER_IP:-localhost}" ]; then \
		_detect_ip() { \
			hostname -I 2>/dev/null | awk '{print $$1}' | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -1; \
		}; \
		if [ "$(FLAGS)" = "-n" ] || [ "$(FLAGS)" = "-y" ]; then \
			DETECTED_IP=$$(_detect_ip); \
			[ -z "$$DETECTED_IP" ] && DETECTED_IP=$$(ipconfig getifaddr en0 2>/dev/null || true); \
			[ -z "$$DETECTED_IP" ] && DETECTED_IP=$$(ip route get 1 2>/dev/null | sed -n 's/.*src \([0-9.]*\) .*/\1/p'); \
			if [ -n "$$DETECTED_IP" ]; then \
				echo "$(GREEN)✓ IP detectado automaticamente: $$DETECTED_IP$(NC)"; \
				export SERVER_IP_DETECTED="$$DETECTED_IP"; \
			else \
				echo "$(YELLOW)⚠️  Não foi possível detectar IP — usando localhost$(NC)"; \
				export SERVER_IP_DETECTED="localhost"; \
			fi; \
		else \
			HOSTNAME=$$(hostname | tr '[:upper:]' '[:lower:]'); \
			if echo "$$HOSTNAME" | grep -q "local"; then \
				echo "$(GREEN)✓ Hostname '$$HOSTNAME' contém 'local' — usando SERVER_IP=localhost$(NC)"; \
				export SERVER_IP_DETECTED="localhost"; \
			else \
				DETECTED_IP=$$(_detect_ip); \
				[ -z "$$DETECTED_IP" ] && DETECTED_IP=$$(ipconfig getifaddr en0 2>/dev/null || true); \
				[ -z "$$DETECTED_IP" ] && DETECTED_IP=$$(ip route get 1 2>/dev/null | sed -n 's/.*src \([0-9.]*\) .*/\1/p'); \
				if [ -n "$$DETECTED_IP" ]; then \
					echo "$(GREEN)✓ IP detectado automaticamente: $$DETECTED_IP$(NC)"; \
					export SERVER_IP_DETECTED="$$DETECTED_IP"; \
				else \
					echo "$(YELLOW)⚠️  SERVER_IP não configurado$(NC)"; \
					echo "$(YELLOW)   Execute: make set-server-ip$(NC)"; \
					exit 1; \
				fi; \
			fi; \
		fi; \
	else \
		echo "$(GREEN)✓ SERVER_IP configurado: $$CURRENT_IP$(NC)"; \
		export SERVER_IP_DETECTED="$$CURRENT_IP"; \
	fi; \
	echo "$(BLUE)4. Configuração interativa (senhas, usuários)...$(NC)"; \
	if [ -n "$$SERVER_IP_DETECTED" ]; then \
		SERVER_IP="$$SERVER_IP_DETECTED" ./scripts/deploy-interactive.sh $(FLAGS) || true; \
	else \
		./scripts/deploy-interactive.sh $(FLAGS) || true; \
	fi
	@echo "$(BLUE)5. Sincronizando .env para todos os projetos...$(NC)"
	@./scripts/sync-envs.sh
	@echo "$(BLUE)6. Gate de qualidade (testes)...$(NC)"
	@./scripts/deploy-with-tests.sh
	@echo "$(GREEN)7. Iniciando serviços...$(NC)"
	@$(MAKE) start FLAGS="$(FLAGS)"

deploy-y: ## Deploy com auto-yes (mantém configs ou aceita defaults)
	@$(MAKE) deploy FLAGS=-y

deploy-n: ## Deploy com auto-no (recria tudo com padrões e limpa volumes)
	@$(MAKE) deploy FLAGS=-n

deploy-quick: ## Deploy rápido sem testes - atualiza _deploy + envs + sync + start
	@echo "$(YELLOW)=== Deploy GGSoft SEM testes ===$(NC)"
	@echo "$(RED)⚠️  AVISO: Pulando testes de qualidade!$(NC)"
	@./scripts/deploy-interactive.sh $(FLAGS)
	@./scripts/sync-envs.sh
	@echo "$(GREEN)=== Iniciando todos os serviços ===$(NC)"
	@$(MAKE) start FLAGS="$(FLAGS)"

deploy-https: ## Deploy completo (HTTP) + camada HTTPS (edge nginx-proxy)
	@$(MAKE) deploy FLAGS="$(FLAGS)"
	@$(MAKE) deploy-edge

deploy-edge: ## Insere só a camada HTTPS (edge) sobre o HTTP que já está rodando
	@echo "$(BLUE)=== Camada HTTPS (edge nginx-proxy) ===$(NC)"
	@$(MAKE) -C "$(EDGE_DIR)" up
	@$(MAKE) -C "$(EDGE_DIR)" crm system-control game
	@echo "$(GREEN)✓ HTTPS inserido — HTTP segue intacto.$(NC)"
	@echo "$(YELLOW)   Cert real (precisa DNS apontando): make -C $(EDGE_DIR) cert$(NC)"

reload-nginx: ## Aplica o config do assets (default.conf/nginx.conf) no ggsoft_nginx — ZERO downtime
	@echo "$(BLUE)=== Recarregando ggsoft_nginx (assets) ===$(NC)"
	@git -C "$(ASSETS_DIR)" pull --ff-only 2>/dev/null || echo "$(YELLOW)⚠ git pull do assets ignorado$(NC)"
	@if docker ps --format '{{.Names}}' | grep -q '^ggsoft_nginx$$'; then \
		docker exec -i ggsoft_nginx sh -c 'cat > /etc/nginx/conf.d/default.conf' < "$(ASSETS_DIR)/default.conf"; \
		docker exec -i ggsoft_nginx sh -c 'cat > /etc/nginx/nginx.conf'            < "$(ASSETS_DIR)/nginx.conf"; \
		if docker exec ggsoft_nginx nginx -t; then \
			docker exec ggsoft_nginx nginx -s reload; \
			echo "$(GREEN)✓ ggsoft_nginx recarregado (zero downtime)$(NC)"; \
		else \
			echo "$(RED)❌ nginx -t falhou — reload abortado, produção intacta$(NC)"; exit 1; \
		fi; \
	else \
		echo "$(YELLOW)⚠ ggsoft_nginx não está rodando — use 'make start' ou 'make deploy'$(NC)"; \
	fi

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
		$(SED_I) "s/^SERVER_IP=.*/SERVER_IP=localhost/" $(ENVS_DIR)/system-control.env; \
		echo "$(GREEN)✓ SERVER_IP=localhost configurado$(NC)"; \
	else \
		echo "$(YELLOW)⚠️  Ambiente remoto/SSH detectado$(NC)"; \
		DETECTED_IP=$$(hostname -I 2>/dev/null | awk '{print $$1}' | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -1); \
		[ -z "$$DETECTED_IP" ] && DETECTED_IP=$$(ipconfig getifaddr en0 2>/dev/null || true); \
		[ -z "$$DETECTED_IP" ] && DETECTED_IP=$$(ip route get 1 2>/dev/null | sed -n 's/.*src \([0-9.]*\) .*/\1/p'); \
		[ -z "$$DETECTED_IP" ] && DETECTED_IP=$$(ifconfig 2>/dev/null | grep -Eo 'inet ([0-9]+\.){3}[0-9]+' | awk '{print $$2}' | grep -v '127.0.0.1' | head -1); \
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
			$(SED_I) "s/^SERVER_IP=.*/SERVER_IP=$$FINAL_IP/" $(ENVS_DIR)/system-control.env; \
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
	$(SED_I) "s/^SERVER_IP=.*/SERVER_IP=$(IP)/" $(ENVS_DIR)/system-control.env; \
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
	@$(MAKE) init-build
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
	@$(MAKE) init-build
	@echo "$(BLUE)Fase 0/4: Derrubando containers existentes...$(NC)"
	@CONTAINERS=$$(docker ps -q --filter "name=ggsoft" 2>/dev/null); [ -n "$$CONTAINERS" ] && docker stop $$CONTAINERS 2>/dev/null || true
	@CONTAINERS=$$(docker ps -aq --filter "name=ggsoft" 2>/dev/null); [ -n "$$CONTAINERS" ] && docker rm -f $$CONTAINERS 2>/dev/null || true
	@$(DOCKER_COMPOSE) down 2>/dev/null || true
	@echo "$(BLUE)Criando rede Docker rede-ggsoft...$(NC)"
	@docker network create rede-ggsoft 2>/dev/null || echo "   Rede já existe"
	@echo "$(BLUE)Fase 1/4: Infraestrutura (mysql, redis)...$(NC)"
	@$(DOCKER_COMPOSE) up -d $(INFRA_SERVICES)
	@echo "$(BLUE)Aguardando healthcheck da infra...$(NC)"
	@sleep 5
	@echo "$(BLUE)Fase 2/4: Build das aplicações...$(NC)"
	@if [ "$(FLAGS)" = "-n" ]; then \
		echo "$(YELLOW)   Modo -n: build sem cache$(NC)"; \
		$(DOCKER_COMPOSE) build --no-cache $(APPS_SERVICES); \
	else \
		$(DOCKER_COMPOSE) build $(APPS_SERVICES); \
	fi
	@echo "$(BLUE)Fase 3/4: Subindo aplicações...$(NC)"
	@$(DOCKER_COMPOSE) up -d --force-recreate $(APPS_SERVICES)
	@echo "$(BLUE)Aguardando healthcheck das aplicações...$(NC)"
	@sleep 10
	@echo "$(BLUE)Fase 4/4: Game Server (RGS)...$(NC)"
	@$(DOCKER_COMPOSE) up -d $(GAME_SERVICES)
	@echo "$(BLUE)Aguardando RGS...$(NC)"
	@sleep 5
	@echo "$(BLUE)Build do Frontend (system-control)...$(NC)"
	@if [ "$(FLAGS)" = "-n" ]; then \
		$(DOCKER_COMPOSE) build --no-cache system-control; \
	else \
		$(DOCKER_COMPOSE) build system-control; \
	fi
	@echo "$(BLUE)Subindo Frontend (nginx, system-control)...$(NC)"
	@$(DOCKER_COMPOSE) up -d --force-recreate $(FRONTEND_SERVICES)
	@echo "$(GREEN)=== Todos os serviços iniciados ===$(NC)"
	@$(MAKE) status

start-infra: ## Inicia só a infraestrutura (mysql, redis)
	@echo "$(BLUE)=== Iniciando infraestrutura ===$(NC)"
	$(DOCKER_COMPOSE) up -d $(INFRA_SERVICES)

start-apps: ## Inicia aplicações (dependem da infra)
	@echo "$(BLUE)=== Iniciando aplicações ===$(NC)"
	$(DOCKER_COMPOSE) up -d $(APPS_SERVICES)

start-rgs: ## Inicia game server (depende das apps)
	@echo "$(BLUE)=== Iniciando RGS ===$(NC)"
	@$(MAKE) init-build
	$(DOCKER_COMPOSE) up -d $(GAME_SERVICES)

wait-health: ## Aguarda todos os healthchecks passarem
	@echo "$(BLUE)=== Aguardando healthchecks ===$(NC)"
	@$(DOCKER_COMPOSE) ps --format "table {{.Name}}\t{{.Status}}"

stop: ## Para todos os serviços
	@echo "$(YELLOW)=== Parando plataforma GGSoft ===$(NC)"
	$(DOCKER_COMPOSE) down

restart: ## Reinicia todos os serviços
	@echo "$(YELLOW)=== Reiniciando plataforma GGSoft ===$(NC)"
	$(DOCKER_COMPOSE) restart

logs: ## Mostra logs de todos os serviços
	$(DOCKER_COMPOSE) logs -f

status: ## Mostra status dos serviços
	@echo "$(GREEN)=== Status dos serviços ===$(NC)"
	@$(DOCKER_COMPOSE) ps

health: ## Mostra status dos healthchecks
	@echo "$(GREEN)=== Healthchecks ===$(NC)"
	@$(DOCKER_COMPOSE) ps

test: ## Executa testes do wallet-auth
	@echo "$(GREEN)=== Executando testes ===$(NC)"
	$(DOCKER_COMPOSE) up -d mysql-test
	@sleep 5
	$(DOCKER_COMPOSE) run --rm wallet-auth-tests

clean: ## Remove containers, volumes GGSoft e rede (⚠️ Dados serão perdidos!)
	@echo "$(RED)=== ATENÇÃO: Isso removerá containers e volumes do GGSoft! ===$(NC)"
	@read -p "Digite 'SIM' para confirmar: " confirm && \
	if [ "$${confirm}" = "SIM" ]; then \
		$(DOCKER_COMPOSE) down; \
		docker volume rm ggsoft_platform_mysql_data 2>/dev/null || true; \
		docker volume rm ggsoft_platform_redis_data 2>/dev/null || true; \
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
