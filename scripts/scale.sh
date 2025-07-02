#!/bin/bash

# Script de Escala com Docker Swarm
# Execute na VPS: bash scripts/scale.sh

set -e

echo "🎯 Configurando Docker Swarm para Escala"
echo "========================================"

# Verificar se Swarm está ativo
if ! docker info | grep -q "Swarm: active"; then
    echo "🔧 Inicializando Docker Swarm..."
    docker swarm init --advertise-addr $(curl -s ifconfig.me)
    echo "✅ Docker Swarm inicializado!"
else
    echo "✅ Docker Swarm já está ativo"
fi

# Criar docker-compose para Swarm (stack)
cat > docker-stack.yml << 'EOF'
version: '3.8'

services:
  app:
    image: nextjs-dashboard:latest
    deploy:
      replicas: 3
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
      update_config:
        parallelism: 1
        delay: 10s
        failure_action: rollback
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          cpus: '0.2'
          memory: 256M
    environment:
      - NODE_ENV=production
    networks:
      - app-network

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx-swarm.conf:/etc/nginx/nginx.conf:ro
      - ./certbot/conf:/etc/letsencrypt:ro
      - ./certbot/www:/var/www/certbot:ro
    deploy:
      replicas: 2
      restart_policy:
        condition: on-failure
    depends_on:
      - app
    networks:
      - app-network

  certbot:
    image: certbot/certbot
    volumes:
      - ./certbot/conf:/etc/letsencrypt:rw
      - ./certbot/www:/var/www/certbot:rw
    deploy:
      replicas: 1
      restart_policy:
        condition: on-failure
    entrypoint: "/bin/sh -c 'trap exit TERM; while :; do certbot renew; sleep 12h & wait $${!}; done;'"

networks:
  app-network:
    driver: overlay
    attachable: true
EOF

# Criar configuração nginx para Swarm (load balancing)
mkdir -p nginx
cat > nginx/nginx-swarm.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    upstream nextjs_cluster {
        server app:3000 max_fails=3 fail_timeout=30s;
        # Docker Swarm fará load balancing automático
        # entre as réplicas do serviço 'app'
    }

    server {
        listen 80;
        server_name _;
        
        location /.well-known/acme-challenge/ {
            root /var/www/certbot;
        }
        
        location / {
            return 301 https://$host$request_uri;
        }
    }

    server {
        listen 443 ssl http2;
        server_name _;
        
        ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;
        
        location / {
            proxy_pass http://nextjs_cluster;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            
            # Health check
            proxy_next_upstream error timeout http_502 http_503 http_504;
        }
    }
}
EOF

echo "📋 Comandos de escala disponíveis:"
echo ""
echo "🚀 Deploy stack:"
echo "   docker stack deploy -c docker-stack.yml nextjs-stack"
echo ""
echo "📊 Escalar aplicação:"
echo "   docker service scale nextjs-stack_app=5"
echo ""
echo "📈 Status dos serviços:"
echo "   docker service ls"
echo "   docker service ps nextjs-stack_app"
echo ""
echo "🔄 Atualizar aplicação:"
echo "   docker service update --image nextjs-dashboard:latest nextjs-stack_app"
echo ""
echo "🛑 Remover stack:"
echo "   docker stack rm nextjs-stack"

# Função para deploy automático
read -p "🤔 Deseja fazer deploy da stack agora? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🚀 Fazendo deploy da stack..."
    docker stack deploy -c docker-stack.yml nextjs-stack
    echo "✅ Stack deployed! Aguarde alguns minutos para inicialização completa."
    echo "📊 Monitore com: docker service ls"
fi