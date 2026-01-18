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

    const users = await prisma.user.findMany({
      select: {
        id: true,
        email: true,
        name: true,
        isAdmin: true,
        messagesUsed: true,
        messagesLimit: true,
        createdAt: true,
        _count: {
          select: { conversations: true }
        }
      },
      orderBy: { createdAt: 'desc' }
    });

    return NextResponse.json({ users });

  } catch (error) {
    console.error('Admin users error:', error);
    return NextResponse.json({ error: 'Erro interno' }, { status: 500 });
  }
}

export async function DELETE(request: NextRequest) {
  try {
    const session = await getServerSession(authOptions);
    if (!session?.user?.isAdmin) {
      return NextResponse.json({ error: 'Acesso negado' }, { status: 403 });
    }

    const { searchParams } = new URL(request.url);
    const id = searchParams.get('id');

    if (!id) {
      return NextResponse.json({ error: 'ID do usuário é obrigatório' }, { status: 400 });
    }

    // Não permitir excluir a si mesmo
    if (id === session.user.id) {
      return NextResponse.json({ error: 'Você não pode excluir sua própria conta' }, { status: 400 });
    }

    await prisma.user.delete({
      where: { id }
    });

    return NextResponse.json({ success: true });

  } catch (error) {
    console.error('Delete user error:', error);
    return NextResponse.json({ error: 'Erro interno' }, { status: 500 });
  }
}

export async function PATCH(request: NextRequest) {
  try {
    const session = await getServerSession(authOptions);
    if (!session?.user?.isAdmin) {
      return NextResponse.json({ error: 'Acesso negado' }, { status: 403 });
    }

    const { id, messagesLimit, isAdmin } = await request.json();

    if (!id) {
      return NextResponse.json({ error: 'ID do usuário é obrigatório' }, { status: 400 });
    }

    const updateData: { messagesLimit?: number; isAdmin?: boolean } = {};
    if (messagesLimit !== undefined) updateData.messagesLimit = messagesLimit;
    if (isAdmin !== undefined) updateData.isAdmin = isAdmin;

    const user = await prisma.user.update({
      where: { id },
      data: updateData
    });

    return NextResponse.json({ user });

  } catch (error) {
    console.error('Update user error:', error);
    return NextResponse.json({ error: 'Erro interno' }, { status: 500 });
  }
}
