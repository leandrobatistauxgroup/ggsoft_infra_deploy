# GGSoft Platform - Infraestrutura de Deploy

Orquestração unificada de todos os serviços da plataforma GGSoft.

## 📁 Estrutura

```
ggsoft_infra_deploy/
├── docker-compose.yml      # Orquestração principal (com healthchecks)
├── Makefile               # Comandos úteis (ordem de subida controlada)
├── .build                 # Arquivo numérico (CRÍTICO para RGS funcionar)
├── .gitignore             # Arquivos ignorados pelo git
├── DEPLOY_INFO.md         # 📚 Documentação completa de todas as configurações
├── envs/                  # Arquivos .env separados por serviço
│   ├── mysql.env
│   ├── redis.env
│   ├── wallet-auth.env    # CS (Credit Server) - antigo core_cs
│   ├── history.env
│   ├── math.env
│   ├── rgs.env
│   └── system-control.env # Painel de controle (novo)
├── reports/               # 📊 Relatórios de falha (gerados automaticamente)
│   └── deploy_failure_*.md
├── scripts/
│   ├── deploy-interactive.sh   # Deploy interativo (sem testes)
│   ├── deploy-with-tests.sh     # Deploy com gate de qualidade (com testes)
│   ├── sync-envs.sh             # Sincroniza .env para todos os projetos
│   └── verify-envs.sh          # Valida sincronização de senhas
└── README.md
```

## 🚀 Setup Inicial

### Deploy Completo (Recomendado - Um Comando)

```bash
make deploy    # Faz TUDO: testes + envs + sync + start
```

**O `make deploy` executa automaticamente:**
1. 🧪 **Testes** do wallet-auth (gate de qualidade)
2. ✅ Se passar → deploy interativo (pergunta configurações)
3. 📝 **Gera .env** em `envs/` com suas configurações
4. 🔄 **Sincroniza** .env para todos os projetos individuais
5. 🚀 **Inicia** todos os serviços automaticamente

❌ Se testes falharem → gera relatório de falha e **aborta**

**O deploy irá perguntar:**
- 🌍 Localização (padrão: GGSOFT)
- 🗄️ Usuário e senha do MySQL
- 🔐 Senha do Redis
- 🔑 Chaves secretas (HMAC, API)
- 🎮 Tokens de teste
- 📡 Portas (Enter = padrões)

Senhas em branco serão **auto-geradas** com segurança (32-64 chars + símbolos).

### ⚡ Deploy Rápido (Sem Testes)

```bash
make deploy-quick    # Faz tudo SEM testes (use com cautela!)
```

**Executa:** deploy interativo + sync + start (sem gate de qualidade)

> ⚠️ **AVISO:** `deploy-quick` pula os testes. Use apenas em desenvolvimento ou quando já rodou testes manualmente.

### Opção 2: Configuração Manual

Edite os arquivos em `envs/` com suas senhas:

```bash
# Senhas que precisam ser iguais entre serviços:
# REDIS_PASSWORD: redis.env, history.env, rgs.env, system-control.env
# MYSQL_PASSWORD: mysql.env, wallet-auth.env, system-control.env
# HISTORY_SECRET_KEY: history.env, rgs.env
```

**Valide as configurações:**
```bash
make verify    # Verifica se senhas estão sincronizadas
make setup     # Cria rede Docker e verifica estrutura
make start     # Inicia todos os serviços
```

### ⚠️ Importante: Arquivo .build (CRÍTICO)

O RGS requer que `.build` seja um **arquivo numérico** (não uma pasta). Se for uma pasta, o build falha:

```bash
make init-build    # Garante que .build é arquivo (executado automaticamente no setup)
make reset-rgs     # Reseta .build se necessário
```

## 📋 Comandos Disponíveis

### Comandos Principais

| Comando | Descrição |
|---------|-----------|
| `make deploy` | **Deploy completo** - testes + envs + sync + start ✅ |
| `make deploy-quick` | Deploy completo SEM testes (use com cautela ⚠️) |
| `make setup` | Setup inicial (rede Docker, verificação, .build) |
| `make sync` | Copia .env do deploy para todos os projetos |
| `make start` | Inicia todos os serviços na ordem correta |
| `make stop` | Para todos os serviços |
| `make restart` | Reinicia serviços |
| `make logs` | Mostra logs em tempo real |
| `make status` | Status dos containers |
| `make health` | Status dos healthchecks |
| `make verify` | Valida sincronização de senhas |

### 📊 Relatórios de Falha

Se os testes falharem durante `make deploy`, um relatório é gerado:

```
reports/
├── deploy_failure_YYYYMMDD_HHMMSS.md    # Relatório da falha
└── test_output_YYYYMMDD_HHMMSS.log    # Log completo dos testes
```

Consulte esses arquivos para investigar o problema.

### Comandos de Subida Gradual (útil para debug)

| Comando | Descrição |
|---------|-----------|
| `make start-infra` | Inicia só MySQL + Redis |
| `make start-apps` | Inicia Wallet-Auth + History + Math |
| `make start-rgs` | Inicia RGS (depende das apps) |

### Utilitários

| Comando | Descrição |
|---------|-----------|
| `make init-build` | Garante que .build é arquivo (não pasta) |
| `make reset-rgs` | Reseta .build do RGS |
| `make test` | Executa testes do wallet-auth |
| `make clean` | Remove tudo (⚠️ perde dados) |
| `make envs` | Lista arquivos de configuração |

## 🌐 Serviços e Portas

| Serviço | Container | Porta Host | Descrição |
|---------|-----------|------------|-----------|
| MySQL | `mysql_database` | 53306 | Banco de dados CS1 |
| Redis | `ggsoft_redis` | 36380 | Cache e sessões |
| Nginx | `ggsoft_nginx` | 8001 | Assets estáticos |
| Wallet-Auth | `python-app-wallet-auth` | 8888 | CS - Crédito/Auth |
| History | `ggsoft_history` | 8890 | Histórico de jogadas |
| Math | `ggsoft-zmq-server-slot` | - | Motor matemático ZMQ |
| RGS (Fruit) | `rgs-fruit` | 43317 | Game server slot |
| System Control | `ggsoft_system-control` | 127.0.0.1:2555 | Painel de controle |

## � Ordem de Subida (Startup Order)

O `make start` sobe os serviços na ordem correta, respeitando dependências:

```
┌─────────────────────────────────────────────────────────────────┐
│  FASE 1: Infraestrutura (aguarda healthcheck)                   │
│  ├── mysql (healthcheck: mysqladmin ping)                        │
│  └── redis (healthcheck: redis-cli ping)                         │
├─────────────────────────────────────────────────────────────────┤
│  FASE 2: Aplicações (aguardam infra saudável)                   │
│  ├── wallet-auth (depende: mysql, redis)                       │
│  ├── history (depende: redis)                                    │
│  └── math (sem dependências externas)                           │
├─────────────────────────────────────────────────────────────────┤
│  FASE 3: Game Server (aguarda aplicações)                       │
│  └── rgs-fruit (depende: wallet-auth, history, redis, math)    │
├─────────────────────────────────────────────────────────────────┤
│  FASE 4: Frontend                                               │
│  ├── nginx (depende: wallet-auth, rgs-fruit)                    │
│  └── system-control                                             │
└─────────────────────────────────────────────────────────────────┘
```

> **Nota:** O docker-compose v2+ suporta `depends_on` com `condition: service_healthy`. 
> Isso garante que cada serviço só sobe depois que suas dependências estão realmente prontas.

## �🔗 Dependências entre Serviços

```
┌─────────────────────────────────────────────────────────────┐
│                      INFRASTRUCTURE                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                    │
│  │  MySQL   │  │  Redis   │  │  Nginx   │                    │
│  │ :53306   │  │ :36380   │  │ :8001    │                    │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘                    │
└───────┼────────────┼────────────┼────────────────────────────┘
        │            │            │
        └────────────┼────────────┘
                     │
        ┌────────────┼────────────┐
        │            │            │
   ┌────▼─────┐ ┌───▼────┐ ┌────▼──────┐
   │  Wallet  │ │ History│ │   Math    │
   │  -Auth   │ │ :8890  │ │   ZMQ     │
   │  :8888   │ │        │ │  :49235   │
   └────┬─────┘ └────────┘ └─────┬─────┘
        │                        │
        └──────────┬─────────────┘
                   │
            ┌──────▼──────┐
            │    RGS      │
            │   :43317    │
            │  (Games)    │
            └─────────────┘
```

## 📝 Notas

- Todos os serviços usam a rede Docker `rede-ggsoft` (externa)
- O painel de controle (`system-control`) só é acessível via localhost (127.0.0.1:2555)
- Os arquivos `.env` estão organizados em `envs/` para melhor manutenção
- O serviço `wallet-auth` é o antigo `core_cs`
- O `system-control` é um novo serviço de painel de controle Docker

## 🧪 Testes

```bash
make test    # Executa testes do wallet-auth
```

## 🗂️ Repositórios Incluídos

| Repositório | Função |
|-------------|--------|
| `ggsoft_infra_mysql` | Banco de dados |
| `ggsoft_infra_redis` | Cache/Session |
| `ggsoft_infra_nginx` | Reverse proxy |
| `ggsoft_wallet-auth` | CS (core_cs) |
| `ggsoft_system-control` | Painel de controle (novo) |
| `ggsoft_history` | Histórico |
| `ggsoft_math_3x3` | Motor matemático |
| `ggsoft_rgs_3x3` | Game server |
| `ggsoft_slot_3x3` | Assets dos jogos |

> **Nota:** O `ggsoft_slot_3x3` precisa ser buildado (`make build-fruits` na pasta dele) para copiar os assets para `ggsoft_infra_nginx/games/8/` antes de jogar.

---

## 📚 Documentação Adicional

- **[DEPLOY_INFO.md](./DEPLOY_INFO.md)** - Guia completo com todas as informações necessárias para deploy:
  - Checklist de configurações obrigatórias e opcionais
  - Padrões e valores sugeridos para cada campo
  - Sincronização de senhas entre serviços
  - Validações pós-deploy
  - Troubleshooting completo

Consulte o `DEPLOY_INFO.md` quando precisar de referência detalhada sobre cada configuração ou para deploy manual sem o assistente interativo.
