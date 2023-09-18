// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Lottery {
    address public owner;
    address payable public winner;

    constructor() {
        owner = msg.sender;
    }

    address payable[] public players;

    function getLength() public view returns (uint) {
        return players.length;
    }

    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }

    function createPlayer() public payable {
        require(msg.value >= 0.1 ether);
        players.push(payable(msg.sender));
    }

    function createRandomNumber() public view returns (uint) {
        require(msg.sender == owner);
        return
            uint(
                keccak256(
                    abi.encodePacked(
                        msg.sender,
                        block.timestamp,
                        players.length
                    )
                )
            );
    }

    function selectWinner() public {
        require(msg.sender == owner);
        uint index = (createRandomNumber()) % (players.length);
        winner = players[index];
    }

    function getAddress() public view returns (address) {
        return msg.sender;
    }

    function getWinner() public view returns (address) {
        return winner;
    }

    function sendMoney() public {
        winner.transfer(address(this).balance);
    }
}
