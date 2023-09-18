// SPDX-License-Identifier:MIT
pragma solidity ^0.8.15;

contract Lottery {
    //State / Storage Variables

    address public owner;
    address payable[] public players;
    address[] public winner;
    uint256 public lotteryId;

    //Constructor
    constructor() {
        owner = msg.sender;
        lotteryId = 0;
    }

    function enter() public payable {
        require(msg.value >= 0.1 ether);
        players.push(payable(msg.sender));
    }

    //get player
    function getplayer() public view returns (address payable[] memory) {
        return players;
    }

    //get balance
    function getbalance() public view returns (uint256) {
        return address(this).balance;
    }

    //get lotteryId
    function getLootteryId() public view returns (uint256) {
        return lotteryId;
    }

    //Random number (helper function to get the winner)
    function randomNumber() public view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(owner, block.timestamp)));
    }

    //pick winner
    function pickWinner() public {
        require(msg.sender == owner);
        uint256 randomIndex = randomNumber() % players.length;
        players[randomIndex].transfer(address(this).balance);
        winner.push(players[randomIndex]);
        lotteryId++;

        //clear the array
        players = new address payable[](0);
    }

    //get winner
    function getWinner() public view returns (address[] memory) {
        return winner;
    }
}
