#!/bin/bash

# Script de Backup
# Execute na VPS: bash scripts/backup.sh

set -e

BACKUP_DIR="/opt/backups"
DATE=$(date +%Y%m%d_%H%M%S)
APP_NAME="nextjs-dashboard"
BACKUP_FILE="${APP_NAME}_backup_${DATE}.tar.gz"

echo "🗄️ Iniciando backup da aplicação..."

# Criar diretório de backup
sudo mkdir -p $BACKUP_DIR

# Parar aplicação temporariamente (opcional - comentar se quiser backup a quente)
# echo "⏸️ Parando aplicação temporariamente..."
# docker-compose stop app

echo "📦 Criando backup..."

# Backup dos arquivos da aplicação
tar -czf "$BACKUP_DIR/$BACKUP_FILE" \
    --exclude='node_modules' \
    --exclude='.git' \
    --exclude='*.log' \
    --exclude='certbot/conf/archive' \
    --exclude='certbot/conf/live' \
    -C /opt app

# Backup da imagem Docker (opcional)
echo "🐳 Fazendo backup da imagem Docker..."
docker save nextjs-dashboard:latest | gzip > "$BACKUP_DIR/${APP_NAME}_image_${DATE}.tar.gz"

# Backup dos certificados SSL
if [ -d "/opt/app/certbot/conf/live" ]; then
    echo "🔐 Fazendo backup dos certificados SSL..."
    tar -czf "$BACKUP_DIR/ssl_backup_${DATE}.tar.gz" -C /opt/app certbot/conf
fi

# Restart da aplicação se foi parada
# echo "▶️ Reiniciando aplicação..."
# docker-compose start app

# Informações do backup
BACKUP_SIZE=$(du -h "$BACKUP_DIR/$BACKUP_FILE" | cut -f1)
echo "✅ Backup concluído!"
echo "📁 Arquivo: $BACKUP_DIR/$BACKUP_FILE"
echo "📏 Tamanho: $BACKUP_SIZE"

# Limpar backups antigos (manter últimos 7 dias)
echo "🧹 Limpando backups antigos..."
find $BACKUP_DIR -name "${APP_NAME}_backup_*.tar.gz" -mtime +7 -delete
find $BACKUP_DIR -name "${APP_NAME}_image_*.tar.gz" -mtime +7 -delete
find $BACKUP_DIR -name "ssl_backup_*.tar.gz" -mtime +7 -delete

echo "📋 Backups disponíveis:"
ls -lh $BACKUP_DIR | grep $APP_NAME

# Instruções de restore
echo ""
echo "🔄 Para restaurar backup:"
echo "   cd /opt"
echo "   sudo rm -rf app"
echo "   sudo tar -xzf $BACKUP_DIR/$BACKUP_FILE"
echo "   cd app && docker-compose up -d"