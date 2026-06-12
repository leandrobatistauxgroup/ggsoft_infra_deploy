#!/bin/bash
# Verificar qual versão do teste está no servidor

echo "=== Verificando teste no servidor ==="
echo ""

echo "1. Remote configurado:"
git remote -v

echo ""
echo "2. Últimos commits:"
git log --oneline -3

echo ""
echo "3. Conteúdo do teste (linha 49-61):"
sed -n '49,61p' tests/test_csv_data.py

echo ""
echo "4. Buscando por 'rgs.ggsoft-tech.xyz' no teste:"
grep -n "rgs.ggsoft-tech.xyz" tests/test_csv_data.py || echo "❌ Não encontrado - teste desatualizado"

echo ""
echo "5. Buscando por '43317' no teste:"
grep -n "43317" tests/test_csv_data.py | head -3

echo ""
echo "=== Se o teste não tiver 'rgs.ggsoft-tech.xyz', precisa corrigir ==="
