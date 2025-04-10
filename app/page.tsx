"use client";

import { useCallback, useEffect, useState } from 'react';
import { useSearchParams } from 'next/navigation';
import TaskList from '@/components/TaskList';
import { fetchLists } from '@/lib/api';
import EmptyState from '@/components/EmptyState';
import Loading from '@/components/Loading';

export default function Home() {
  const [lists, setLists] = useState<TaskList[]>([]);
  const [loading, setLoading] = useState(true);
  const searchParams = useSearchParams();
  const selectedListId = Number(searchParams.get('list')) || null;
  
  const selectedList = lists.find(list => list.ID === selectedListId) || null;

  const loadLists = useCallback(async () => {
    try {
      setLoading(true);
      const fetchedLists = await fetchLists();
      setLists(fetchedLists);
    } catch (error) {
      console.error('Erro ao carregar listas:', error);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadLists();
  }, [loadLists]);

  if (loading) {
    return <Loading />;
  }

  if (lists.length === 0) {
    return <EmptyState onListsChange={loadLists} />;
  }

  if (!selectedList && lists.length > 0) {
    return (
      <div className="flex items-center justify-center h-full">
        <div className="text-center max-w-md p-6 bg-white rounded-lg shadow-sm">
          <h2 className="text-xl font-bold mb-4">Selecione uma lista</h2>
          <p className="text-gray-600 mb-2">
            Escolha uma lista de tarefas no menu lateral para visualizar e gerenciar suas tarefas.
          </p>
        </div>
      </div>
    );
  }

  return (
    <div>
      {selectedList && (
        <TaskList 
          list={selectedList} 
          onListsChange={loadLists}
        />
      )}
    </div>
  );
}