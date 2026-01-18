import { NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import { prisma } from '@/lib/prisma';

export async function GET() {
  try {
    const session = await getServerSession(authOptions);
    if (!session?.user?.isAdmin) {
      return NextResponse.json({ error: 'Acesso negado' }, { status: 403 });
    }

    const [totalUsers, totalMessages, totalConversations] = await Promise.all([
      prisma.user.count(),
      prisma.message.count(),
      prisma.conversation.count()
    ]);

    return NextResponse.json({
      stats: {
        totalUsers,
        totalMessages,
        totalConversations
      }
    });

  } catch (error) {
    console.error('Stats error:', error);
    return NextResponse.json({ error: 'Erro interno' }, { status: 500 });
  }
}
