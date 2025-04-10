// src/__tests__/api.test.ts

import MockAdapter from 'axios-mock-adapter';
import axios from 'axios';
import * as apiModule from '../lib/api';
import api from '../lib/api'; 

// Criando o mock adapter diretamente para o axios
const mock = new MockAdapter(api);


describe('API Service', () => {
  afterEach(() => {
    mock.reset();
  });

  describe('Listas', () => {
    it('deve buscar listas de tarefas', async () => {
      const mockLists: apiModule.TaskList[] = [
        {
          ID: 1,
          Name: 'Lista 1',
          Tasks: []
        }
      ];

      mock.onGet('/lists').reply(200, mockLists);

      const result = await apiModule.fetchLists();
      expect(result).toEqual(mockLists);
    });

    it('deve criar uma nova lista', async () => {
      const mockList: apiModule.TaskList = { 
        ID: 2, 
        Name: 'Nova Lista', 
        Tasks: [] 
      };

      mock.onPost('/lists', { name: 'Nova Lista' }).reply(201, mockList);

      const result = await apiModule.createList('Nova Lista');
      expect(result).toEqual(mockList);
    });

    it('deve atualizar uma lista', async () => {
      const updatedList: apiModule.TaskList = { 
        ID: 1, 
        Name: 'Lista Atualizada', 
        Tasks: [] 
      };

      mock.onPut('/lists/1', { name: 'Lista Atualizada' }).reply(200, updatedList);

      const result = await apiModule.updateList(1, 'Lista Atualizada');
      expect(result).toEqual(updatedList);
    });

    it('deve deletar uma lista', async () => {
      mock.onDelete('/lists/1').reply(204);
      await expect(apiModule.deleteList(1)).resolves.not.toThrow();
    });

    it('deve lidar com erros ao buscar listas', async () => {
      mock.onGet('/lists').reply(500);
      await expect(apiModule.fetchLists()).rejects.toThrow();
    });
  });

  describe('Tarefas', () => {
    it('deve buscar tarefas de uma lista', async () => {
      const mockTasks: apiModule.Task[] = [
        { 
          ID: 1, 
          Text: 'Tarefa 1', 
          IsCompleted: false, 
          ListID: 1 
        }
      ];

      mock.onGet('/lists/1/tasks').reply(200, mockTasks);

      const result = await apiModule.fetchTasksByList(1);
      expect(result).toEqual(mockTasks);
    });

    it('deve criar uma nova tarefa', async () => {
      const mockTask: apiModule.Task = { 
        ID: 1, 
        Text: 'Nova Tarefa', 
        IsCompleted: false, 
        ListID: 1 
      };

      mock.onPost('/lists/1/tasks', { text: 'Nova Tarefa' }).reply(201, mockTask);

      const result = await apiModule.createTask(1, 'Nova Tarefa');
      expect(result).toEqual(mockTask);
    });

    it('deve atualizar uma tarefa', async () => {
      const updatedTask: apiModule.Task = { 
        ID: 1, 
        Text: 'Tarefa Atualizada', 
        IsCompleted: true, 
        ListID: 1 
      };

      mock.onPut('/tasks/1', { 
        Text: 'Tarefa Atualizada', 
        IsCompleted: true 
      }).reply(200, updatedTask);

      const result = await apiModule.updateTask(1, { 
        Text: 'Tarefa Atualizada', 
        IsCompleted: true 
      });
      
      expect(result).toEqual(updatedTask);
    });

    it('deve marcar uma tarefa como concluída', async () => {
      const updatedTask: apiModule.Task = { 
        ID: 1, 
        Text: 'Tarefa 1', 
        IsCompleted: true, 
        ListID: 1 
      };

      mock.onPut('/tasks/1', { IsCompleted: true }).reply(200, updatedTask);

      const result = await apiModule.updateTask(1, { IsCompleted: true });
      expect(result).toEqual(updatedTask);
      expect(result.IsCompleted).toBe(true);
    });

    it('deve deletar uma tarefa', async () => {
      mock.onDelete('/tasks/1').reply(204);
      await expect(apiModule.deleteTask(1)).resolves.not.toThrow();
    });

    it('deve lidar com erros ao buscar tarefas', async () => {
      mock.onGet('/lists/1/tasks').reply(500);
      await expect(apiModule.fetchTasksByList(1)).rejects.toThrow();
    });
  });
});
