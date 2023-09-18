// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Message {
    mapping(address => string) public myMessage;

    function setMessage(string memory _message) public {
        myMessage[msg.sender] = _message;
    }

    function getMessage(address _address) public view returns (string memory) {
        return myMessage[_address];
    }
}