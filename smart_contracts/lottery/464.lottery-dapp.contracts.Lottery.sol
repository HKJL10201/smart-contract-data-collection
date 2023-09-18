// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.19;

contract Lottery {
    address public manager;
    address[] public players;

    constructor() {
        manager = msg.sender;
    }

    function enter() public payable {
        require(msg.value > 0.01 ether, "Pay a minimum of 0.01 ETH.");

        players.push(msg.sender);
    }

    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, players)));
    }

    modifier onlyManager() {
        require(msg.sender == manager, "Only the manager can perform this action.");
        _;
    }

    function pickWinner() public payable onlyManager {
        // Send a random player the contract balance
        payable(players[random() % players.length]).transfer(address(this).balance);

        players = new address[](0);
    }

    function getPlayers() public view returns (address[] memory) {
        return players;
    }
}
