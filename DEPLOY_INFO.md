# GGSoft Platform - Guia de Informações para Deploy

> Documentação completa das informações necessárias para realizar o deploy da plataforma GGSoft. Use este guia quando `make deploy` não estiver disponível ou para referência manual.

---

## �️ Gate de Qualidade

O deploy padrão (`make deploy`) inclui um **gate de qualidade** que executa testes automatizados antes de permitir o deploy.

### Fluxo do Deploy

```
┌─────────────────┐
│  make deploy    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Executa Testes  │ ◄── wallet-auth + lounge tests (pytest)
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
┌───────┐ ┌───────────┐
│ PASSOU│ │ FALHOU    │
└───┬───┘ └─────┬─────┘
    │           │
    ▼           ▼
┌──────────┐ ┌────────────────────┐
│ Continua │ │ Gera relatório .md │
│ Deploy   │ │ Aborta deploy      │
└──────────┘ └────────────────────┘
```

### Comandos de Deploy

| Comando | Descrição | Quando Usar |
|---------|-----------|-------------|
| `make deploy` | **Padrão** - Com testes | Sempre que possível (recomendado) |
| `make deploy-quick` | Sem testes | Desenvolvimento local, testes já executados |

### Se Testes Falharem

Um relatório é gerado automaticamente em:
```
reports/deploy_failure_YYYYMMDD_HHMMSS.md
reports/test_output_YYYYMMDD_HHMMSS.log
```

---

## �📋 Checklist de Informações Necessárias

Antes de iniciar o deploy, colete as seguintes informações:

### 1. 🌍 Localização e Ambiente

| Campo | Obrigatório | Padrão | Descrição |
|-------|-------------|--------|-----------|
| `LOCATION` | Sim | `GGSOFT` | Identificador do ambiente (ex: GGSOFT, PROD, STAGING). Usado pelo RGS para identificar a localização do game. |
| `MODE_ENV` | Sim | `LOCAL` | Modo de operação: `LOCAL` (logs detalhados), `production` (modo produção). |

### 2. 🗄️ Configurações do MySQL

| Campo | Obrigatório | Padrão | Descrição |
|-------|-------------|--------|-----------|
| `MYSQL_CONTAINER_NAME` | Sim | `mysql_database` | Nome do container MySQL na rede Docker. **Não alterar** se usar o compose unificado. |
| `MYSQL_IMAGE` | Sim | `mysql:8.4.0` | Imagem Docker do MySQL. |
| `MYSQL_HOST_PORT` | Sim | `53306` | Porta exposta no host para acesso externo ao MySQL. |
| `MYSQL_USER` | Sim | `ggsoft_user` | Usuário do banco de dados CS1. |
| `MYSQL_PASSWORD` | **Sim** | - | Senha do usuário do banco. **Mínimo 8 caracteres**. |
| `MYSQL_ROOT_PASSWORD` | **Sim** | - | Senha do root do MySQL. Geralmente `${MYSQL_PASSWORD}_root`. |
| `MYSQL_DATABASE` | Sim | `CS1` | Nome do banco de dados. Não alterar sem refatorar código. |

**⚠️ Importante:** O MySQL só aplica as senhas na **primeira inicialização**. Se o volume já existe, alterar estas senhas nos arquivos `.env` não altera as senhas reais. Seria necessário apagar o volume `mysql_data` e recriar.

### 3. 🔐 Configurações do Redis

| Campo | Obrigatório | Padrão | Descrição |
|-------|-------------|--------|-----------|
| `REDIS_CONTAINER_NAME` | Sim | `ggsoft_redis` | Nome do container Redis na rede Docker. **Não alterar** se usar o compose unificado. |
| `REDIS_IMAGE` | Sim | `redis:latest` | Imagem Docker do Redis. |
| `REDIS_PORT` | Sim | `36380` | Porta exposta no host para acesso ao Redis. |
| `REDIS_PASSWORD` | **Sim** | - | Senha de autenticação do Redis. **Mínimo 8 caracteres**. |

### 4. 🔑 Chaves de Segurança

| Campo | Obrigatório | Padrão | Descrição | Onde Usar |
|-------|-------------|--------|-----------|-----------|
| `SECRET_KEY` (Wallet-Auth) | **Sim** | - | Chave HMAC-SHA256 para assinatura de endpoints. **Mínimo 48 caracteres recomendado**. Usada em `/credit`, `/withdrawal`, `/pin`. | `wallet-auth.env` |
| `API_SECRET_KEY` (History) | **Sim** | - | Chave API para autenticação no History (header `X-API-KEY`). **Mínimo 24 caracteres**. | `history.env` |
| `HISTORY_SECRET_KEY` (RGS) | **Sim** | - | Deve ser **igual** ao `API_SECRET_KEY` do History. Usada pelo RGS para autenticar no History. | `rgs.env` |
| `REQUIRE_HMAC` | Não | `false` | Se `true`, exige HMAC nos endpoints opt-in (`/movement`, `/partner_credit`). | `wallet-auth.env` |

**Geração de chaves seguras:**
```bash
# HMAC Secret (48+ chars)
python3 -c "import secrets; print(secrets.token_urlsafe(48))"

# API Secret (24+ chars)
python3 -c "import secrets; print(secrets.token_urlsafe(24))"
```

### 5. 🎮 Configurações de Teste (Opcional)

| Campo | Obrigatório | Padrão | Descrição |
|-------|-------------|--------|-----------|
| `RGS_TOKEN` | Não | `lab1975@` | Token de usuário de teste (`is_test=1`) para o Pinger. Mantém sessão ativa contínua. |
| `CIRCUIT_TOKEN` | Não | `lab1975_b@` | Token de segundo usuário de teste para o Circuit. **Deve ser diferente do RGS_TOKEN** para evitar conflito de sessão. |

**Nota:** Para usar os tokens de teste, é necessário criar os usuários no banco `CS1` com `is_test=1` na tabela `user`.

### 6. 📡 Configurações de Portas (Avançado)

Geralmente mantenha os padrões abaixo, mas podem ser alterados se houver conflito:

| Serviço | Porta Padrão | Descrição |
|---------|--------------|-----------|
| MySQL | `53306` | Acesso externo ao banco |
| Redis | `36380` | Acesso externo ao cache |
| Wallet-Auth | `8888` | API de crédito/auth |
| History | `8890` | API de histórico |
| Math (ZMQ) | `49235` | **Somente interna**, não exposta |
| RGS (Fruit) | `43317` | Game server slot |
| System Control | `2555` | Painel de controle (**localhost only**) |
| Nginx | `8001` | Assets dos jogos |

---

## 🗂️ Estrutura dos Arquivos .env Gerados

Após executar `make deploy` (ou configurar manualmente), os seguintes arquivos serão criados em `envs/`:

### `mysql.env`
```bash
MYSQL_IMAGE=mysql:8.4.0
MYSQL_CONTAINER_NAME=mysql_database
MYSQL_ROOT_PASSWORD='senha_root_segura'
MYSQL_DATABASE=CS1
MYSQL_USER=ggsoft_user
MYSQL_PASSWORD='senha_user_segura'
MYSQL_HOST_PORT=53306
```

### `redis.env`
```bash
REDIS_IMAGE=redis:latest
REDIS_CONTAINER_NAME=ggsoft_redis
REDIS_PORT=36380
REDIS_PASSWORD='senha_redis_segura'
```

### `wallet-auth.env`
```bash
MODE_ENV=LOCAL
MYSQL_HOST=mysql_database
MYSQL_PORT=3306
MYSQL_USER=ggsoft_user
MYSQL_PASSWORD='senha_user_segura'
DATABASE_NAME=CS1
SECRET_KEY='chave_hmac_muito_longa_e_segura_gerada_automaticamente'
REQUIRE_HMAC=false
ALLOWED_ORIGINS=*
```

### `history.env`
```bash
REDIS_SERVER=ggsoft_redis
REDIS_PORT=36380
REDIS_PASSWORD='senha_redis_segura'
API_SECRET_KEY='chave_api_history_segura_24_chars'
CORS_ORIGINS=*
MODE_ENV=dev
PORT=8890
```

### `math.env`
```bash
SERVER_PORT=49235
```

### `rgs.env`
```bash
MODE_ENV=LOCAL
LOCATION=GGSOFT
SERVER_CS=http://python-app-wallet-auth:8888
REDIS_SEVER=ggsoft_redis
REDIS_PASSWORD='senha_redis_segura'
REDIS_PORT=36380
MATH_SERVER=tcp://ggsoft-zmq-server-slot:49235
HISTORY_SERVER=http://ggsoft_history:8890
HISTORY_SECRET_KEY='chave_api_history_segura_24_chars'
SERVER_JPS_SERVER=titan.cletrix.net
SERVER_JPS_PORT=44888
```

### `system-control.env`
```bash
WORKSPACE_DIR=/Users/leandrobatista/Desktop/ux-ggsoft
PANEL_PORT=2555
REDIS_PASSWORD='senha_redis_segura'
MYSQL_USER=ggsoft_user
MYSQL_PASSWORD='senha_user_segura'
RGS_TOKEN=lab1975@
CIRCUIT_TOKEN=lab1975_b@
```

---

## 🔗 Sincronização de Senhas entre Serviços

**CRÍTICO:** As seguintes senhas devem ser **idênticas** entre os arquivos:

```
REDIS_PASSWORD:
  ├── redis.env
  ├── history.env
  ├── rgs.env
  └── system-control.env

MYSQL_PASSWORD:
  ├── mysql.env
  ├── wallet-auth.env
  └── system-control.env

HISTORY_SECRET_KEY (history.env) == API_SECRET_KEY (rgs.env):
  ├── history.env → API_SECRET_KEY
  └── rgs.env → HISTORY_SECRET_KEY
```

**Valide a sincronização:**
```bash
make verify
```

---

## ✅ Validações Pós-Deploy

Após executar `make start`, valide o deploy:

### 1. Verificar Healthchecks
```bash
make health
```
Todos os serviços devem estar `healthy`.

### 2. Verificar Status dos Containers
```bash
make status
```

### 3. Verificar Logs
```bash
make logs
```

### 4. Testar Conectividade

#### MySQL:
```bash
make -C ../ggsoft_infra_mysql shell
# ou
mysql -h localhost -P 53306 -u ggsoft_user -p
```

#### Redis:
```bash
make -C ../ggsoft_infra_redis cli
```

#### Wallet-Auth:
```bash
curl http://localhost:8888/
```

#### RGS:
```bash
curl http://localhost:43317/status
```

#### Nginx (com games buildados):
```bash
open http://localhost:8001/8/?id=lab1975@&url=http://localhost:43317/
```

---

## 🚨 Troubleshooting

### Problema: RGS não sobe

**Causa provável:** `.build` é uma pasta, não arquivo.

**Solução:**
```bash
make reset-rgs
make start-rgs
```

### Problema: Senhas não sincronizadas

**Sintoma:** Erro de autenticação no Redis ou MySQL.

**Solução:**
```bash
make verify
# Corrija manualmente os arquivos .env
make stop
make start
```

### Problema: MySQL não aceita nova senha

**Causa:** Volume já existe com senha antiga.

**Solução:**
```bash
make clean  # ⚠️ PERDE TODOS OS DADOS
make deploy
make start
```

### Problema: Game não carrega no browser

**Causa:** Assets do `ggsoft_slot_3x3` não foram buildados/deployados.

**Solução:**
```bash
cd ../ggsoft_slot_3x3/game
make build-fruits  # Compila e copia para nginx/games/8/
```

---

## 📞 Informações Adicionais

- **Rede Docker:** Todos os containers compartilham a rede `rede-ggsoft` (externa).
- **Volumes Persistentes:** `mysql_data`, `redis_data` (definidos no compose).
- **Segurança:** O painel de controle (`system-control`) só aceita conexões de `127.0.0.1`.
- **Documentação dos repos individuais:**
  - `ggsoft_rgs_3x3/docs/SKILLS.md`
  - `ggsoft_wallet-auth/docs/skills.md`
  - `ggsoft_wallet-auth/docs/operacao.md`
  - `ggsoft_slot_3x3/game/docs/dev-local-e-deploy.md`

---

## 📝 Histórico de Alterações

| Data | Versão | Alterações |
|------|--------|------------|
| 2026-06-09 | 1.0 | Criação do documento com informações do deploy interativo |

---

**Para iniciar o deploy:**
```bash
make deploy
make start
```

**Para validar:**
```bash
make verify
make health
```
