# Configuração .env do System-Control

Para usar domínios HTTPS, o painel lê **3 variáveis independentes** do `.env`.
Cada serviço aponta para o seu próprio subdomínio — o RGS **não** é derivado do
domínio dos games.

> O deploy já injeta estes valores em `ggsoft_infra_deploy/envs/system-control.env`
> e o `sync-envs.sh` copia para `ggsoft_system-control/.env`. Edição manual só é
> necessária fora do fluxo do `make deploy`.

## Variáveis

```bash
# Fallback (modo IP:porta) — usado SÓ se as *_URL abaixo estiverem vazias.
SERVER_IP=10.10.42.144

# URLs públicas HTTPS (cada uma independente)
NGINX_PUBLIC_URL=https://games.ggsoft-tech.xyz   # base dos games (edge games.* injeta /games)
RGS_PUBLIC_URL=https://rgs.ggsoft-tech.xyz/      # domínio do RGS (subdomínio próprio)
PAGE_URL=https://sc.ggsoft-tech.xyz/             # painel / choice
```

O painel constrói a URL do jogo como `NGINX_PUBLIC_URL + "/" + <id> + "/"`, ex.:
`https://games.ggsoft-tech.xyz/8/`. O edge nginx (`games.conf`) reescreve
`/8/` → `/games/8/` internamente, então **não** se coloca `/games` no
`NGINX_PUBLIC_URL` (senão o edge duplicaria → `/games/games/8/` → 404).

> ⚠️ Não use `SERVER_IP=games.ggsoft-tech.xyz`. O `SERVER_IP` é só o fallback
> IP:porta; setá-lo para o domínio dos games faria o RGS virar
> `http://games.ggsoft-tech.xyz:43317/` (host errado) quando o fallback fosse usado.

## Como o fallback funciona (config.go)

`config/services.yaml` referencia `${NGINX_PUBLIC_URL}` / `${RGS_PUBLIC_URL}` /
`${PAGE_URL}`. Como o Go (`os.ExpandEnv`) **não** entende `${VAR:-default}`, o
fallback IP:porta é resolvido em `config.go`:

| Variável vazia | Fallback gerado |
|---|---|
| `NGINX_PUBLIC_URL` | `http://${SERVER_IP}:8001` |
| `RGS_PUBLIC_URL` | `http://${SERVER_IP}:43317/` |
| `PAGE_URL` | `http://${SERVER_IP}:23458/choice` |

Para voltar ao modo IP:porta, basta esvaziar/comentar as 3 `*_URL`.

## Comandos no Servidor (fora do make deploy)

```bash
cd ~/test/ggsoft_system-control
# editar .env com as 3 variáveis acima

# Rebuild obrigatório (services.yaml é embedado no binário)
docker compose build --no-cache system-control
docker compose up -d system-control
```

## Verificação

```bash
curl -s http://127.0.0.1:2555/api/games | python3 -m json.tool
```

**Esperado:** `play_url` do jogo ativo apontando para
`https://games.ggsoft-tech.xyz/8/?id=...&url=https://rgs.ggsoft-tech.xyz/&page_url=https://sc.ggsoft-tech.xyz/`
