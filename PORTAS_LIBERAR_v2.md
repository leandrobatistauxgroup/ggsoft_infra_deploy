# Portas para Liberar - GGSoft Platform v2

> ⚠️ **ATENÇÃO:** Este documento contém **PORTAS NOVAS** que devem ser liberadas no firewall. Verifique a seção "Portas Novas" no final.

---

## 🔥 Portas Externas (Acesso Público/Internet)

| Porta | Protocolo | Serviço | Descrição | Obrigatória |
|-------|-----------|---------|-----------|-------------|
| `43317` | TCP | RGS (Fruit) | Game server slot fruit | ✅ Sim |
| `8888` | TCP | Wallet-Auth (CS) | API de crédito/autenticação | ✅ Sim |
| `8890` | TCP | History | API de histórico de jogadas | ✅ Sim |
| `8001` | TCP | Nginx | Assets dos jogos (HTML5) | ✅ Sim |

---

## 🔒 Portas Internas (Apenas localhost/rede interna)

| Porta | Protocolo | Serviço | Descrição | Acesso |
|-------|-----------|---------|-----------|--------|
| `2555` | TCP | System-Control | Painel de controle Docker | `127.0.0.1` only |
| `53306` | TCP | MySQL | Banco de dados CS1 | localhost/rede interna |
| `36380` | TCP | Redis | Cache e sessões | localhost/rede interna |
| `49235` | TCP | Math (ZMQ) | Motor matemático | **Somente interna** |

---

## 🌐 Conectividade Externa (Outbound)

| Destino | Porta | Protocolo | Descrição |
|---------|-------|-----------|-----------|
| `titan.cletrix.net` | `44888` | TCP | Jackpot Service (JPS) |

---

## 🆕 PORTAS NOVAS (Adicionadas na v2)

As seguintes portas são **NOVAS** e devem ser liberadas se ainda não estiverem:

| Porta | Status | Motivo |
|-------|--------|--------|
| `43317` | 🔴 **NOVA** | RGS Fruit game server (substituiu porta anterior) |
| `8890` | 🔴 **NOVA** | History service (novo serviço no ecossistema) |
| `2555` | 🔴 **NOVA** | System Control panel (novo serviço de monitoramento) |
| `49235` | 🟡 **ATENÇÃO** | Math ZMQ - verificar se já está liberada internamente |

---

## 📋 Resumo para Liberação no Firewall

### Regras de Entrada (Inbound):
```bash
# Obrigatórias - Acesso Público
ALLOW TCP 43317  # RGS Fruit
ALLOW TCP 8888   # Wallet-Auth (CS)
ALLOW TCP 8890   # History
ALLOW TCP 8001   # Nginx/Assets

# Internas - Apenas rede local/localhost
ALLOW TCP 2555 FROM 127.0.0.1  # System Control
ALLOW TCP 53306 FROM LOCAL_NET   # MySQL
ALLOW TCP 36380 FROM LOCAL_NET   # Redis
ALLOW TCP 49235 FROM LOCAL_NET   # Math ZMQ
```

### Regras de Saída (Outbound):
```bash
ALLOW TCP 44888 TO titan.cletrix.net  # Jackpot Service
```

---

## 🔍 Verificação de Portas

Para verificar se as portas estão abertas:

```bash
# Local
netstat -tlnp | grep -E "43317|8888|8890|8001|2555|53306|36380|49235"

# Remoto (testar conectividade)
telnet localhost 43317
telnet localhost 8888
telnet localhost 8890
telnet localhost 8001
```

---

## 📝 Changelog v2

| Versão | Data | Alterações |
|--------|------|------------|
| v1 | - | Portas originais do ecossistema |
| **v2** | **2026-06-09** | **Adicionadas portas do novo deploy unificado** |

**Mudanças principais na v2:**
- ✅ Adicionada porta `43317` (RGS Fruit)
- ✅ Adicionada porta `8890` (History)
- ✅ Adicionada porta `2555` (System Control - localhost only)
- ✅ Documentada porta `49235` (Math ZMQ - interna)
- ✅ Incluída conectividade externa para JPS (44888)

---

**Responsável:** DevOps / Infraestrutura  
**Aprovação:** Segurança da Informação  
**Validade:** Até próxima atualização de arquitetura
