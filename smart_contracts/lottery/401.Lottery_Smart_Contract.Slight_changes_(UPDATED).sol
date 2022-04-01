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

        // player must send atleast 0.1 ether in order to participate in the lottery and the owner cannot participate
        require(msg.value==0.1 ether && msg.sender!=owner," Amount must be atleast 0.1 eth ");

        // if the condition is true, then the address of that participant is added to the array
        players.push(payable(msg.sender));
        
    }

    function random()public view returns(uint){
        return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,players.length)));
    }

    function pickwinner()public{

        /* winner can be picked only by the owner of the conntact and
        only when there are atleast 10 players in the dynamic array*/

        require(msg.sender==owner," You are not the owner ");
        require(players.length>=10," There must be atleast 5 players ");

        uint r=random();
        uint index=r%players.length;

        address payable winner;
        winner=players[index];

        uint winnerprize=(getbalance()*90)/100;
        uint commision=(getbalance()*10)/100;

        //here we have transfered the winning balance to the selected winner
        winner.transfer(winnerprize);

        // and the commision to the owner's adress
        payable(owner).transfer(commision);

        //and in last, the lottery is being reset for next time
        players=new address payable[](0);
    }



}
