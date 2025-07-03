# 🚀 GUIA DEFINITIVO: Deploy Next.js → VPS DigitalOcean

**Migração completa do projeto gestaoconquiste.com.br para VPS com Docker + HTTPS**

---

## 📋 **INFORMAÇÕES DO PROJETO**

- **🌐 Domínio:** `gestaoconquiste.com.br`
- **🔗 IP VPS:** `159.203.64.25`
- **👤 Usuário SSH:** `ubuntu`
- **🐳 Tecnologia:** Docker + Next.js + Nginx + SSL

---

## 🎯 **PASSO A PASSO COMPLETO**

### **ETAPA 1: Preparação Local** ⚙️

#### **1.1 Verificar se Docker está instalado**
```bash
docker --version
docker-compose --version
```
> Se não estiver instalado, acesse: https://docs.docker.com/get-docker/

#### **1.2 Validar estrutura do projeto**
```bash
# Verificar se todos os arquivos foram criados
ls -la
# Deve mostrar: Dockerfile, docker-compose.yml, nginx/, scripts/
```

#### **1.3 Testar build local (OPCIONAL)**
```bash
# Build de teste
docker build -t nextjs-test .

# Se der erro, verificar node_modules
rm -rf node_modules && npm install
# ou
rm -rf node_modules && pnpm install
```

---

### **ETAPA 2: Configuração DNS** 🌐

#### **2.1 Validar DNS do domínio**
```bash
# Script automático de validação
bash scripts/validate-dns.sh
```

#### **2.2 Se DNS não estiver correto:**
1. Acesse o painel do seu provedor de domínio
2. Configure os registros DNS:
   - **Tipo A:** `gestaoconquiste.com.br` → `159.203.64.25`
   - **Tipo A:** `www.gestaoconquiste.com.br` → `159.203.64.25`
3. Aguarde propagação (até 24h)
4. Execute novamente: `bash scripts/validate-dns.sh`

---

### **ETAPA 3: Configuração da VPS** 🖥️

#### **3.1 Conectar na VPS**
```bash
ssh ubuntu@159.203.64.25
```

#### **3.2 Setup inicial da VPS**
```bash
# Download e execução do script de setup
curl -fsSL https://raw.githubusercontent.com/docker/docker-install/master/install.sh | bash

# OU execute manualmente o setup
wget https://raw.githubusercontent.com/SEU_USUARIO/SEU_REPO/main/scripts/setup-vps.sh
chmod +x setup-vps.sh
bash setup-vps.sh
```

#### **3.3 Setup manual (se o script não funcionar)**
```bash
# Atualizar sistema
sudo apt update && sudo apt upgrade -y

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

# Logout e login novamente
exit
```

#### **3.4 Reiniciar VPS**
```bash
# Na VPS
sudo reboot
```

---

### **ETAPA 4: Deploy da Aplicação** 🚀

#### **4.1 Verificar configurações do script**
```bash
# No seu computador, verificar se as variáveis estão corretas
cat scripts/deploy.sh | grep -E "(VPS_IP|DOMAIN|VPS_USER)"
```
**Deve mostrar:**
```
VPS_IP="159.203.64.25"
DOMAIN="gestaoconquiste.com.br"
VPS_USER="ubuntu"
```

#### **4.2 Executar deploy completo**
```bash
# Dar permissões se necessário
chmod +x scripts/*.sh

# Executar deploy
bash scripts/deploy.sh
```

**O script fará automaticamente:**
- ✅ Build da aplicação Docker
- ✅ Upload para VPS
- ✅ Configuração SSL (Let's Encrypt)
- ✅ Inicialização dos containers

#### **4.3 Acompanhar progresso**
O deploy pode levar **5-10 minutos**. Aguarde as mensagens:
- `🔨 Fazendo build da aplicação...`
- `📤 Enviando arquivos para VPS...`
- `🔐 Configurando SSL...`
- `🚀 Iniciando aplicação...`
- `✅ Deploy finalizado com sucesso!`

---

### **ETAPA 5: Verificação e Testes** ✅

#### **5.1 Verificar status na VPS**
```bash
# Conectar na VPS
ssh ubuntu@159.203.64.25

# Ir para diretório da aplicação
cd /opt/app

# Verificar status
bash scripts/monitor.sh
```

#### **5.2 Verificar containers**
```bash
# Status dos containers
docker-compose ps

# Logs da aplicação
docker-compose logs app

# Logs do nginx
docker-compose logs nginx
```

#### **5.3 Testar acesso**
```bash
# Testar HTTP (deve redirecionar para HTTPS)
curl -I http://gestaoconquiste.com.br

# Testar HTTPS
curl -I https://gestaoconquiste.com.br
```

#### **5.4 Verificar no navegador**
1. Acesse: **https://gestaoconquiste.com.br**
2. Verifique se aparece o **cadeado verde** (SSL ativo)
3. Teste todas as funcionalidades do dashboard

---

## 🔧 **COMANDOS ÚTEIS PÓS-DEPLOY**

### **Monitoramento**
```bash
# Status geral
bash scripts/monitor.sh

# Logs em tempo real
docker-compose logs -f

# Uso de recursos
docker stats

# Verificar certificados SSL
docker exec nginx-proxy ls -la /etc/letsencrypt/live/
```

### **Reinicialização**
```bash
# Reiniciar apenas a aplicação
docker-compose restart app

# Reiniciar tudo
docker-compose restart

# Parar tudo
docker-compose down

# Subir novamente
docker-compose up -d
```

### **Atualizações**
```bash
# Após mudanças no código, execute localmente:
bash scripts/deploy.sh

# Ou na VPS, rebuild:
docker-compose down
docker-compose up -d --build
```

---

## 🚨 **TROUBLESHOOTING**

### **❌ Problema: Deploy falha com erro SSH**
```bash
# Verificar conexão SSH
ssh ubuntu@159.203.64.25

# Verificar chaves SSH
ssh-add -l
```

### **❌ Problema: SSL não funciona**
```bash
# Na VPS, verificar certificados
docker exec nginx-proxy ls -la /etc/letsencrypt/live/gestaoconquiste.com.br/

# Regenerar certificados manualmente
docker run --rm -v $(pwd)/certbot/conf:/etc/letsencrypt \
  -v $(pwd)/certbot/www:/var/www/certbot \
  certbot/certbot certonly --webroot \
  --webroot-path=/var/www/certbot \
  --email admin@gestaoconquiste.com.br \
  --agree-tos --no-eff-email \
  -d gestaoconquiste.com.br
```

### **❌ Problema: App não carrega**
```bash
# Verificar logs
docker-compose logs app

# Verificar se app está respondendo internamente
docker exec nextjs-app curl http://localhost:3000

# Verificar nginx
docker exec nginx-proxy nginx -t
```

### **❌ Problema: Falta de recursos**
```bash
# Verificar uso de recursos
docker stats --no-stream

# Limpar containers antigos
docker container prune

# Limpar imagens antigas
docker image prune -a
```

---

## 📈 **PRÓXIMOS PASSOS: ESCALA**

### **Configurar Docker Swarm**
```bash
# Na VPS
bash scripts/scale.sh

# Deploy com múltiplas réplicas
docker stack deploy -c docker-stack.yml nextjs-stack

# Escalar para 5 instâncias
docker service scale nextjs-stack_app=5
```

### **Backup Automático**
```bash
# Na VPS, configurar backup diário
bash scripts/backup.sh

# Adicionar ao crontab
crontab -e
# Adicionar linha:
# 0 2 * * * cd /opt/app && bash scripts/backup.sh
```

---

## 📊 **RESUMO DO QUE FOI CONFIGURADO**

### ✅ **Segurança Implementada**
- 🔒 SSL/TLS automático (Let's Encrypt)
- 🛡️ Firewall UFW (portas 22, 80, 443)
- 🚫 Rate limiting (10 req/s)
- 🔐 Headers de segurança (HSTS, XSS, etc.)
- 👤 Containers não-root

### ✅ **Performance Otimizada**
- ⚡ Docker multi-stage build
- 🗜️ Gzip compression no Nginx
- 💾 Cache de arquivos estáticos
- 📊 Logs rotacionados

### ✅ **Escalabilidade Preparada**
- 🐳 Docker Swarm configurado
- ⚖️ Load balancing automático
- 🔄 Rolling updates sem downtime
- 📈 Réplicas configuráveis

---

## 🎉 **APLICAÇÃO EM PRODUÇÃO!**

Após seguir este guia, sua aplicação estará rodando em:

### **🌐 URLs de Acesso**
- **HTTP:** http://gestaoconquiste.com.br (redireciona para HTTPS)
- **HTTPS:** https://gestaoconquiste.com.br ✅

### **🛡️ Características de Produção**
- ✅ SSL ativo e renovação automática
- ✅ Containers isolados e seguros
- ✅ Firewall configurado
- ✅ Monitoramento ativo
- ✅ Backup configurado
- ✅ Pronto para escalar

---

## 📞 **SUPORTE**

**Em caso de dúvidas:**
1. Execute: `bash scripts/monitor.sh` (na VPS)
2. Verifique logs: `docker-compose logs`
3. Teste conectividade: `bash scripts/validate-dns.sh`

**Logs importantes:**
- Aplicação: `/opt/app/` (VPS)
- Nginx: `/var/log/nginx/` (VPS)
- SSL: `/opt/app/certbot/conf/` (VPS)

---

✅ **Deploy completo finalizado! Aplicação 100% em produção com Docker!**