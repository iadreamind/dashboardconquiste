#!/bin/bash

# Script de Deploy para VPS
# Execute como: bash scripts/deploy.sh

set -e

# Configurações - INFORMAÇÕES REAIS DO PROJETO
VPS_IP="159.203.64.25"
VPS_USER="ubuntu"
DOMAIN="gestaoconquiste.com.br"
APP_NAME="nextjs-dashboard"

echo "🚀 Iniciando deploy para VPS..."

# Verificar se as variáveis foram configuradas
if [ "$VPS_IP" = "SEU_IP_DA_VPS" ]; then
    echo "❌ ERRO: Configure o IP da VPS no script!"
    echo "📝 Edite as variáveis no topo do arquivo deploy.sh"
    exit 1
fi

# Build local da imagem
echo "🔨 Fazendo build da aplicação..."
docker build -t $APP_NAME:latest .

# Criar arquivo tar da imagem
echo "📦 Criando arquivo da imagem..."
docker save $APP_NAME:latest | gzip > $APP_NAME.tar.gz

# Copiar arquivos para VPS
echo "📤 Enviando arquivos para VPS..."
scp -r . $VPS_USER@$VPS_IP:/opt/app/
scp $APP_NAME.tar.gz $VPS_USER@$VPS_IP:/opt/app/

# Executar deploy na VPS
echo "🎯 Executando deploy na VPS..."
ssh $VPS_USER@$VPS_IP << EOF
cd /opt/app

# Carregar imagem Docker
echo "📥 Carregando imagem Docker..."
docker load < $APP_NAME.tar.gz
rm $APP_NAME.tar.gz

# Parar containers existentes
echo "🛑 Parando containers existentes..."
docker-compose down 2>/dev/null || true

# Atualizar configuração do nginx com domínio correto
echo "🔧 Configurando domínio..."
sed -i 's/your-domain.com/$DOMAIN/g' nginx/nginx.conf

# Criar diretórios necessários
mkdir -p certbot/conf
mkdir -p certbot/www
mkdir -p nginx/ssl

# Gerar certificado SSL inicial (temporário)
echo "🔐 Configurando SSL..."
if [ ! -f certbot/conf/live/$DOMAIN/fullchain.pem ]; then
    # Primeiro, subir nginx sem SSL para validação do certbot
    sed -i 's/listen 443 ssl http2;/listen 443;/' nginx/nginx.conf
    sed -i '/ssl_certificate/d' nginx/nginx.conf
    sed -i '/ssl_/d' nginx/nginx.conf
    
    # Subir containers temporariamente
    docker-compose up -d nginx
    
    # Obter certificado SSL
    docker run --rm -v \$(pwd)/certbot/conf:/etc/letsencrypt -v \$(pwd)/certbot/www:/var/www/certbot certbot/certbot certonly --webroot --webroot-path=/var/www/certbot --email admin@$DOMAIN --agree-tos --no-eff-email -d $DOMAIN
    
    # Restaurar configuração SSL
    git checkout nginx/nginx.conf
    sed -i 's/your-domain.com/$DOMAIN/g' nginx/nginx.conf
    
    # Parar containers temporários
    docker-compose down
fi

# Iniciar aplicação
echo "🚀 Iniciando aplicação..."
docker-compose up -d

echo "✅ Deploy concluído!"
echo "🌐 Aplicação disponível em: https://$DOMAIN"
EOF

# Limpeza local
rm $APP_NAME.tar.gz

echo "✅ Deploy finalizado com sucesso!"
echo "🌐 Acesse: https://$DOMAIN"