#!/bin/sh
set -e

echo "🔧 Configurando banco de dados..."

# Criar banco e aplicar migrations
npx prisma db push

# Executar seed se o banco estiver vazio
npx prisma db seed 2>/dev/null || echo "Seed já executado ou erro ignorado"

echo "✅ Banco configurado!"
echo "🚀 Iniciando aplicação..."

exec "$@"
