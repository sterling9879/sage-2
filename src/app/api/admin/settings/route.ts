import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import { prisma } from '@/lib/prisma';

export async function GET() {
  try {
    const session = await getServerSession(authOptions);
    if (!session?.user?.isAdmin) {
      return NextResponse.json({ error: 'Acesso negado' }, { status: 403 });
    }

    const settings = await prisma.settings.findMany();

    // Converter para objeto
    const settingsObj: Record<string, string> = {};
    for (const setting of settings) {
      settingsObj[setting.key] = setting.value;
    }

    return NextResponse.json({ settings: settingsObj });

  } catch (error) {
    console.error('Get settings error:', error);
    return NextResponse.json({ error: 'Erro interno' }, { status: 500 });
  }
}

export async function POST(request: NextRequest) {
  try {
    const session = await getServerSession(authOptions);
    if (!session?.user?.isAdmin) {
      return NextResponse.json({ error: 'Acesso negado' }, { status: 403 });
    }

    const { key, value } = await request.json();

    if (!key) {
      return NextResponse.json({ error: 'Chave é obrigatória' }, { status: 400 });
    }

    await prisma.settings.upsert({
      where: { key },
      update: { value: value || '' },
      create: { key, value: value || '' }
    });

    return NextResponse.json({ success: true });

  } catch (error) {
    console.error('Save settings error:', error);
    return NextResponse.json({ error: 'Erro interno' }, { status: 500 });
  }
}
