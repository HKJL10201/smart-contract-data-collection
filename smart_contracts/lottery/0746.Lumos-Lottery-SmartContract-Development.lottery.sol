// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Lottery {
    address public manager;
    address payable[] public players;

    constructor() {
        manager = msg.sender;
    }

    function buyTicket() public payable {
        require(msg.value == 1 ether, "Please send exactly 0.1 ether to buy a ticket.");
        players.push(payable(msg.sender));
    }

    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }

    function pickWinner() public restricted {
        require(players.length > 0, "There are no players in the lottery.");
        uint index = random() % players.length;
        players[index].transfer(address(this).balance);
        players = new address payable[](0);
    }

    modifier restricted() {
        require(msg.sender == manager, "Only the manager can pick a winner.");
        _;
    }

    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }
}
