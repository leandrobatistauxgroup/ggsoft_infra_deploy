# Testes de Integração - GGSoft Deploy

> **Testes end-to-end centralizados no `ggsoft_infra_deploy`**

## 📁 Estrutura

```
tests/
├── __init__.py
├── test_csv_data.py           ← Testa integridade dos CSVs
├── test_service_connectivity.py ← Testa conectividade
├── test_api_compatibility.py    ← Testa APIs
├── test_deploy_config.py        ← Testa configurações
└── README.md
```

## 🧪 Tipos de Testes

### 1. `test_csv_data.py`
Testa integridade dos dados CSV antes do deploy:

| Teste | Descrição |
|-------|-----------|
| `test_game_csv_has_fruits_with_id_8` | Game 'fruits' deve ter ID 8 |
| `test_location_csv_has_ggsoft_with_games_path` | GGSOFT game_url com `/games/` |
| `test_game_location_csv_fruits_linked_to_ggsoft` | Fruits → GGSOFT associado |
| `test_game_location_csv_uses_correct_rgs_port` | RGS usa porta 43317 |
| `test_users_csv_has_test_users_with_is_test` | Usuários teste têm is_test=1 |
| `test_users_csv_has_production_users` | Usuários produção is_test=0 |

### 2. `test_service_connectivity.py`
Testa se serviços conseguem se comunicar:

| Teste | Descrição |
|-------|-----------|
| `test_wallet_auth_responds` | Porta 8888 responde |
| `test_history_responds` | Porta 8890 responde |
| `test_rgs_fruit_responds` | Porta 43317 responde |
| `test_nginx_responds` | Porta 80 responde |
| `test_rgs_can_reach_wallet_auth` | RGS → Wallet-Auth OK |
| `test_rgs_can_reach_history` | RGS → History OK |

### 3. `test_api_compatibility.py`
Testa compatibilidade de APIs:

| Teste | Descrição |
|-------|-----------|
| `test_wallet_auth_credit_endpoint` | `/credit` retorna JSON |
| `test_wallet_auth_open_endpoint` | `/open` aceita game/location |
| `test_history_matches_accepts_post` | History aceita POST |
| `test_rgs_open_accepts_post` | RGS `/open` funciona |
| `test_rgs_ping_endpoint` | RGS `/ping` responde |
| `test_nginx_serves_game_files` | `/games/8/` não retorna 404 |

### 4. `test_deploy_config.py`
Testa configurações de deploy:

| Teste | Descrição |
|-------|-----------|
| `test_rgs_game_name_is_fruits` | GAME_NAME=fruits |
| `test_rgs_game_code_is_8` | GAME_CODE=8 |
| `test_rgs_port_is_43317` | PORT=43317 |
| `test_history_api_secret_configured` | API_SECRET >= 24 chars |
| `test_wallet_auth_mysql_connection_string` | MySQL configurado |

## 🚀 Execução

### Via deploy (automático):
```bash
make deploy
# Fase 2/4: Executa testes de integração automaticamente
```

### Manual:
```bash
# Sobe serviços
docker-compose up -d mysql wallet-auth history rgs-fruit nginx

# Executa testes
docker-compose --profile integration-test run --rm integration-tests

# Ou manual com pytest
cd /Users/leandrobatista/Desktop/ux-ggsoft/ggsoft_infra_deploy
docker-compose --profile integration-test run --rm integration-tests pytest -v tests/
```

## 📝 Saída de Exemplo

```
=== FASE 2/5: Testes de Integração End-to-End ===

🧪 Testando integração de serviços...
tests/test_csv_data.py::TestCSVDataIntegrity::test_game_csv_has_fruits_with_id_8 PASSED
tests/test_csv_data.py::TestCSVDataIntegrity::test_location_csv_has_ggsoft_with_games_path PASSED
tests/test_service_connectivity.py::TestServiceConnectivity::test_rgs_fruit_responds PASSED
tests/test_api_compatibility.py::TestAPICompatibility::test_nginx_serves_game_files PASSED

✅ Testes de integração passaram!
```

## 🎯 Cobertura de Falhas

Esses testes detectam:
- ✅ GAME_NAME incorreto no RGS
- ✅ game_url sem `/games/` no location
- ✅ Game ID diferente de 8
- ✅ RGS usando porta errada
- ✅ History não respondendo
- ✅ APIs incompatíveis (GET vs POST)
- ✅ Arquivos de jogo não encontrados (404)

## 🔗 Integração com Deploy

Os testes são executados automaticamente em:
- **Fase 2/5** do `deploy-with-tests.sh`
- Após testes unitários de wallet-auth e lounge
- Antes de subir infraestrutura de produção

Se falharem, o deploy é **bloqueado**.
