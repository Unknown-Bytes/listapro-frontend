"use client";

import { useState, useEffect, useCallback } from 'react';
import { PlusIcon, PencilIcon, TrashIcon, CheckIcon, XMarkIcon } from '@heroicons/react/24/outline';
import { updateTask, deleteTask, createTask, fetchTasksByList } from '@/lib/api';

interface TaskListProps {
  list: TaskList;
  onListsChange: () => Promise<void>;
}

export default function TaskList({ list, onListsChange }: TaskListProps) {
  const [tasks, setTasks] = useState<Task[]>(list.Tasks || []);
  const [newTaskText, setNewTaskText] = useState('');
  const [isAddingTask, setIsAddingTask] = useState(false);
  const [editingTaskId, setEditingTaskId] = useState<number | null>(null);
  const [editingTaskText, setEditingTaskText] = useState('');
  const [loading, setLoading] = useState(false);

  const loadTasks = useCallback(async () => {
    try {
      setLoading(true);
      const fetchedTasks = await fetchTasksByList(list.ID);
      setTasks(fetchedTasks);
    } catch (error) {
      console.error('Erro ao carregar tarefas:', error);
    } finally {
      setLoading(false);
    }
  }, [list.ID]);

  useEffect(() => {
    loadTasks();
  }, [loadTasks]);

  const handleCreateTask = async () => {
    if (!newTaskText.trim()) return;
    
    try {
      setLoading(true);
      const newTask = await createTask(list.ID, newTaskText.trim());
      setTasks(prev => [...prev, newTask]);
      setNewTaskText('');
      setIsAddingTask(false);
      await onListsChange();
    } catch (error) {
      console.error('Erro ao criar tarefa:', error);
      loadTasks(); 
    } finally {
      setLoading(false);
    }
  };

  const handleUpdateTaskText = async (id: number) => {
    if (!editingTaskText.trim()) return;
    
    try {
      setLoading(true);
      setTasks(prev => prev.map(task => 
        task.ID === id ? { ...task, Text: editingTaskText.trim() } : task
      ));
      await updateTask(id, { Text: editingTaskText.trim() });
      setEditingTaskId(null);
      setEditingTaskText('');
      await onListsChange();
    } catch (error) {
      console.error('Erro ao atualizar texto da tarefa:', error);
      loadTasks(); 
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteTask = async (id: number) => {
    try {
      setLoading(true);
      setTasks(prev => prev.filter(task => task.ID !== id));
      await deleteTask(id);
      await onListsChange();
    } catch (error) {
      console.error('Erro ao excluir tarefa:', error);
      loadTasks(); 
    } finally {
      setLoading(false);
    }
  };

  const toggleTaskCompletion = async (task: Task) => {
    try {
      setTasks(prev => prev.map(t => 
        t.ID === task.ID ? { ...t, IsCompleted: !t.IsCompleted } : t
      ));
      await updateTask(task.ID, { IsCompleted: !task.IsCompleted });
      await onListsChange();
    } catch (error) {
      console.error('Erro ao atualizar tarefa:', error);
      loadTasks(); 
    }
  };
  const startEditing = (task: Task) => {
    setEditingTaskId(task.ID);
    setEditingTaskText(task.Text);
  };


  return (
    <div className="bg-white rounded-lg shadow-sm p-6 max-w-3xl mx-auto">
      <div className="flex items-center justify-between mb-6">
        <h2 className="text-2xl font-bold text-gray-800">{list.Name}</h2>
        <span className="text-sm text-gray-500">
          {tasks.filter(t => t.IsCompleted).length}/{tasks.length} concluídas
        </span>
      </div>

      <div className="mb-6">
        {isAddingTask ? (
          <div className="flex items-center p-3 bg-gray-50 rounded-md">
            <input
              type="text"
              value={newTaskText}
              onChange={(e) => setNewTaskText(e.target.value)}
              placeholder="Nova tarefa"
              className="flex-1 bg-transparent outline-none"
              autoFocus
              onKeyDown={(e) => e.key === 'Enter' && handleCreateTask()}
            />
            <button 
              onClick={handleCreateTask}
              className="ml-2 text-green-600 hover:text-green-800"
            >
              <CheckIcon className="w-5 h-5" />
            </button>
            <button 
              onClick={() => {
                setIsAddingTask(false);
                setNewTaskText('');
              }}
              className="ml-1 text-red-600 hover:text-red-800"
            >
              <XMarkIcon className="w-5 h-5" />
            </button>
          </div>
        ) : (
          <button
            onClick={() => setIsAddingTask(true)}
            className="flex items-center w-full p-3 text-left font-medium text-blue-600 hover:bg-gray-50 rounded-md transition-colors"
          >
            <PlusIcon className="w-5 h-5 mr-2" />
            Adicionar Tarefa
          </button>
        )}
      </div>

      {loading ? (
        <div className="text-center py-4">
          <div className="animate-spin w-8 h-8 border-2 border-blue-600 border-t-transparent rounded-full mx-auto mb-2"></div>
          <p className="text-gray-500">Carregando tarefas...</p>
        </div>
      ) : tasks.length === 0 ? (
        <div className="text-center py-8 text-gray-500">
          <p>Nenhuma tarefa nesta lista.</p>
          <p className="text-sm mt-1">Adicione uma nova tarefa para começar.</p>
        </div>
      ) : (
        <ul className="space-y-2">
          {tasks.map((task) => (
            <li key={task.ID} className="group relative">
              {editingTaskId === task.ID ? (
                <div className="flex items-center p-3 bg-gray-50 rounded-md">
                  <input
                    type="text"
                    value={editingTaskText}
                    onChange={(e) => setEditingTaskText(e.target.value)}
                    className="flex-1 bg-transparent outline-none"
                    autoFocus
                    onKeyDown={(e) => e.key === 'Enter' && handleUpdateTaskText(task.ID)}
                  />
                  <button 
                    onClick={() => handleUpdateTaskText(task.ID)}
                    className="ml-2 text-green-600 hover:text-green-800"
                  >
                    <CheckIcon className="w-5 h-5" />
                  </button>
                  <button 
                    onClick={() => {
                      setEditingTaskId(null);
                      setEditingTaskText('');
                    }}
                    className="ml-1 text-red-600 hover:text-red-800"
                  >
                    <XMarkIcon className="w-5 h-5" />
                  </button>
                </div>
              ) : (
                <div 
                  className={`
                    flex items-center p-3 rounded-md hover:bg-gray-50 transition-colors
                    ${task.IsCompleted ? 'text-gray-400' : 'text-gray-800'}
                  `}
                >
                  <button
                    onClick={() => toggleTaskCompletion(task)}
                    className={`
                      w-5 h-5 rounded-full border mr-3 flex items-center justify-center
                      ${task.IsCompleted 
                        ? 'border-green-500 bg-green-500 text-white' 
                        : 'border-gray-300 hover:border-blue-500'}
                    `}
                  >
                    {task.IsCompleted && <CheckIcon className="w-3 h-3" />}
                  </button>
                  <span className={`flex-1 ${task.IsCompleted ? 'line-through' : ''}`}>
                    {task.Text}
                  </span>
                  <div className="flex opacity-0 group-hover:opacity-100 transition-opacity">
                    <button
                      onClick={() => startEditing(task)}
                      className="ml-1 p-1 text-gray-500 hover:text-gray-700"
                    >
                      <PencilIcon className="w-4 h-4" />
                    </button>
                    <button
                      onClick={() => handleDeleteTask(task.ID)}
                      className="ml-1 p-1 text-gray-500 hover:text-red-600"
                    >
                      <TrashIcon className="w-4 h-4" />
                    </button>
                  </div>
                </div>
              )}
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}