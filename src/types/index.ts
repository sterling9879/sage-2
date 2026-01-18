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

export interface User {
  id: string;
  email: string;
  name: string | null;
  isAdmin: boolean;
  messagesUsed: number;
  messagesLimit: number;
  createdAt: Date;
}
