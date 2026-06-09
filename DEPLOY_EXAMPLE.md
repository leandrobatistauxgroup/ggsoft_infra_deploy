# GGSoft Deploy - Exemplo de Execução

> Guia passo a passo do que será perguntado no `make deploy` e exemplos de respostas.

---

## 🚀 Executando o Deploy

```bash
cd /Users/leandrobatista/Desktop/ux-ggsoft/ggsoft_infra_deploy
make deploy
```

---

## 📋 Exemplo Completo de Sessão

### 1. Cabeçalho do Deploy

```
╔══════════════════════════════════════════════════════════════════╗
║     Deploy GGSoft com Gate de Qualidade                          ║
║     Testes devem passar para liberar deploy                      ║
╚══════════════════════════════════════════════════════════════════╝

=== FASE 1/3: Executando Testes de Qualidade ===

🧪 Testando wallet-auth...
[Aguarda testes terminarem...]

✅ Todos os testes passaram!

╔══════════════════════════════════════════════════════════════════╗
║  ✅ TESTES APROVADOS - Deploy Autorizado                          ║
╚══════════════════════════════════════════════════════════════════╝

🚀 Iniciando deploy interativo...
```

---

### 2. Configurações de Ambiente

**Pergunta:**
```
🌍 Localização [GGSOFT]:
```

**Resposta exemplo:**
```
GGSOFT
```
> ou pressione `Enter` para usar o padrão GGSOFT

---

### 3. Configurações do MySQL

**Pergunta 1:**
```
🗄️  MySQL - Usuário [ggsoft_user]:
```

**Resposta exemplo:**
```
ggsoft_user
```
> ou pressione `Enter` para usar o padrão

---

**Pergunta 2:**
```
🗄️  MySQL - Senha (mín 8 chars, padrão: auto-gerada):
```

**Resposta exemplo:**
```
MinhaSenhaSegura123!
```

**Confirmação:**
```
   Confirme a senha: MinhaSenhaSegura123!
```

> 💡 **Dica:** Se deixar em branco (apenas Enter), uma senha segura será auto-gerada

---

### 4. Configurações do Redis

**Pergunta:**
```
🔐 Redis - Senha (mín 8 chars, padrão: auto-gerada):
```

**Resposta exemplo:**
```
RedisSenha2024!
```

**Confirmação:**
```
   Confirme a senha: RedisSenha2024!
```

> 💡 **Dica:** Use senhas diferentes do MySQL para maior segurança

---

### 5. Chaves de Segurança

**Pergunta 1 (Wallet-Auth SECRET_KEY):**
```
🔑 Wallet-Auth - SECRET_KEY HMAC (mín 16 chars, padrão: auto-gerada):
```

**Resposta exemplo:**
```
minha_chave_hmac_super_secreta_nao_compartilhe_48_chars
```

> ⚠️ **IMPORTANTE:** Esta chave é usada para assinar requisições HMAC. Guarde-a em local seguro!
> 
> 💡 Recomendação: Deixe em branco para auto-gerar uma chave segura de 48+ caracteres

---

**Pergunta 2 (History API_SECRET_KEY):**
```
🔑 History - API_SECRET_KEY (mín 16 chars, padrão: auto-gerada):
```

**Resposta exemplo:**
```
history_api_secret_2024_segura
```

> 💡 Esta chave será copiada automaticamente para o rgs.env como HISTORY_SECRET_KEY

---

### 6. Tokens de Teste (Opcional)

**Pergunta 1:**
```
🎮 RGS_TOKEN de teste [lab1975@]:
```

**Resposta exemplo:**
```
teste_usuario_1
```
> ou pressione `Enter` para usar o padrão

---

**Pergunta 2:**
```
🎮 CIRCUIT_TOKEN de teste [lab1975_b@]:
```

**Resposta exemplo:**
```
teste_usuario_2
```
> ou pressione `Enter` para usar o padrão

> ⚠️ **Importante:** CIRCUIT_TOKEN deve ser diferente de RGS_TOKEN

---

### 7. Portas (Avançado - Geralmente mantenha padrão)

```
📡 Portas (Enter para manter padrões):
📡 MySQL Host Port [53306]:
```

**Resposta:**
```
[Enter - usa 53306]
```

```
📡 Redis Port [36380]:
```

**Resposta:**
```
[Enter - usa 36380]
```

```
📡 Wallet-Auth Port [8888]:
```

**Resposta:**
```
[Enter - usa 8888]
```

```
📡 History Port [8890]:
```

**Resposta:**
```
[Enter - usa 8890]
```

```
📡 RGS Port [43317]:
```

**Resposta:**
```
[Enter - usa 43317]
```

```
📡 Panel Port [2555]:
```

**Resposta:**
```
[Enter - usa 2555]
```

```
📡 Nginx Port [8001]:
```

**Resposta:**
```
[Enter - usa 8001]
```

---

### 8. Resumo Final

```
✅ Arquivos .env gerados em ./envs/

══════════════════════════════════════════════════════════════════
📋 RESUMO DA CONFIGURAÇÃO
══════════════════════════════════════════════════════════════════

Localização: GGSOFT
MySQL: ggsoft_user / porta 53306
Redis: porta 36380
Wallet-Auth: porta 8888
History: porta 8890
RGS: porta 43317
Panel: porta 2555 (localhost only)
Nginx: porta 8001

⚠️  ANOTE AS SENHAS GERADAS:
   MySQL Root: MinhaSenhaSegura123!_root
   MySQL User: MinhaSenhaSegura123!
   Redis: RedisSenha2024!
   Wallet SECRET_KEY: [auto-gerada - veja no arquivo envs/wallet-auth.env]
   History API_SECRET: [auto-gerada - veja no arquivo envs/history.env]

══════════════════════════════════════════════════════════════════
🚀 Deploy configurado!
   Próximo passo: make start
══════════════════════════════════════════════════════════════════
```

---

## ✅ Próximo Passo

Após o deploy interativo completar:

```bash
make start   # Inicia todos os serviços
```

Ou passo a passo:

```bash
make start-infra   # Só MySQL + Redis
make start-apps    # Wallet + History + Math
make start-rgs     # RGS
```

---

## 🔍 Verificar se Funcionou

```bash
make health    # Verifica healthchecks
make status    # Status dos containers
```

Acesse os serviços:
- **Panel:** http://localhost:2555 (localhost only)
- **Nginx:** http://localhost:8001/games/
- **Wallet-Auth:** curl http://localhost:8888/

---

## ⚠️ Se Precisar Reconfigurar

```bash
make deploy    # Executa novamente, sobrescreve .env
# ou
rm -rf envs/*.env   # Apaga configs
make deploy         # Gera novas configs
```

---

## 📞 Resumo das Senhas que Precisam ser Iguis

| Senha | Arquivos onde deve ser IGUAL |
|-------|------------------------------|
| REDIS_PASSWORD | redis.env, history.env, rgs.env, system-control.env |
| MYSQL_PASSWORD | mysql.env, wallet-auth.env, system-control.env |
| HISTORY_SECRET_KEY | history.env (API_SECRET_KEY) = rgs.env (HISTORY_SECRET_KEY) |

Valide com:
```bash
make verify
```
