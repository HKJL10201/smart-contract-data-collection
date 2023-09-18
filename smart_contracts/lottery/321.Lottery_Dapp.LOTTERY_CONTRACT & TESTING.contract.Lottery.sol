// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Lottery{
    address public manager;
    address payable[] public player;
    
    constructor(){
        manager = msg.sender;
        //msg is a global variable provided in every contract
        //it has information about the data,sender,gas and value(ether)
    }
    
    function enter() public payable{
        require(msg.value > 0.01 ether);
        player.push(payable(msg.sender));//according to changes in v0.5.0
    }
    
    function random() private view returns(uint){
        return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,player.length)));
    }
    
    function pickWinner() public payable{
        uint index = random()%player.length;
        player[index].transfer(address(this).balance);//according to changes in v0.5.0
        player = new address payable[](0);
    }
    
    modifier restricted(){
        require(msg.sender == manager);
        _;
    }
    
    function getPlayers() public view returns(address payable[] memory){
        return player;
    }
    
    
}