//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

interface IMath {
    function sub() view external returns(uint256);
}

contract MathSub {
    address public par;
    constructor () {
        par = msg.sender;
    }
}
// Math contract
contract Math {
    uint public age = 200;
    address owner;
    IMath public ma;
    constructor(uint _age) {
        age = _age;
        new MathSub();
    }
    modifier onlyOwner () {
        require(msg.sender == owner);
        _;
    }
    function add (uint a, uint b) view public returns (uint) {
        return uint(a + b + age);
    }
}

