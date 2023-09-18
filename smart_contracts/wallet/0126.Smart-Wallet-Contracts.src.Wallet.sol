// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity ^0.8.4;

contract Wallet is Ownable{

address[] private owners;
//uint256 private threshold;

mapping(address=>uint256) public balances;

event Deposit(address indexed despositor, uint256 amount);
event Withdrawal(address indexed to, uint256 amount);
event Transfer(address indexed sender,address indexed recepient,uint256 amount);


constructor( address[] memory _owners) {
    owners = _owners;
    require(_owners.length > 0, "Owners required");
}


function deposit()public payable onlyOwner{
balances[msg.sender] += msg.value;
uint256 amount = msg.value;
emit Deposit(msg.sender,amount);
}


function withdraw(uint256 amount)public payable onlyOwner{
require(balances[msg.sender]>= amount,"Not enough funds");
require(amount > 0,"invalid amount");
 (bool sent, ) = msg.sender.call{value: amount}("");
require(sent, "Failed to send Ether");
emit Withdrawal(msg.sender,amount);
}

receive() external payable{
require(msg.value>0,"invalid amount");
balances[msg.sender] += msg.value;
uint256 amount = msg.value;
emit Deposit(msg.sender,amount);

}


}
/*

*/