#!/bin/bash

# Script de Setup Inicial para VPS Ubuntu 20.04+
# Execute como: bash setup-vps.sh

set -e

echo "🚀 Iniciando setup da VPS para Docker..."

# Atualizar sistema
echo "📦 Atualizando sistema..."
sudo apt update && sudo apt upgrade -y

# Instalar dependências
echo "🔧 Instalando dependências..."
sudo apt install -y curl wget git ufw

# Instalar Docker
echo "🐳 Instalando Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
rm get-docker.sh

# Instalar Docker Compose
echo "🐙 Instalando Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Configurar Firewall
echo "🔥 Configurando firewall..."
sudo ufw --force enable
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Criar diretório para aplicação
echo "📁 Criando estrutura de diretórios..."
sudo mkdir -p /opt/app
sudo chown $USER:$USER /opt/app

# Configurar logrotate para logs do Docker
echo "📝 Configurando rotação de logs..."
sudo tee /etc/logrotate.d/docker-containers > /dev/null <<EOF
/var/lib/docker/containers/*/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    copytruncate
}
EOF

echo "✅ Setup da VPS concluído!"
echo "🔄 IMPORTANTE: Execute 'sudo reboot' e reconecte via SSH"
echo "📋 Próximo passo: Execute o script deploy.sh na sua máquina local"