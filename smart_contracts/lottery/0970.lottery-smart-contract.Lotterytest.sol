// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Lottery {
    address public manager;
    address payable[] public participants;
    uint  public randomParticipant;
    

    constructor(){
        manager = msg.sender;
    }

    receive() external payable{
        require(msg.value==2 ether);
        participants.push(payable(msg.sender));

    }

    function getBalance() public view returns(uint){
        require(msg.sender==manager);
        return address(this).balance;
    }

    function random() public returns(uint ){
        require(msg.sender==manager);
        randomParticipant = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, participants.length)));
        return randomParticipant;
    }

    function selectWinner() public{
        require (msg.sender == manager);
        require (participants.length >= 3);
        address payable winner;
        uint index = randomParticipant %  participants.length + 1; 
        winner = participants[index];
        winner.transfer(getBalance());
        participants = new address payable[](0);
        
    }
}

// For test this smart contract 
// Transfer 2-2 ether to this smart contract. (Note Transfer from min 3 different account)
