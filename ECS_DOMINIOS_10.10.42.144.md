# Mapeamento de Domínios - ECS 10.10.42.144

## Visão Geral

Documentação dos domínios, portas internas, target groups e configurações do AWS ALB para o ambiente GGSoft no ECS com IP `10.10.42.144`.

---

## Domínios Configurados

| Domínio | Serviço Interno | Porta Container | Target Group | Listener Rule Priority |
|---------|-----------------|-----------------|--------------|------------------------|
| `crm.ggsoft-tech.xyz` | uxGroup-user-segmentation | 41001 | `ggsoft-gg-soft-dev-crm` | 110 |
| `sc.ggsoft-tech.xyz` | system-control | 2555 | `ggsoft-gg-soft-dev-sc` | 100 |
| `games.ggsoft-tech.xyz` | nginx assets | 80 | `ggsoft-gg-soft-dev-game` | 120 |
| `rgs.ggsoft-tech.xyz` | RGS fruits | 43317 | `ggsoft-gg-soft-dev-rgs` | 130 |

---

## Configuração AWS ALB

### Host Header Conditions

| Priority | Host Header | Target Group | Container:Porta |
|----------|-------------|--------------|-----------------|
| 100 | `sc.ggsoft-tech.xyz` | `ggsoft-gg-soft-dev-sc` | `ggsoft_system-control:2555` |
| 110 | `crm.ggsoft-tech.xyz` | `ggsoft-gg-soft-dev-crm` | `uxgroup-user-segmentation-1:41001` |
| 120 | `games.ggsoft-tech.xyz` | `ggsoft-gg-soft-dev-game` | `ggsoft_nginx:80` |
| 130 | `rgs.ggsoft-tech.xyz` | `ggsoft-gg-soft-dev-rgs` | `rgs-fruit:43317` |

### Health Check Settings

| Target Group | Protocol | Port | Path | Timeout | Interval | Healthy Threshold |
|--------------|----------|------|------|---------|----------|-----------------|
| `ggsoft-gg-soft-dev-crm` | HTTP | traffic-port | `/health` | 5s | 30s | 3 |
| `ggsoft-gg-soft-dev-sc` | HTTP | traffic-port | `/health` | 5s | 30s | 3 |
| `ggsoft-gg-soft-dev-game` | HTTP | traffic-port | `/health` | 5s | 30s | 3 |
| `ggsoft-gg-soft-dev-rgs` | HTTP | traffic-port | `/health` | 5s | 30s | 3 |

---

## URLs de Acesso

### Acesso Direto (HTTP - Portas Publicadas)

| Serviço | URL Direta | Container |
|---------|------------|-----------|
| Assets/Games | `http://10.10.42.144:8001/games/8/` | `ggsoft_nginx` |
| RGS | `http://10.10.42.144:43317/` | `rgs-fruit` |
| System Control | `http://10.10.42.144:2555/` | `ggsoft_system-control` |
| CRM | `http://10.10.42.144:41001/` | `uxgroup-user-segmentation` |

### Acesso via Domínio (HTTPS - Futuro)

```
https://games.ggsoft-tech.xyz/games/8/?id=TK15&url=https://rgs.ggsoft-tech.xyz/&page_url=https://sc.ggsoft-tech.xyz/
```

---

## Mapeamento Interno Docker

### Rede `rede-ggsoft`

| Container | Porta Interna | Porta Host | Serviço |
|-----------|---------------|------------|---------|
| `ggsoft_nginx` | 80 | 8001 | Assets/Games |
| `rgs-fruit` | 43317 | 43317 | RGS Fruits |
| `ggsoft_system-control` | 2555 | 2555 | System Control |
| `uxgroup-user-segmentation-1` | 41001 | 41001 | CRM |
| `ggsoft_infra_nginx-proxy` | 80/443 | 80/443 | Edge Gateway HTTPS |

---

## Configuração do Nginx Edge (HTTPS)

### Certificado SAN Bundle

- **Nome**: `ggsoft-bundle`
- **Local**: `/etc/letsencrypt/live/ggsoft-bundle/`
- **Domínios**: 
  - `crm.ggsoft-tech.xyz`
  - `sc.ggsoft-tech.xyz`
  - `games.ggsoft-tech.xyz`
  - `rgs.ggsoft-tech.xyz`

### Arquivos de Configuração

| Arquivo | Domínio | Upstream |
|---------|---------|----------|
| `nginx/conf.d/crm.conf` | `crm.ggsoft-tech.xyz` | `uxgroup-user-segmentation-1:41001` |
| `nginx/conf.d/sc.conf` | `sc.ggsoft-tech.xyz` | `ggsoft_system-control:2555` |
| `nginx/conf.d/rgs.conf` | `rgs.ggsoft-tech.xyz` | `rgs-fruit:43317` |
| `nginx/conf.d/games.conf` | `games.ggsoft-tech.xyz` | `ggsoft_nginx:80` |
| `nginx/conf.d/00-default.conf` | default | `444` (reject) |

### Health Checks (Nginx)

| Rota | Resposta | Tipo |
|------|----------|------|
| `/health` | "GGSoft Gateway OK" | Mocado (200 fixo) |
| `/health/crm` | "CRM OK" | Mocado (200 fixo) |
| `/health/sc` | "System Control OK" | Mocado (200 fixo) |
| `/health/games` | "Games OK" | Mocado (200 fixo) |
| `/health/rgs` | "RGS OK" | Mocado (200 fixo) |

---

## Comandos Úteis

### Verificar Target Groups

```bash
aws elbv2 describe-target-groups --names ggsoft-gg-soft-dev-crm ggsoft-gg-soft-dev-sc ggsoft-gg-soft-dev-game ggsoft-gg-soft-dev-rgs
```

### Verificar Listener Rules

```bash
aws elbv2 describe-rules --listener-arn <LISTENER_ARN>
```

### Verificar Health Checks

```bash
# Via nginx edge
curl -f http://10.10.42.144/health
curl -f http://10.10.42.144/health/crm
curl -f http://10.10.42.144/health/sc
curl -f http://10.10.42.144/health/games
curl -f http://10.10.42.144/health/rgs

# Via ALB Target Groups
aws elbv2 describe-target-health --target-group-arn <TARGET_GROUP_ARN>
```

---

## Status Atual

### ✅ Configurado
- [x] Target Groups no ALB
- [x] Listener Rules com Host Header
- [x] Health checks no ALB (porta traffic-port, path `/health`)
- [x] Portas publicadas no host (8001, 43317, 2555, 41001)
- [x] Nginx edge com certificado SAN bundle
- [x] Domínios configurados no nginx edge

### ⚠️ Pendente / Observações
- [ ] DNS A records apontando para o ALB (não direto para o IP)
- [ ] Health checks reais nos serviços (atualmente mocados no nginx)
- [ ] Portas 80/443 liberadas no Security Group para o ALB
- [ ] Renovação automática do certificado Let's Encrypt

---

## Notas Importantes

1. **Acesso Direto vs Edge**: Hoje o acesso é direto por IP:porta. O nginx edge só será necessário quando o DNS apontar para o ALB com HTTPS.

2. **Portas Publicadas**: As portas 8001, 43317, 2555, 41001 estão publicadas no host, permitindo acesso direto sem passar pelo ALB.

3. **Target Groups**: Cada serviço tem seu próprio target group no ALB, permitindo health checks individuais.

4. **Health Checks**: O ALB faz health check nas portas internas (traffic-port). O nginx edge também responde `/health` mocado para facilitar monitoramento.

---

**IP do Servidor**: `10.10.42.144`  
**VPC**: `vpc-09ae025e172fe17e5`  
**ALB**: `ggsoft-dev-alb`  
**Última Atualização**: 2026-06-12
