import { prisma } from './prisma';

export async function getApiKey(): Promise<string | null> {
  const setting = await prisma.settings.findUnique({
    where: { key: 'wavespeed_api_key' }
  });
  return setting?.value || null;
}

export async function chatWithAI(prompt: string, model: string): Promise<string> {
  const apiKey = await getApiKey();

  if (!apiKey) {
    throw new Error('API Key não configurada. Configure no painel admin.');
  }

  const response = await fetch('https://api.wavespeed.ai/api/v3/wavespeed-ai/any-llm', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${apiKey}`
    },
    body: JSON.stringify({
      prompt,
      model,
      enable_sync_mode: true,
      priority: 'latency'
    })
  });

  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.message || 'Erro na API WaveSpeed');
  }

  const data = await response.json();
  return data.output || '';
}

export function buildPromptWithHistory(
  messages: Array<{ role: string; content: string }>,
  newMessage: string
): string {
  let prompt = '';

  // Adiciona histórico (últimas 10 mensagens para não estourar contexto)
  const recentMessages = messages.slice(-10);

  for (const msg of recentMessages) {
    const role = msg.role === 'USER' ? 'Usuário' : 'Assistente';
    prompt += `${role}: ${msg.content}\n\n`;
  }

  prompt += `Usuário: ${newMessage}\n\nAssistente:`;
  return prompt;
}
