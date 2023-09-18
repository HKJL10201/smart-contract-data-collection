pragma solidity ^0.8.0;

contract DecentralBank {
    string public name = "Decentral Bank";
    address public owner;


    constructor() {
        owner = msg.sender;
    }

    
}
