pragma solidity ^0.5.1;

contract Lottery {
    address public owner;
    address payable [] public players;
    address public result;

    constructor() public{
        owner = msg.sender;
    }

    modifier ownerOnly (){
        if(owner == msg.sender)
        _;
    }

    function enter() public payable{
        require(msg.value == 1 ether, "This lottery is only require 1 ether");
        players.push(msg.sender);
    }

    function generateRandomNumber() private view returns(uint){
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }

    function selectWinner() public ownerOnly returns(address) {
        require(owner == msg.sender);
        uint randomNumber = generateRandomNumber();
        uint index = randomNumber % players.length;
        address payable winner = players[index];

        winner.transfer(address(this).balance);
        result = winner;
        players = new address payable [](0);
        return result;
    }

    function getPlayers() public view returns (uint) {
        return players.length;
    }



}

// Entery in lottery
// Save invested amouunt in mapping array
// Get the total nuumber of players
// Get the total prize value
// Set random number for chosing winner
// Declear the winner
// Reset the contract for new entries
//
