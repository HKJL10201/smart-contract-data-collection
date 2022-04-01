// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Lottery{

    address public manager;

    address payable[] public players;
    uint public playersCounter;
    
    uint public maxPlayersCounter;

    event PlayerJoined(address player);
    event PlayerWon(address player, uint amount);

    constructor(uint playersNumber) {
        maxPlayersCounter = playersNumber;
        manager = msg.sender;
    }
    function join() payable public{
        require(msg.value >= .1 ether);

        players.push(payable(msg.sender));
        playersCounter++;

        emit PlayerJoined(msg.sender);

        if (playersCounter >= maxPlayersCounter){

        }
    }

    function getPlayers() public view returns(address payable[] memory){
        return players;
    }

    function forceDrawing() public onlyManager {
        require(msg.sender == manager);

        drawWinner();
    }

    modifier onlyManager{ 
        require(msg.sender == manager);
        _;
        
    }

    function drawWinner() private {
        uint index = random() % players.length;
        uint amount = address(this).balance;

        address payable winner = players[index];
        winner.transfer(amount); 

        players = new address payable[](0);
        playersCounter = 0;

        emit PlayerWon(winner, amount);
    }

    function random() private view returns(uint){
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
    }
}