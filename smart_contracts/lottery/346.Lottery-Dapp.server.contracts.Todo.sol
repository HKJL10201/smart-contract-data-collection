// SPDX-License-Identifier: SEE LICENSE IN LICENSE

pragma solidity ^0.8.0;

contract Todo {
    constructor() {}

    // add to the array of todo
    // get one today
    // delete todo

    struct todo {
        string descriptipn;
        string title;
        uint256 _index;
    }

    todo[] public todos;

    function addTodo(
        string memory descriptipn,
        string memory title,
        uint256 _index
    ) public {
        todos.push(todo(descriptipn, title, _index));
    }

    function getTodo(uint256 _index)
        public
        view
        returns (string memory description, string memory title)
    {
        todo storage todoOne = todos[_index];
        return (todoOne.descriptipn, todoOne.title);
    }
}
