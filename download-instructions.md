# 📥 Como Baixar o dashboard.zip

## 🎯 OPÇÕES DE DOWNLOAD

### 1. 💻 Via Interface Cursor (MAIS FÁCIL)
- No Explorer do Cursor (painel esquerdo)
- Clique direito em `dashboard.zip`
- Selecione "Download" ou "Save As"

### 2. 🌐 Via SCP (Servidor Remoto)
```bash
scp usuario@IP_SERVIDOR:/workspace/dashboard.zip ~/Downloads/
```

### 3. 🌍 Via Servidor HTTP Temporário
```bash
# Na pasta do projeto:
python3 -m http.server 8000

# Acesse no navegador:
http://localhost:8000/dashboard.zip
# ou
http://IP_DO_SERVIDOR:8000/dashboard.zip
```

### 4. 📋 Via Base64 (Copiar/Colar)
```bash
# Ver conteúdo base64:
cat dashboard_base64.txt

# Para converter de volta:
base64 -d dashboard_base64.txt > dashboard.zip
```

## 🚀 APÓS BAIXAR

1. Extrair o arquivo:
```bash
unzip dashboard.zip
cd dashboard
```

2. Executar deploy:
```bash
bash scripts/deploy-complete.sh
```

3. Acessar aplicação:
```
https://gestaoconquiste.com.br
```

## 📊 Informações do Arquivo
- **Nome:** dashboard.zip
- **Tamanho:** 23KB
- **Conteúdo:** Projeto completo com Docker + Scripts
- **Configurado para:** gestaoconquiste.com.br (159.203.64.25)