'use client';

import { ModelSelector } from './ModelSelector';
import { MessageList } from './MessageList';
import { ChatInput } from './ChatInput';

export function ChatArea() {
  return (
    <div className="flex-1 flex flex-col h-full">
      <div className="border-b p-4 flex items-center justify-between">
        <h1 className="text-lg font-semibold">Chat</h1>
        <ModelSelector />
      </div>
      <MessageList />
      <ChatInput />
    </div>
  );
}
