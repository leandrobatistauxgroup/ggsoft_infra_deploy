# GGSoft - Dados Hardcoded no Deploy

> **Documento de referência dos dados padrão inseridos automaticamente no banco**
> 
> **Data:** 09/06/2026  
> **Arquivos CSV:** `ggsoft_wallet-auth/app/mydb/ddl/default/`

---

## 👤 USUÁRIOS (users.csv)

Local: `ggsoft_wallet-auth/app/mydb/ddl/default/users.csv`

| ID | Token | Login | Senha | Crédito | is_test |
|----|-------|-------|-------|---------|---------|
| ID15 | **TK15** | player | go15 | 10.000 | 1 (teste) |
| ID16 | **TK16** | player | go16 | 10.000 | 1 (teste) |
| 3E15C8C5B8FE4A54AEB595D4FBC02C75 | **9D672E0D088845348075** | cleyton | **b1ng0** | 99.984 | 1 (teste) |
| A1B2C3D4E5F6478490A1B2C3D4E5F678 | **LEANDROTOKEN01** | leandro | academia | 10.000 | 0 (produção) |
| B2C3D4E5F6A7B8C9D0E1F2A3B4C5D6E7 | **HENRIQUETOKEN01** | henrique | sport | 10.000 | 0 (produção) |
| C3D4E5F6A7B8C9D0E1F2A3B4C5D6E7F8 | **DOUGLASTOKEN01** | douglas | portugal | 10.000 | 0 (produção) |

**Tokens de Teste (usados pelo System-Control):**
- `RGS_TOKEN`: **TK15** (player ID15)
- `CIRCUIT_TOKEN`: **TK16** (player ID16)

---

## 🎮 JOGOS (game.csv)

Local: `ggsoft_wallet-auth/app/mydb/ddl/default/game.csv`

| ID | Nome | Coin List | Bet List |
|----|------|-----------|----------|
| **8** | **fruits** | [1, 5, 10, 25, 50, 100] | [1, 2, 3, 4, 5, 6, 7, 8, 9, 10] |

**Nota:** ID 8 é o ID original do fruits no banco de dados legado.

---

## 📍 LOCALIZAÇÕES (location.csv)

Local: `ggsoft_wallet-auth/app/mydb/ddl/default/location.csv`

| ID | Nome | Grupo | Page URL | Game URL | Idioma |
|----|------|-------|----------|----------|--------|
| 1 | **GGSOFT** | Main | http://localhost:23458/choice | http://localhost:8001 | POR |

---

## 🔗 GAME_LOCATION (game_location.csv)

Local: `ggsoft_wallet-auth/app/mydb/ddl/default/game_location.csv`

| ID | id_game | id_location | RGS URL | Coin List | Bet List |
|----|---------|-------------|---------|-----------|----------|
| 1 | **8** (fruits) | **1** (GGSOFT) | http://localhost:43317 | [1, 5, 10, 25, 50, 100] | [1, 2, 3, 4, 5, 6, 7, 8, 9, 10] |

---

## 🔧 VARIÁVEIS DE AMBIENTE (.env files)

### rgs.env + docker-compose
```env
GAME_NAME="fruits"  # ⚠️ Deve ser "fruits" (com 's') para corresponder ao banco
GAME_CODE="8"
PORT="43317"
```

**Importante:** GAME_NAME deve ser igual ao `name` na tabela `game` (fruits)

### lounge.env
```env
LOCATION=GGSOFT
PORT=23458
SERVER_CS=http://python-app-wallet-auth:8888
SERVER_RGS=http://rgs-fruit:43317
```

### system-control.env
```env
RGS_TOKEN=TK15
CIRCUIT_TOKEN=TK16
PANEL_PORT=2555
```

---

## 📝 DDL - Estrutura das Tabelas

### Tabela `user`
```sql
CREATE TABLE IF NOT EXISTS `user` (
    `id` VARCHAR(36) PRIMARY KEY,
    `token` VARCHAR(36),
    `machine` VARCHAR(128),
    `login` VARCHAR(36),
    `password` VARCHAR(36),
    `credit` INT,
    `counter_in` INT,
    `counter_out` INT,
    `state` VARCHAR(36),
    `pin` VARCHAR(16),
    `pin_expires` DATETIME DEFAULT NULL,
    `machine_status` VARCHAR(32) DEFAULT NULL,
    `blocked_value` INT DEFAULT 0,
    `last_blocked_value` INT DEFAULT 0,
    `is_test` TINYINT(1) NOT NULL DEFAULT 0,
    UNIQUE KEY `uniq_machine` (`machine`)
)
```

### Tabela `game`
```sql
CREATE TABLE IF NOT EXISTS `game` (
  `id` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `coin_list_range` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '[1, 5, 10, 25, 50, 100]',
  `bet_list_range` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
```

### Tabela `location`
```sql
CREATE TABLE IF NOT EXISTS `location` (
  `id` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `group` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `page_url` varchar(2083) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `game_url` varchar(2083) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `language` varchar(3) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'POR',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
```

### Tabela `game_location`
```sql
CREATE TABLE IF NOT EXISTS `game_location` (
  `id` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `id_game` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `id_location` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `rgs_url` varchar(2083) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `coin_list` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '[1, 5, 10, 25, 50, 100]',
  `bet_list` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]',
  PRIMARY KEY (`id`),
  KEY `id_game` (`id_game`),
  KEY `id_location` (`id_location`),
  CONSTRAINT `game_location_ibfk_1` FOREIGN KEY (`id_game`) REFERENCES `game` (`id`),
  CONSTRAINT `game_location_ibfk_2` FOREIGN KEY (`id_location`) REFERENCES `location` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
```

---

## 🚀 Fluxo de Inserção no Deploy

1. **wallet-auth** inicia e executa `create.py`
2. `create.py` chama `insert_fake_data()` para cada CSV
3. Dados são inseridos com `INSERT IGNORE` (não duplica se já existir)

**Arquivo responsável:** `ggsoft_wallet-auth/app/mydb/create.py`

---

## 🧪 Testes de Integração

Local: `ggsoft_infra_deploy/tests/`

### Execução no Deploy

Os testes de integração são executados automaticamente na **Fase 2/5**:

```bash
make deploy
# ...
=== FASE 2/5: Testes de Integração End-to-End ===
```

### Tipos de Testes

| Arquivo | Propósito |
|---------|-----------|
| `test_csv_data.py` | Game ID 8=fruits, GGSOFT tem /games/, RGS porta 43317 |
| `test_service_connectivity.py` | Todos os serviços respondem nas portas corretas |
| `test_api_compatibility.py` | APIs retornam JSON, History aceita POST, Nginx serve arquivos |
| `test_deploy_config.py` | GAME_NAME=fruits, LOCATION=GGSOFT, etc. |

### Bloqueio de Deploy

Se qualquer teste falhar, o deploy é **bloqueado**:
```
❌ DEPLOY BLOQUEADO - Testes Falharam
```

---

**Documento gerado automaticamente - manter atualizado com mudanças nos CSVs.**
