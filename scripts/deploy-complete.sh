#!/bin/bash

# Deploy Completo - gestaoconquiste.com.br
# Este script executa todo o processo de deploy automaticamente

set -e

VPS_IP="159.203.64.25"
DOMAIN="gestaoconquiste.com.br"
VPS_USER="ubuntu"

echo "🚀 DEPLOY COMPLETO: gestaoconquiste.com.br"
echo "========================================"
echo ""
echo "📊 Configurações:"
echo "   🌐 Domínio: $DOMAIN"
echo "   🔗 IP VPS: $VPS_IP"
echo "   👤 Usuário: $VPS_USER"
echo ""

# Verificar se está no diretório correto
if [ ! -f "Dockerfile" ] || [ ! -f "docker-compose.yml" ]; then
    echo "❌ ERRO: Execute este script no diretório raiz do projeto!"
    echo "   Verifique se existem: Dockerfile, docker-compose.yml"
    exit 1
fi

# ETAPA 1: Validar DNS
echo "🌐 ETAPA 1: Validando DNS..."
if bash scripts/validate-dns.sh; then
    echo "✅ DNS validado com sucesso!"
else
    echo "⚠️ Problema no DNS. Configure o domínio e tente novamente."
    echo "📋 Configuração necessária:"
    echo "   Tipo A: $DOMAIN → $VPS_IP"
    echo "   Tipo A: www.$DOMAIN → $VPS_IP"
    read -p "🤔 DNS já está configurado e quer continuar? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# ETAPA 2: Testar conexão SSH
echo ""
echo "🔗 ETAPA 2: Testando conexão SSH..."
if ssh -o ConnectTimeout=10 -o BatchMode=yes $VPS_USER@$VPS_IP exit; then
    echo "✅ Conexão SSH funcionando!"
else
    echo "❌ ERRO: Não foi possível conectar via SSH!"
    echo "📋 Verifique:"
    echo "   1. VPS está ligada"
    echo "   2. IP está correto: $VPS_IP"
    echo "   3. Usuário está correto: $VPS_USER"
    echo "   4. Chave SSH está configurada"
    exit 1
fi

# ETAPA 3: Verificar se Docker está instalado na VPS
echo ""
echo "🐳 ETAPA 3: Verificando Docker na VPS..."
if ssh $VPS_USER@$VPS_IP "docker --version && docker-compose --version"; then
    echo "✅ Docker já instalado na VPS!"
else
    echo "🔧 Docker não encontrado. Instalando..."
    echo "⏳ Isso pode levar alguns minutos..."
    
    ssh $VPS_USER@$VPS_IP << 'EOF'
# Atualizar sistema
sudo apt update

# Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker ubuntu
rm get-docker.sh

# Instalar Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Configurar firewall
sudo ufw --force enable
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Criar diretório
sudo mkdir -p /opt/app
sudo chown ubuntu:ubuntu /opt/app
EOF
    
    echo "✅ Docker instalado! Reconectando..."
    # Reconectar para carregar grupo docker
    ssh $VPS_USER@$VPS_IP "docker --version"
fi

# ETAPA 4: Build e Deploy
echo ""
echo "🔨 ETAPA 4: Build e Deploy da aplicação..."
bash scripts/deploy.sh

# ETAPA 5: Verificação final
echo ""
echo "✅ ETAPA 5: Verificação final..."
echo "⏳ Aguardando 30 segundos para containers iniciarem..."
sleep 30

# Testar se está respondendo
echo "🌐 Testando acesso à aplicação..."
if curl -s -o /dev/null -w "%{http_code}" https://$DOMAIN | grep -q "200\|301\|302"; then
    echo "🎉 SUCESSO! Aplicação está respondendo!"
else
    echo "⚠️ Aplicação pode não estar respondendo ainda."
    echo "   Verifique manualmente: https://$DOMAIN"
fi

echo ""
echo "🎉 DEPLOY COMPLETO FINALIZADO!"
echo "================================"
echo ""
echo "🌐 Acesse sua aplicação:"
echo "   https://$DOMAIN"
echo ""
echo "🔧 Comandos úteis na VPS:"
echo "   ssh $VPS_USER@$VPS_IP"
echo "   cd /opt/app"
echo "   bash scripts/monitor.sh"
echo "   docker-compose logs -f"
echo ""
echo "📊 Para monitorar:"
echo "   docker-compose ps"
echo "   docker stats"
echo ""
echo "✅ Aplicação 100% em produção com Docker + HTTPS!"