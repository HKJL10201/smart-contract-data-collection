//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19; 

contract Wallet {

    address payable Owner;
    mapping(address => uint) allowance;
    mapping (address => bool) isAllowedToSend;
    mapping (address => bool) isGuardian;
    address payable nextOnwer;
    uint guardainResetCount;
    uint public constant confirmationFromGurdianReset = 3;
    mapping (address => mapping (address => bool)) nextOwnerGuardianVoted; 
    constructor () {
        Owner = payable (msg.sender);
    }
    receive() external payable {

    }
    function allowed(address _for, uint _amount) public {
    require (msg.sender == Owner, "You are not the owner");
    allowance[_for] = _amount;

    if (allowance[_for] <= 0) {
       isAllowedToSend[_for]  = false;
    }

    else {
        isAllowedToSend[_for]  = true;

    }

    }

    function setGuardian (address _to,  bool value) public {
        require (msg.sender == Owner, " You are not the owner");
        isGuardian[_to] = value;
    }

    function sendAmount(address payable _to,uint _amount, bytes memory _payload) public  returns (bytes memory){
    if (msg.sender != Owner) {
        require(allowance[msg.sender] >= _amount, "You are trying to send more than you are allowed");
        require(isAllowedToSend[msg.sender], "You are not allowed to send");
        allowance[msg.sender] -= _amount;
     }  
          (bool success, bytes memory data)   = _to.call{value:_amount , gas: 1500} (_payload);
            require (success, "Aborting");
            return  data;
    }

    function setNewOwner (address payable newOwner)  public { 
    require (isGuardian[msg.sender], " You are not the guardian");
    require ( nextOwnerGuardianVoted[msg.sender] [newOwner] == false, "You have already voted");
    if (newOwner != nextOnwer && guardainResetCount >= confirmationFromGurdianReset ) {
        nextOnwer = newOwner;
        guardainResetCount++;
    }
    else {
        Owner = nextOnwer;
    }
    
    }

}