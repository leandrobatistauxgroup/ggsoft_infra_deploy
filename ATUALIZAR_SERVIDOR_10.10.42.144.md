# Atualizar Servidor 10.10.42.144

## Problema
O deploy está falhando porque o servidor está usando versão antiga do teste `test_csv_data.py`.

**Erro no servidor:**
```
AssertionError: Fruits deve usar RGS porta 43317, encontrado: https://rgs.ggsoft-tech.xyz/
```

**Correção no git:**
```
efd45c2 fix: update RGS port test to accept HTTPS domain
```

---

## Comandos para Atualizar

No servidor `10.10.42.144`, execute:

```bash
# 1. Entrar no diretório do deploy
cd ~/test/ggsoft_infra_deploy

# 2. Verificar status atual
git status
git log --oneline -3

# 3. Atualizar do git
git pull origin main

# 4. Verificar se o teste foi atualizado
grep -A5 "def test_game_location_csv_uses_correct_rgs_port" tests/test_csv_data.py
```

**Saída esperada após atualização:**
```python
def test_game_location_csv_uses_correct_rgs_port(self):
    """RGS URL deve usar porta 43317 ou domínio HTTPS rgs.ggsoft-tech.xyz (fruits)"""
    ...
    valid_rgs = '43317' in gl['rgs_url'] or 'rgs.ggsoft-tech.xyz' in gl['rgs_url']
```

---

## Se o diretório não for git

Se `~/test/ggsoft_infra_deploy` não for um repositório git, o deploy pode estar copiando de outro lugar:

```bash
# Verificar se é git
cd ~/test/ggsoft_infra_deploy && git rev-parse --git-dir 2>/dev/null && echo "É git" || echo "Não é git"

# Se não for git, verificar de onde vem o código
ls -la ~/test/
cat ~/test/ggsoft_infra_deploy/.git/config 2>/dev/null || echo "Sem .git/config"
```

---

## Workaround Imediato (se não puder atualizar)

Se precisar fazer deploy AGORA sem atualizar o servidor:

```bash
# 1. Voltar o CSV para usar IP:porta (modo antigo)
cd ~/test/ggsoft_infra_deploy

# 2. Editar o CSV temporariamente
sed -i 's|https://rgs.ggsoft-tech.xyz/|http://10.10.42.144:43317|g' /app/wallet-auth-data/game_location.csv
sed -i 's|https://sc.ggsoft-tech.xyz/choice|http://10.10.42.144:2555/choice|g' /app/wallet-auth-data/location.csv
sed -i 's|https://games.ggsoft-tech.xyz/games|http://10.10.42.144:8001/games|g' /app/wallet-auth-data/location.csv

# 3. Fazer deploy
make deploy-y

# 4. Depois do deploy, voltar para HTTPS (se o nginx edge estiver pronto)
```

---

## Verificação Pós-Atualização

Após atualizar o servidor, execute o teste isolado:

```bash
cd ~/test/ggsoft_infra_deploy
python -m pytest tests/test_csv_data.py::TestCSVDataIntegrity::test_game_location_csv_uses_correct_rgs_port -v
```

**Esperado:** `PASSED`

---

## Status

| Item | Status |
|------|--------|
| Correção no git | ✅ Commit `efd45c2` |
| Atualização no servidor | ⏳ Pendente (executar comandos acima) |
| Deploy funcionando | ⏳ Após atualização |

---

**Data:** 2026-06-12  
**Commit correto:** `efd45c2 fix: update RGS port test to accept HTTPS domain`
