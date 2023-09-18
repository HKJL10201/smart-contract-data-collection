// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

contract HelloWorld {
    string public greeting = "Greeting";

    function setGreeting(string memory __greeting) public{
        greeting = __greeting;
    }

}
