// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Lottery {

    // state variables
    address public manager;
    address[] public players;

    constructor () {
        manager = msg.sender;
    }

    modifier restricted() {
        require(
            msg.sender == manager,
            "need to be the creator of the contract to execute this function"
        );
        _;
    }

    function enter() public payable {
        require(
            msg.value > .01 ether,
            "min 0.01 ether required"
        );
        players.push(msg.sender);
    }

    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
    }

    function pickWinner() public restricted payable {
        uint index = random() % players.length;
        payable(players[index]).transfer(address(this).balance);
        players = new address[](0);
    }

    function getPlayers() public view returns (address[] memory) {
        return players;
    }
}