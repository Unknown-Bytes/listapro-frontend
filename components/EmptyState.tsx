"use client";

import { useState } from 'react';
import { createList } from '@/lib/api';
import { PlusIcon } from '@heroicons/react/24/outline';

interface EmptyStateProps {
  onListsChange: () => Promise<void>;
}

export default function EmptyState({ onListsChange }: EmptyStateProps) {
  const [isCreatingList, setIsCreatingList] = useState(false);
  const [newListName, setNewListName] = useState('');

  const handleCreateList = async () => {
    if (!newListName.trim()) return;
    
    try {
      await createList(newListName.trim());
      setNewListName('');
      setIsCreatingList(false);
      await onListsChange();
    } catch (error) {
      console.error('Erro ao criar lista:', error);
    }
  };

  return (
    <div className="flex items-center justify-center h-full">
      <div className="text-center max-w-md p-8 bg-white rounded-lg shadow-sm">
        <h2 className="text-xl font-bold mb-4">Bem-vindo ao Gerenciador de Tarefas</h2>
        <p className="text-gray-600 mb-6">
          Parece que você ainda não tem nenhuma lista de tarefas. Crie sua primeira lista para começar.
        </p>
        
        {isCreatingList ? (
          <div className="flex items-center p-3 bg-gray-50 rounded-md">
            <input
              type="text"
              value={newListName}
              onChange={(e) => setNewListName(e.target.value)}
              placeholder="Nome da lista"
              className="flex-1 bg-transparent outline-none"
              autoFocus
              onKeyDown={(e) => e.key === 'Enter' && handleCreateList()}
            />
            <button 
              onClick={handleCreateList}
              className="ml-2 btn btn-primary"
            >
              Criar
            </button>
            <button 
              onClick={() => {
                setIsCreatingList(false);
                setNewListName('');
              }}
              className="ml-2 btn btn-secondary"
            >
              Cancelar
            </button>
          </div>
        ) : (
          <button
            onClick={() => setIsCreatingList(true)}
            className="btn btn-primary flex items-center mx-auto"
          >
            <PlusIcon className="w-5 h-5 mr-2" />
            Criar Nova Lista
          </button>
        )}
      </div>
    </div>
  );
}
