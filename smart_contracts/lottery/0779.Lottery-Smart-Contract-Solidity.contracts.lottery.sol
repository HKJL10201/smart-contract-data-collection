// SPDX-License-Identifier:MIT

pragma solidity ^ 0.8.0;

contract Lottery
{
    address manager;
    address payable[] participants;

    constructor()
    {
        manager=msg.sender;//gloabal variable
    } 

    //special type of function run only one time allways external and payable
    //also pass arguments if u want
    receive()
    external payable
    {
        require(msg.value==1 ether);
        participants.push(payable(msg.sender));
    }

    //return total ammont in ether 
    //balance is keyweord return ammount when manger want to see 
    //only manager use this function
    function getBalance()
    public view
    returns(uint)
    {
        require(msg.sender==manager);
        return address(this).balance;
    }

    function random()
    internal view
    returns(uint)
    {
        //Built-in function
        //return random number 
        return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,participants.length)));
    }

    function selectWinner()
    public 
    {
        require(msg.sender==manager);
        require(participants.length>=3);
        uint r=random();
        address payable winner;
        uint index=r% participants.length;
        winner=participants[index];
        //transfer is keyword 
        //transfer to winner
        winner.transfer(getBalance()); 
        participants=new address payable[](0);
    }
}