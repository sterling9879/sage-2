#!/bin/bash

# ============================================
# WaveSpeed Chat - Script de Instalação Rápida
# Para VPS Ubuntu 22.04+
# ============================================

set -e

echo "🚀 Instalando WaveSpeed Chat..."

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Verificar se é root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Execute como root: sudo bash install.sh${NC}"
  exit 1
fi

# 1. Instalar Node.js 20 (se não existir)
if ! command -v node &> /dev/null; then
  echo -e "${YELLOW}Instalando Node.js 20...${NC}"
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
  apt-get install -y nodejs
else
  echo -e "${GREEN}Node.js já instalado: $(node -v)${NC}"
fi

# 2. Instalar PM2 (se não existir)
if ! command -v pm2 &> /dev/null; then
  echo -e "${YELLOW}Instalando PM2...${NC}"
  npm install -g pm2
else
  echo -e "${GREEN}PM2 já instalado${NC}"
fi

# 3. Criar diretório do app
APP_DIR="/var/www/wavespeed-chat"
mkdir -p $APP_DIR

# 4. Copiar arquivos (se estiver rodando do diretório do projeto)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/package.json" ]; then
  echo -e "${YELLOW}Copiando arquivos...${NC}"
  cp -r "$SCRIPT_DIR"/* $APP_DIR/
  cp -r "$SCRIPT_DIR"/.env.example $APP_DIR/.env 2>/dev/null || true
  cp -r "$SCRIPT_DIR"/.gitignore $APP_DIR/ 2>/dev/null || true
fi

cd $APP_DIR

# 5. Criar .env se não existir
if [ ! -f ".env" ]; then
  echo -e "${YELLOW}Criando arquivo .env...${NC}"
  SECRET=$(openssl rand -base64 32)
  cat > .env << EOF
DATABASE_URL="file:./dev.db"
NEXTAUTH_SECRET="${SECRET}"
NEXTAUTH_URL="http://$(curl -s ifconfig.me):3000"
EOF
fi

# 6. Instalar dependências
echo -e "${YELLOW}Instalando dependências...${NC}"
npm install

# 7. Setup do banco de dados
echo -e "${YELLOW}Configurando banco de dados...${NC}"
npx prisma generate
npx prisma db push
npx prisma db seed

# 8. Build da aplicação
echo -e "${YELLOW}Fazendo build...${NC}"
npm run build

# 9. Iniciar com PM2
echo -e "${YELLOW}Iniciando aplicação...${NC}"
pm2 delete wavespeed-chat 2>/dev/null || true
pm2 start npm --name "wavespeed-chat" -- start
pm2 save
pm2 startup

# 10. Pegar IP público
PUBLIC_IP=$(curl -s ifconfig.me)

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}✅ Instalação concluída!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo -e "Acesse: ${YELLOW}http://${PUBLIC_IP}:3000${NC}"
echo ""
echo -e "Credenciais admin:"
echo -e "  Email: ${YELLOW}admin@admin.com${NC}"
echo -e "  Senha: ${YELLOW}admin123${NC}"
echo ""
echo -e "Comandos úteis:"
echo -e "  ${YELLOW}pm2 logs wavespeed-chat${NC}  - Ver logs"
echo -e "  ${YELLOW}pm2 restart wavespeed-chat${NC} - Reiniciar"
echo -e "  ${YELLOW}pm2 stop wavespeed-chat${NC}    - Parar"
echo ""
