// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
contract lottery{
address public manager;
constructor(){
    manager=msg.sender;
}
address[] public players;
 function getbalance() public view returns(uint){
     require(msg.sender==manager);
     return address(this).balance;
 }

receive() payable external {
    require(msg.value>=1 ether);
    players.push(msg.sender);
}

function random() public view returns(uint256){
    
return uint256(keccak256(abi.encodePacked(block.difficulty,block.timestamp,block.difficulty,players.length)));
}


function pick_Winner() public payable returns(address){
    require (msg.sender==manager);
    uint r=random();
    uint winner_index=r%players.length;
    address payable winner=payable(players  [winner_index]);
    winner.transfer(getbalance());
    return winner;
}}