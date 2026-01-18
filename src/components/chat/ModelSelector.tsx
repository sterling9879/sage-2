'use client';

import { useState, useRef, useEffect } from 'react';
import Image from 'next/image';
import { FiChevronDown } from 'react-icons/fi';
import { MODELS, PROVIDER_LOGOS } from '@/lib/models';
import { useChatStore } from '@/stores/chat';

export function ModelSelector() {
  const [isOpen, setIsOpen] = useState(false);
  const dropdownRef = useRef<HTMLDivElement>(null);
  const { selectedModel, setSelectedModel } = useChatStore();

  const currentModel = MODELS.find(m => m.id === selectedModel) || MODELS[0];

  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    }

    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  return (
    <div className="relative" ref={dropdownRef}>
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="flex items-center gap-2 px-3 py-2 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
      >
        <Image
          src={PROVIDER_LOGOS[currentModel.provider]}
          alt={currentModel.provider}
          width={20}
          height={20}
          className="w-5 h-5"
        />
        <span className="text-sm font-medium">{currentModel.name}</span>
        <FiChevronDown className={`w-4 h-4 transition-transform ${isOpen ? 'rotate-180' : ''}`} />
      </button>

      {isOpen && (
        <div className="absolute top-full left-0 mt-1 w-64 bg-white border border-gray-200 rounded-lg shadow-lg z-50 max-h-80 overflow-auto">
          {MODELS.map((model) => (
            <button
              key={model.id}
              onClick={() => {
                setSelectedModel(model.id);
                setIsOpen(false);
              }}
              className={`w-full flex items-center gap-3 px-3 py-2 hover:bg-gray-100 transition-colors ${
                model.id === selectedModel ? 'bg-blue-50' : ''
              }`}
            >
              <Image
                src={PROVIDER_LOGOS[model.provider]}
                alt={model.provider}
                width={20}
                height={20}
                className="w-5 h-5"
              />
              <span className="text-sm">{model.name}</span>
            </button>
          ))}
        </div>
      )}
    </div>
  );
}
