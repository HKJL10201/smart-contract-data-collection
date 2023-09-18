// SPDX-License-Identifiers: GPL-3.0

pragma solidity >= 0.5.0 < 0.9.0;

// Need componnets for this project
// 1.create a manager, who access this contract
// 2.create a receive function, to receive participents amount to the contract 
//      and store the participents address into an array
// 3.create a function which randomly find the winner from the participents

contract Lottery{
    address manager;
    address payable[] public participants; //it will store the participents addresses
    address payable public winner;

    constructor(){
        manager = msg.sender;
    }

    receive() payable external{
        require(msg.value == 1 ether, "Ticket value is 1 ether only");
        participants.push(payable(msg.sender));
    }

    function getBalance() public view returns(uint){
        require(msg.sender == manager, "You are not the manager");
        return address(this).balance;
    }

    function random() internal view returns(uint){
         return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty, participants.length)));
    }

    function getWinner() public{
        require(msg.sender == manager, "Only manager can access this function");
        require(participants.length >= 3, "Minimum 3 Participents is required to process");
        uint winnerIndex = random() % participants.length;
        winner = participants[winnerIndex];
        winner.transfer(getBalance());
        participants = new address payable[](0);
    }

    function allParticipents() public view returns(address payable[] memory){
        return participants;
    }
}

// contract address: 0x484A0013BCcf079EeaBfe543089625fe309F2396 //goerli
// contract address: 0xcEF7Ec8507225294252BE96ca1174A6A49326E69 //ganache