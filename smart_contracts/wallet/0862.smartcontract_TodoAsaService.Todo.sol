//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;


contract Todo{

  //address owner;

    struct TodoStruct{
        uint id;
        string task;
        bool completed;
        }

       mapping(address =>mapping (uint => TodoStruct)) todos;
        

        function addTask(address _address, uint _id, string memory _task, bool _completed) public {
        
         TodoStruct storage t = todos[_address][_id];

         t.id = _id;
         t.task = _task;
         t.completed = _completed;

        }

         function getUserTasks(address _address, uint _id) public view returns (TodoStruct memory){
            return todos[_address][_id];
        }

        function updateTask(address _address, uint _id, bool _completed) public {
            TodoStruct storage t = todos[_address][_id];
               
                t.completed = _completed;
        }

        function deleteTask(address _address, uint _id) public{
            delete todos[_address][_id];
        }

        



     
}