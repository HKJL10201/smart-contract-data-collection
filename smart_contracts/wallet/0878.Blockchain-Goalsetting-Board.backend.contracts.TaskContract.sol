// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract TaskContract {
  event AddTask(address recipient, uint taskId);
  event DeleteTask(uint taskId, bool isDeleted);

  // Task : { id: 0, taskText: 'clean', isDeleted: false }
  struct Task {
    uint id;
    string taskText;
    bool isDeleted;
  }

  Task[] private tasks;
  mapping(uint256 => address) taskToOwner;

  function addTask(string memory taskText,bool isDeleted)
  external {
    // When you get tasks.length you get the the taskId
    //{ id: 0, taskText: 'example', isDeleted: false },
    //{ id: 0, taskText: 'example', isDeleted: false },
    //{ id: 0, taskText: 'example', isDeleted: false }
    uint taskId = tasks.length;
    // This will create one object like the ones above
    tasks.push(Task(taskId, taskText, isDeleted));
    taskToOwner[taskId] = msg.sender;
    emit AddTask(msg.sender, taskId);
  }

  // Get tasks that are mine and not yet deleted
  function getMyTasks() external view returns (Task[] memory) {
    Task[] memory temporary = new Task[](tasks.length);
    uint counter = 0;

    for (uint i = 0; i < tasks.length; i++) {
        // Make sure it's not deleted
      if(taskToOwner[i] == msg.sender && tasks[i].isDeleted == false) {
        temporary[counter] = tasks[i];
        counter++;    
      } 
    }
    Task[] memory result = new Task[](counter);
    for (uint i = 0; i < counter; i++) {
      result[i] = temporary[i]; 
    }
    return result;
  }

  // We're not really deleting the task but filtering it so it doesnt sho up on tasks board, on Blockchain you can't really delete anything
  function deleteTask(uint taskId, bool isDeleted) external {
    if(taskToOwner[taskId] == msg.sender) {
      tasks[taskId].isDeleted = isDeleted;
      emit DeleteTask(taskId, isDeleted); 
    }
  }
  
  
}
