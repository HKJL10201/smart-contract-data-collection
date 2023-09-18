// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Lottery {
    address public manager;
    address payable[] players;
    uint public maxPlayers;
    uint constant joinPrice = 0.1 ether;

    event PlayerJoined(address player);
    event PlayerWon(address player, uint prize);

    constructor(uint initMaxPlayers) {
        maxPlayers = initMaxPlayers;
        manager = msg.sender;
    }

    modifier onlyManager {
        require(msg.sender == manager);
        _;
    }

    function join() payable public {
        require(msg.value >= joinPrice);
        players.push(payable(msg.sender));
        emit PlayerJoined(address(msg.sender));

        if (players.length >= maxPlayers) {
            drawWinner();
        }
    }

    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }

    function getPlayersCount() public view returns (uint) {
        return players.length;
    }

    function forceDrawWinner() public onlyManager {
        drawWinner();
    }

    function drawWinner() private {
        uint winnerIndex = random() % players.length;
        uint winningPrize = address(this).balance;

        address payable winner = players[winnerIndex];

        winner.transfer(winningPrize);
        emit PlayerWon(winner, winningPrize);

        restartGame();
    }

    function random() private view returns (uint) {
        return uint(
            keccak256(
                abi.encodePacked(block.difficulty, block.timestamp, players)
            )
        );
    }

    function restartGame() private {
        players = new address payable[](0);
    }
}