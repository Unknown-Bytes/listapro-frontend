"use client";

import { useState } from 'react';
import Link from 'next/link';
import { useSearchParams, useRouter } from 'next/navigation';
import { PlusIcon, TrashIcon, PencilIcon, CheckIcon, XMarkIcon } from '@heroicons/react/24/outline';
import { fetchLists, createList, updateList, deleteList } from '@/lib/api';
import { useEffect } from 'react';

export default function Sidebar() {
  const [lists, setLists] = useState<TaskList[]>([]);
  const [loading, setLoading] = useState(true);
  const [isCreatingList, setIsCreatingList] = useState(false);
  const [newListName, setNewListName] = useState('');
  const [editingListId, setEditingListId] = useState<number | null>(null);
  const [editingListName, setEditingListName] = useState('');
  
  const router = useRouter();
  const searchParams = useSearchParams();
  const selectedListId = Number(searchParams.get('list')) || null;
  
  const loadLists = async () => {
    try {
      setLoading(true);
      const fetchedLists = await fetchLists();
      setLists(fetchedLists);
    } catch (error) {
      console.error('Erro ao carregar listas:', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadLists();
  }, []);

  const handleCreateList = async () => {
    if (!newListName.trim()) return;
    
    try {
      await createList(newListName.trim());
      setNewListName('');
      setIsCreatingList(false);
      await loadLists();
    } catch (error) {
      console.error('Erro ao criar lista:', error);
    }
  };

  const handleUpdateList = async (id: number) => {
    if (!editingListName.trim()) return;
    
    try {
      await updateList(id, editingListName.trim());
      setEditingListId(null);
      setEditingListName('');
      await loadLists();
    } catch (error) {
      console.error('Erro ao atualizar lista:', error);
    }
  };

  const handleDeleteList = async (id: number) => {
    if (!confirm('Tem certeza que deseja excluir esta lista?')) return;
    
    try {
      await deleteList(id);
      if (selectedListId === id) {
        router.push('/');
      }
      await loadLists();
    } catch (error) {
      console.error('Erro ao excluir lista:', error);
    }
  };

  const startEditing = (list: TaskList) => {
    setEditingListId(list.ID);
    setEditingListName(list.Name);
  };

  return (
    <aside className="w-64 bg-white border-r border-gray-200 p-4 overflow-y-auto">
      <div className="flex items-center justify-between mb-6">
        <p>Esse é o ambiente de release</p>
        <h1 className="text-xl font-bold text-gray-800">Minhas Listas</h1>
      </div>

      <div className="mb-4">
        {isCreatingList ? (
          <div className="flex items-center p-2 bg-gray-100 rounded-md">
            <input
              type="text"
              value={newListName}
              onChange={(e) => setNewListName(e.target.value)}
              placeholder="Nome da lista"
              className="flex-1 bg-transparent outline-none text-sm"
              autoFocus
              onKeyDown={(e) => e.key === 'Enter' && handleCreateList()}
            />
            <button 
              onClick={handleCreateList}
              className="ml-2 text-green-600 hover:text-green-800"
            >
              <CheckIcon className="w-5 h-5" />
            </button>
            <button 
              onClick={() => {
                setIsCreatingList(false);
                setNewListName('');
              }}
              className="ml-1 text-red-600 hover:text-red-800"
            >
              <XMarkIcon className="w-5 h-5" />
            </button>
          </div>
        ) : (
          <button
            onClick={() => setIsCreatingList(true)}
            className="flex items-center w-full p-2 text-sm text-left font-medium text-blue-600 hover:bg-gray-100 rounded-md transition-colors"
          >
            <PlusIcon className="w-5 h-5 mr-2" />
            Nova Lista
          </button>
        )}
      </div>

      <nav>
        <ul className="space-y-1">
          {loading ? (
            <li className="text-sm text-gray-500 p-2">Carregando listas...</li>
          ) : lists.length === 0 ? (
            <li className="text-sm text-gray-500 p-2">Nenhuma lista encontrada</li>
          ) : (
            lists.map((list) => (
              <li key={list.ID} className="relative">
                {editingListId === list.ID ? (
                  <div className="flex items-center p-2 bg-gray-100 rounded-md">
                    <input
                      type="text"
                      value={editingListName}
                      onChange={(e) => setEditingListName(e.target.value)}
                      className="flex-1 bg-transparent outline-none text-sm"
                      autoFocus
                      onKeyDown={(e) => e.key === 'Enter' && handleUpdateList(list.ID)}
                    />
                    <button 
                      onClick={() => handleUpdateList(list.ID)}
                      className="ml-2 text-green-600 hover:text-green-800"
                    >
                      <CheckIcon className="w-5 h-5" />
                    </button>
                    <button 
                      onClick={() => {
                        setEditingListId(null);
                        setEditingListName('');
                      }}
                      className="ml-1 text-red-600 hover:text-red-800"
                    >
                      <XMarkIcon className="w-5 h-5" />
                    </button>
                  </div>
                ) : (
                  <Link
                    href={`/?list=${list.ID}`}
                    className={`
                      flex items-center justify-between p-2 text-sm font-medium rounded-md hover:bg-gray-100
                      ${selectedListId === list.ID ? 'bg-blue-50 text-blue-700' : 'text-gray-700'}
                    `}
                  >
                    <span className="truncate">{list.Name}</span>
                    <span className="ml-2 text-xs bg-gray-200 rounded-full px-2 py-0.5">
                      {list.Tasks ? list.Tasks.length : 0}
                    </span>
                    <div className="absolute right-0 hidden group-hover:flex">
                      <button
                        onClick={(e) => {
                          e.preventDefault();
                          startEditing(list);
                        }}
                        className="p-1 text-gray-500 hover:text-gray-700"
                      >
                        <PencilIcon className="w-4 h-4" />
                      </button>
                      <button
                        onClick={(e) => {
                          e.preventDefault();
                          handleDeleteList(list.ID);
                        }}
                        className="p-1 text-gray-500 hover:text-red-600"
                      >
                        <TrashIcon className="w-4 h-4" />
                      </button>
                    </div>
                  </Link>
                )}
              </li>
            ))
          )}
        </ul>
      </nav>
    </aside>
  );
}
