//SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

contract Lottery{
    address public owner;
    address payable[] public players;
    uint public lotteryId;
    mapping (uint => address payable) public lotteryHistory;

    constructor() {
        owner = msg.sender;
        lotteryId = 1;
    }

    function GenerateRandomNumber(uint number) public view returns(uint){
        return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,  
        msg.sender))) % number;
    }

    function getWinnerByLottery(uint id) public view returns (address payable){
        return lotteryHistory[id];
    }

    function getSender() public view returns (address) {
        return address(msg.sender);
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getPlayers() public view returns (address payable[] memory){
        return players;
    }

    function enter() public payable {
        require(msg.value > .01 ether, "Transaction failed. Not enough gas.");

        //address of player entering lottery
        players.push(payable(msg.sender));  
    }

    function pickWinner() public onlyOwner {
        uint index = GenerateRandomNumber(players.length);
        players[index].transfer(address(this).balance);

        lotteryHistory[lotteryId] = players[index];
        lotteryId++;

        //reset the state of the contract
        players = new address payable[](0);
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "Transaction failed. Operation available only for owner.");
        _;
    }
}