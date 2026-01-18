'use client';

import { useEffect, useState } from 'react';
import { FiUsers, FiMessageSquare, FiMessageCircle } from 'react-icons/fi';

interface Stats {
  totalUsers: number;
  totalMessages: number;
  totalConversations: number;
}

export default function AdminDashboard() {
  const [stats, setStats] = useState<Stats | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    loadStats();
  }, []);

  const loadStats = async () => {
    try {
      const response = await fetch('/api/admin/stats');
      const data = await response.json();
      if (data.stats) {
        setStats(data.stats);
      }
    } catch (error) {
      console.error('Erro ao carregar estatísticas:', error);
    } finally {
      setIsLoading(false);
    }
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  const statCards = [
    {
      label: 'Total de Usuários',
      value: stats?.totalUsers || 0,
      icon: FiUsers,
      color: 'bg-blue-500'
    },
    {
      label: 'Total de Mensagens',
      value: stats?.totalMessages || 0,
      icon: FiMessageSquare,
      color: 'bg-green-500'
    },
    {
      label: 'Total de Conversas',
      value: stats?.totalConversations || 0,
      icon: FiMessageCircle,
      color: 'bg-purple-500'
    }
  ];

  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">Dashboard</h1>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {statCards.map((card, index) => {
          const Icon = card.icon;
          return (
            <div
              key={index}
              className="bg-white rounded-lg shadow p-6 flex items-center gap-4"
            >
              <div className={`${card.color} p-4 rounded-lg`}>
                <Icon className="w-6 h-6 text-white" />
              </div>
              <div>
                <p className="text-sm text-gray-500">{card.label}</p>
                <p className="text-2xl font-bold">{card.value}</p>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
