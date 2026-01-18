'use client';

import { useEffect } from 'react';
import { FiMessageSquare, FiTrash2 } from 'react-icons/fi';
import { useChatStore } from '@/stores/chat';
import toast from 'react-hot-toast';

export function ConversationList() {
  const {
    conversations,
    currentConversationId,
    setConversations,
    setCurrentConversation,
    setMessages
  } = useChatStore();

  useEffect(() => {
    loadConversations();
  }, []);

  const loadConversations = async () => {
    try {
      const response = await fetch('/api/conversations');
      const data = await response.json();
      if (data.conversations) {
        setConversations(data.conversations);
      }
    } catch (error) {
      console.error('Erro ao carregar conversas:', error);
    }
  };

  const selectConversation = async (id: string) => {
    try {
      setCurrentConversation(id);
      const response = await fetch(`/api/conversations?id=${id}`);
      const data = await response.json();
      if (data.messages) {
        setMessages(data.messages);
      }
    } catch (error) {
      console.error('Erro ao carregar mensagens:', error);
    }
  };

  const deleteConversation = async (id: string, e: React.MouseEvent) => {
    e.stopPropagation();

    if (!confirm('Tem certeza que deseja excluir esta conversa?')) return;

    try {
      const response = await fetch(`/api/conversations?id=${id}`, {
        method: 'DELETE'
      });

      if (response.ok) {
        setConversations(conversations.filter(c => c.id !== id));
        if (currentConversationId === id) {
          setCurrentConversation(null);
          setMessages([]);
        }
        toast.success('Conversa excluída');
      }
    } catch (error) {
      toast.error('Erro ao excluir conversa');
    }
  };

  return (
    <div className="flex-1 overflow-auto">
      {conversations.length === 0 ? (
        <p className="text-sm text-gray-500 p-4 text-center">
          Nenhuma conversa ainda
        </p>
      ) : (
        <div className="space-y-1 p-2">
          {conversations.map((conversation) => (
            <div
              key={conversation.id}
              onClick={() => selectConversation(conversation.id)}
              className={`flex items-center justify-between gap-2 p-3 rounded-lg cursor-pointer transition-colors group ${
                currentConversationId === conversation.id
                  ? 'bg-blue-100 text-blue-900'
                  : 'hover:bg-gray-100'
              }`}
            >
              <div className="flex items-center gap-2 min-w-0">
                <FiMessageSquare className="w-4 h-4 flex-shrink-0" />
                <span className="text-sm truncate">
                  {conversation.title || 'Nova conversa'}
                </span>
              </div>
              <button
                onClick={(e) => deleteConversation(conversation.id, e)}
                className="opacity-0 group-hover:opacity-100 p-1 hover:bg-gray-200 rounded transition-all"
              >
                <FiTrash2 className="w-4 h-4 text-red-500" />
              </button>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
