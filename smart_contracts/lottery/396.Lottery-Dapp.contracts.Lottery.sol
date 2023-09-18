// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

contract Lottery{
    address public manager;
    address payable[] public participants;

    constructor(){
        manager=msg.sender;
    }

    receive() payable external{
        require(msg.value>=1 ether);
        participants.push(payable(msg.sender));
    }

    function getBalance() public view returns(uint){
        require(msg.sender==manager);
        return address(this).balance;
    }

    function random() public view returns(uint){
       return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,participants.length)));
    }

    function selectWinner() public {
        require(msg.sender==manager);
        uint num=random();
        uint index= num%participants.length;
        address payable winner=participants[index];
        winner.transfer(getBalance()); //transfering winning amount into winner account
        participants=new address payable[](0);
    }

}