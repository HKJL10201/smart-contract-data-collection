//SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.5.0 < 0.9.0;

contract GlobalVariables{

    address public owner;
    uint public sentValue;
    uint public this_moment = block.timestamp;
    uint public block_number = block.number;
    uint public difficulty = block.difficulty;
    uint public gasLimit = block.gaslimit;

    constructor(){

        owner = msg.sender;
    }

    function changeOwner() public{

        owner = msg.sender;
    }

    function sentEther() public payable{

        sentValue = msg.value;
    }

    function getBalance() public view returns(uint){

        return address(this).balance;
    }

    function howMuchGas() public view returns(uint){

        uint start = gasleft();
        uint j = 1;

        for(uint i = 1; i<20; i++){

            j *= i;
        }

        uint end = gasleft();

        return start - end;
    }

    

}