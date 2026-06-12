# Migração: IP + Porta → Domínio HTTPS

Guia para migrar de acesso direto por IP:porta para acesso via domínios HTTPS quando o nginx edge estiver ativo.

---

## Resumo da Mudança

| Antes (IP:porta) | Depois (domínio HTTPS) |
|-----------------|------------------------|
| `http://10.10.42.144:8001/games/8/` | `https://games.ggsoft-tech.xyz/games/8/` |
| `http://10.10.42.144:43317/` | `https://rgs.ggsoft-tech.xyz/` |
| `http://10.10.42.144:2555/choice` | `https://sc.ggsoft-tech.xyz/choice` |
| `http://10.10.42.144:41001/` | `https://crm.ggsoft-tech.xyz/` |

---

## 1. Ajuste no .env do system-control

### Arquivo: `ggsoft_system-control/.env`

```bash
# ============================================
# MODO 1: IP + Porta (modo atual - funciona hoje)
# ============================================
SERVER_IP=10.10.42.144

# ============================================
# MODO 2: Domínio HTTPS (modo futuro - quando nginx edge estiver ativo)
# ============================================
# Descomente as linhas abaixo quando o nginx edge estiver no ar:
# SERVER_IP=games.ggsoft-tech.xyz
# NGINX_PUBLIC_URL=https://games.ggsoft-tech.xyz
# RGS_PUBLIC_URL=https://rgs.ggsoft-tech.xyz/
# PAGE_URL=https://sc.ggsoft-tech.xyz/choice
```

---

## 2. Ajuste no services.yaml

### Arquivo: `ggsoft_system-control/config/services.yaml`

```yaml
network: rede-ggsoft

# Usa URL completa se definida, senão fallback para IP:porta
nginx_public: "${NGINX_PUBLIC_URL:-http://${SERVER_IP}:8001}"
games_dir: "${WORKSPACE_DIR}/ggsoft_infra_nginx/games"

rgs:
  base_url: "http://rgs-fruit:43317"  # circuito (rede interna, não muda)
  public_url: "${RGS_PUBLIC_URL:-http://${SERVER_IP}:43317/}"
  page_url: "${PAGE_URL:-http://${SERVER_IP}:23458/choice}"
  token: "${RGS_TOKEN}"
  circuit_token: "${CIRCUIT_TOKEN}"
  game: "fruits"
  game_id: "8"
```

---

## 3. Atualização do Banco de Dados

As URLs também estão nas tabelas `location` e `game_location`. Após mudar o .env, atualize o banco:

### SQL para atualização:

```sql
-- Atualizar tabela location (URLs do painel/navegador)
UPDATE location 
SET page_url = 'https://sc.ggsoft-tech.xyz/choice',
    game_url = 'https://games.ggsoft-tech.xyz/games'
WHERE name = 'GGSOFT';

-- Atualizar tabela game_location (URL do RGS)
UPDATE game_location 
SET rgs_url = 'https://rgs.ggsoft-tech.xyz/'
WHERE id_location IN (
    SELECT id FROM location WHERE name = 'GGSOFT'
);
```

### CSVs default (para novos deploys):

**Arquivo: `ggsoft_wallet-auth/app/mydb/ddl/default/location.csv`**
```csv
"id","name","group","page_url","game_url","language"
"1",GGSOFT,Main,https://sc.ggsoft-tech.xyz/choice,https://games.ggsoft-tech.xyz/games,POR
"2",Jane,Labs,https://sc.ggsoft-tech.xyz/choice,https://games.ggsoft-tech.xyz/games,POR
```

**Arquivo: `ggsoft_wallet-auth/app/mydb/ddl/default/game_location.csv`**
```csv
"id","id_game","id_location","rgs_url","coin_list","bet_list"
"1","8","1",https://rgs.ggsoft-tech.xyz/,"[1, 5, 10, 25, 50, 100]","[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]"
"2","8","2",https://rgs.ggsoft-tech.xyz/,"[1, 5, 10, 25, 50, 100]","[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]"
```

---

## 4. Script de Migração Automática

### Arquivo: `scripts/migrar_para_dominios.sh`

```bash
#!/bin/bash
# Migra configuração de IP:porta para domínios HTTPS

set -e

echo "=== Migração IP:porta → Domínios HTTPS ==="
echo ""

# Verifica se está no diretório correto
if [ ! -f ".env" ]; then
    echo "❌ Execute este script do diretório do system-control"
    exit 1
fi

echo "1. Atualizando .env..."
cat >> .env << 'EOF'

# ============================================
# MIGRAÇÃO: Domínios HTTPS (ativado em $(date))
# ============================================
SERVER_IP=games.ggsoft-tech.xyz
NGINX_PUBLIC_URL=https://games.ggsoft-tech.xyz
RGS_PUBLIC_URL=https://rgs.ggsoft-tech.xyz/
PAGE_URL=https://sc.ggsoft-tech.xyz/choice
EOF

echo "✅ .env atualizado"
echo ""
echo "2. Rebuild do system-control necessário..."
echo "   Execute: docker compose build --no-cache system-control"
echo "   Depois: docker compose up -d system-control"
echo ""
echo "3. Atualização do banco de dados:"
echo "   Execute no MySQL:"
echo ""
cat << 'EOF'
UPDATE location SET page_url='https://sc.ggsoft-tech.xyz/choice', game_url='https://games.ggsoft-tech.xyz/games' WHERE name='GGSOFT';
UPDATE game_location SET rgs_url='https://rgs.ggsoft-tech.xyz/' WHERE id_location IN (SELECT id FROM location WHERE name='GGSOFT');
EOF
echo ""
echo "=== Migração configurada ==="
echo "⚠️  Lembre-se de subir o nginx edge antes: ./scripts/init_bundle_cert.sh"
```

---

## 5. Checklist de Migração

### Antes de começar:
- [ ] Nginx edge está no ar (`docker ps | grep nginx-proxy`)
- [ ] Certificado SAN bundle válido (`curl https://games.ggsoft-tech.xyz/health`)
- [ ] DNS apontando para o servidor (ou /etc/hosts para teste)
- [ ] Backup do banco de dados

### Passos:
1. [ ] Parar system-control: `docker compose stop system-control`
2. [ ] Atualizar `.env` com novas variáveis
3. [ ] Rebuild system-control: `docker compose build --no-cache system-control`
4. [ ] Subir system-control: `docker compose up -d system-control`
5. [ ] Atualizar banco com SQL acima
6. [ ] Verificar URLs: `docker logs system-control | grep URL`
7. [ ] Testar acesso: `https://games.ggsoft-tech.xyz/games/8/`

### Rollback (se necessário):
```bash
# Reverter .env
SERVER_IP=10.10.42.144
# Comentar: NGINX_PUBLIC_URL, RGS_PUBLIC_URL, PAGE_URL

# Reverter banco
UPDATE location SET page_url='http://10.10.42.144:2555/choice', game_url='http://10.10.42.144:8001/games' WHERE name='GGSOFT';
UPDATE game_location SET rgs_url='http://10.10.42.144:43317/' WHERE id_location IN (SELECT id FROM location WHERE name='GGSOFT');

# Rebuild system-control
docker compose build --no-cache system-control
docker compose up -d system-control
```

---

## Resumo das Variáveis

| Variável .env | Valor IP (hoje) | Valor Domínio (futuro) |
|---------------|-----------------|------------------------|
| `SERVER_IP` | `10.10.42.144` | `games.ggsoft-tech.xyz` |
| `NGINX_PUBLIC_URL` | `http://10.10.42.144:8001` | `https://games.ggsoft-tech.xyz` |
| `RGS_PUBLIC_URL` | `http://10.10.42.144:43317/` | `https://rgs.ggsoft-tech.xyz/` |
| `PAGE_URL` | `http://10.10.42.144:2555/choice` | `https://sc.ggsoft-tech.xyz/choice` |

---

## ⚠️ Importante

1. **Fallback automático**: Se as variáveis `*_URL` não estiverem definidas, o system-control usa `SERVER_IP` com portas (comportamento atual)

2. **Rebuild obrigatório**: O `services.yaml` é embedado no binário. Sempre faça `docker compose build --no-cache system-control` após mudar

3. **Banco sincronizado**: As URLs no banco devem corresponder às do .env, senão o cliente receberá URLs diferentes

4. **Teste antes**: Use `/etc/hosts` para testar localmente antes de mudar o DNS:
   ```
   10.10.42.144 games.ggsoft-tech.xyz sc.ggsoft-tech.xyz rgs.ggsoft-tech.xyz crm.ggsoft-tech.xyz
   ```

---

**Data da Documentação**: 2026-06-12  
**Versão**: 1.0
