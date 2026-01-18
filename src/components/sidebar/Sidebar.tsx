'use client';

import { signOut, useSession } from 'next-auth/react';
import { FiPlus, FiLogOut, FiSettings, FiUser } from 'react-icons/fi';
import { ConversationList } from './ConversationList';
import { useChatStore } from '@/stores/chat';
import Link from 'next/link';

export function Sidebar() {
  const { data: session } = useSession();
  const { clearMessages } = useChatStore();

  const handleNewChat = () => {
    clearMessages();
  };

  return (
    <div className="w-64 bg-gray-50 border-r flex flex-col h-full">
      <div className="p-4 border-b">
        <button
          onClick={handleNewChat}
          className="w-full flex items-center justify-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
        >
          <FiPlus className="w-5 h-5" />
          Nova Conversa
        </button>
      </div>

      <ConversationList />

      <div className="border-t p-4 space-y-2">
        <div className="flex items-center gap-2 text-sm text-gray-600">
          <FiUser className="w-4 h-4" />
          <span className="truncate">{session?.user?.email}</span>
        </div>

        <div className="flex gap-2">
          {session?.user?.isAdmin && (
            <Link
              href="/admin"
              className="flex-1 flex items-center justify-center gap-1 px-3 py-2 text-sm bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition-colors"
            >
              <FiSettings className="w-4 h-4" />
              Admin
            </Link>
          )}
          <button
            onClick={() => signOut({ callbackUrl: '/login' })}
            className="flex-1 flex items-center justify-center gap-1 px-3 py-2 text-sm bg-red-100 text-red-600 rounded-lg hover:bg-red-200 transition-colors"
          >
            <FiLogOut className="w-4 h-4" />
            Sair
          </button>
        </div>
      </div>
    </div>
  );
}
