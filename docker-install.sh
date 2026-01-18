#!/bin/bash

# ============================================
# WaveSpeed Chat - Instalação com Docker
# Para VPS Ubuntu 22.04+
# ============================================

set -e

echo "🐳 Instalando WaveSpeed Chat com Docker..."

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Verificar se é root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Execute como root: sudo bash docker-install.sh${NC}"
  exit 1
fi

# 1. Instalar Docker (se não existir)
if ! command -v docker &> /dev/null; then
  echo -e "${YELLOW}Instalando Docker...${NC}"
  curl -fsSL https://get.docker.com | sh
  systemctl enable docker
  systemctl start docker
else
  echo -e "${GREEN}Docker já instalado${NC}"
fi

# 2. Instalar Docker Compose (se não existir)
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
  echo -e "${YELLOW}Instalando Docker Compose...${NC}"
  apt-get update
  apt-get install -y docker-compose-plugin
else
  echo -e "${GREEN}Docker Compose já instalado${NC}"
fi

# 3. Gerar secret se não existir
if [ -z "$NEXTAUTH_SECRET" ]; then
  export NEXTAUTH_SECRET=$(openssl rand -base64 32)
  echo "NEXTAUTH_SECRET=$NEXTAUTH_SECRET" > .env.docker
  echo -e "${YELLOW}Secret gerado e salvo em .env.docker${NC}"
fi

# 4. Build e iniciar
echo -e "${YELLOW}Fazendo build e iniciando containers...${NC}"

# Tentar docker compose (v2) primeiro, senão docker-compose (v1)
if docker compose version &> /dev/null; then
  docker compose up -d --build
else
  docker-compose up -d --build
fi

# 5. Aguardar inicialização
echo -e "${YELLOW}Aguardando inicialização...${NC}"
sleep 10

# 6. Pegar IP público
PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || echo "localhost")

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}✅ Instalação com Docker concluída!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo -e "Acesse: ${YELLOW}http://${PUBLIC_IP}:3000${NC}"
echo ""
echo -e "Credenciais admin:"
echo -e "  Email: ${YELLOW}admin@admin.com${NC}"
echo -e "  Senha: ${YELLOW}admin123${NC}"
echo ""
echo -e "Comandos úteis:"
echo -e "  ${YELLOW}docker logs wavespeed-chat${NC}      - Ver logs"
echo -e "  ${YELLOW}docker restart wavespeed-chat${NC}   - Reiniciar"
echo -e "  ${YELLOW}docker stop wavespeed-chat${NC}      - Parar"
echo -e "  ${YELLOW}docker compose down${NC}             - Remover"
echo ""
