// SPDX-License-Identifier: MIT

// Pseudo random number

pragma solidity ^0.8.11;

contract Lottery {

    // owner of contract
    address public owner;

    // list of players (array)
    // payable = they can receive ether
    address payable[] public players;

    // lottery id
    uint public lotteryId;

    // winners
    mapping(uint => address payable) public lotteryHistory;


    constructor(){
        owner = msg.sender;
        lotteryId = 1;
    }

    // FUNCTIONS

    function getWinnerByLottery(uint lottery) public view returns(address payable){
        return lotteryHistory[lottery];
    }

    // get balance
    function getBalance() public view returns(uint){
        // returns how much is payed in this contract!
        return address(this).balance;
    }

    // get players
    function getPlayers() public view returns(address payable[] memory){
        return players;
    }

    // player enters lottery
    function enter() public payable {
        // player must pay to enter the lottery
        require(msg.value > .01 ether);
        // players are added to lottery
        players.push(payable(msg.sender));
    }

    // get random num
    function getRandomNumber() public view returns(uint){
        // hash a random num
        return uint(keccak256(abi.encodePacked(owner, block.timestamp)));
    }

    // just owner can call this function
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    // pic winner
    function pickWinner() public onlyOwner{
        uint index = getRandomNumber() % players.length;
        // pay to the winner
        players[index].transfer(address(this).balance);

        // add player to winners
        lotteryHistory[lotteryId] = players[index];

        // increment id of lottery
        // FIRST TRANSFER MONEY THAN CHANGE THE STATE
        // TO PREVENT REENTRY ATTACKS
        lotteryId++;



        // reset array for next round
        players = new address payable[](0);
    }


}
