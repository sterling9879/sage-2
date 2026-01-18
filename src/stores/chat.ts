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
