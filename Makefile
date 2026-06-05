DEPLOY_DIR := $(shell pwd)
BASE       := $(DEPLOY_DIR)/ggsoft
GIT        := git@github-ggsoft:GGSoftBR

REPOS := \
	ggsoft_infra_mysql \
	ggsoft_infra_redis \
	ggsoft_infra_nginx \
	ggsoft_core_cs \
	ggsoft_core_lounge \
	ggsoft_core_rgs_slot3x3 \
	ggsoft_core_math_slot \
	ggsoft_core_history

DC_MYSQL   := docker-compose -f $(BASE)/ggsoft_infra_mysql/docker-compose.yml
DC_REDIS   := docker-compose -f $(BASE)/ggsoft_infra_redis/docker-compose.yml
DC_CS      := docker-compose -f $(BASE)/ggsoft_core_cs/cs/docker-compose.yml
DC_LOUNGE  := docker-compose -f $(BASE)/ggsoft_core_lounge/docker-compose.yml
DC_RGS     := docker-compose -f $(BASE)/ggsoft_core_rgs_slot3x3/docker-compose.yml
DC_MATH    := docker-compose -f $(BASE)/ggsoft_core_math_slot/docker-compose.yml
DC_HISTORY := docker-compose -f $(BASE)/ggsoft_core_history/docker-compose.yml
DC_NGINX   := docker-compose -f $(BASE)/ggsoft_infra_nginx/docker-compose.yml

.PHONY: help clone pull env up build run deploy stop restart log log-mysql log-redis log-cs log-lounge log-rgs log-nginx log-math log-history monitor status erase

clone: ## Clona todos os repositórios em ./ggsoft/
	@mkdir -p $(BASE)
	@for repo in $(REPOS); do \
		if [ ! -d "$(BASE)/$$repo" ]; then \
			echo "▶ Clonando $$repo..."; \
			if ! git clone $(GIT)/$$repo.git $(BASE)/$$repo 2>&1; then \
				echo ""; \
				echo "╔══════════════════════════════════════════════════════════╗"; \
				echo "║                  ❌ ERRO DE ACESSO SSH                  ║"; \
				echo "╠══════════════════════════════════════════════════════════╣"; \
				echo "║  Não foi possível clonar: $$repo                        ║"; \
				echo "║                                                          ║"; \
				echo "║  A chave SSH deste servidor não está autorizada.         ║"; \
				echo "║                                                          ║"; \
				echo "║  Entre em contato com o suporte GGSoft e forneça        ║"; \
				echo "║  a chave pública SSH deste servidor:                     ║"; \
				echo "║                                                          ║"; \
				echo "║    cat ~/.ssh/ggsoft.pub                                 ║"; \
				echo "║                                                          ║"; \
				echo "║  Consulte o README.md para instruções completas.         ║"; \
				echo "╚══════════════════════════════════════════════════════════╝"; \
				echo ""; \
				exit 1; \
			fi \
		else \
			echo "  $$repo já existe, pulando."; \
		fi \
	done
	@echo "✅ Clone concluído em $(BASE)"

pull: ## Atualiza todos os repositórios backend/infra
	@for repo in $(REPOS); do \
		echo "▶ Pull $$repo..."; \
		git -C $(BASE)/$$repo pull origin main 2>/dev/null || echo "  ⚠️  $$repo: falhou"; \
	done
	@echo "✅ Pull concluído."

help: ## Mostra este menu
	@echo ""
	@echo "  GGSoft Deploy"
	@echo ""
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'
	@echo ""

env: ## Cria todos os .env no local correto de cada projeto
	@bash $(DEPLOY_DIR)/setup_envs.sh $(BASE)

up: ## Sobe todos os serviços (sem rebuild)
	@echo "▶ MySQL..."
	@$(DC_MYSQL) up -d
	@echo "   aguardando MySQL (15s)..."
	@sleep 15
	@echo "▶ Redis..."
	@$(DC_REDIS) up -d
	@echo "▶ Math..."
	@$(DC_MATH) up -d
	@echo "▶ History..."
	@$(DC_HISTORY) up -d
	@echo "▶ CS..."
	@$(DC_CS) up -d
	@sleep 5
	@echo "▶ RGS Slot (solid + fruits)..."
	@$(DC_RGS) up -d
	@echo "▶ Lounge..."
	@$(DC_LOUNGE) up -d
	@echo "▶ Nginx..."
	@$(DC_NGINX) up -d
	@echo ""
	@echo "✅ Todos no ar!"
	@echo "   Lounge  → http://localhost:23458"
	@echo "   Nginx   → http://localhost:8001"
	@echo "   CS      → http://localhost:8888"
	@echo "   RGS solid  → http://localhost:43319"
	@echo "   RGS fruits → http://localhost:43316"

build: ## Build + sobe todos os serviços
	@docker network create rede-ggsoft 2>/dev/null || true
	@echo "▶ MySQL..."
	@$(DC_MYSQL) up -d
	@echo "   aguardando MySQL (25s)..."
	@sleep 25
	@echo "▶ Redis..."
	@$(DC_REDIS) up -d
	@echo "▶ Math (build)..."
	@$(DC_MATH) up --build -d
	@echo "▶ History (build)..."
	@$(DC_HISTORY) up --build -d
	@echo "▶ CS (build)..."
	@$(DC_CS) up --build -d
	@sleep 5
	@echo "▶ RGS Slot (build)..."
	@$(DC_RGS) up --build -d
	@echo "▶ Lounge (build)..."
	@$(DC_LOUNGE) up --build -d
	@echo "▶ Nginx..."
	@$(DC_NGINX) up -d
	@echo ""
	@echo "✅ Build completo!"

deploy: ## 🚀 Tudo automatico: clone/pull + .envs + build + sobe
	@if [ ! -f "$(DEPLOY_DIR)/ggsoft.env" ]; then \
		echo ""; \
		echo "❌ ERRO: arquivo ggsoft.env não encontrado!"; \
		echo ""; \
		echo "   Execute:"; \
		echo "   cp ggsoft.env.example ggsoft.env"; \
		echo "   nano ggsoft.env   # preencha as senhas"; \
		echo ""; \
		exit 1; \
	fi
	@if grep -q "ALTERE_" "$(DEPLOY_DIR)/ggsoft.env"; then \
		echo ""; \
		echo "❌ ERRO: ggsoft.env ainda tem valores não preenchidos (ALTERE_*)!"; \
		echo "   Edite o arquivo antes de continuar: nano ggsoft.env"; \
		echo ""; \
		exit 1; \
	fi
	@echo "\n========================================"
	@echo "  GGSoft Deploy - inicio"
	@echo "========================================\n"
	@mkdir -p $(BASE)
	@for repo in $(REPOS); do \
		if [ ! -d "$(BASE)/$$repo" ]; then \
			echo "▶ Clonando $$repo..."; \
			git clone $(GIT)/$$repo.git $(BASE)/$$repo; \
		else \
			echo "▶ Pull $$repo..."; \
			git -C $(BASE)/$$repo pull origin main; \
		fi \
	done
	@echo "\n▶ Criando .envs..."
	@bash $(DEPLOY_DIR)/setup_envs.sh $(BASE)
	@echo "\n▶ Criando rede rede-ggsoft..."
	@docker network create rede-ggsoft 2>/dev/null || echo "   rede ja existe"
	@echo "▶ MySQL..."
	@$(DC_MYSQL) up -d
	@echo "   aguardando MySQL ficar pronto (25s)..."
	@sleep 25
	@echo "▶ Redis..."
	@$(DC_REDIS) up -d
	@echo "▶ Math (build)..."
	@$(DC_MATH) up --build -d
	@echo "▶ History (build)..."
	@$(DC_HISTORY) up --build -d
	@echo "▶ CS (build)..."
	@$(DC_CS) up --build -d
	@sleep 5
	@echo "▶ RGS (build)..."
	@$(DC_RGS) up --build -d
	@echo "▶ Lounge (build)..."
	@$(DC_LOUNGE) up --build -d
	@echo "▶ Nginx..."
	@$(DC_NGINX) up -d
	@echo "\n========================================"
	@echo "  ✅ GGSoft no ar!"
	@echo "  Lounge  → http://localhost:23458"
	@echo "  Nginx   → http://localhost:8001"
	@echo "  CS      → http://localhost:8888"
	@echo "  RGS solid  → http://localhost:43310"
	@echo "  RGS fruits → http://localhost:43316"
	@echo "========================================\n"
	@echo "▶ Status dos containers:"
	@docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

run: env build ## Cria .envs + build + sobe tudo

stop: ## Para todos os serviços
	@$(DC_NGINX) down
	@$(DC_LOUNGE) down
	@$(DC_RGS) down
	@$(DC_MATH) down
	@$(DC_HISTORY) down
	@$(DC_CS) down
	@$(DC_REDIS) down
	@$(DC_MYSQL) down
	@echo "🛑 Todos parados."

restart: stop build ## Para e sobe tudo novamente

status: ## Status de todos os containers
	@docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "NAME|mysql|redis|cs|lounge|nginx" || docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

log: ## Logs de todos (últimas 20 linhas de cada)
	@echo "=== MySQL ===" && $(DC_MYSQL) logs --tail=20
	@echo "=== Redis ===" && $(DC_REDIS) logs --tail=20
	@echo "=== CS ===" && $(DC_CS) logs --tail=20
	@echo "=== RGS ===" && $(DC_RGS) logs --tail=20
	@echo "=== Lounge ===" && $(DC_LOUNGE) logs --tail=20
	@echo "=== Nginx ===" && $(DC_NGINX) logs --tail=20

log-mysql: ## Logs do MySQL (follow)
	@$(DC_MYSQL) logs -f

log-redis: ## Logs do Redis (follow)
	@$(DC_REDIS) logs -f

log-cs: ## Logs do CS (follow)
	@$(DC_CS) logs -f

log-lounge: ## Logs do Lounge (follow)
	@$(DC_LOUNGE) logs -f

log-rgs: ## Logs do RGS Slot (follow)
	@$(DC_RGS) logs -f

log-nginx: ## Logs do Nginx (follow)
	@$(DC_NGINX) logs -f

monitor: ## Monitor em tempo real dos containers (atualiza a cada 2s)
	@watch -n 2 -c '\
		echo "\033[1;36m╔══════════════════════════════════════════════════════════╗\033[0m"; \
		echo "\033[1;36m║           GGSoft - Monitor de Containers                ║\033[0m"; \
		echo "\033[1;36m╚══════════════════════════════════════════════════════════╝\033[0m"; \
		echo ""; \
		docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null | awk \
		  "NR==1{print \"\033[1;33m\" \$$0 \"\033[0m\"; next} \
		   /Up/{print \"\033[1;32m✔  \" \$$0 \"\033[0m\"; next} \
		   /Exit|Restarting|Dead/{print \"\033[1;31m✖  \" \$$0 \"\033[0m\"; next} \
		   {print \"   \" \$$0}"; \
		echo ""; \
		echo "\033[0;37m  Lounge  → http://localhost:23458\033[0m"; \
		echo "\033[0;37m  Nginx   → http://localhost:8001\033[0m"; \
		echo "\033[0;37m  CS      → http://localhost:8888\033[0m"; \
		echo "\033[0;37m  Ctrl+C para sair\033[0m"; \
	'

log-math: ## Logs do Math ZMQ (follow)
	@$(DC_MATH) logs -f

log-history: ## Logs do History (follow)
	@$(DC_HISTORY) logs -f

erase: stop ## Para tudo e limpa imagens/volumes Docker
	@docker system prune -f
	@echo "🧹 Docker limpo."
