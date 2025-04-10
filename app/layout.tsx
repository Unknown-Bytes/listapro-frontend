import './globals.css';
import { Inter } from 'next/font/google';
import Sidebar from '@/components/Sidebar';
import { Suspense } from 'react';

const inter = Inter({ subsets: ['latin'] });

export const metadata = {
  title: 'TodoList App',
  description: 'Aplicativo de lista de tarefas',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="pt-BR">
      <body className={inter.className + ' bg-gray-50'}>
        <div className="flex min-h-screen">
          <Suspense fallback={<div className="p-6">Carregando menu...</div>}>
            <Sidebar />
          </Suspense>
          <main className="flex-1 p-6">{children}</main>
        </div>
      </body>
    </html>
  );
}
