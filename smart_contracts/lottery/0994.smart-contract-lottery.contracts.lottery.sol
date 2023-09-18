// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Lottery {
    address public owner;
    address public winner;
    address payable [] public players;
    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner () {
        require(msg.sender == owner);
        _;
    }

    // enter the lottery function
    function enter() public payable {
        require(msg.value == 1 ether, "Insufficient Funds");
        players.push(payable(msg.sender));
    }

    // getting a random number
    function random() public view returns (uint8) {
        return uint8(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, players)))%251);
    }

    // picking winner using random number
    function pickWinner() public onlyOwner {
        uint256 index = random() % players.length;

        // transfer reward to winner
        players[index].transfer(address(this).balance);
        winner = players[index];

        // reset the state
        players = new address payable[](0);
    }
}