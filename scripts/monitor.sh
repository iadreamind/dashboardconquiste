#!/bin/bash

# Script de Monitoramento
# Execute na VPS: bash scripts/monitor.sh

echo "🔍 Status da Aplicação Next.js Dashboard"
echo "========================================"

# Status dos containers
echo "📦 Status dos Containers:"
docker-compose ps

echo ""
echo "💾 Uso de Recursos:"
echo "CPU e Memória:"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"

echo ""
echo "💿 Uso de Disco:"
df -h /

echo ""
echo "🔗 Conectividade:"
echo "Testando conexão interna..."
docker exec nextjs-app curl -s http://localhost:3000 > /dev/null && echo "✅ App respondendo" || echo "❌ App não responde"

echo ""
echo "🌐 Teste HTTPS:"
curl -s -o /dev/null -w "%{http_code}" https://$(curl -s ifconfig.me) && echo " - SSL funcionando" || echo " - Problema com SSL"

echo ""
echo "📊 Logs recentes:"
echo "App logs (últimas 10 linhas):"
docker-compose logs --tail=10 app

echo ""
echo "Nginx logs (últimas 5 linhas):"
docker-compose logs --tail=5 nginx

echo ""
echo "🔄 Comandos úteis:"
echo "  Reiniciar:    docker-compose restart"
echo "  Logs ao vivo: docker-compose logs -f"
echo "  Parar tudo:   docker-compose down"
echo "  Rebuild:      docker-compose up -d --build"