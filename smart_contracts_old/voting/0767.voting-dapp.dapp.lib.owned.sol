pragma solidity ^0.5.16;

contract owned {
    address owner;

    modifier onlyowner() {
        if (msg.sender == owner) {
            _;
        }
    }

    constructor () public {
        owner = msg.sender;
    }
}
