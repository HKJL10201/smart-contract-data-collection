// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Lottery {
    address public manager; // The manager who initiates the lottery
    address[] public players; // Addresses of participants in the lottery

    constructor() {
        manager = msg.sender; // The contract creator becomes the manager
    }

    function enter() public payable {
        require(msg.value > .01 ether, "Minimum contribution is 0.01 ether");
        players.push(msg.sender);
    }

    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
    }

    function pickWinner() public restricted {
        uint index = random() % players.length;
        address winner = players[index];
        address payable winnerPayable = payable(winner);
        winnerPayable.transfer(address(this).balance);

        // Reset the players array for the next lottery
        players = new address[](0);
    }

    modifier restricted() {
        require(msg.sender == manager, "Only the manager can call this function");
        _;
    }

    function getPlayers() public view returns (address[] memory) {
        return players;
    }
}
