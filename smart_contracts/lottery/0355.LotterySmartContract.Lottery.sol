//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

contract Lottery {
    address public manager;
    address payable[] public participants; 

    constructor(){
        manager = msg.sender; //global variable
    }

    receive() external payable{
        require(msg.value == 1 ether);
        participants.push(payable(msg.sender));
    }

    function getBalance() public view returns(uint){
        require(msg.sender == manager);
        return address(this).balance;
    }

    //selecting participants on random basis
    function random() public view returns(uint){
        return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,participants.length)));
    }

    //Though we are generating a big random number,we don't require that big number.We need to choose particioants from that array.To fetch index here to find the participants
    function selectWinner() public {
        require(msg.sender==manager);
        require(participants.length>=3);
        uint r = random();
        uint index = r % participants.length;
        address payable winner;
        winner = participants[index];
        winner.transfer(getBalance());
        participants = new address payable[](0);//dynamic array will become empty

    }
}









