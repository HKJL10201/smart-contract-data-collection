//SPDX-License-Identifier : GPL-3.0
// Khushi Agrawal 2019120001
pragma solidity ^0.8.0;
contract LotterySystem{
    address public manager;
    address payable[] public participants;

    constructor() {
        manager=msg.sender;
    }
    modifier onlyManager(){
        require(manager==msg.sender, "Only Manager can access this function");
        _;
    }
    receive() external payable{
        require(msg.value == 1 ether);
        participants.push(payable(msg.sender));
    }
    function getBalance() public onlyManager view returns(uint){
        return address(this).balance;
    }
    function random() public view returns(uint){
        return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty, participants.length)));
    }
    function selectWinner() public onlyManager returns(address){
        require(participants.length>=3);
        address payable winner;
        uint r = random();
        uint index = r%participants.length;
        winner = participants[index];
        winner.transfer(getBalance());
        participants = new address payable[](0);
        return winner;
    }
}