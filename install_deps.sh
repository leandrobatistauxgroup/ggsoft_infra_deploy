#!/bin/bash
# GGSoft - Setup completo: dependências + SSH + deploy
# Uso: bash install_deps.sh
# Execute como usuário ubuntu (não root). Usa sudo internamente.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SSH_KEY="$HOME/.ssh/ggsoft_ec2_10_10_42_144"
SSH_CONFIG="$HOME/.ssh/config"

echo ""
echo "========================================"
echo "  GGSoft - Setup completo do servidor"
echo "========================================"
echo ""

if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
else
    SUDO=""
fi

# ================================================
# 1. DEPENDÊNCIAS DO SISTEMA
# ================================================
echo "▶ [1/4] Instalando dependências do sistema..."
$SUDO apt-get update -y -qq
$SUDO apt-get install -y -qq git make curl ca-certificates gnupg lsb-release apt-transport-https

# --- Remover Docker antigo (Ubuntu apt) se não tiver compose plugin ---
if command -v docker &>/dev/null && ! docker compose version &>/dev/null 2>&1; then
    echo "  ▶ Docker sem compose plugin detectado — reinstalando versão oficial..."
    $SUDO apt-get remove -y docker docker.io docker-doc docker-compose docker-compose-v2 \
        podman-docker containerd runc 2>/dev/null || true
fi

# --- Instalar Docker oficial se não estiver instalado ou se compose ainda falhar ---
if ! command -v docker &>/dev/null || ! docker compose version &>/dev/null 2>&1; then
    echo "  ▶ Instalando Docker oficial (com compose plugin)..."
    $SUDO install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
        | $SUDO gpg --dearmor -o /etc/apt/keyrings/docker.gpg 2>/dev/null
    $SUDO chmod a+r /etc/apt/keyrings/docker.gpg
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
        https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
        | $SUDO tee /etc/apt/sources.list.d/docker.list > /dev/null
    $SUDO apt-get update -y -qq
    $SUDO apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    $SUDO systemctl enable docker --now
fi

echo "  ✔ Docker: $(docker --version)"
echo "  ✔ Docker Compose: $(docker compose version)"

# --- Adicionar usuário ao grupo docker ---
CURRENT_USER="${SUDO_USER:-$(whoami)}"
if ! groups "$CURRENT_USER" 2>/dev/null | grep -q docker; then
    $SUDO usermod -aG docker "$CURRENT_USER"
    echo "  ✔ Usuário $CURRENT_USER adicionado ao grupo docker"
fi

# ================================================
# 2. CHAVE SSH PARA O GITHUB GGSOFT
# ================================================
echo ""
echo "▶ [2/4] Configurando SSH para GitHub GGSoft..."

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

if [ ! -f "$SSH_KEY" ]; then
    echo ""
    echo "  ❌ Chave SSH não encontrada: $SSH_KEY"
    echo "  Certifique-se de que o arquivo existe no servidor antes de continuar."
    exit 1
fi
echo "  ✔ Chave SSH encontrada: $SSH_KEY"
chmod 600 "$SSH_KEY"

if ! grep -q "github-ggsoft" "$SSH_CONFIG" 2>/dev/null; then
    cat >> "$SSH_CONFIG" << 'EOF'

Host github-ggsoft
  HostName github.com
  User git
  IdentityFile ~/.ssh/ggsoft_ec2_10_10_42_144
  IdentitiesOnly yes
EOF
    chmod 600 "$SSH_CONFIG"
    echo "  ✔ ~/.ssh/config configurado"
else
    echo "  ✔ ~/.ssh/config já configurado"
fi

# ================================================
# 3. VERIFICAR CONEXÃO COM GITHUB
# ================================================
echo ""
echo "▶ [3/4] Verificando conexão com GitHub GGSoft..."

MAX_TRIES=5
for i in $(seq 1 $MAX_TRIES); do
    RESULT=$(ssh -T -o StrictHostKeyChecking=no git@github-ggsoft 2>&1 || true)
    if echo "$RESULT" | grep -q "successfully authenticated"; then
        echo "  ✔ Conexão com GitHub OK!"
        break
    else
        if [ "$i" -eq "$MAX_TRIES" ]; then
            echo ""
            echo "  ❌ Não foi possível conectar ao GitHub após $MAX_TRIES tentativas."
            echo ""
            echo "  Cadastre a chave pública abaixo em:"
            echo "  https://github.com/organizations/GGSoftBR/settings/keys"
            echo ""
            cat "${SSH_KEY}.pub"
            echo ""
            read -r -p "  → Pressione ENTER após cadastrar para tentar novamente, ou Ctrl+C para cancelar: "
            MAX_TRIES=$((MAX_TRIES + 5))
        else
            echo "  ⚠️  Tentativa $i/$MAX_TRIES falhou. Tentando novamente em 3s..."
            sleep 3
        fi
    fi
done

# ================================================
# 4. DEPLOY
# ================================================
echo ""
echo "▶ [4/4] Iniciando deploy..."
echo ""

ENV_FILE="$SCRIPT_DIR/ggsoft.env"

if [ ! -f "$ENV_FILE" ]; then
    cp "$SCRIPT_DIR/ggsoft.env.example" "$ENV_FILE"
    echo "  ⚠️  Arquivo ggsoft.env criado. Preencha as senhas antes de continuar."
    echo ""
    nano "$ENV_FILE"
fi

# Usar sg para rodar docker no grupo sem logout
sg docker -c "make -C $SCRIPT_DIR deploy"
