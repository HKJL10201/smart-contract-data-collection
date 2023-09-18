// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract simpleStorage {
    uint storedData;

    function set(uint a) public {
        storedData = a;
    }

    function get() view public returns (uint) {
        return storedData;
    }

    function increment (uint n) public {
        storedData = storedData + n;
        return;
    }

    function decrement (uint n) public {
        storedData = storedData - n;
        return;
    }
}