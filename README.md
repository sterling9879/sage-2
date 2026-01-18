# WaveSpeed Chat

Chat de IA simples usando a API WaveSpeed como backend.

## Stack

- Next.js 14 (App Router)
- TypeScript
- Tailwind CSS
- Prisma + SQLite
- NextAuth (credentials)
- Zustand

## Instalação

```bash
# 1. Instalar dependências
npm install

# 2. Gerar Prisma Client
npx prisma generate

# 3. Criar banco de dados
npx prisma db push

# 4. Criar usuário admin inicial
npx prisma db seed

# 5. Rodar em desenvolvimento
npm run dev
```

## Credenciais Admin

Após rodar o seed, você terá um usuário admin:

- **Email:** admin@admin.com
- **Senha:** admin123

## Configuração

Após fazer login como admin, vá em **Admin > Configurações** e insira sua API Key do WaveSpeed.

## Estrutura

```
├── prisma/           # Schema e seed do banco
├── public/logos/     # Logos dos providers (Anthropic, Google, OpenAI, Meta)
├── src/
│   ├── app/          # App Router pages e API routes
│   ├── components/   # Componentes React
│   ├── lib/          # Utilitários (prisma, auth, wavespeed)
│   ├── stores/       # Zustand stores
│   └── types/        # TypeScript types
```

## Modelos Disponíveis

- **Anthropic:** Claude 3.7 Sonnet, Claude 3.5 Sonnet, Claude 3 Haiku
- **Google:** Gemini 2.5 Flash, Gemini 2.0 Flash, Gemini 2.5 Pro
- **OpenAI:** GPT-4o, GPT-4.1
- **Meta:** LLaMA 4 Maverick, LLaMA 4 Scout

## Deploy em VPS Ubuntu 22.04

```bash
# 1. Instalar Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# 2. Instalar PM2
sudo npm install -g pm2

# 3. Clonar/copiar projeto
cd /var/www/wavespeed-chat

# 4. Instalar dependências
npm install

# 5. Setup do banco
npx prisma generate
npx prisma db push
npx prisma db seed

# 6. Build
npm run build

# 7. Rodar com PM2
pm2 start npm --name "wavespeed-chat" -- start
pm2 save
pm2 startup

# Acesse: http://IP-DA-VPS:3000
```

## Variáveis de Ambiente (.env)

```env
DATABASE_URL="file:./dev.db"
NEXTAUTH_SECRET="sua-chave-secreta-aqui"
NEXTAUTH_URL="http://localhost:3000"
```
