//SPDX-License-Identifier:GPL-3.0;

pragma solidity 0.8.0;

contract lottery{

    // this dynamic array will store the address of the participants
    address payable[]public players;
    address public owner;

    constructor(){
        // initializing the owner at the time of the contract deployement
        owner=msg.sender;
    }

    function getbalance()public view returns(uint){

        // Balance can be checked only by the owner of the conntact

        require(msg.sender==owner,"You are not the owner");
        return address(this).balance;
    }

    receive()external payable{

        // player must send atleast 0.1 ether in order to participate in the lottery
        require(msg.value==0.1 ether," Amount must be atleast 0.1 eth ");

        // if the condition is true, then the address of that participant is added to the array
        players.push(payable(msg.sender));
    }

    function random()public view returns(uint){
        return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,players.length)));
    }

    function pickwinner()public{

        /* winner can be picked only by the owner of the conntact and
        only when there are atleast 5 players in the dynamic array*/

        require(msg.sender==owner," You are not the owner ");
        require(players.length>=5," There must be atleast 5 players ");

        uint r=random();
        uint index=r%players.length;

        address payable winner;
        winner=players[index];

        //here we have transfered all the winning balance to the selected winner
        winner.transfer(getbalance());

        //and in last, the lottery is being reset for next time
        players=new address payable[](0);
    }



}