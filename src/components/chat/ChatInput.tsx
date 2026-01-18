'use client';

import { useState, FormEvent, KeyboardEvent } from 'react';
import { FiSend } from 'react-icons/fi';
import { useChatStore } from '@/stores/chat';
import toast from 'react-hot-toast';

export function ChatInput() {
  const [message, setMessage] = useState('');
  const {
    currentConversationId,
    selectedModel,
    isLoading,
    setLoading,
    addMessage,
    setCurrentConversation,
    conversations,
    setConversations
  } = useChatStore();

  const handleSubmit = async (e?: FormEvent) => {
    e?.preventDefault();

    const trimmedMessage = message.trim();
    if (!trimmedMessage || isLoading) return;

    setMessage('');
    setLoading(true);

    // Adicionar mensagem do usuário localmente
    const userMessage = {
      id: `temp-${Date.now()}`,
      role: 'USER' as const,
      content: trimmedMessage,
      createdAt: new Date()
    };
    addMessage(userMessage);

    try {
      const response = await fetch('/api/chat', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          message: trimmedMessage,
          conversationId: currentConversationId,
          model: selectedModel
        })
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error || 'Erro ao enviar mensagem');
      }

      // Atualizar conversationId se for nova conversa
      if (!currentConversationId && data.conversationId) {
        setCurrentConversation(data.conversationId);
        // Recarregar lista de conversas
        const convResponse = await fetch('/api/conversations');
        const convData = await convResponse.json();
        if (convData.conversations) {
          setConversations(convData.conversations);
        }
      }

      // Adicionar resposta da IA
      addMessage({
        id: data.message.id,
        role: 'ASSISTANT',
        content: data.message.content,
        model: data.message.model,
        createdAt: new Date()
      });
    } catch (error: any) {
      toast.error(error.message || 'Erro ao enviar mensagem');
    } finally {
      setLoading(false);
    }
  };

  const handleKeyDown = (e: KeyboardEvent<HTMLTextAreaElement>) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSubmit();
    }
  };

  return (
    <form onSubmit={handleSubmit} className="border-t p-4">
      <div className="flex gap-2">
        <textarea
          value={message}
          onChange={(e) => setMessage(e.target.value)}
          onKeyDown={handleKeyDown}
          placeholder="Digite sua mensagem... (Shift+Enter para nova linha)"
          className="flex-1 resize-none rounded-lg border border-gray-300 px-4 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent min-h-[44px] max-h-[200px]"
          rows={1}
          disabled={isLoading}
        />
        <button
          type="submit"
          disabled={!message.trim() || isLoading}
          className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
        >
          <FiSend className="w-5 h-5" />
        </button>
      </div>
    </form>
  );
}
