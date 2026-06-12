# Configuração .env do System-Control

Para usar domínios HTTPS, configure o `.env` do system-control:

## Arquivo: `ggsoft_system-control/.env`

```bash
# Domínio base (usado para gerar URLs)
SERVER_IP=games.ggsoft-tech.xyz

# URLs completas (substituem IP:porta)
NGINX_PUBLIC_URL=https://games.ggsoft-tech.xyz
RGS_PUBLIC_URL=https://rgs.ggsoft-tech.xyz/
PAGE_URL=https://sc.ggsoft-tech.xyz/
```

## Comandos no Servidor

```bash
cd ~/test/ggsoft_system-control

# Editar .env
cat >> .env << 'EOF'
SERVER_IP=games.ggsoft-tech.xyz
NGINX_PUBLIC_URL=https://games.ggsoft-tech.xyz
RGS_PUBLIC_URL=https://rgs.ggsoft-tech.xyz/
PAGE_URL=https://sc.ggsoft-tech.xyz/
EOF

# Rebuild obrigatório (services.yaml é embedado)
docker compose build --no-cache system-control
docker compose up -d system-control
```

## Verificação

```bash
# Verificar se gerou URL correta
curl http://10.10.42.144:2555/health
# Ou endpoint que retorna URL do jogo
```

**Esperado:** `https://games.ggsoft-tech.xyz/games/8/...`

---

**Importante:** O system-control original usa essas variáveis do `.env`. Não requer alteração no código.
