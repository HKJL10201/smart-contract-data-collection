//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

// Here even you dont tag it as abstract, it will be treated as abstract as there is 
// a function without implemenration. 
abstract contract AB {
    string public myWord = "schkria";
    uint myNumber = 5;

    function changeWord() external virtual;
    //function without implementation must be marked as virtual.
}

contract E is AB{

    function changeWord() external override {
        myWord = "kathmandu";
    }
}

/* The difference between of contract F and D is:
F can limit what we want to see from Contract A
D cannot limit. It will show us everything from Contract A

Contracts are identified as abstract contracts when at least one of their functions 
lacks an implementation. As a result, they cannot be compiled. They can however be 
used as base contracts from which other contracts can inherit from. They act like pattern setters.
They are not for compiling/deploying. They cant be compiled and deployed.

1) Inside the abstract you can modify functions, 
2) Abstract contracts can have variables
3) Abstract contracts can have one constructor

4) Interfaces cannot have any functions implemented
5) Interfaces cannot inherit other contracts or interfaces 
(contracts can however inherit interfaces just as they would inherit other contracts)
6) Interfaces cannot define a constructor
7) Interfaces cannot define variables
8) Interfaces cannot define structs
9) Interfaces cannot define enums
*/