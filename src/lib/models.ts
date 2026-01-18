export const MODELS = [
  { id: 'anthropic/claude-3.7-sonnet', name: 'Claude 3.7 Sonnet', provider: 'anthropic' },
  { id: 'anthropic/claude-3.5-sonnet', name: 'Claude 3.5 Sonnet', provider: 'anthropic' },
  { id: 'anthropic/claude-3-haiku', name: 'Claude 3 Haiku', provider: 'anthropic' },
  { id: 'google/gemini-2.5-flash', name: 'Gemini 2.5 Flash', provider: 'google' },
  { id: 'google/gemini-2.0-flash-001', name: 'Gemini 2.0 Flash', provider: 'google' },
  { id: 'google/gemini-2.5-pro', name: 'Gemini 2.5 Pro', provider: 'google' },
  { id: 'openai/gpt-4o', name: 'GPT-4o', provider: 'openai' },
  { id: 'openai/gpt-4.1', name: 'GPT-4.1', provider: 'openai' },
  { id: 'meta-llama/llama-4-maverick', name: 'LLaMA 4 Maverick', provider: 'meta' },
  { id: 'meta-llama/llama-4-scout', name: 'LLaMA 4 Scout', provider: 'meta' },
];

export const PROVIDER_LOGOS: Record<string, string> = {
  anthropic: '/logos/anthropic.svg',
  google: '/logos/google.svg',
  openai: '/logos/openai.svg',
  meta: '/logos/meta.svg',
};

export const DEFAULT_MODEL = 'google/gemini-2.5-flash';
