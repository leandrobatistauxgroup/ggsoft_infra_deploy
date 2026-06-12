#!/bin/bash
# Script para atualizar o servidor 10.10.42.144 e corrigir o teste

set -e

echo "=== Atualizando ggsoft_infra_deploy no servidor ==="
echo ""

# Verificar se está no diretório correto
if [ ! -f "tests/test_csv_data.py" ]; then
    echo "❌ Execute este script do diretório ggsoft_infra_deploy"
    echo "   cd ~/test/ggsoft_infra_deploy"
    exit 1
fi

echo "1. Verificando remote atual..."
git remote -v | head -2

echo ""
echo "2. Fazendo pull do git..."
git pull origin main || git pull origin master || echo "⚠️  Pull falhou - verificar remote"

echo ""
echo "3. Verificando se o teste foi atualizado..."
if grep -q "rgs.ggsoft-tech.xyz" tests/test_csv_data.py; then
    echo "✅ Teste atualizado corretamente (aceita domínio HTTPS)"
else
    echo "⚠️  Teste ainda com versão antiga"
    echo "    Conteúdo atual:"
    grep -A3 "def test_game_location_csv_uses_correct_rgs_port" tests/test_csv_data.py | head -5
fi

echo ""
echo "4. Executando teste isolado..."
python -m pytest tests/test_csv_data.py::TestCSVDataIntegrity::test_game_location_csv_uses_correct_rgs_port -v || echo "❌ Teste falhou"

echo ""
echo "=== Concluído ==="
echo "Se o teste passou, execute: make deploy-y"
