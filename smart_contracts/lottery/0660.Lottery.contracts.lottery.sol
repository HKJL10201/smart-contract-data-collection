// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Lottery{
    address public manager;
    address payable[] public participants;
    constructor(){
        manager=msg.sender;     // as constructor is executed once to jo deploy krega wo uss time msg.sender hoga aur whi manager bn jyega
                                // msg.sender means which address is executing the contract at that time

    }
    
    receive() external payable{
        require(msg.value==1 ether);   // agr yeh true hoga tbhi next statement execute hoga  but agr false hua to revert back kr jyega
        participants.push(payable(msg.sender));   // adding members to participants after receiving payemnt
    }
    function getBalance() public view returns(uint){
        require(msg.sender==manager); // work as if statement but also have some more functionality 
        return address(this).balance;           // returns balance of this contract
    }
    function randomselect() public view returns(uint){
        return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,participants.length)));  // no need to learn this function and do not use this in real world contracts
    }
    function selectwinner() public returns(address){
        require(msg.sender==manager);
        require(participants.length>=3);
        uint r=randomselect();
        uint index = r % participants.length;
        sendprizemoney(participants[index]);
        return participants[index];
    }
    function sendprizemoney(address payable winner) public {
        winner.transfer(getBalance());
    }
}
