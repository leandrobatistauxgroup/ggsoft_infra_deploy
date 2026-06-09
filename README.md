# GGSoft - Deploy

Este repositório contém tudo que é necessário para subir a plataforma GGSoft do zero em qualquer servidor.

---

## Pré-requisitos

- **Docker** e **Docker Compose** instalados
- **Git** instalado
- **Acesso SSH** aos repositórios GGSoft (ver seção abaixo)
- **make** instalado (`apt install make` ou `brew install make`)

---

## Acesso SSH aos repositórios

Os repositórios dos serviços GGSoft são privados. Para que o `make deploy` consiga cloná-los, a chave SSH do servidor precisa estar cadastrada na organização GGSoft no GitHub.

**Antes de continuar, siga os passos abaixo:**

1. Gere uma chave SSH no servidor (se ainda não tiver):
   ```bash
   ssh-keygen -t ed25519 -C "deploy@seuservidor" -f ~/.ssh/ggsoft_ec2_10_10_42_144
   ```

2. Exiba a chave pública gerada:
   ```bash
   cat ~/.ssh/ggsoft_ec2_10_10_42_144.pub
   ```

3. **Cadastre essa chave no GitHub da organização GGSoft:**
   - Acesse: `https://github.com/GGSoftBR`
   - Vá em **Settings → Deploy Keys → Add deploy key**
   - Cole o conteúdo da chave pública e salve
   > Você precisa ter acesso de administrador à organização para realizar esse passo.

4. Adicione ao `~/.ssh/config`:
   ```
   Host github-ggsoft
     HostName github.com
     User git
     IdentityFile ~/.ssh/ggsoft_ec2_10_10_42_144
     IdentitiesOnly yes
   ```

5. Teste a conexão:
   ```bash
   ssh -T git@github-ggsoft
   ```
   Deve retornar: `Hi ...! You've successfully authenticated`

---

## Passo a passo

### 1. Clonar este repositório

```bash
git clone https://github.com/leandrobatistauxgroup/ggsoft_infra_deploy.git
cd ggsoft_infra_deploy
```

### 2. Criar o arquivo de configuração

```bash
cp ggsoft.env.example ggsoft.env
nano ggsoft.env
```

Preencha **apenas** os valores marcados com `ALTERE_`:

| Variável | Descrição |
|---|---|
| `MYSQL_USER` | Usuário do banco de dados MySQL |
| `MYSQL_PASSWORD` | Senha do banco de dados MySQL |
| `REDIS_PASSWORD` | Senha do Redis |
| `CS_SECRET_KEY` | Chave secreta do Central Server (use aspas simples se tiver caracteres especiais) |
| `HISTORY_SECRET_KEY` | Chave de API do serviço de histórico |

> As demais variáveis (portas, nomes de containers, etc.) já estão preenchidas e não precisam ser alteradas.

### 3. Executar o deploy

```bash
make deploy
```

O comando irá automaticamente:
- Verificar se o `ggsoft.env` está configurado
- Clonar todos os repositórios dos serviços
- Criar os arquivos `.env` de cada serviço
- Criar a rede Docker `rede-ggsoft`
- Fazer o build e subir todos os containers

Ao final você verá:

```
✅ GGSoft no ar!
   Lounge  → http://localhost:23458
   Nginx   → http://localhost:8001
   CS      → http://localhost:8888
   RGS solid  → http://localhost:43319
   RGS fruits → http://localhost:43316
```

---

## Comandos úteis

| Comando | Descrição |
|---|---|
| `make deploy` | Deploy completo do zero |
| `make monitor` | Monitor em tempo real dos containers |
| `make stop` | Para todos os containers |
| `make restart` | Para e sobe novamente |
| `make log` | Últimas 20 linhas de log de cada serviço |
| `make log-cs` | Log do CS em tempo real |
| `make log-rgs` | Log do RGS em tempo real |
| `make log-history` | Log do History em tempo real |
| `make status` | Status resumido dos containers |
| `make erase` | Para tudo e limpa imagens Docker |
| `make help` | Lista todos os comandos disponíveis |

---

## Serviços e Portas

| Serviço | Porta | Descrição |
|---|---|---|
| Lounge | 23458 | Interface do operador |
| Nginx | 8001 | Servidor de assets dos jogos |
| CS | 8888 | Central Server |
| RGS Solid | 43319 | Motor do jogo Solid |
| RGS Fruits | 43316 | Motor do jogo Fruits |
| Math | 49235 | Servidor de cálculo (ZMQ) |
| History | 8890 | Histórico de partidas |
| Redis | 36380 | Cache |
| MySQL | 53306 | Banco de dados |

---

## Problemas comuns

### ❌ Erro ao clonar repositórios

```
ERROR: Repository not found
fatal: Could not read from remote repository
```

**Solução:** A chave SSH do servidor não está autorizada.
Siga a seção [Acesso SSH aos repositórios](#acesso-ssh-aos-repositórios) e entre em contato com o suporte GGSoft.

### ❌ ggsoft.env não encontrado

```
❌ ERRO: arquivo ggsoft.env não encontrado!
```

**Solução:**
```bash
cp ggsoft.env.example ggsoft.env
nano ggsoft.env
```

### ❌ Valores ALTERE_ não preenchidos

```
❌ ERRO: ggsoft.env ainda tem valores não preenchidos (ALTERE_*)!
```

**Solução:** Edite o `ggsoft.env` e substitua todos os `ALTERE_*` pelos valores reais.

### ❌ Porta já em uso

```
Bind for 0.0.0.0:8888 failed: port is already allocated
```

**Solução:** Verifique se outro processo está usando a porta e encerre-o, ou rode `make erase` para limpar tudo.
