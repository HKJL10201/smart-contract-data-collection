//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract Todo {
    struct Todos{
        string task;
        bool completed;
    }

    Todos[] myTasks;

    // add tasks: here when I use calldata instead of memory, it still works.
    function addTask(string calldata _task) external {
        Todos memory newTask = Todos(_task, false); // Here it has to be memory and I dont know why
        myTasks.push(newTask);
    }

    // update tasks: here when I say calldata instead of memory it still works.
    function updateTask(uint index, string calldata _task) external {
        //WAY-1: this was is cheaper if we update a few fields
        myTasks[index].task = _task;

        //WAY-2: this way will be cheaper if we update many multiple fields.
        // Todos storage freshTask = myTasks[index];
        // freshTask.task = _task;

    }

    // tag tasks as completed
    function tagCompleted(uint index) external {
        myTasks[index].completed = true;
    }

    // change completed status of tasks
    function toggleCompleted(uint index) external {
        myTasks[index].completed = !myTasks[index].completed;
    }

    // view tasks
    function getTasks(uint index) external view returns(Todos memory) {
        return myTasks[index];
    }
}