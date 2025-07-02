# 🚀 Guia Completo: Next.js Dashboard → VPS DigitalOcean

Migração completa de dashboard Next.js (Vercel V0) para VPS com Docker, HTTPS e escala.

## 📋 **Pré-requisitos**

- ✅ VPS Ubuntu 20.04+ na DigitalOcean
- ✅ Acesso SSH (root ou sudo)
- ✅ Domínio apontado para IP da VPS (opcional, pode usar IP)
- ✅ Docker instalado localmente

---

## 🎯 **PASSO A PASSO COMPLETO**

### **1. Configurar VPS (Execute uma vez)**

```bash
# 1.1 Conectar na VPS
ssh root@SEU_IP_VPS

# 1.2 Executar setup automático
curl -fsSL https://raw.githubusercontent.com/seu-usuario/seu-repo/main/scripts/setup-vps.sh | bash

# 1.3 Reiniciar VPS
sudo reboot
```

### **2. Configurar Projeto Localmente**

```bash
# 2.1 Verificar arquivos gerados
ls -la
# Deve mostrar: Dockerfile, docker-compose.yml, nginx/, scripts/

# 2.2 Testar build local (opcional)
docker build -t nextjs-dashboard:test .

# 2.3 Configurar variáveis no script de deploy
nano scripts/deploy.sh
# Editar:
# VPS_IP="192.168.1.100"        # IP da sua VPS
# DOMAIN="meudominio.com"       # Seu domínio ou IP
# VPS_USER="root"               # Usuário SSH
```

### **3. Deploy para VPS**

```bash
# 3.1 Tornar scripts executáveis
chmod +x scripts/*.sh

# 3.2 Executar deploy
bash scripts/deploy.sh

# 3.3 Aguardar conclusão (5-10 minutos)
# O script fará automaticamente:
# - Build da aplicação
# - Upload para VPS
# - Configuração SSL
# - Inicialização dos containers
```

### **4. Verificar Deploy**

```bash
# 4.1 Conectar na VPS
ssh root@SEU_IP_VPS

# 4.2 Verificar status
cd /opt/app
bash scripts/monitor.sh

# 4.3 Ver logs em tempo real
docker-compose logs -f
```

---

## 🔧 **Estrutura de Arquivos Criada**

```
projeto/
├── Dockerfile                 # Container otimizado Next.js
├── docker-compose.yml        # Orquestração completa
├── .dockerignore             # Otimização de build
├── nginx/
│   ├── nginx.conf            # Proxy reverso + SSL
│   └── nginx-swarm.conf      # Para escala
├── scripts/
│   ├── setup-vps.sh          # Setup inicial VPS
│   ├── deploy.sh             # Deploy automático
│   ├── monitor.sh            # Monitoramento
│   └── scale.sh              # Configuração escala
└── DEPLOY_GUIDE.md           # Esta documentação
```

---

## 🌐 **Acessar Aplicação**

Após deploy bem-sucedido:

- **HTTP**: `http://SEU_IP_OU_DOMINIO` (redireciona para HTTPS)
- **HTTPS**: `https://SEU_IP_OU_DOMINIO` ✅

---

## 🔒 **Recursos de Segurança Incluídos**

### ✅ **SSL/TLS Automático**
- Certificados Let's Encrypt
- Renovação automática a cada 12h
- Headers de segurança (HSTS, XSS Protection, etc.)
- Redirecionamento HTTP → HTTPS

### ✅ **Firewall & Rate Limiting**
- UFW configurado (portas 22, 80, 443)
- Rate limiting nginx (10 req/s)
- Headers de segurança

### ✅ **Container Security**
- Usuário não-root nos containers
- Multi-stage build (menor superficie de ataque)
- Logs rotacionados automaticamente

---

## 📈 **Comandos de Monitoramento**

```bash
# Status geral
bash scripts/monitor.sh

# Logs em tempo real
docker-compose logs -f

# Uso de recursos
docker stats

# Reiniciar aplicação
docker-compose restart app

# Atualizar após mudanças
docker-compose down
docker-compose up -d --build
```

---

## 🎯 **Escala com Docker Swarm**

### **Configuração Inicial** (Execute na VPS)

```bash
# Configurar Swarm
bash scripts/scale.sh

# Deploy com múltiplas réplicas
docker stack deploy -c docker-stack.yml nextjs-stack
```

### **Comandos de Escala**

```bash
# Escalar para 5 instâncias da aplicação
docker service scale nextjs-stack_app=5

# Ver status dos serviços
docker service ls
docker service ps nextjs-stack_app

# Atualizar aplicação (zero downtime)
docker service update --image nextjs-dashboard:latest nextjs-stack_app

# Rollback se necessário
docker service rollback nextjs-stack_app
```

---

## 🌟 **Integração StarOxan (Overview)**

### **Opção 1: Configuração Básica**
```yaml
# staroban-config.yml
version: '1.0'
services:
  - name: nextjs-dashboard
    image: nextjs-dashboard:latest
    replicas: 3
    ports:
      - "3000:3000"
    health_check: "/api/health"
```

### **Opção 2: Migração de Swarm**
```bash
# Exportar configuração atual do Swarm
docker service inspect nextjs-stack_app > staroban-service.json

# Adaptar para StarOxan conforme documentação oficial
```

---

## 🔄 **Workflow de Atualizações**

### **Atualização Simples**
```bash
# 1. Fazer mudanças no código
# 2. Commit & push para repositório
# 3. Executar deploy novamente
bash scripts/deploy.sh
```

### **Atualização com Zero Downtime (Swarm)**
```bash
# 1. Build nova versão
docker build -t nextjs-dashboard:v2.0 .

# 2. Update rolling
docker service update --image nextjs-dashboard:v2.0 nextjs-stack_app
```

---

## ⚠️ **Troubleshooting**

### **Problema: SSL não funciona**
```bash
# Verificar certificados
docker exec nginx-proxy ls -la /etc/letsencrypt/live/

# Regenerar certificados
docker run --rm -v $(pwd)/certbot/conf:/etc/letsencrypt \
  -v $(pwd)/certbot/www:/var/www/certbot \
  certbot/certbot certonly --webroot \
  --webroot-path=/var/www/certbot \
  --email admin@seudominio.com \
  --agree-tos --no-eff-email -d seudominio.com
```

### **Problema: App não responde**
```bash
# Ver logs detalhados
docker-compose logs app

# Testar conectividade interna
docker exec nextjs-app curl http://localhost:3000

# Reiniciar apenas a aplicação
docker-compose restart app
```

### **Problema: Falta de recursos**
```bash
# Ver uso de recursos
docker stats --no-stream

# Limpar images antigas
docker image prune -a

# Limpar containers parados
docker container prune
```

---

## 📊 **Métricas e Monitoring**

### **Setup Prometheus + Grafana (Opcional)**
```yaml
# Adicionar ao docker-compose.yml
  prometheus:
    image: prom/prometheus
    ports:
      - "9090:9090"
  
  grafana:
    image: grafana/grafana
    ports:
      - "3001:3000"
```

### **Logs Centralizados**
```bash
# Configurar ELK Stack ou usar serviços como:
# - Papertrail
# - Loggly
# - CloudWatch (se na AWS)
```

---

## 🎉 **Próximos Passos**

1. **Backup**: Configurar backup automático dos dados
2. **Monitoring**: Implementar alertas (Prometheus + AlertManager)
3. **CI/CD**: Integrar com GitHub Actions
4. **Staging**: Criar ambiente de homologação
5. **Database**: Adicionar PostgreSQL/MongoDB se necessário

---

## 📞 **Suporte**

- 📧 Logs: `/var/log/nginx/` na VPS
- 🐳 Docker logs: `docker-compose logs`
- 📊 Monitoring: Execute `bash scripts/monitor.sh`

---

✅ **Aplicação pronta para produção com Docker + HTTPS + Escala!**