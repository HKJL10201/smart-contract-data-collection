// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.9;//solidity version 

contract Lottery{
    address public manager;
    address[] public players;//made an array to store addresses of the players

    constructor (){
        manager=msg.sender;//makes deployer the manager of the lottery
    }
    modifier restricted(){//automatically called to check restriction before a function is executed
        require (msg.sender == manager);// error check to make sure that manager is the owner of the contract 
        _;
    } 

    function playersData() public view returns(address[]memory){
        return players;
    }
    function enter() public payable{
        require(msg.value >=0.05 ether);//checks whether the player has paid the amount for the ticket
        players.push(msg.sender);//if no error then adds theplayer to the players array
    }
    function random() private view returns(uint) {//called from pickWinner()
        return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp)));//gets a hexadecimal hash
        //ani.encode ->concatenates the bytes
    }

    function pickWinner() public restricted {
        uint id= random() % players.length;
        payable(players[id]).transfer(address(this).balance);//transfers the money collected to the winner
    }
}