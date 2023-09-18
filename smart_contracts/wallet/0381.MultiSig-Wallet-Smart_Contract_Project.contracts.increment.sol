// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Increment {
    uint public number = 0;

    event IncreaseDone();

    function increase() public {
        number += 10;
        emit IncreaseDone();
    }
}
