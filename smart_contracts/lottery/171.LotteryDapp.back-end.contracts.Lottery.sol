// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Lottery {
    address public manager;
    address[] players;
    uint256 public escrow;
    address public winner;

    modifier _onlyManager() {
        require(msg.sender == manager, "Restricted Access");
        _;
    }

    constructor() {
        manager = msg.sender;
    }

    function enterLottery() public payable {
        require(
            msg.value > 0.0001 ether,
            "value should be greater than 0.0001 ether"
        );
        escrow = escrow + msg.value;
        players.push(msg.sender);
    }

    function random() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encode(block.difficulty, block.timestamp, players)
                )
            );
    }

    function pickWinner() public _onlyManager {
        require(players.length > 0, "No player participate yet");
        uint256 index = random() % players.length;
        payable(players[index]).transfer(escrow);
        winner = players[index];
        players = new address[](0);
        escrow = 0;
    }

    function getPlayers() public view returns (address[] memory) {
        return players;
    }
}
