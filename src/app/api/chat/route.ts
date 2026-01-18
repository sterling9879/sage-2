import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import { prisma } from '@/lib/prisma';
import { chatWithAI, buildPromptWithHistory } from '@/lib/wavespeed';

export async function POST(request: NextRequest) {
  try {
    const session = await getServerSession(authOptions);
    if (!session?.user?.id) {
      return NextResponse.json({ error: 'Não autorizado' }, { status: 401 });
    }

    const { message, conversationId, model } = await request.json();

    if (!message?.trim()) {
      return NextResponse.json({ error: 'Mensagem vazia' }, { status: 400 });
    }

    // Pegar ou criar conversa
    let conversation;
    let messages: { role: string; content: string }[] = [];

    if (conversationId) {
      conversation = await prisma.conversation.findUnique({
        where: { id: conversationId },
        include: { messages: { orderBy: { createdAt: 'asc' } } }
      });
      messages = conversation?.messages || [];
    }

    if (!conversation) {
      conversation = await prisma.conversation.create({
        data: {
          userId: session.user.id,
          title: message.substring(0, 50),
          model: model || 'google/gemini-2.5-flash'
        }
      });
    }

    // Salvar mensagem do usuário
    await prisma.message.create({
      data: {
        conversationId: conversation.id,
        userId: session.user.id,
        role: 'USER',
        content: message
      }
    });

    // Montar prompt com histórico
    const prompt = buildPromptWithHistory(messages, message);

    // Chamar API
    const aiResponse = await chatWithAI(prompt, model || conversation.model);

    // Salvar resposta
    const assistantMessage = await prisma.message.create({
      data: {
        conversationId: conversation.id,
        userId: session.user.id,
        role: 'ASSISTANT',
        content: aiResponse,
        model: model || conversation.model
      }
    });

    // Atualizar conversa
    await prisma.conversation.update({
      where: { id: conversation.id },
      data: { updatedAt: new Date() }
    });

    // Atualizar contador de mensagens do usuário
    await prisma.user.update({
      where: { id: session.user.id },
      data: { messagesUsed: { increment: 1 } }
    });

    return NextResponse.json({
      conversationId: conversation.id,
      message: {
        id: assistantMessage.id,
        role: 'ASSISTANT',
        content: aiResponse,
        model: model || conversation.model
      }
    });

  } catch (error: unknown) {
    console.error('Chat error:', error);
    const errorMessage = error instanceof Error ? error.message : 'Erro interno';
    return NextResponse.json({ error: errorMessage }, { status: 500 });
  }
}
