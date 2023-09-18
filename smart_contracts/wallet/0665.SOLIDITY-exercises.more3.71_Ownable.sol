// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract Ownable { 
    //Ownable contract exists in almost all projects. You need understand
    // and memorize this syntax. First create an address and with constructor set
    // this address to msg.sender. This means, whoever deploys contract firsttime 
    // will have owner account privileges. Then with the help of modifier, make
    // sure only owner can call some functions. You can also change owner of the account,
    // but this has to done by the owner itself.
    address public owner;

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "You are not the owner of contract");
        _;
    }

    function setNewOwner(address _newAddress) external onlyOwner{
        require(_newAddress != address(0), "invalid address");
        owner = _newAddress;
    }

    function onlyOwnerCanCall(string memory _word) external view onlyOwner returns(string memory) {
        return _word;
    }

    function anybodyCanCall(string memory _word2) external pure returns(string memory) {
        return _word2;
    }
}