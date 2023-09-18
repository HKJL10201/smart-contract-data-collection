// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract lottery
{
    address payable[] public participtant;
    address public manager;

    constructor()
    {
        manager = msg.sender;
    }

    receive() external payable
    {
        require(msg.value == 0.04 ether);
        participtant.push(payable(msg.sender));
    }

    function getbalance() public view returns(uint)
    {
        require(msg.sender == manager);
        return address(this).balance;
    }

    function random() public view returns(uint)
    {
        return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,participtant.length)));
    }

    function randomindex() public {
        require(msg.sender == manager);
        uint index =  random()%participtant.length;
        address payable winner =  participtant[index];
        winner.transfer(getbalance());
        participtant = new address payable[](0); //this will reset our participtant array in the end after sending the balance to our winner account
    }
}