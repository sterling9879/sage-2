'use client';

import { useSession } from 'next-auth/react';
import { redirect } from 'next/navigation';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { FiHome, FiUsers, FiSettings, FiArrowLeft } from 'react-icons/fi';

const navItems = [
  { href: '/admin', label: 'Dashboard', icon: FiHome },
  { href: '/admin/users', label: 'Usuários', icon: FiUsers },
  { href: '/admin/settings', label: 'Configurações', icon: FiSettings },
];

export default function AdminLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const { data: session, status } = useSession();
  const pathname = usePathname();

  if (status === 'loading') {
    return (
      <div className="h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  if (!session) {
    redirect('/login');
  }

  if (!session.user.isAdmin) {
    redirect('/chat');
  }

  return (
    <div className="h-screen flex">
      <aside className="w-64 bg-gray-800 text-white flex flex-col">
        <div className="p-4 border-b border-gray-700">
          <h1 className="text-xl font-bold">Admin Panel</h1>
        </div>

        <nav className="flex-1 p-4 space-y-1">
          {navItems.map((item) => {
            const isActive = pathname === item.href;
            const Icon = item.icon;
            return (
              <Link
                key={item.href}
                href={item.href}
                className={`flex items-center gap-3 px-4 py-2 rounded-lg transition-colors ${
                  isActive
                    ? 'bg-blue-600 text-white'
                    : 'text-gray-300 hover:bg-gray-700'
                }`}
              >
                <Icon className="w-5 h-5" />
                {item.label}
              </Link>
            );
          })}
        </nav>

        <div className="p-4 border-t border-gray-700">
          <Link
            href="/chat"
            className="flex items-center gap-2 text-gray-300 hover:text-white transition-colors"
          >
            <FiArrowLeft className="w-5 h-5" />
            Voltar ao Chat
          </Link>
        </div>
      </aside>

      <main className="flex-1 bg-gray-100 overflow-auto">
        <div className="p-6">{children}</div>
      </main>
    </div>
  );
}
