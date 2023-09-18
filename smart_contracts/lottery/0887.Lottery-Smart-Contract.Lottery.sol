//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract Lottery {
    address public manager;
    address payable[] public participants;

    constructor() {
        manager = msg.sender; // global variable
    }

    receive() external payable{
       require(msg.value == 1 ether); 
       participants.push(payable(msg.sender)); 
    }

    function getBalance() public view returns(uint){
        require(msg.sender ==  manager);
        return address(this).balance;
    }

    function random() private view returns(uint){
       return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, participants.length)));
    }

    function selectWinner() public{
        require(msg.sender ==  manager);
        require(participants.length >= 3);
        uint randomValue = random();
        uint index = randomValue % participants.length; // it will always return a value lower than participants length
        address payable winner;
        winner = participants[index];
        winner.transfer(getBalance());
        participants = new address payable[](0);
    }
}