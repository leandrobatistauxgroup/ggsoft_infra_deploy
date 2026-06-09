# GGSoft - Status das Portas no Servidor ECS (10.10.42.144)

> **Data:** 09/06/2026  
> **Servidor:** ip-10-10-42-144 (ECS)  
> **Status:** Containers rodando, parcialmente liberado

---

## 📋 RESUMO - Portas de Acesso

| Porta | Protocolo | Acesso | Descrição | Status |
|-------|-----------|--------|-----------|--------|
| **80** | TCP | **PÚBLICO** | HTTP redirect + ACME (Let's Encrypt) | ❌ Não testado |
| **443** | TCP | **PÚBLICO** | HTTPS - Portal principal (Proxy) | 🔴 Timeout no SG |
| **23458** | TCP | **VPN** | Lounge HTTP direto - devs | ✅ HTTP 200 OK |
| **43316** | TCP | **VPN** | RGS Fruits - jogo local dos devs | 🔴 Bloqueado SG |
| **43319** | TCP | **VPN** | RGS Solid - jogo local dos devs | 🔴 Bloqueado SG |
| **41001** | TCP | **VPN** | Math Service - cálculos matemáticos | 🔴 Timeout no SG |
| **53306** | TCP | **VPN** | MySQL - gerenciamento operacional | ✅ TCP OK |

---

## 🔌 PORTAS DIRETAS (Acesso HTTP)

Acesso direto via porta - **precisam estar liberadas no SG para devs/VPN**:

| Porta | URL Direta | Serviço | Status | Ação |
|-------|------------|---------|--------|------|
| **23458** | `http://10.10.42.144:23458/` | Lounge | ✅ HTTP 200 | ✅ Liberado |
| **53306** | - | MySQL | ✅ TCP OK | ✅ Liberado (VPN) |
| **8888** | `http://10.10.42.144:8888/` | Wallet-Auth/CS | 🔴 Timeout | Liberar no SG (VPN) |
| **8890** | `http://10.10.42.144:8890/health` | History | 🔴 Timeout | Liberar no SG (VPN) |
| **8001** | `http://10.10.42.144:8001/` | Nginx Assets | 🔴 Timeout | Liberar no SG (VPN) |
| **43316** | `http://10.10.42.144:43316/status` | RGS Fruits | 🔴 Timeout | Liberar no SG (VPN) |
| **43319** | `http://10.10.42.144:43319/status` | RGS Solid | 🔴 Timeout | Liberar no SG (VPN) |
| **41001** | `http://10.10.42.144:41001/` | Math Service | 🔴 Timeout | Liberar no SG (VPN) |

---

## � URLs VIA PROXY HTTPS (Porta 443)

Acesso via Nginx Proxy - **ativam quando porta 443 for liberada**:

| URL Externa | Destino Interno | Status |
|-------------|-----------------|--------|
| `https://10.10.42.144/` | Lounge:23458 | 🔴 Timeout |
| `https://10.10.42.144/cs/` | CS:8888 | 🔴 Timeout |
| `https://10.10.42.144/api43316/` | RGS Fruits:43316 | 🔴 Timeout |
| `https://10.10.42.144/api43319/` | RGS Solid:43319 | 🔴 Timeout |
| `https://10.10.42.144/gate/` | Nginx Assets:8001 | 🔴 Timeout |

---

## �� PORTAS NOVAS DO DEPLOY UNIFICADO

Ainda não existem no servidor:

| Porta | URL Direta | Serviço | Ação |
|-------|------------|---------|------|
| **43317** | `http://10.10.42.144:43317/status` | RGS Fruit (Novo) | Fazer novo deploy |

---

## 🔧 COMANDOS AWS PARA LIBERAR

```bash
# 1. Liberar HTTPS (443) - PÚBLICO
aws ec2 authorize-security-group-ingress \
    --group-id sg-XXXXXXX \
    --protocol tcp \
    --port 443 \
    --cidr 0.0.0.0/0 \
    --description "HTTPS Principal - Proxy Nginx"

# 2. Liberar portas de dev - VPN/Whitelist
aws ec2 authorize-security-group-ingress \
    --group-id sg-XXXXXXX \
    --protocol tcp \
    --port 23458,53306,8888,8890,8001,43316,43319,41001 \
    --cidr SEU_IP/32 \
    --description "GGSoft Dev Ports"

# Ou liberar para subnet VPN interna:
# --cidr 10.10.0.0/16
```

---

## 📊 CONTAINERS RODANDO NO SERVIDOR

```
✅ nginx (proxy HTTPS)     - Portas 80, 443 ❌ BLOQUEADAS no SG
✅ lounge                  - Porta 23458 ✅ LIBERADA
✅ rgs-fruits              - Porta 43316 ❌ BLOQUEADA
✅ rgs-solid               - Porta 43319 ❌ BLOQUEADA
✅ cs (wallet-auth)        - Porta 8888 ❌ BLOQUEADA
✅ history                 - Porta 8890 ❌ BLOQUEADA
✅ nginx (assets)          - Porta 8001 ❌ BLOQUEADA
✅ mysql                   - Porta 53306 ✅ LIBERADA
✅ math                    - Porta 41001 ❌ BLOQUEADA
```

**⚠️ Container `rgs-fruit` (porta 43317) não existe - fazer deploy do novo RGS.**

---

## ✅ CHECKLIST PARA DEPLOY COMPLETO

### URLs Via Proxy (HTTPS 443)
- [ ] Liberar porta 443 no SG (público) → Ativa todas as URLs abaixo:
  - [ ] `https://10.10.42.144/` (Lounge)
  - [ ] `https://10.10.42.144/cs/` (Wallet-Auth)
  - [ ] `https://10.10.42.144/api43316/` (RGS Fruits)
  - [ ] `https://10.10.42.144/api43319/` (RGS Solid)
  - [ ] `https://10.10.42.144/gate/` (Nginx Assets)

### Portas Diretas (VPN/Devs)
- [x] 23458 (Lounge) liberado
- [x] 53306 (MySQL) liberado
- [ ] 8888 (Wallet-Auth) liberar no SG
- [ ] 8890 (History) liberar no SG
- [ ] 8001 (Nginx Assets) liberar no SG
- [ ] 43316 (RGS Fruits) liberar no SG
- [ ] 43319 (RGS Solid) liberar no SG
- [ ] 41001 (Math Service) liberar no SG

### Novo Deploy
- [ ] 43317 (RGS Fruit novo) fazer deploy

---

**Documento gerado automaticamente após teste de portas.**  
**Para atualizar:** Executar testes novamente após liberar no Security Group.
