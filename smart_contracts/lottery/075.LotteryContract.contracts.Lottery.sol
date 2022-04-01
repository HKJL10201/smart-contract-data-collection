// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract Lottery {
    address public manager;
    address[] public players;
    
    constructor() {
        manager = msg.sender;
    }
    function Enter() public payable{
        require(msg.value > 0.01 ether);

        players.push(msg.sender);
    }
    function getPlayers() public view returns(address[] memory){
        return  players;
    }
    function random() private view returns(uint){
        return uint(keccak256(abi.encode(block.difficulty, block.timestamp, players)));
    }
    function pickWinner() public payable {
        require(msg.sender == manager);
        uint index = random() % (players.length);
        
        payable(players[index]).transfer(address(this).balance);
        players = new address[](0);
    }
   
}