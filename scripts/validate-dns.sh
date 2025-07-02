#!/bin/bash

# Script de Validação DNS
# Execute antes do deploy: bash scripts/validate-dns.sh

VPS_IP="159.203.64.25"
DOMAIN="gestaoconquiste.com.br"

echo "🌐 Validando configuração DNS para o domínio..."
echo "=============================================="
echo ""

echo "🔍 Informações do projeto:"
echo "   Domínio: $DOMAIN"
echo "   IP VPS:  $VPS_IP"
echo ""

# Verificar se nslookup existe
if ! command -v nslookup &> /dev/null; then
    echo "⚠️ nslookup não encontrado. Instalando..."
    if command -v apt &> /dev/null; then
        sudo apt update && sudo apt install -y dnsutils
    elif command -v yum &> /dev/null; then
        sudo yum install -y bind-utils
    else
        echo "❌ Não foi possível instalar nslookup. Faça a verificação manual."
        exit 1
    fi
fi

echo "🔎 Verificando DNS do domínio..."
RESOLVED_IP=$(nslookup $DOMAIN | grep "Address:" | tail -1 | awk '{print $2}')

if [ -z "$RESOLVED_IP" ]; then
    echo "❌ ERRO: Não foi possível resolver o domínio $DOMAIN"
    echo ""
    echo "📋 Ações necessárias:"
    echo "   1. Verifique se o domínio está registrado"
    echo "   2. Configure os registros DNS:"
    echo "      - Tipo A: $DOMAIN → $VPS_IP"
    echo "      - Tipo A: www.$DOMAIN → $VPS_IP"
    echo "   3. Aguarde propagação DNS (até 24h)"
    echo ""
    exit 1
fi

echo "✅ DNS resolvido: $DOMAIN → $RESOLVED_IP"

if [ "$RESOLVED_IP" = "$VPS_IP" ]; then
    echo "🎉 PERFEITO! O domínio está apontando corretamente para a VPS!"
    echo ""
    echo "🚀 Próximo passo: Execute o deploy"
    echo "   bash scripts/deploy.sh"
else
    echo "⚠️ ATENÇÃO: DNS não está apontando para a VPS!"
    echo "   Esperado: $VPS_IP"
    echo "   Atual:    $RESOLVED_IP"
    echo ""
    echo "📋 Ações necessárias:"
    echo "   1. Acesse o painel do seu provedor de domínio"
    echo "   2. Configure o registro A: $DOMAIN → $VPS_IP"
    echo "   3. Configure o registro A: www.$DOMAIN → $VPS_IP"
    echo "   4. Aguarde propagação DNS (até 24h)"
    echo "   5. Execute este script novamente"
    echo ""
fi

# Testar conectividade com a VPS
echo "🔗 Testando conectividade com a VPS..."
if ping -c 1 $VPS_IP &> /dev/null; then
    echo "✅ VPS respondendo: $VPS_IP"
else
    echo "❌ VPS não responde: $VPS_IP"
    echo "   Verifique se a VPS está ligada e o IP está correto"
fi

echo ""
echo "📊 Status geral:"
echo "   DNS: $([ "$RESOLVED_IP" = "$VPS_IP" ] && echo "✅ OK" || echo "❌ Incorreto")"
echo "   VPS: $(ping -c 1 $VPS_IP &> /dev/null && echo "✅ Online" || echo "❌ Offline")"