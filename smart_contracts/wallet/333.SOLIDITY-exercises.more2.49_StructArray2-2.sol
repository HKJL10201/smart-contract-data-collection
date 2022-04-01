//SPDX-Licence-Identifier: MIT
pragma solidity >=0.8.7;

import "./48_StructArray2-1.sol";

contract TodosList {
    //Todos struct is imported from other document
    Todos[] public todosArray;

    function addTasks(string memory task, bool completion) external {
        todosArray.push(Todos(task, completion));
    }

    //Here we cannot return all record, I mean only task info is returned.
    // But when I search the same thing on array, I can return both task and completed info
    function getValues(uint indexNumber) external view returns(string memory) {
        return todosArray[indexNumber].task;
    }
}
