// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract Lottery {
    address public manager;
    address[] public players;

    constructor () {
        manager = msg.sender;
    }

    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

    function enterLottery() public payable {
        require(msg.value >= .01 ether);

        players.push(msg.sender);
    }

    function generateRandom() private view restricted returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
    }

    function pickWinner() public restricted {
        uint index = generateRandom() % players.length;
        payable(players[index]).transfer(address(this).balance);
        players = new address[](0);
    }

    function getPlayers() public view returns (address[] memory) {
        return players;
    }
}
