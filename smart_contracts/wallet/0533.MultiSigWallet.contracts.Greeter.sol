// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

contract Greeter {
    string public greetings;

    constructor(string memory greeting) {
        greetings = greeting;
    }

    function greet() external view returns (string memory) {
        return greetings;
    }

    function setGreeting(string memory greeting) external {
        greetings = greeting;
    }
}
