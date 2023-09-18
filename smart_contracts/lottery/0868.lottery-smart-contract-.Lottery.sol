// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Lottery {
    address public manager;
    address payable[] public players;

    constructor() {
        manager = msg.sender;
    }

    function enter() public payable {
        require(msg.value > 0.01 ether, "Insufficient entry fee");

        players.push(payable(msg.sender));
    }

    function random() private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }

    function pickWinner() public restricted {
        require(players.length > 0, "No players in the lottery");

        uint256 index = random() % players.length;
        players[index].transfer(address(this).balance);

        // Reset the lottery for the next round
        players = new address payable[](0);
    }

    modifier restricted() {
        require(msg.sender == manager, "Only the manager can call this function");
        _;
    }

    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }
}
