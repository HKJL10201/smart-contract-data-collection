// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Lottery{

    address public manager;
    address payable[] public players;
    address lastWinner;
    constructor() {
        manager = msg.sender;
    }
    function entry() public payable {
        require( msg.value > 0.001 ether);
        players.push((payable(msg.sender)));
    }

    function random() private view returns(uint){
        return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,players)));
    }
    modifier restricted(){
        require(msg.sender == manager);
        _;
    }

    function pickWinner() public restricted returns(address) {    
        uint index = random() % players.length;
        players[index].transfer(address(this).balance);
        lastWinner = players[index];
        return lastWinner;
        //emptying players array after selecting winner i-e new dynamic array
        players = new address payable[](0); 
    }

    function getPlayers() public view returns( address payable [] memory){
        return players;
    }
   
}
