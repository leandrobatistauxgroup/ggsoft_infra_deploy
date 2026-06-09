# GGSoft - Relação de URLs e Acessos Externos v2

> ⚠️ **ATENÇÃO:** Este documento contém **PORTAS NOVAS** adicionadas no novo deploy unificado.

---

## 🔴 PORTAS NOVAS - Liberar Imediatamente

As seguintes portas são **NOVAS** e devem ser liberadas no firewall:

| Porta | Protocolo | Serviço | Acesso | Descrição |
|-------|-----------|---------|--------|-----------|
| **43317** | TCP | RGS Fruit | VPN | Game server slot fruit (novo deploy unificado) |
| **8888** | TCP | Wallet-Auth (CS) | VPN | API de crédito/autenticação (CS) |
| **8890** | TCP | History | VPN | API de histórico de jogadas |
| **8001** | TCP | Nginx | VPN | Assets estáticos dos jogos |
| **2555** | TCP | System-Control | **localhost only** | Painel de controle Docker (apenas local) |
| **36380** | TCP | Redis | Rede interna | Cache e sessões (não expor externamente) |
| **49235** | TCP | Math (ZMQ) | Rede interna | Motor matemático (não expor externamente) |
| **44888** | TCP | Jackpot Service | Outbound | Conexão externa para titan.cletrix.net |

> **Ação:** Liberar portas 43317, 8888, 8890, 8001 na VPN.  
> Portas 2555, 36380, 49235 são internas (não liberar externamente).  
> Porta 44888 é outbound (saída) para jackpot service.

---

**Documento para solicitação de liberação ao setor de Deploy**  
**Projeto:** GGSoft - Plataforma de Jogos Slot  
**Classificação:** Interno - Acesso via VPN Obrigatória  
**Data:** 09/06/2026

---

## 📋 RESUMO EXECUTIVO - O que liberar

### Portas de Acesso

| Porta | Protocolo | Acesso | Descrição |
|-------|-----------|--------|-----------|
| **80** | TCP | **PÚBLICO** | HTTP redirect + ACME (Let's Encrypt) |
| **443** | TCP | **PÚBLICO** | HTTPS - Portal principal (Lounge via Proxy) |
| **23458** | TCP | **VPN** | Lounge HTTP direto - devs testarem localmente |
| **43316** | TCP | **VPN** | RGS Fruits - jogo local dos devs |
| **43319** | TCP | **VPN** | RGS Solid - jogo local dos devs |
| **53306** | TCP | **VPN** | MySQL - gerenciamento operacional |

### URLs para Liberação

| Cenário | URL/Porta | Protocolo | Acesso |
|---------|-----------|-----------|--------|
| **Produção** | `https://${DOMAIN}/` | HTTPS (443) | Internet |
| **Produção** | `https://${DOMAIN}/cs/` | HTTPS (443) | Internet |
| **Produção** | `https://${DOMAIN}/api43316/` | HTTPS (443) | Internet |
| **Produção** | `https://${DOMAIN}/api43319/` | HTTPS (443) | Internet |
| **Dev/Teste** | `http://${DOMAIN}:23458/` | HTTP (direto) | VPN exclusivamente |
| **Dev/Teste** | `http://${DOMAIN}:43316/` | HTTP (direto) | VPN exclusivamente |
| **Dev/Teste** | `http://${DOMAIN}:43319/` | HTTP (direto) | VPN exclusivamente |

> **Requisito:** Todas as portas de desenvolvimento (23458, 43316, 43319, 53306) devem ser **restritas à VPN** - nunca expostas publicamente.

### Fluxo do Token (Autenticação)

```
1. Dev acessa Lounge → http://${DOMAIN}:${PORT_LOUNGE}/
2. Lounge autentica no CS (interno) → Gera token
3. Lounge redireciona dev para jogo com token
   • HTML5: token na URL como parâmetro `?id=${TOKEN}`
   • Desktop: token como argumento do executável
4. Jogo usa token para chamar RGS → POST /open {token, game}
5. RGS valida token no CS → Inicia sessão
```

---

## ⏳ STATUS - DOMÍNIO PENDENTE

| Item | Status | Descrição |
|------|--------|-----------|
| **Domínio** | ⏳ **PENDENTE** | Aguardando definição do domínio oficial |
| **DNS A Record** | ⏳ Bloqueado | Pendente definição do domínio |
| **SSL/TLS (Let's Encrypt)** | ⏳ Bloqueado | Pendente definição do domínio |

> **Ação necessária:** Definir domínio oficial (ex: `ggsoft.com.br`, `jogos.ggsoft.io`, etc.)  
> Todas as URLs neste documento usam placeholder `${DOMAIN}` até a definição.

---

## ⚠️ REQUISITO DE SEGURANÇA - VPN OBRIGATÓRIA

### Acesso restrito via VPN Corporativa

| Ambiente | Requisito | Arquivo VPN |
|----------|-----------|-------------|
| **Produção/Dev** | VPN ativa obrigatória | `*.ovpn` (fornecido pelo setor de Infra) |

### Portas que exigem VPN

Todas as portas de desenvolvimento e operacional **NÃO devem ser expostas publicamente** na internet:

| Porta | Serviço | Acesso |
|-------|---------|--------|
| `${PORT_LOUNGE}` | Lounge | VPN + whitelist de IP |
| `${PORT_RGS_FRUITS}` | RGS Fruits | VPN + whitelist de IP |
| `${PORT_RGS_SOLID}` | RGS Solid | VPN + whitelist de IP |
| `${MYSQL_PORT}` | MySQL | VPN exclusivamente |

### Instruções para Deploy

1. **Configurar firewall** para aceitar conexões apenas da rede VPN:
   ```bash
   # Exemplo: permitir apenas range da VPN
   sudo ufw allow from ${VPN_SUBNET} to any port ${MYSQL_PORT}
   sudo ufw allow from ${VPN_SUBNET} to any port ${PORT_LOUNGE}
   sudo ufw allow from ${VPN_SUBNET} to any port ${PORT_RGS_FRUITS}
   sudo ufw allow from ${VPN_SUBNET} to any port ${PORT_RGS_SOLID}
   ```

2. **Bloquear acesso externo direto** às portas de desenvolvimento

3. **Portas 80/443** podem ser públicas (terminação HTTPS + validação de token)

> **Compliance:** Acesso ao MySQL e APIs de desenvolvimento apenas via VPN corporativa ativa.

### Usuários Autorizados para Acesso VPN

| Usuário | Email/Identificador | Status | Arquivo VPN |
|---------|---------------------|--------|-------------|
| leandro.batista | leandro.batista@ux.group | ✅ Enviado | `leandro.batista-gg-dev.ovpn` |
| henrique.albuquerque | henrique.albuquerque@ux.group | ⏳ Pendente | `henrique.albuquerque-gg-dev.ovpn` |
| douglas.lira | douglas.lira@ux.group | ⏳ Pendente | `douglas.lira-gg-dev.ovpn` |
| cleyton.pedroza | cleyton.pedroza@ux.group | ⏳ Pendente | `cleyton.pedroza-gg-dev.ovpn` |

> **Ação para Deploy:** Gerar arquivos `.ovpn` para usuários pendentes e distribuir via canal seguro.

---

## 1. Resumo para Deploy

**Acessos externos que precisam ser liberados:**

| Tipo | Serviço | Porta | Acesso |
|------|---------|-------|--------|
| **Público** | HTTPS (Lounge via Proxy) | 443 | Internet |
| **VPN** | Lounge HTTP direto | ${PORT_LOUNGE} | Devs locais |
| **VPN** | RGS (jogos) | ${PORT_RGS_*} | Jogos locais dos devs |

---

## 2. Portas Externas Necessárias

### 2.1 Portas que o Deploy precisa liberar

| Porta | Protocolo | Serviço | Tipo de Acesso | Ação |
|-------|-----------|---------|----------------|------|
| **80** | TCP | HTTP Redirect | **PÚBLICO** | Liberar na internet |
| **443** | TCP | HTTPS (Proxy) | **PÚBLICO** | Liberar na internet |
| **${PORT_LOUNGE}** | TCP | Lounge | **VPN** | Restringir à VPN |
| **${PORT_RGS_FRUITS}** | TCP | RGS Fruits | **VPN** | Restringir à VPN |
| **${PORT_RGS_SOLID}** | TCP | RGS Solid | **VPN** | Restringir à VPN |
| **${PORT_RGS_*}** | TCP | Novos Jogos | **VPN** | Adicionar conforme necessidade |

**Portas internas (NÃO liberar externamente):** MySQL, Redis, CS, History, ZMQ

### 2.2 Diagrama de Portas

| Porta | Serviço | Container | Tipo | Observação |
|-------|---------|-----------|------|------------|
```
┌─────────────────────────────────────────────────────────────────┐
│  INTERNET (Público)              │   VPN (Restrito)              │
│  ─────────────────────────────   │   ─────────────────────────     │
│  • Porta 80   → HTTP             │   • Porta ${PORT_LOUNGE}       │
│  • Porta 443  → HTTPS (Proxy)   │     → Lounge direto            │
│                                  │   • Porta ${PORT_RGS_FRUITS}   │
│  URLs de produção:               │     → RGS Fruits (devs)        │
│  https://${DOMAIN}/              │   • Porta ${PORT_RGS_SOLID}    │
│  https://${DOMAIN}/cs/           │     → RGS Solid (devs)         │
│  https://${DOMAIN}/api43316/     │                                │
│  https://${DOMAIN}/api43319/     │   Devs acessam jogos locais    │
│                                  │   via VPN para testar          │
└─────────────────────────────────────────────────────────────────┘
```

**Interno (Docker Network apenas):** MySQL, Redis, CS, History, ZMQ, Nginx Assets

---

## 3. URLs de Acesso e Endpoints

### 3.1 URLs Públicas (Via Proxy HTTPS)

| URL Externa | Destino Interno | Descrição |
|-------------|-----------------|-----------|
| `https://${DOMAIN}/` | Lounge:${PORT_LOUNGE} | Portal principal / Lobby |
| `https://${DOMAIN}/cs/` | CS:${PORT_CS} | Cash Server (API de autenticação) |
| `https://${DOMAIN}/api${PORT_RGS_SOLID}/` | RGS Solid:${PORT_RGS_SOLID} | API do jogo Solid (game code 2) |
| `https://${DOMAIN}/api${PORT_RGS_FRUITS}/` | RGS Fruits:${PORT_RGS_FRUITS} | API do jogo Fruits (game code 1) |
| `https://${DOMAIN}/gate/` | Nginx:${PORT_NGINX_ASSETS} | Assets estáticos dos jogos (JS, imagens) |

> **Resumo:** Devs acessam Lounge via `${PORT_LOUNGE}` e jogos via `${PORT_RGS_*}` (Fruits, Solid, etc.)  
> para testar localmente. Todas essas portas devem estar **restritas à VPN** conforme configuração na seção 2.1

---

## 4. Configuração de Infraestrutura

### 4.1 Servidor

| Requisito | Especificação |
|-----------|---------------|
| **Sistema Operacional** | Linux (Ubuntu 22.04 LTS recomendado) |
| **Docker** | v20.10+ |
| **Docker Compose** | v2.0+ |
| **Rede Docker** | `rede-ggsoft` (bridge) |
| **Memória RAM** | Mínimo 4GB (recomendado 8GB+) |
| **CPU** | 2+ cores |
| **Disco** | 20GB+ (SSD recomendado) |

### 5.2 DNS

| Registro | Tipo | Valor | Status |
|----------|------|-------|--------|
| `${DOMAIN}` | A | ${SERVER_IP} | ⏳ Pendente definição |
| `www.${DOMAIN}` | A | ${SERVER_IP} | ⏳ Pendente definição |

> **Nota:** Configurar DNS A record após definição do domínio na seção "STATUS - DOMÍNIO PENDENTE".

### 5.3 Firewall (iptables/UFW)

```bash
# =========================================
# PORTAS PÚBLICAS (Internet)
# =========================================
sudo ufw allow 80/tcp   # HTTP redirect + ACME
sudo ufw allow 443/tcp  # HTTPS principal

# =========================================
# PORTAS DE DEV - SOMENTE VIA VPN/Whitelist
# =========================================
# ⚠️ REQUISITO: Acesso apenas via VPN corporativa ativa
# ou whitelist de IPs autorizados (IPs de escritório/devs)

# Opção 1: Restringir à subnet da VPN (recomendado)
sudo ufw allow from ${VPN_SUBNET} to any port ${PORT_LOUNGE:-23458}/tcp
sudo ufw allow from ${VPN_SUBNET} to any port ${PORT_RGS_FRUITS:-43316}/tcp
sudo ufw allow from ${VPN_SUBNET} to any port ${PORT_RGS_SOLID:-43319}/tcp

# Opção 2: Whitelist de IPs específicos (se VPN não disponível)
# sudo ufw allow from ${IP_DEV_1} to any port ${PORT_LOUNGE:-23458}/tcp
# sudo ufw allow from ${IP_DEV_2} to any port ${PORT_LOUNGE:-23458}/tcp

# =========================================
# PORTA OPERACIONAL (MySQL) - VPN EXCLUSIVAMENTE
# =========================================
# ⚠️ CRÍTICO: MySQL NUNCA deve ser exposto publicamente
sudo ufw allow from ${VPN_SUBNET} to any port ${MYSQL_PORT:-53306}/tcp

# =========================================
# SOMENTE INTERNA - Docker Network (não expor)
# =========================================
# - ${REDIS_PORT} (Redis)
# - ${PORT_MATH} (ZMQ)
# - ${PORT_CS} (CS)
# - ${PORT_HISTORY} (History)
# - ${PORT_NGINX_ASSETS} (Nginx Assets interno)
```

---

## 6. Fluxo para Devs Testarem Localmente

### 6.1 Cenário: Dev roda jogo local acessando servidor externo

```
┌─────────────────┐         ┌──────────────────────────────┐
│  Jogo (local)   │ ──────► │  Servidor GGSoft (externo)   │
│                 │         │                              │
│  HTML5/Desktop  │         │  ┌─────────┐   ┌─────────┐   │
│                 │ HTTP    │  │ Lounge  │   │  RGS    │   │
│  Parâmetros:    │ ──────► │  │ :23458  │   │ :43316  │   │
│  - token        │         │  └────┬────┘   └────┬────┘   │
│  - url_rgs      │         │       │             │         │
│  - page_url     │         │       └─────┬───────┘         │
└─────────────────┘         │             │                 │
                            │    ┌────────┴────────┐        │
                            │    │   Nginx Proxy   │        │
                            │    │    :443/:80     │        │
                            │    └─────────────────┘        │
                            └───────────────────────────────┘
```

### 5.2 Fluxo de Acesso dos Devs

**Como os devs acessam para testar:**

| Ação | URL/Porta | Exemplo |
|------|-----------|---------|
| Acessar Lounge | `${DOMAIN}:${PORT_LOUNGE}` | `meujogo.com:23458` |
| Jogar (Fruits) | `${DOMAIN}:${PORT_RGS_FRUITS}` | `meujogo.com:43316` |
| Jogar (Solid) | `${DOMAIN}:${PORT_RGS_SOLID}` | `meujogo.com:43319` |

> **Importante:** Todas essas portas devem ser **restritas à VPN** conforme configuração na seção 2.1

### 5.3 Adicionando Novos Jogos

Quando adicionar novo jogo (ex: Tiger):

1. Adicionar porta `${PORT_RGS_TIGER}` no `docker-compose.yml`
2. Liberar porta no firewall: `sudo ufw allow from ${VPN_SUBNET} to any port ${PORT_RGS_TIGER}`
3. Adicionar location no Nginx Proxy
4. Atualizar este documento

---

## 6. Certificados SSL/TLS

| Componente | Tipo | Renovação |
|------------|------|-----------|
| **Let's Encrypt** | TLS v1.2/v1.3 | Automática (Certbot) |

> Requisitos: Porta 80 aberta para ACME challenge + domínio configurado no DNS.

---

## 7. Checklist para Deploy

- [ ] Servidor Linux provisionado com Docker + Docker Compose
- [ ] **VPN Server configurado** (OpenVPN/Wireguard) - obrigatório para compliance
- [ ] Portas 80 e 443 liberadas no firewall externo
- [ ] Portas de dev (23458, 43316, 43319, 53306) **restritas à VPN** (whitelist subnet VPN)
- [ ] DNS A record configurado apontando para o servidor
- [ ] Chave SSH cadastrada no GitHub (GGSoftBR)
- [ ] Rede Docker `rede-ggsoft` criada: `docker network create rede-ggsoft`
- [ ] Repositórios clonados via `make clone`
- [ ] Certificados Let's Encrypt emitidos (`./scripts/init_cert.sh`)
- [ ] Cron de renovação automática instalado
- [ ] Arquivos VPN `.ovpn` distribuídos aos devs autorizados
- [ ] Containers iniciados: `make deploy`

---

## 🆕 Portas Novas (Adicionadas no Deploy Unificado)

As seguintes portas são **NOVAS** e devem ser liberadas no firewall:

### Portas Externas (Público/VPN)

| Porta | Protocolo | Serviço | Tipo de Acesso | Descrição |
|-------|-----------|---------|----------------|-----------|
| **43317** | TCP | RGS Fruit (Novo) | **VPN** | Game server slot fruit (novo deploy) |
| **8888** | TCP | Wallet-Auth (CS) | **VPN** | API de crédito/autenticação |
| **8890** | TCP | History | **VPN** | API de histórico de jogadas |
| **8001** | TCP | Nginx | **VPN** | Assets estáticos dos jogos (JS, imagens) |

### Portas Internas (localhost/rede interna)

| Porta | Protocolo | Serviço | Acesso | Descrição |
|-------|-----------|---------|--------|-----------|
| **2555** | TCP | System-Control | `127.0.0.1` only | Painel de controle Docker |
| **36380** | TCP | Redis | localhost/rede interna | Cache e sessões |
| **49235** | TCP | Math (ZMQ) | **Somente interna** | Motor matemático |

### Conectividade Externa (Outbound)

| Destino | Porta | Protocolo | Descrição |
|---------|-------|-----------|-----------|
| `titan.cletrix.net` | **44888** | TCP | Jackpot Service (JPS) |

### Resumo das Regras de Firewall para Portas Novas

```bash
# =========================================
# PORTAS NOVAS - VPN (Restrito)
# =========================================
sudo ufw allow from ${VPN_SUBNET} to any port 43317/tcp   # RGS Fruit
sudo ufw allow from ${VPN_SUBNET} to any port 8888/tcp    # Wallet-Auth (CS)
sudo ufw allow from ${VPN_SUBNET} to any port 8890/tcp    # History
sudo ufw allow from ${VPN_SUBNET} to any port 8001/tcp    # Nginx Assets

# =========================================
# PORTAS NOVAS - SOMENTE INTERNA (Não expor)
# =========================================
# 2555  → System Control (localhost only)
# 36380 → Redis (rede interna apenas)
# 49235 → Math ZMQ (rede interna apenas)

# =========================================
# OUTBOUND (Saída) - Liberar no firewall de saída
# =========================================
ALLOW TCP 44888 TO titan.cletrix.net  # Jackpot Service (JPS)
```

> **Nota:** As portas 43317, 8888, 8890, 8001 substituem/em complementam as portas antigas do deploy anterior.

---

**Documento gerado para solicitação de liberação de infraestrutura.**  
**Versão:** 2.0  
**Data:** 09/06/2026  
**Alterações v2:** Adicionadas portas do novo deploy unificado (43317, 8888, 8890, 8001, 2555, 36380, 49235, 44888)
