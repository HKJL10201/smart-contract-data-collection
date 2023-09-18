// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Lottery {

    address public manager;
    address[] public players;
    
    constructor(){
        manager = msg.sender;
    }

    function Enter() public payable{
        require(msg.value > 0.1 ether);
        players.push(msg.sender);
    }

    function getRandom() private view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
    }

    function getWinner() public restricted{
        
        uint index = getRandom() % players.length;
        payable(players[index]).transfer(address(this).balance);
        players = new address[](0);
    }

    modifier restricted(){
        require(msg.sender == manager);
        _;
    }

    function getplayers() public view returns(address[] memory){
        return players;
    }
}