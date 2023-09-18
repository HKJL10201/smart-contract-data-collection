// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
 

contract Lottery {
    address payable[] public players;
    address manager;
    address payable public winner;


    constructor(){
        manager = msg.sender;
    }

    receive() external payable {
        require(msg.value==0.00000005 ether,"pay 1 ether");
        players.push(payable(msg.sender));
    }

    function getbalance() public view returns(uint){
        require(manager==msg.sender,"u r not manager");
        return address(this).balance ;
    }
    function random(uint number) internal view returns(uint){
        return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,  
        msg.sender))) % number;
    }

    function PickWinner() public {
        require(manager==msg.sender,"u r not manager");
        uint index = random(3);
        winner = players[index];
        winner.transfer(getbalance());
        players = new address payable[](0);
    }

    function allPlayers() public view returns(address payable[] memory){
        return players;
        
    }
}