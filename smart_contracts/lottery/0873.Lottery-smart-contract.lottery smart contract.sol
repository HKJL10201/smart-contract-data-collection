
// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0< 0.9.0;

contract map
{
    
    address public manager;
    address payable[] public  members;
    constructor()
{
    manager=msg.sender;
}

receive() external payable
{
    require(msg.value==4 ether);
members.push(payable(msg.sender));
}

function checkbalance()public view returns(uint)
{
    require(msg.sender==manager);
    return address(this).balance;
}

function random()public view returns(uint)   ///////Random address generation
{
     return uint(keccak256(abi.encodePacked(block.prevrandao,block.timestamp,members.length)));
}

function selectwinner()public{
    require(msg.sender==manager);
    require(members.length>=5);
    uint r=random();
    address payable winner;
    uint index=r % members.length;  
    winner=members[index];
    winner.transfer(checkbalance());
    members=new address payable[](0);
}
}

 

