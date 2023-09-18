//SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Lottery {
    address public manager;
    address payable[] public players;
    mapping(address => uint256) public uniquePlayers;
    uint256 public noOfPlayers;
    address public lastWinner;

    constructor() {
        manager = msg.sender;
    }

    modifier restricted() {
        require(msg.sender == manager, "You are not the manager.");
        _;
    }

    function enter() public payable {
        require(msg.value > 0.01 ether, "Must send more than 0.01 Ether.");
        if (uniquePlayers[msg.sender] == 0) {
            noOfPlayers++;
        }
        uniquePlayers[msg.sender] += msg.value;
        players.push(payable(msg.sender));
    }

    function random() internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(block.difficulty, players, block.timestamp)
                )
            );
    }

    function pickWinner() public restricted {
        require(players.length >= 3, "Minimum number of players is 3.");
        uint256 index = random() % players.length;
        lastWinner = players[index];
        players[index].transfer(address(this).balance);
        noOfPlayers = 0;
        for (uint256 i = 0; i < players.length; i++) {
            address funder = players[i];
            uniquePlayers[funder] = 0;
        }
        players = new address payable[](0);
    }

    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
