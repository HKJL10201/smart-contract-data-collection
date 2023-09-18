// SPDX-License-Identifier: GPL-3.0
 pragma solidity >= 0.5.0 < 0.9.0;

 contract Lottery
 {
     address payable[] public participants;
     address manager;
     address payable public winner;

     constructor()
     {
         manager = msg.sender; // indicate the person who has created the contract
     }

     receive() external payable // taking the participantys
     {
         require(msg.value==0.0001 ether, "Please pay 0.0001 ether only");
         participants.push(payable(msg.sender));

     }

     function getBalance() public view returns(uint) // cheking the balance
     {
         require(manager==msg.sender,"You are not the manager");
         return address(this).balance;
     }

     function random() private view returns(uint) // give random number
     {
        return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,participants.length)));
     }

     function pickWinner() public 
     {
         require(manager==msg.sender,"You are not the manager");
         require(participants.length>=3, "Participants less than 3");
         uint r = random();
         uint index = r%participants.length;
         winner = participants[index];
         winner.transfer(getBalance());
         participants = new address payable[](0);


     }

     function ListofParticipants() public view returns(address payable[] memory)
     {
         return participants;
     }

 }
 //contract add-> 0x174442EB62cd833e42384DDa99Cc087996809c46