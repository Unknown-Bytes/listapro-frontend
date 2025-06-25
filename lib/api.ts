import axios from 'axios';

// Configuração da URL da API baseada na variável de ambiente
const API_URL = process.env.NEXT_PUBLIC_API_URL || process.env.BACKEND_URL || '/api'; 

export interface Task {
  ID: number;
  Text: string;
  IsCompleted: boolean;
  ListID: number;
}

export interface TaskList {
  ID: number;
  Name: string;
  Tasks: Task[];
}

const api = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Exportando o api para poder ser mockado nos testes
export default api;

// Funções para listas
export const fetchLists = async (): Promise<TaskList[]> => {
  const response = await api.get('/lists');
  return response.data;
};

export const createList = async (name: string): Promise<TaskList> => {
  const response = await api.post('/lists', { name });
  return response.data;
};

export const updateList = async (id: number, name: string): Promise<TaskList> => {
  const response = await api.put(`/lists/${id}`, { name });
  return response.data;
};

export const deleteList = async (id: number): Promise<void> => {
  await api.delete(`/lists/${id}`);
};

// Funções para tarefas
export const fetchTasksByList = async (listId: number): Promise<Task[]> => {
  const response = await api.get(`/lists/${listId}/tasks`);
  return response.data;
};

export const createTask = async (listId: number, text: string): Promise<Task> => {
  const response = await api.post(`/lists/${listId}/tasks`, { text });
  return response.data;
};

export const updateTask = async (id: number, task: Partial<Task>): Promise<Task> => {
  const response = await api.put(`/tasks/${id}`, task);
  return response.data;
};

export const deleteTask = async (id: number): Promise<void> => {
  await api.delete(`/tasks/${id}`);
};
