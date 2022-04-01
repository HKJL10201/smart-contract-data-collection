pragma solidity ^0.5.0;

contract TodoList {
    uint public taskCount = 0;

    struct Tasks{
        uint id;
        string _content;
        bool completed;
    }


    mapping(uint => Tasks) public tasks;
    event TaskCreated(
         uint id,
        string _content,
        bool completed
    );


    constructor() public {
        createTask("Task 1 worked");
    }

    function createTask(string memory _content) public {
        taskCount ++;
        tasks[taskCount] = Tasks(taskCount, _content, false);
        emit TaskCreated(taskCount, _content, false);

    }


}