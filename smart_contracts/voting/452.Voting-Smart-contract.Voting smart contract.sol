// SPDX-License-Identifier: MIT

pragma solidity >= 0.7.0 < 0.9.0;

contract Counter{
    
    address public owner;
    uint public count;

    constructor(){
        owner = msg.sender;
    }

    function setCount(uint _count) public {
        require(owner == msg.sender, "Only owner can modify this function");
        count += _count;
    }
}