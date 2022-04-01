// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.2;

contract Lottery {
    address payable[] public players;
    address public lastWinner;
    address public manager;

    constructor() {
        manager = msg.sender;
    }

    function enter() public payable {
        require(msg.value == 0.1 ether);
        players.push(payable(msg.sender));
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }

    function random() public view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }

    function pickWinner() public {
        require(msg.sender == manager);

        uint r = random();
        address payable winner;
        uint index = r % players.length;
        winner = players[index];

        lastWinner = winner;
        winner.transfer(getBalance());
        players = new address payable[](0);
    }
}