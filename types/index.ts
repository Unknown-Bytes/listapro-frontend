interface Task {
    ID: number;
    Text: string;
    IsCompleted: boolean;
    ListID: number;
  }
  
  interface TaskList {
    ID: number;
    Name: string;
    Tasks: Task[];
  }