// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract myGreeter {
    string public yourName;

    /* on execution of smart contract */
    function greeter() public {
        yourName = "Hey!"; /* default value */
    }

    function set(string memory name) public {
        yourName = name;
    }

    function hello() view public returns (string memory) {
        return yourName;
    }
}