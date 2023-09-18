// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Lottery {
    address payable public owner;
    address[] public players;
    address payable public winner;
    uint256 public jackpot;
    uint256 public ticketPrice;
    uint256 public maxPlayers;

    constructor(uint256 _ticketPrice, uint256 _maxPlayers) {
        owner = payable(msg.sender);
        ticketPrice = _ticketPrice;
        maxPlayers = _maxPlayers;
    }

    function getBalance() public view returns(uint){
        return address(this).balance;
    }

    function enter() public payable {
        require(msg.value == ticketPrice, "The ticket price is not correct.");
        require(players.length < maxPlayers, "The lottery has reached its maximum number of players.");
        players.push(msg.sender);
        jackpot += msg.value;
    }

    function random() public view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)));
    }

    function pickWinner() public {
        require(msg.sender == owner, "Only the owner can pick a winner.");
        require(players.length > 0, "There must be at least one player to pick a winner.");
        uint256 winnerIndex = random() % players.length;
        winner = payable(players[winnerIndex]);
        winner.transfer(jackpot);
        delete players;
        jackpot = 0;
    }

    function getPlayers() public view returns (address[] memory) {
        return players;
        }
}