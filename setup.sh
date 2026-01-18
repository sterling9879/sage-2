#!/bin/bash

# =============================================
# WaveSpeed Chat - Instalação Completa
# Execute: curl -fsSL URL_DO_SCRIPT | sudo bash
# =============================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

APP_DIR="/var/www/wavespeed-chat"

echo -e "${BLUE}"
echo "╔═══════════════════════════════════════╗"
echo "║     WaveSpeed Chat - Instalador       ║"
echo "╚═══════════════════════════════════════╝"
echo -e "${NC}"

# Verificar root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}❌ Execute como root: sudo bash setup.sh${NC}"
  exit 1
fi

# ============ INSTALAR NODE.JS ============
echo -e "${YELLOW}[1/7] Instalando Node.js 20...${NC}"
if ! command -v node &> /dev/null; then
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash - > /dev/null 2>&1
  apt-get install -y nodejs > /dev/null 2>&1
fi
echo -e "${GREEN}✓ Node.js $(node -v)${NC}"

# ============ INSTALAR PM2 ============
echo -e "${YELLOW}[2/7] Instalando PM2...${NC}"
if ! command -v pm2 &> /dev/null; then
  npm install -g pm2 > /dev/null 2>&1
fi
echo -e "${GREEN}✓ PM2 instalado${NC}"

# ============ CRIAR DIRETÓRIO ============
echo -e "${YELLOW}[3/7] Criando diretório do projeto...${NC}"
mkdir -p $APP_DIR
cd $APP_DIR

# ============ CRIAR ARQUIVOS ============
echo -e "${YELLOW}[4/7] Criando arquivos do projeto...${NC}"

# package.json
cat > package.json << 'PKGJSON'
{
  "name": "wavespeed-chat",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "postinstall": "prisma generate"
  },
  "dependencies": {
    "@prisma/client": "^5.10.0",
    "bcryptjs": "^2.4.3",
    "next": "14.1.0",
    "next-auth": "^4.24.5",
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-hot-toast": "^2.4.1",
    "react-icons": "^5.0.1",
    "zustand": "^4.5.0"
  },
  "devDependencies": {
    "@types/bcryptjs": "^2.4.6",
    "@types/node": "^20.11.0",
    "@types/react": "^18.2.48",
    "@types/react-dom": "^18.2.18",
    "autoprefixer": "^10.4.17",
    "postcss": "^8.4.33",
    "prisma": "^5.10.0",
    "tailwindcss": "^3.4.1",
    "typescript": "^5.3.3"
  },
  "prisma": {
    "seed": "node prisma/seed.js"
  }
}
PKGJSON

# tsconfig.json
cat > tsconfig.json << 'TSCONFIG'
{
  "compilerOptions": {
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [{"name": "next"}],
    "paths": {"@/*": ["./src/*"]}
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
TSCONFIG

# next.config.js
cat > next.config.js << 'NEXTCONFIG'
/** @type {import('next').NextConfig} */
const nextConfig = {
  images: { unoptimized: true },
};
module.exports = nextConfig;
NEXTCONFIG

# tailwind.config.ts
cat > tailwind.config.ts << 'TAILWIND'
import type { Config } from 'tailwindcss';
const config: Config = {
  content: ['./src/**/*.{js,ts,jsx,tsx,mdx}'],
  theme: { extend: {} },
  plugins: [],
};
export default config;
TAILWIND

# postcss.config.js
cat > postcss.config.js << 'POSTCSS'
module.exports = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
};
POSTCSS

# .env
SECRET=$(openssl rand -base64 32)
PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || echo "localhost")
cat > .env << ENVFILE
DATABASE_URL="file:./dev.db"
NEXTAUTH_SECRET="${SECRET}"
NEXTAUTH_URL="http://${PUBLIC_IP}:3000"
ENVFILE

# Criar estrutura de diretórios
mkdir -p prisma
mkdir -p public/logos
mkdir -p src/app/\(auth\)/login
mkdir -p src/app/\(auth\)/register
mkdir -p src/app/chat
mkdir -p src/app/admin/users
mkdir -p src/app/admin/settings
mkdir -p src/app/api/auth/\[...nextauth\]
mkdir -p src/app/api/chat
mkdir -p src/app/api/conversations
mkdir -p src/app/api/register
mkdir -p src/app/api/admin/users
mkdir -p src/app/api/admin/settings
mkdir -p src/app/api/admin/stats
mkdir -p src/components/chat
mkdir -p src/components/sidebar
mkdir -p src/components/ui
mkdir -p src/lib
mkdir -p src/stores
mkdir -p src/types

# prisma/schema.prisma
cat > prisma/schema.prisma << 'PRISMA'
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "sqlite"
  url      = env("DATABASE_URL")
}

model User {
  id            String    @id @default(cuid())
  email         String    @unique
  password      String
  name          String?
  isAdmin       Boolean   @default(false)
  messagesUsed  Int       @default(0)
  messagesLimit Int       @default(50)
  createdAt     DateTime  @default(now())
  conversations Conversation[]
  messages      Message[]
}

model Conversation {
  id        String    @id @default(cuid())
  title     String?
  userId    String
  model     String    @default("google/gemini-2.5-flash")
  createdAt DateTime  @default(now())
  updatedAt DateTime  @updatedAt
  user      User      @relation(fields: [userId], references: [id], onDelete: Cascade)
  messages  Message[]
}

model Message {
  id             String   @id @default(cuid())
  conversationId String
  userId         String
  role           String
  content        String
  model          String?
  createdAt      DateTime @default(now())
  conversation   Conversation @relation(fields: [conversationId], references: [id], onDelete: Cascade)
  user           User         @relation(fields: [userId], references: [id], onDelete: Cascade)
}

model Settings {
  id    String @id @default(cuid())
  key   String @unique
  value String
}
PRISMA

# prisma/seed.js
cat > prisma/seed.js << 'SEED'
const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');
const prisma = new PrismaClient();

async function main() {
  const hashedPassword = await bcrypt.hash('admin123', 10);
  await prisma.user.upsert({
    where: { email: 'admin@admin.com' },
    update: {},
    create: {
      email: 'admin@admin.com',
      password: hashedPassword,
      name: 'Administrador',
      isAdmin: true,
      messagesLimit: 9999
    }
  });
  console.log('Admin criado: admin@admin.com / admin123');
}

main()
  .then(async () => await prisma.$disconnect())
  .catch(async (e) => {
    console.error(e);
    await prisma.$disconnect();
    process.exit(1);
  });
SEED

# Logos SVG
cat > public/logos/anthropic.svg << 'SVG'
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M17.304 3H13.896L20 21H23.408L17.304 3Z" fill="#D97757"/><path d="M6.696 3L0.592 21H4.096L5.32 17.4H12.68L13.904 21H17.408L11.304 3H6.696ZM6.376 14.28L9 6.576L11.624 14.28H6.376Z" fill="#D97757"/></svg>
SVG

cat > public/logos/google.svg << 'SVG'
<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/><path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/><path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/><path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/></svg>
SVG

cat > public/logos/openai.svg << 'SVG'
<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M22.28 9.82a5.98 5.98 0 0 0-.52-4.91 6.05 6.05 0 0 0-6.51-2.9A6.07 6.07 0 0 0 4.98 4.18 5.98 5.98 0 0 0 1 7.08a6.05 6.05 0 0 0 .74 7.1 5.98 5.98 0 0 0 .51 4.91 6.05 6.05 0 0 0 6.51 2.9A5.98 5.98 0 0 0 13.26 24a6.06 6.06 0 0 0 5.77-4.21 5.99 5.99 0 0 0 4-2.9 6.06 6.06 0 0 0-.75-7.07zm-9.02 12.61a4.48 4.48 0 0 1-2.88-1.04l.14-.08 4.78-2.76a.79.79 0 0 0 .39-.68v-6.74l2.02 1.17a.07.07 0 0 1 .04.05v5.58a4.5 4.5 0 0 1-4.49 4.5zm-9.66-4.13a4.47 4.47 0 0 1-.53-3.01l.14.08 4.78 2.76a.77.77 0 0 0 .78 0l5.84-3.37v2.33a.08.08 0 0 1-.03.06l-4.83 2.79a4.5 4.5 0 0 1-6.14-1.64zM2.34 7.9a4.49 4.49 0 0 1 2.37-1.97v5.7a.77.77 0 0 0 .39.68l5.81 3.35-2.02 1.17a.08.08 0 0 1-.07 0l-4.83-2.79A4.5 4.5 0 0 1 2.34 7.87zm16.6 3.86l-5.84-3.37 2.02-1.16a.08.08 0 0 1 .07 0l4.83 2.79a4.49 4.49 0 0 1-.68 8.1v-5.68a.79.79 0 0 0-.4-.68zm2.01-3.02l-.14-.09-4.77-2.78a.78.78 0 0 0-.79 0l-5.84 3.37V6.9a.07.07 0 0 1 .03-.06l4.83-2.79a4.5 4.5 0 0 1 6.68 4.66zM8.31 12.86l-2.02-1.16a.08.08 0 0 1-.04-.06V6.07a4.5 4.5 0 0 1 7.38-3.45l-.14.08-4.78 2.76a.79.79 0 0 0-.39.68zm1.1-2.37l2.6-1.5 2.6 1.5v3l-2.6 1.5-2.6-1.5z" fill="#000"/></svg>
SVG

cat > public/logos/meta.svg << 'SVG'
<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M6.91 4.03c-1.97 0-3.68 1.28-4.87 3.11C.7 9.21 0 11.88 0 14.45c0 .71.07 1.37.21 1.97a4.92 4.92 0 0 0 1.03 1.97c.49.57 1.09.93 1.85.93 1.08 0 1.98-.65 2.82-1.46a21.83 21.83 0 0 0 2.13-2.68c.48-.68.92-1.35 1.34-2.04a6.88 6.88 0 0 1-.4-2.1c0-1.03.32-1.91.88-2.6.57-.68 1.36-1.04 2.3-1.04.78 0 1.45.31 1.99.87.54.57.83 1.29.88 2.15.06.86-.1 1.78-.43 2.72-.33.94-.75 1.77-1.23 2.46a23.11 23.11 0 0 1-2.1 2.66c-.83.93-1.74 1.64-2.72 2.1-.99.46-2.09.69-3.3.69-1.04 0-1.95-.22-2.73-.65a4.73 4.73 0 0 1-1.83-1.78A4.91 4.91 0 0 1 0 17.55c0-.2 0-.39.03-.58a9.82 9.82 0 0 1-.03-.68c0-2.68.72-5.4 2.09-7.64C3.5 6.38 5.32 4.96 7.26 4.96c.76 0 1.44.18 2.02.52.59.34 1.01.82 1.29 1.42.28.59.42 1.26.42 2 0 .59-.07 1.17-.21 1.73a14.02 14.02 0 0 1-.51 1.62 24.92 24.92 0 0 1-.73 1.78c-.26.6-.52 1.16-.76 1.69-.24.52-.45 1-.63 1.42-.18.42-.32.78-.42 1.07a6.6 6.6 0 0 0-.2.87c.2-.18.44-.42.74-.73.29-.3.63-.66 1-1.08.37-.42.77-.88 1.2-1.39.42-.5.86-1.03 1.3-1.57a31.41 31.41 0 0 0 1.27-1.7c.41-.6.79-1.19 1.12-1.76a13.73 13.73 0 0 0 .87-1.7c.24-.56.41-1.08.52-1.56.11-.48.17-.92.17-1.31 0-.5-.07-.97-.2-1.4a3.31 3.31 0 0 0-.59-1.13 2.74 2.74 0 0 0-.99-.78 3.1 3.1 0 0 0-1.37-.28c-1.07 0-2.06.38-2.95 1.13-.89.75-1.68 1.77-2.36 3.03a17.47 17.47 0 0 0-1.56 4.12 19.95 19.95 0 0 0-.61 4.33c.01.32.04.63.08.93.04.3.1.6.18.89.16.57.39 1.09.7 1.54.31.46.69.82 1.17 1.07.48.25 1.07.38 1.78.38 1.13 0 2.16-.24 3.1-.7.94-.47 1.81-1.1 2.59-1.88a22.25 22.25 0 0 0 2.14-2.57 27.72 27.72 0 0 0 1.76-2.89c.5-.92.9-1.8 1.21-2.63.3-.83.51-1.58.61-2.25a7.53 7.53 0 0 0 .11-1.4c0-.85-.19-1.58-.56-2.18a3.68 3.68 0 0 0-1.5-1.39 4.18 4.18 0 0 0-2.05-.5c-.96 0-1.94.31-2.92.93-.98.62-1.93 1.45-2.84 2.48-.91 1.03-1.77 2.21-2.55 3.52-.79 1.31-1.47 2.68-2.04 4.09a20.93 20.93 0 0 0-1.19 4.12 16.78 16.78 0 0 0-.32 3.2c0 1.03.14 1.97.42 2.8.28.82.68 1.53 1.21 2.1.52.58 1.16 1.01 1.9 1.31.74.3 1.57.45 2.48.45 1.39 0 2.68-.27 3.87-.8 1.19-.54 2.27-1.26 3.24-2.16a18.8 18.8 0 0 0 2.62-3.14c.76-1.15 1.39-2.35 1.9-3.59.51-1.24.88-2.48 1.1-3.71.23-1.23.34-2.41.34-3.52 0-1.3-.17-2.49-.51-3.58a8.12 8.12 0 0 0-1.55-2.89 7.29 7.29 0 0 0-2.61-1.98c-1.04-.49-2.24-.74-3.61-.74z" fill="#0081FB"/></svg>
SVG

# src/types/index.ts
cat > src/types/index.ts << 'TYPES'
export interface Message {
  id: string;
  role: 'USER' | 'ASSISTANT';
  content: string;
  model?: string;
  createdAt: Date;
}

export interface Conversation {
  id: string;
  title: string | null;
  model: string;
  createdAt: Date;
  updatedAt: Date;
  messages?: Message[];
}
TYPES

# src/types/next-auth.d.ts
cat > src/types/next-auth.d.ts << 'NEXTAUTH_TYPES'
import 'next-auth';

declare module 'next-auth' {
  interface Session {
    user: {
      id: string;
      email: string;
      name?: string | null;
      isAdmin: boolean;
    };
  }

  interface User {
    id: string;
    email: string;
    name?: string | null;
    isAdmin: boolean;
  }
}

declare module 'next-auth/jwt' {
  interface JWT {
    id: string;
    isAdmin: boolean;
  }
}
NEXTAUTH_TYPES

# src/lib/prisma.ts
cat > src/lib/prisma.ts << 'PRISMA_LIB'
import { PrismaClient } from '@prisma/client';

const globalForPrisma = globalThis as unknown as { prisma: PrismaClient | undefined };

export const prisma = globalForPrisma.prisma ?? new PrismaClient();

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma;
PRISMA_LIB

# src/lib/auth.ts
cat > src/lib/auth.ts << 'AUTH_LIB'
import { NextAuthOptions } from 'next-auth';
import CredentialsProvider from 'next-auth/providers/credentials';
import bcrypt from 'bcryptjs';
import { prisma } from './prisma';

export const authOptions: NextAuthOptions = {
  providers: [
    CredentialsProvider({
      name: 'credentials',
      credentials: {
        email: { label: 'Email', type: 'email' },
        password: { label: 'Senha', type: 'password' }
      },
      async authorize(credentials) {
        if (!credentials?.email || !credentials?.password) {
          throw new Error('Email e senha são obrigatórios');
        }

        const user = await prisma.user.findUnique({
          where: { email: credentials.email }
        });

        if (!user) throw new Error('Usuário não encontrado');

        const isValid = await bcrypt.compare(credentials.password, user.password);
        if (!isValid) throw new Error('Senha incorreta');

        return { id: user.id, email: user.email, name: user.name, isAdmin: user.isAdmin };
      }
    })
  ],
  callbacks: {
    async jwt({ token, user }) {
      if (user) { token.id = user.id; token.isAdmin = user.isAdmin; }
      return token;
    },
    async session({ session, token }) {
      if (session.user) { session.user.id = token.id as string; session.user.isAdmin = token.isAdmin as boolean; }
      return session;
    }
  },
  pages: { signIn: '/login' },
  session: { strategy: 'jwt' },
  secret: process.env.NEXTAUTH_SECRET
};
AUTH_LIB

# src/lib/models.ts
cat > src/lib/models.ts << 'MODELS_LIB'
export const MODELS = [
  { id: 'anthropic/claude-3.7-sonnet', name: 'Claude 3.7 Sonnet', provider: 'anthropic' },
  { id: 'anthropic/claude-3.5-sonnet', name: 'Claude 3.5 Sonnet', provider: 'anthropic' },
  { id: 'anthropic/claude-3-haiku', name: 'Claude 3 Haiku', provider: 'anthropic' },
  { id: 'google/gemini-2.5-flash', name: 'Gemini 2.5 Flash', provider: 'google' },
  { id: 'google/gemini-2.0-flash-001', name: 'Gemini 2.0 Flash', provider: 'google' },
  { id: 'google/gemini-2.5-pro', name: 'Gemini 2.5 Pro', provider: 'google' },
  { id: 'openai/gpt-4o', name: 'GPT-4o', provider: 'openai' },
  { id: 'openai/gpt-4.1', name: 'GPT-4.1', provider: 'openai' },
  { id: 'meta-llama/llama-4-maverick', name: 'LLaMA 4 Maverick', provider: 'meta' },
  { id: 'meta-llama/llama-4-scout', name: 'LLaMA 4 Scout', provider: 'meta' },
];

export const PROVIDER_LOGOS: Record<string, string> = {
  anthropic: '/logos/anthropic.svg',
  google: '/logos/google.svg',
  openai: '/logos/openai.svg',
  meta: '/logos/meta.svg',
};

export const DEFAULT_MODEL = 'google/gemini-2.5-flash';
MODELS_LIB

# src/lib/wavespeed.ts
cat > src/lib/wavespeed.ts << 'WAVESPEED_LIB'
import { prisma } from './prisma';

export async function getApiKey(): Promise<string | null> {
  const setting = await prisma.settings.findUnique({ where: { key: 'wavespeed_api_key' } });
  return setting?.value || null;
}

export async function chatWithAI(prompt: string, model: string): Promise<string> {
  const apiKey = await getApiKey();
  if (!apiKey) throw new Error('API Key não configurada. Configure no painel admin.');

  const response = await fetch('https://api.wavespeed.ai/api/v3/wavespeed-ai/any-llm', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${apiKey}` },
    body: JSON.stringify({ prompt, model, enable_sync_mode: true, priority: 'latency' })
  });

  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.message || 'Erro na API WaveSpeed');
  }

  const data = await response.json();
  return data.output || '';
}

export function buildPromptWithHistory(messages: Array<{ role: string; content: string }>, newMessage: string): string {
  let prompt = '';
  const recentMessages = messages.slice(-10);
  for (const msg of recentMessages) {
    const role = msg.role === 'USER' ? 'Usuário' : 'Assistente';
    prompt += `${role}: ${msg.content}\n\n`;
  }
  prompt += `Usuário: ${newMessage}\n\nAssistente:`;
  return prompt;
}
WAVESPEED_LIB

# src/stores/chat.ts
cat > src/stores/chat.ts << 'STORE'
import { create } from 'zustand';
import { Message, Conversation } from '@/types';
import { DEFAULT_MODEL } from '@/lib/models';

interface ChatState {
  conversations: Conversation[];
  currentConversationId: string | null;
  messages: Message[];
  isLoading: boolean;
  selectedModel: string;
  setConversations: (conversations: Conversation[]) => void;
  setCurrentConversation: (id: string | null) => void;
  setMessages: (messages: Message[]) => void;
  addMessage: (message: Message) => void;
  setLoading: (loading: boolean) => void;
  setSelectedModel: (model: string) => void;
  clearMessages: () => void;
}

export const useChatStore = create<ChatState>((set) => ({
  conversations: [],
  currentConversationId: null,
  messages: [],
  isLoading: false,
  selectedModel: DEFAULT_MODEL,
  setConversations: (conversations) => set({ conversations }),
  setCurrentConversation: (id) => set({ currentConversationId: id }),
  setMessages: (messages) => set({ messages }),
  addMessage: (message) => set((state) => ({ messages: [...state.messages, message] })),
  setLoading: (loading) => set({ isLoading: loading }),
  setSelectedModel: (model) => set({ selectedModel: model }),
  clearMessages: () => set({ messages: [], currentConversationId: null })
}));
STORE

# src/app/globals.css
cat > src/app/globals.css << 'CSS'
@tailwind base;
@tailwind components;
@tailwind utilities;

* { box-sizing: border-box; }
html, body { height: 100%; margin: 0; padding: 0; }

::-webkit-scrollbar { width: 8px; height: 8px; }
::-webkit-scrollbar-track { background: #f1f1f1; }
::-webkit-scrollbar-thumb { background: #c1c1c1; border-radius: 4px; }
::-webkit-scrollbar-thumb:hover { background: #a1a1a1; }
CSS

# src/app/layout.tsx
cat > src/app/layout.tsx << 'LAYOUT'
import type { Metadata } from 'next';
import { Inter } from 'next/font/google';
import { Toaster } from 'react-hot-toast';
import './globals.css';
import { Providers } from './providers';

const inter = Inter({ subsets: ['latin'] });

export const metadata: Metadata = {
  title: 'WaveSpeed Chat',
  description: 'Chat com IA usando WaveSpeed API',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="pt-BR">
      <body className={inter.className}>
        <Providers>
          {children}
          <Toaster position="top-right" />
        </Providers>
      </body>
    </html>
  );
}
LAYOUT

# src/app/providers.tsx
cat > src/app/providers.tsx << 'PROVIDERS'
'use client';

import { SessionProvider } from 'next-auth/react';
import { ReactNode } from 'react';

export function Providers({ children }: { children: ReactNode }) {
  return <SessionProvider>{children}</SessionProvider>;
}
PROVIDERS

# src/app/page.tsx
cat > src/app/page.tsx << 'PAGE'
import { redirect } from 'next/navigation';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';

export default async function Home() {
  const session = await getServerSession(authOptions);
  if (session) redirect('/chat');
  else redirect('/login');
}
PAGE

# src/components/ui/Button.tsx
cat > src/components/ui/Button.tsx << 'BUTTON'
'use client';

import { ButtonHTMLAttributes, forwardRef } from 'react';

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'danger' | 'ghost';
  size?: 'sm' | 'md' | 'lg';
  isLoading?: boolean;
}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className = '', variant = 'primary', size = 'md', isLoading, children, disabled, ...props }, ref) => {
    const base = 'inline-flex items-center justify-center font-medium rounded-lg transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed';
    const variants: Record<string, string> = {
      primary: 'bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500',
      secondary: 'bg-gray-200 text-gray-900 hover:bg-gray-300 focus:ring-gray-500',
      danger: 'bg-red-600 text-white hover:bg-red-700 focus:ring-red-500',
      ghost: 'bg-transparent text-gray-700 hover:bg-gray-100 focus:ring-gray-500'
    };
    const sizes: Record<string, string> = { sm: 'px-3 py-1.5 text-sm', md: 'px-4 py-2 text-base', lg: 'px-6 py-3 text-lg' };

    return (
      <button ref={ref} className={`${base} ${variants[variant]} ${sizes[size]} ${className}`} disabled={disabled || isLoading} {...props}>
        {isLoading && <svg className="animate-spin -ml-1 mr-2 h-4 w-4" fill="none" viewBox="0 0 24 24"><circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" /><path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" /></svg>}
        {children}
      </button>
    );
  }
);

Button.displayName = 'Button';
BUTTON

# src/components/ui/Input.tsx
cat > src/components/ui/Input.tsx << 'INPUT'
'use client';

import { InputHTMLAttributes, forwardRef } from 'react';

interface InputProps extends InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  error?: string;
}

export const Input = forwardRef<HTMLInputElement, InputProps>(
  ({ className = '', label, error, ...props }, ref) => {
    return (
      <div className="w-full">
        {label && <label className="block text-sm font-medium text-gray-700 mb-1">{label}</label>}
        <input ref={ref} className={`w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent disabled:bg-gray-100 disabled:cursor-not-allowed ${error ? 'border-red-500' : ''} ${className}`} {...props} />
        {error && <p className="mt-1 text-sm text-red-600">{error}</p>}
      </div>
    );
  }
);

Input.displayName = 'Input';
INPUT

# src/components/chat/ModelSelector.tsx
cat > src/components/chat/ModelSelector.tsx << 'MODEL_SELECTOR'
'use client';

import { useState, useRef, useEffect } from 'react';
import Image from 'next/image';
import { FiChevronDown } from 'react-icons/fi';
import { MODELS, PROVIDER_LOGOS } from '@/lib/models';
import { useChatStore } from '@/stores/chat';

export function ModelSelector() {
  const [isOpen, setIsOpen] = useState(false);
  const dropdownRef = useRef<HTMLDivElement>(null);
  const { selectedModel, setSelectedModel } = useChatStore();
  const currentModel = MODELS.find(m => m.id === selectedModel) || MODELS[0];

  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) setIsOpen(false);
    }
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  return (
    <div className="relative" ref={dropdownRef}>
      <button onClick={() => setIsOpen(!isOpen)} className="flex items-center gap-2 px-3 py-2 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors">
        <Image src={PROVIDER_LOGOS[currentModel.provider]} alt={currentModel.provider} width={20} height={20} className="w-5 h-5" />
        <span className="text-sm font-medium">{currentModel.name}</span>
        <FiChevronDown className={`w-4 h-4 transition-transform ${isOpen ? 'rotate-180' : ''}`} />
      </button>
      {isOpen && (
        <div className="absolute top-full left-0 mt-1 w-64 bg-white border border-gray-200 rounded-lg shadow-lg z-50 max-h-80 overflow-auto">
          {MODELS.map((model) => (
            <button key={model.id} onClick={() => { setSelectedModel(model.id); setIsOpen(false); }} className={`w-full flex items-center gap-3 px-3 py-2 hover:bg-gray-100 transition-colors ${model.id === selectedModel ? 'bg-blue-50' : ''}`}>
              <Image src={PROVIDER_LOGOS[model.provider]} alt={model.provider} width={20} height={20} className="w-5 h-5" />
              <span className="text-sm">{model.name}</span>
            </button>
          ))}
        </div>
      )}
    </div>
  );
}
MODEL_SELECTOR

# src/components/chat/MessageList.tsx
cat > src/components/chat/MessageList.tsx << 'MESSAGE_LIST'
'use client';

import { useEffect, useRef } from 'react';
import { FiUser } from 'react-icons/fi';
import { RiRobot2Line } from 'react-icons/ri';
import { useChatStore } from '@/stores/chat';

export function MessageList() {
  const { messages, isLoading } = useChatStore();
  const messagesEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => { messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' }); }, [messages]);

  if (messages.length === 0 && !isLoading) {
    return (
      <div className="flex-1 flex items-center justify-center">
        <div className="text-center text-gray-500">
          <RiRobot2Line className="w-16 h-16 mx-auto mb-4 text-gray-300" />
          <h3 className="text-lg font-medium mb-2">Comece uma conversa</h3>
          <p className="text-sm">Envie uma mensagem para iniciar o chat com a IA</p>
        </div>
      </div>
    );
  }

  return (
    <div className="flex-1 overflow-auto p-4 space-y-4">
      {messages.map((message) => (
        <div key={message.id} className={`flex gap-3 ${message.role === 'USER' ? 'justify-end' : 'justify-start'}`}>
          {message.role === 'ASSISTANT' && <div className="flex-shrink-0 w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center"><RiRobot2Line className="w-5 h-5 text-blue-600" /></div>}
          <div className={`max-w-[70%] rounded-lg px-4 py-2 ${message.role === 'USER' ? 'bg-blue-600 text-white' : 'bg-gray-100 text-gray-900'}`}>
            <p className="whitespace-pre-wrap">{message.content}</p>
          </div>
          {message.role === 'USER' && <div className="flex-shrink-0 w-8 h-8 bg-gray-200 rounded-full flex items-center justify-center"><FiUser className="w-5 h-5 text-gray-600" /></div>}
        </div>
      ))}
      {isLoading && (
        <div className="flex gap-3 justify-start">
          <div className="flex-shrink-0 w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center"><RiRobot2Line className="w-5 h-5 text-blue-600" /></div>
          <div className="bg-gray-100 rounded-lg px-4 py-2">
            <div className="flex space-x-1">
              <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style={{ animationDelay: '0ms' }} />
              <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style={{ animationDelay: '150ms' }} />
              <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style={{ animationDelay: '300ms' }} />
            </div>
          </div>
        </div>
      )}
      <div ref={messagesEndRef} />
    </div>
  );
}
MESSAGE_LIST

# src/components/chat/ChatInput.tsx
cat > src/components/chat/ChatInput.tsx << 'CHAT_INPUT'
'use client';

import { useState, FormEvent, KeyboardEvent } from 'react';
import { FiSend } from 'react-icons/fi';
import { useChatStore } from '@/stores/chat';
import toast from 'react-hot-toast';

export function ChatInput() {
  const [message, setMessage] = useState('');
  const { currentConversationId, selectedModel, isLoading, setLoading, addMessage, setCurrentConversation, setConversations } = useChatStore();

  const handleSubmit = async (e?: FormEvent) => {
    e?.preventDefault();
    const trimmedMessage = message.trim();
    if (!trimmedMessage || isLoading) return;

    setMessage('');
    setLoading(true);
    addMessage({ id: `temp-${Date.now()}`, role: 'USER', content: trimmedMessage, createdAt: new Date() });

    try {
      const response = await fetch('/api/chat', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ message: trimmedMessage, conversationId: currentConversationId, model: selectedModel })
      });
      const data = await response.json();
      if (!response.ok) throw new Error(data.error || 'Erro ao enviar mensagem');

      if (!currentConversationId && data.conversationId) {
        setCurrentConversation(data.conversationId);
        const convResponse = await fetch('/api/conversations');
        const convData = await convResponse.json();
        if (convData.conversations) setConversations(convData.conversations);
      }

      addMessage({ id: data.message.id, role: 'ASSISTANT', content: data.message.content, model: data.message.model, createdAt: new Date() });
    } catch (error: unknown) {
      toast.error(error instanceof Error ? error.message : 'Erro ao enviar mensagem');
    } finally {
      setLoading(false);
    }
  };

  const handleKeyDown = (e: KeyboardEvent<HTMLTextAreaElement>) => {
    if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); handleSubmit(); }
  };

  return (
    <form onSubmit={handleSubmit} className="border-t p-4">
      <div className="flex gap-2">
        <textarea value={message} onChange={(e) => setMessage(e.target.value)} onKeyDown={handleKeyDown} placeholder="Digite sua mensagem... (Shift+Enter para nova linha)" className="flex-1 resize-none rounded-lg border border-gray-300 px-4 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent min-h-[44px] max-h-[200px]" rows={1} disabled={isLoading} />
        <button type="submit" disabled={!message.trim() || isLoading} className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"><FiSend className="w-5 h-5" /></button>
      </div>
    </form>
  );
}
CHAT_INPUT

# src/components/chat/ChatArea.tsx
cat > src/components/chat/ChatArea.tsx << 'CHAT_AREA'
'use client';

import { ModelSelector } from './ModelSelector';
import { MessageList } from './MessageList';
import { ChatInput } from './ChatInput';

export function ChatArea() {
  return (
    <div className="flex-1 flex flex-col h-full">
      <div className="border-b p-4 flex items-center justify-between">
        <h1 className="text-lg font-semibold">Chat</h1>
        <ModelSelector />
      </div>
      <MessageList />
      <ChatInput />
    </div>
  );
}
CHAT_AREA

# src/components/sidebar/ConversationList.tsx
cat > src/components/sidebar/ConversationList.tsx << 'CONV_LIST'
'use client';

import { useEffect } from 'react';
import { FiMessageSquare, FiTrash2 } from 'react-icons/fi';
import { useChatStore } from '@/stores/chat';
import toast from 'react-hot-toast';

export function ConversationList() {
  const { conversations, currentConversationId, setConversations, setCurrentConversation, setMessages } = useChatStore();

  useEffect(() => { loadConversations(); }, []);

  const loadConversations = async () => {
    try {
      const response = await fetch('/api/conversations');
      const data = await response.json();
      if (data.conversations) setConversations(data.conversations);
    } catch (error) { console.error('Erro ao carregar conversas:', error); }
  };

  const selectConversation = async (id: string) => {
    try {
      setCurrentConversation(id);
      const response = await fetch(`/api/conversations?id=${id}`);
      const data = await response.json();
      if (data.messages) setMessages(data.messages);
    } catch (error) { console.error('Erro ao carregar mensagens:', error); }
  };

  const deleteConversation = async (id: string, e: React.MouseEvent) => {
    e.stopPropagation();
    if (!confirm('Tem certeza que deseja excluir esta conversa?')) return;
    try {
      const response = await fetch(`/api/conversations?id=${id}`, { method: 'DELETE' });
      if (response.ok) {
        setConversations(conversations.filter(c => c.id !== id));
        if (currentConversationId === id) { setCurrentConversation(null); setMessages([]); }
        toast.success('Conversa excluída');
      }
    } catch (error) { toast.error('Erro ao excluir conversa'); }
  };

  return (
    <div className="flex-1 overflow-auto">
      {conversations.length === 0 ? (
        <p className="text-sm text-gray-500 p-4 text-center">Nenhuma conversa ainda</p>
      ) : (
        <div className="space-y-1 p-2">
          {conversations.map((conversation) => (
            <div key={conversation.id} onClick={() => selectConversation(conversation.id)} className={`flex items-center justify-between gap-2 p-3 rounded-lg cursor-pointer transition-colors group ${currentConversationId === conversation.id ? 'bg-blue-100 text-blue-900' : 'hover:bg-gray-100'}`}>
              <div className="flex items-center gap-2 min-w-0">
                <FiMessageSquare className="w-4 h-4 flex-shrink-0" />
                <span className="text-sm truncate">{conversation.title || 'Nova conversa'}</span>
              </div>
              <button onClick={(e) => deleteConversation(conversation.id, e)} className="opacity-0 group-hover:opacity-100 p-1 hover:bg-gray-200 rounded transition-all"><FiTrash2 className="w-4 h-4 text-red-500" /></button>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
CONV_LIST

# src/components/sidebar/Sidebar.tsx
cat > src/components/sidebar/Sidebar.tsx << 'SIDEBAR'
'use client';

import { signOut, useSession } from 'next-auth/react';
import { FiPlus, FiLogOut, FiSettings, FiUser } from 'react-icons/fi';
import { ConversationList } from './ConversationList';
import { useChatStore } from '@/stores/chat';
import Link from 'next/link';

export function Sidebar() {
  const { data: session } = useSession();
  const { clearMessages } = useChatStore();

  return (
    <div className="w-64 bg-gray-50 border-r flex flex-col h-full">
      <div className="p-4 border-b">
        <button onClick={() => clearMessages()} className="w-full flex items-center justify-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors">
          <FiPlus className="w-5 h-5" /> Nova Conversa
        </button>
      </div>
      <ConversationList />
      <div className="border-t p-4 space-y-2">
        <div className="flex items-center gap-2 text-sm text-gray-600"><FiUser className="w-4 h-4" /><span className="truncate">{session?.user?.email}</span></div>
        <div className="flex gap-2">
          {session?.user?.isAdmin && <Link href="/admin" className="flex-1 flex items-center justify-center gap-1 px-3 py-2 text-sm bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition-colors"><FiSettings className="w-4 h-4" />Admin</Link>}
          <button onClick={() => signOut({ callbackUrl: '/login' })} className="flex-1 flex items-center justify-center gap-1 px-3 py-2 text-sm bg-red-100 text-red-600 rounded-lg hover:bg-red-200 transition-colors"><FiLogOut className="w-4 h-4" />Sair</button>
        </div>
      </div>
    </div>
  );
}
SIDEBAR

# src/app/(auth)/login/page.tsx
cat > 'src/app/(auth)/login/page.tsx' << 'LOGIN'
'use client';

import { useState } from 'react';
import { signIn } from 'next-auth/react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import toast from 'react-hot-toast';

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    try {
      const result = await signIn('credentials', { email, password, redirect: false });
      if (result?.error) toast.error(result.error);
      else { router.push('/chat'); router.refresh(); }
    } catch (error) { toast.error('Erro ao fazer login'); }
    finally { setIsLoading(false); }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-100">
      <div className="bg-white p-8 rounded-lg shadow-md w-full max-w-md">
        <h1 className="text-2xl font-bold text-center mb-6">WaveSpeed Chat</h1>
        <h2 className="text-lg text-gray-600 text-center mb-6">Entrar</h2>
        <form onSubmit={handleSubmit} className="space-y-4">
          <Input type="email" label="Email" value={email} onChange={(e) => setEmail(e.target.value)} placeholder="seu@email.com" required />
          <Input type="password" label="Senha" value={password} onChange={(e) => setPassword(e.target.value)} placeholder="Sua senha" required />
          <Button type="submit" className="w-full" isLoading={isLoading}>Entrar</Button>
        </form>
        <p className="mt-4 text-center text-sm text-gray-600">Não tem uma conta? <Link href="/register" className="text-blue-600 hover:underline">Cadastre-se</Link></p>
      </div>
    </div>
  );
}
LOGIN

# src/app/(auth)/register/page.tsx
cat > 'src/app/(auth)/register/page.tsx' << 'REGISTER'
'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import toast from 'react-hot-toast';

export default function RegisterPage() {
  const router = useRouter();
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (password !== confirmPassword) { toast.error('As senhas não conferem'); return; }
    if (password.length < 6) { toast.error('A senha deve ter pelo menos 6 caracteres'); return; }
    setIsLoading(true);
    try {
      const response = await fetch('/api/register', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email, password, name }) });
      const data = await response.json();
      if (!response.ok) throw new Error(data.error || 'Erro ao cadastrar');
      toast.success('Cadastro realizado com sucesso!');
      router.push('/login');
    } catch (error: unknown) { toast.error(error instanceof Error ? error.message : 'Erro ao cadastrar'); }
    finally { setIsLoading(false); }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-100">
      <div className="bg-white p-8 rounded-lg shadow-md w-full max-w-md">
        <h1 className="text-2xl font-bold text-center mb-6">WaveSpeed Chat</h1>
        <h2 className="text-lg text-gray-600 text-center mb-6">Criar Conta</h2>
        <form onSubmit={handleSubmit} className="space-y-4">
          <Input type="text" label="Nome (opcional)" value={name} onChange={(e) => setName(e.target.value)} placeholder="Seu nome" />
          <Input type="email" label="Email" value={email} onChange={(e) => setEmail(e.target.value)} placeholder="seu@email.com" required />
          <Input type="password" label="Senha" value={password} onChange={(e) => setPassword(e.target.value)} placeholder="Mínimo 6 caracteres" required />
          <Input type="password" label="Confirmar Senha" value={confirmPassword} onChange={(e) => setConfirmPassword(e.target.value)} placeholder="Repita a senha" required />
          <Button type="submit" className="w-full" isLoading={isLoading}>Cadastrar</Button>
        </form>
        <p className="mt-4 text-center text-sm text-gray-600">Já tem uma conta? <Link href="/login" className="text-blue-600 hover:underline">Entrar</Link></p>
      </div>
    </div>
  );
}
REGISTER

# src/app/chat/layout.tsx
cat > src/app/chat/layout.tsx << 'CHAT_LAYOUT'
'use client';

import { useSession } from 'next-auth/react';
import { redirect } from 'next/navigation';
import { Sidebar } from '@/components/sidebar/Sidebar';

export default function ChatLayout({ children }: { children: React.ReactNode }) {
  const { data: session, status } = useSession();

  if (status === 'loading') return <div className="h-screen flex items-center justify-center"><div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div></div>;
  if (!session) redirect('/login');

  return <div className="h-screen flex"><Sidebar /><main className="flex-1 flex flex-col overflow-hidden">{children}</main></div>;
}
CHAT_LAYOUT

# src/app/chat/page.tsx
cat > src/app/chat/page.tsx << 'CHAT_PAGE'
'use client';

import { ChatArea } from '@/components/chat/ChatArea';

export default function ChatPage() {
  return <ChatArea />;
}
CHAT_PAGE

# src/app/admin/layout.tsx
cat > src/app/admin/layout.tsx << 'ADMIN_LAYOUT'
'use client';

import { useSession } from 'next-auth/react';
import { redirect } from 'next/navigation';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { FiHome, FiUsers, FiSettings, FiArrowLeft } from 'react-icons/fi';

const navItems = [
  { href: '/admin', label: 'Dashboard', icon: FiHome },
  { href: '/admin/users', label: 'Usuários', icon: FiUsers },
  { href: '/admin/settings', label: 'Configurações', icon: FiSettings },
];

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  const { data: session, status } = useSession();
  const pathname = usePathname();

  if (status === 'loading') return <div className="h-screen flex items-center justify-center"><div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div></div>;
  if (!session) redirect('/login');
  if (!session.user.isAdmin) redirect('/chat');

  return (
    <div className="h-screen flex">
      <aside className="w-64 bg-gray-800 text-white flex flex-col">
        <div className="p-4 border-b border-gray-700"><h1 className="text-xl font-bold">Admin Panel</h1></div>
        <nav className="flex-1 p-4 space-y-1">
          {navItems.map((item) => {
            const isActive = pathname === item.href;
            const Icon = item.icon;
            return <Link key={item.href} href={item.href} className={`flex items-center gap-3 px-4 py-2 rounded-lg transition-colors ${isActive ? 'bg-blue-600 text-white' : 'text-gray-300 hover:bg-gray-700'}`}><Icon className="w-5 h-5" />{item.label}</Link>;
          })}
        </nav>
        <div className="p-4 border-t border-gray-700"><Link href="/chat" className="flex items-center gap-2 text-gray-300 hover:text-white transition-colors"><FiArrowLeft className="w-5 h-5" />Voltar ao Chat</Link></div>
      </aside>
      <main className="flex-1 bg-gray-100 overflow-auto"><div className="p-6">{children}</div></main>
    </div>
  );
}
ADMIN_LAYOUT

# src/app/admin/page.tsx
cat > src/app/admin/page.tsx << 'ADMIN_PAGE'
'use client';

import { useEffect, useState } from 'react';
import { FiUsers, FiMessageSquare, FiMessageCircle } from 'react-icons/fi';

export default function AdminDashboard() {
  const [stats, setStats] = useState<{ totalUsers: number; totalMessages: number; totalConversations: number } | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    fetch('/api/admin/stats').then(r => r.json()).then(data => { if (data.stats) setStats(data.stats); }).finally(() => setIsLoading(false));
  }, []);

  if (isLoading) return <div className="flex items-center justify-center h-64"><div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div></div>;

  const statCards = [
    { label: 'Total de Usuários', value: stats?.totalUsers || 0, icon: FiUsers, color: 'bg-blue-500' },
    { label: 'Total de Mensagens', value: stats?.totalMessages || 0, icon: FiMessageSquare, color: 'bg-green-500' },
    { label: 'Total de Conversas', value: stats?.totalConversations || 0, icon: FiMessageCircle, color: 'bg-purple-500' }
  ];

  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">Dashboard</h1>
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {statCards.map((card, index) => {
          const Icon = card.icon;
          return <div key={index} className="bg-white rounded-lg shadow p-6 flex items-center gap-4"><div className={`${card.color} p-4 rounded-lg`}><Icon className="w-6 h-6 text-white" /></div><div><p className="text-sm text-gray-500">{card.label}</p><p className="text-2xl font-bold">{card.value}</p></div></div>;
        })}
      </div>
    </div>
  );
}
ADMIN_PAGE

# src/app/admin/users/page.tsx
cat > src/app/admin/users/page.tsx << 'ADMIN_USERS'
'use client';

import { useEffect, useState } from 'react';
import { FiTrash2 } from 'react-icons/fi';
import toast from 'react-hot-toast';

interface User { id: string; email: string; name: string | null; isAdmin: boolean; messagesUsed: number; messagesLimit: number; createdAt: string; _count: { conversations: number }; }

export default function AdminUsersPage() {
  const [users, setUsers] = useState<User[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => { fetch('/api/admin/users').then(r => r.json()).then(data => { if (data.users) setUsers(data.users); }).finally(() => setIsLoading(false)); }, []);

  const deleteUser = async (id: string) => {
    if (!confirm('Tem certeza que deseja excluir este usuário?')) return;
    const response = await fetch(`/api/admin/users?id=${id}`, { method: 'DELETE' });
    if (response.ok) { setUsers(users.filter(u => u.id !== id)); toast.success('Usuário excluído'); }
    else { const data = await response.json(); toast.error(data.error || 'Erro ao excluir usuário'); }
  };

  if (isLoading) return <div className="flex items-center justify-center h-64"><div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div></div>;

  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">Usuários</h1>
      <div className="bg-white rounded-lg shadow overflow-hidden">
        <table className="w-full">
          <thead className="bg-gray-50"><tr><th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Usuário</th><th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Mensagens</th><th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Conversas</th><th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Cadastro</th><th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Tipo</th><th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase">Ações</th></tr></thead>
          <tbody className="divide-y divide-gray-200">
            {users.map((user) => (
              <tr key={user.id} className="hover:bg-gray-50">
                <td className="px-6 py-4"><div><div className="font-medium text-gray-900">{user.name || 'Sem nome'}</div><div className="text-sm text-gray-500">{user.email}</div></div></td>
                <td className="px-6 py-4"><span className="text-sm">{user.messagesUsed} / {user.messagesLimit}</span></td>
                <td className="px-6 py-4"><span className="text-sm">{user._count.conversations}</span></td>
                <td className="px-6 py-4"><span className="text-sm">{new Date(user.createdAt).toLocaleDateString('pt-BR')}</span></td>
                <td className="px-6 py-4"><span className={`inline-flex px-2 py-1 text-xs font-medium rounded-full ${user.isAdmin ? 'bg-purple-100 text-purple-800' : 'bg-gray-100 text-gray-800'}`}>{user.isAdmin ? 'Admin' : 'Usuário'}</span></td>
                <td className="px-6 py-4 text-right"><button onClick={() => deleteUser(user.id)} className="text-red-500 hover:text-red-700 transition-colors"><FiTrash2 className="w-5 h-5" /></button></td>
              </tr>
            ))}
          </tbody>
        </table>
        {users.length === 0 && <div className="text-center py-8 text-gray-500">Nenhum usuário encontrado</div>}
      </div>
    </div>
  );
}
ADMIN_USERS

# src/app/admin/settings/page.tsx
cat > src/app/admin/settings/page.tsx << 'ADMIN_SETTINGS'
'use client';

import { useEffect, useState } from 'react';
import { Button } from '@/components/ui/Button';
import toast from 'react-hot-toast';
import { FiEye, FiEyeOff } from 'react-icons/fi';

export default function AdminSettingsPage() {
  const [apiKey, setApiKey] = useState('');
  const [showApiKey, setShowApiKey] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);

  useEffect(() => { fetch('/api/admin/settings').then(r => r.json()).then(data => { if (data.settings?.wavespeed_api_key) setApiKey(data.settings.wavespeed_api_key); }).finally(() => setIsLoading(false)); }, []);

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSaving(true);
    const response = await fetch('/api/admin/settings', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ key: 'wavespeed_api_key', value: apiKey }) });
    if (response.ok) toast.success('Configurações salvas com sucesso!');
    else toast.error('Erro ao salvar configurações');
    setIsSaving(false);
  };

  if (isLoading) return <div className="flex items-center justify-center h-64"><div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div></div>;

  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">Configurações</h1>
      <div className="bg-white rounded-lg shadow p-6 max-w-xl">
        <h2 className="text-lg font-semibold mb-4">API WaveSpeed</h2>
        <form onSubmit={handleSave} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">API Key</label>
            <div className="relative">
              <input type={showApiKey ? 'text' : 'password'} value={apiKey} onChange={(e) => setApiKey(e.target.value)} placeholder="Insira sua API Key do WaveSpeed" className="w-full px-3 py-2 pr-10 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent" />
              <button type="button" onClick={() => setShowApiKey(!showApiKey)} className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-500 hover:text-gray-700">{showApiKey ? <FiEyeOff className="w-5 h-5" /> : <FiEye className="w-5 h-5" />}</button>
            </div>
            <p className="mt-1 text-sm text-gray-500">Obtenha sua API Key em <a href="https://wavespeed.ai" target="_blank" rel="noopener noreferrer" className="text-blue-600 hover:underline">wavespeed.ai</a></p>
          </div>
          <Button type="submit" isLoading={isSaving}>Salvar Configurações</Button>
        </form>
      </div>
    </div>
  );
}
ADMIN_SETTINGS

# API Routes
cat > 'src/app/api/auth/[...nextauth]/route.ts' << 'AUTH_ROUTE'
import NextAuth from 'next-auth';
import { authOptions } from '@/lib/auth';

const handler = NextAuth(authOptions);

export { handler as GET, handler as POST };
AUTH_ROUTE

cat > src/app/api/register/route.ts << 'REGISTER_ROUTE'
import { NextRequest, NextResponse } from 'next/server';
import bcrypt from 'bcryptjs';
import { prisma } from '@/lib/prisma';

export async function POST(request: NextRequest) {
  try {
    const { email, password, name } = await request.json();
    if (!email || !password) return NextResponse.json({ error: 'Email e senha são obrigatórios' }, { status: 400 });

    const existingUser = await prisma.user.findUnique({ where: { email } });
    if (existingUser) return NextResponse.json({ error: 'Este email já está cadastrado' }, { status: 400 });

    const hashedPassword = await bcrypt.hash(password, 10);
    const user = await prisma.user.create({ data: { email, password: hashedPassword, name: name || null } });

    return NextResponse.json({ success: true, user: { id: user.id, email: user.email, name: user.name } });
  } catch (error) {
    console.error('Register error:', error);
    return NextResponse.json({ error: 'Erro interno' }, { status: 500 });
  }
}
REGISTER_ROUTE

cat > src/app/api/chat/route.ts << 'CHAT_ROUTE'
import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import { prisma } from '@/lib/prisma';
import { chatWithAI, buildPromptWithHistory } from '@/lib/wavespeed';

export async function POST(request: NextRequest) {
  try {
    const session = await getServerSession(authOptions);
    if (!session?.user?.id) return NextResponse.json({ error: 'Não autorizado' }, { status: 401 });

    const { message, conversationId, model } = await request.json();
    if (!message?.trim()) return NextResponse.json({ error: 'Mensagem vazia' }, { status: 400 });

    let conversation;
    let messages: { role: string; content: string }[] = [];

    if (conversationId) {
      conversation = await prisma.conversation.findUnique({ where: { id: conversationId }, include: { messages: { orderBy: { createdAt: 'asc' } } } });
      messages = conversation?.messages || [];
    }

    if (!conversation) {
      conversation = await prisma.conversation.create({ data: { userId: session.user.id, title: message.substring(0, 50), model: model || 'google/gemini-2.5-flash' } });
    }

    await prisma.message.create({ data: { conversationId: conversation.id, userId: session.user.id, role: 'USER', content: message } });

    const prompt = buildPromptWithHistory(messages, message);
    const aiResponse = await chatWithAI(prompt, model || conversation.model);

    const assistantMessage = await prisma.message.create({ data: { conversationId: conversation.id, userId: session.user.id, role: 'ASSISTANT', content: aiResponse, model: model || conversation.model } });

    await prisma.conversation.update({ where: { id: conversation.id }, data: { updatedAt: new Date() } });
    await prisma.user.update({ where: { id: session.user.id }, data: { messagesUsed: { increment: 1 } } });

    return NextResponse.json({ conversationId: conversation.id, message: { id: assistantMessage.id, role: 'ASSISTANT', content: aiResponse, model: model || conversation.model } });
  } catch (error: unknown) {
    console.error('Chat error:', error);
    return NextResponse.json({ error: error instanceof Error ? error.message : 'Erro interno' }, { status: 500 });
  }
}
CHAT_ROUTE

cat > src/app/api/conversations/route.ts << 'CONV_ROUTE'
import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import { prisma } from '@/lib/prisma';

export async function GET(request: NextRequest) {
  try {
    const session = await getServerSession(authOptions);
    if (!session?.user?.id) return NextResponse.json({ error: 'Não autorizado' }, { status: 401 });

    const { searchParams } = new URL(request.url);
    const id = searchParams.get('id');

    if (id) {
      const conversation = await prisma.conversation.findUnique({ where: { id, userId: session.user.id }, include: { messages: { orderBy: { createdAt: 'asc' } } } });
      if (!conversation) return NextResponse.json({ error: 'Conversa não encontrada' }, { status: 404 });
      return NextResponse.json({ messages: conversation.messages });
    }

    const conversations = await prisma.conversation.findMany({ where: { userId: session.user.id }, orderBy: { updatedAt: 'desc' }, select: { id: true, title: true, model: true, createdAt: true, updatedAt: true } });
    return NextResponse.json({ conversations });
  } catch (error) {
    console.error('Conversations error:', error);
    return NextResponse.json({ error: 'Erro interno' }, { status: 500 });
  }
}

export async function DELETE(request: NextRequest) {
  try {
    const session = await getServerSession(authOptions);
    if (!session?.user?.id) return NextResponse.json({ error: 'Não autorizado' }, { status: 401 });

    const { searchParams } = new URL(request.url);
    const id = searchParams.get('id');
    if (!id) return NextResponse.json({ error: 'ID da conversa é obrigatório' }, { status: 400 });

    const conversation = await prisma.conversation.findUnique({ where: { id } });
    if (!conversation || conversation.userId !== session.user.id) return NextResponse.json({ error: 'Conversa não encontrada' }, { status: 404 });

    await prisma.conversation.delete({ where: { id } });
    return NextResponse.json({ success: true });
  } catch (error) {
    console.error('Delete conversation error:', error);
    return NextResponse.json({ error: 'Erro interno' }, { status: 500 });
  }
}
CONV_ROUTE

cat > src/app/api/admin/stats/route.ts << 'STATS_ROUTE'
import { NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import { prisma } from '@/lib/prisma';

export async function GET() {
  try {
    const session = await getServerSession(authOptions);
    if (!session?.user?.isAdmin) return NextResponse.json({ error: 'Acesso negado' }, { status: 403 });

    const [totalUsers, totalMessages, totalConversations] = await Promise.all([prisma.user.count(), prisma.message.count(), prisma.conversation.count()]);
    return NextResponse.json({ stats: { totalUsers, totalMessages, totalConversations } });
  } catch (error) {
    console.error('Stats error:', error);
    return NextResponse.json({ error: 'Erro interno' }, { status: 500 });
  }
}
STATS_ROUTE

cat > src/app/api/admin/users/route.ts << 'USERS_ROUTE'
import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import { prisma } from '@/lib/prisma';

export async function GET() {
  try {
    const session = await getServerSession(authOptions);
    if (!session?.user?.isAdmin) return NextResponse.json({ error: 'Acesso negado' }, { status: 403 });

    const users = await prisma.user.findMany({ select: { id: true, email: true, name: true, isAdmin: true, messagesUsed: true, messagesLimit: true, createdAt: true, _count: { select: { conversations: true } } }, orderBy: { createdAt: 'desc' } });
    return NextResponse.json({ users });
  } catch (error) {
    console.error('Admin users error:', error);
    return NextResponse.json({ error: 'Erro interno' }, { status: 500 });
  }
}

export async function DELETE(request: NextRequest) {
  try {
    const session = await getServerSession(authOptions);
    if (!session?.user?.isAdmin) return NextResponse.json({ error: 'Acesso negado' }, { status: 403 });

    const { searchParams } = new URL(request.url);
    const id = searchParams.get('id');
    if (!id) return NextResponse.json({ error: 'ID do usuário é obrigatório' }, { status: 400 });
    if (id === session.user.id) return NextResponse.json({ error: 'Você não pode excluir sua própria conta' }, { status: 400 });

    await prisma.user.delete({ where: { id } });
    return NextResponse.json({ success: true });
  } catch (error) {
    console.error('Delete user error:', error);
    return NextResponse.json({ error: 'Erro interno' }, { status: 500 });
  }
}
USERS_ROUTE

cat > src/app/api/admin/settings/route.ts << 'SETTINGS_ROUTE'
import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import { prisma } from '@/lib/prisma';

export async function GET() {
  try {
    const session = await getServerSession(authOptions);
    if (!session?.user?.isAdmin) return NextResponse.json({ error: 'Acesso negado' }, { status: 403 });

    const settings = await prisma.settings.findMany();
    const settingsObj: Record<string, string> = {};
    for (const setting of settings) settingsObj[setting.key] = setting.value;
    return NextResponse.json({ settings: settingsObj });
  } catch (error) {
    console.error('Get settings error:', error);
    return NextResponse.json({ error: 'Erro interno' }, { status: 500 });
  }
}

export async function POST(request: NextRequest) {
  try {
    const session = await getServerSession(authOptions);
    if (!session?.user?.isAdmin) return NextResponse.json({ error: 'Acesso negado' }, { status: 403 });

    const { key, value } = await request.json();
    if (!key) return NextResponse.json({ error: 'Chave é obrigatória' }, { status: 400 });

    await prisma.settings.upsert({ where: { key }, update: { value: value || '' }, create: { key, value: value || '' } });
    return NextResponse.json({ success: true });
  } catch (error) {
    console.error('Save settings error:', error);
    return NextResponse.json({ error: 'Erro interno' }, { status: 500 });
  }
}
SETTINGS_ROUTE

echo -e "${GREEN}✓ Arquivos criados${NC}"

# ============ INSTALAR DEPENDÊNCIAS ============
echo -e "${YELLOW}[5/7] Instalando dependências (pode demorar)...${NC}"
npm install > /dev/null 2>&1
echo -e "${GREEN}✓ Dependências instaladas${NC}"

# ============ CONFIGURAR BANCO ============
echo -e "${YELLOW}[6/7] Configurando banco de dados...${NC}"
npx prisma generate > /dev/null 2>&1
npx prisma db push > /dev/null 2>&1
node prisma/seed.js > /dev/null 2>&1
echo -e "${GREEN}✓ Banco configurado${NC}"

# ============ BUILD E INICIAR ============
echo -e "${YELLOW}[7/7] Fazendo build e iniciando...${NC}"
npm run build > /dev/null 2>&1
pm2 delete wavespeed-chat 2>/dev/null || true
pm2 start npm --name "wavespeed-chat" -- start > /dev/null 2>&1
pm2 save > /dev/null 2>&1
pm2 startup > /dev/null 2>&1

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     ✅ INSTALAÇÃO CONCLUÍDA!              ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════╝${NC}"
echo ""
echo -e "🌐 Acesse: ${YELLOW}http://${PUBLIC_IP}:3000${NC}"
echo ""
echo -e "👤 Login Admin:"
echo -e "   Email: ${YELLOW}admin@admin.com${NC}"
echo -e "   Senha: ${YELLOW}admin123${NC}"
echo ""
echo -e "⚙️  Configure a API Key em: Admin > Configurações"
echo ""
echo -e "📋 Comandos úteis:"
echo -e "   ${BLUE}pm2 logs wavespeed-chat${NC}    - Ver logs"
echo -e "   ${BLUE}pm2 restart wavespeed-chat${NC} - Reiniciar"
echo -e "   ${BLUE}pm2 stop wavespeed-chat${NC}    - Parar"
echo ""
