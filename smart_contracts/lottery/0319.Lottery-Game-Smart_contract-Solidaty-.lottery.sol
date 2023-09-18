//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract Lottery{

    address payable[] public players;
    address public manager;



    constructor(){
        manager = msg.sender;
    }

    receive () payable external{
        require(msg.value == 1 ether);// requires work as if-else.
        players.push(payable(msg.sender));
    }

    function getBalance() public view returns(uint){
        require(msg.sender == manager);
        return address(this).balance;
    }

    function random() internal view returns(uint){
       return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));// randomly generates winner.
    }


    function pickWinner() public{

        require(msg.sender == manager);
        require (players.length >= 4);
        uint r = random();
        address payable winner;
        uint index = r % players.length;// to get index instead of winner address
        winner = players[index];

        winner.transfer(getBalance());// transfer ether to the winner address


        players = new address payable[](0);//We are making size of our dynamic array zero or new.  
    }

}


