import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import { prisma } from '@/lib/prisma';

export async function GET(request: NextRequest) {
  try {
    const session = await getServerSession(authOptions);
    if (!session?.user?.id) {
      return NextResponse.json({ error: 'Não autorizado' }, { status: 401 });
    }

    const { searchParams } = new URL(request.url);
    const id = searchParams.get('id');

    if (id) {
      // Retornar uma conversa específica com mensagens
      const conversation = await prisma.conversation.findUnique({
        where: { id, userId: session.user.id },
        include: {
          messages: {
            orderBy: { createdAt: 'asc' }
          }
        }
      });

      if (!conversation) {
        return NextResponse.json({ error: 'Conversa não encontrada' }, { status: 404 });
      }

      return NextResponse.json({ messages: conversation.messages });
    }

    // Retornar lista de conversas
    const conversations = await prisma.conversation.findMany({
      where: { userId: session.user.id },
      orderBy: { updatedAt: 'desc' },
      select: {
        id: true,
        title: true,
        model: true,
        createdAt: true,
        updatedAt: true
      }
    });

    return NextResponse.json({ conversations });

  } catch (error) {
    console.error('Conversations error:', error);
    return NextResponse.json({ error: 'Erro interno' }, { status: 500 });
  }
}

export async function DELETE(request: NextRequest) {
  try {
    const session = await getServerSession(authOptions);
    if (!session?.user?.id) {
      return NextResponse.json({ error: 'Não autorizado' }, { status: 401 });
    }

    const { searchParams } = new URL(request.url);
    const id = searchParams.get('id');

    if (!id) {
      return NextResponse.json({ error: 'ID da conversa é obrigatório' }, { status: 400 });
    }

    // Verificar se a conversa pertence ao usuário
    const conversation = await prisma.conversation.findUnique({
      where: { id }
    });

    if (!conversation || conversation.userId !== session.user.id) {
      return NextResponse.json({ error: 'Conversa não encontrada' }, { status: 404 });
    }

    await prisma.conversation.delete({
      where: { id }
    });

    return NextResponse.json({ success: true });

  } catch (error) {
    console.error('Delete conversation error:', error);
    return NextResponse.json({ error: 'Erro interno' }, { status: 500 });
  }
}
