//SPDX-License-Identifier: UNLICENSED

pragma solidity >0.5.0 <0.9.0;

contract Lottery{
    address public manager;
    address payable[] public participants;
    uint public fees = 2 ether;

    constructor(){
        manager = msg.sender;
    }

    function enterLotteryByPayingFees() external payable{
        require(msg.value==fees);
        participants.push(payable(msg.sender));
    }

    function getBalance() public view returns(uint){
        require(msg.sender == manager);
        return address(this).balance;
    }

    function findRandomNumber() private view returns(uint){
        return uint(keccak256(abi.encode(block.timestamp,block.difficulty,participants.length)))%participants.length;
    }

    function findWinner() public returns(address){
        require(msg.sender == manager);
        uint rand = findRandomNumber();
        participants[rand].transfer(getBalance());
        participants = new address payable[](0);
        return address(participants[rand]);
    }

}