//SPDX-License-Identifier: GPL-3.0;
pragma solidity ^0.8.0;

contract Lottery{
    //manager have almost every power
    //can see the balance
    //declare the winner of lottery
    //the address who delploy the contract
    address public manager;

    //this code is executed only once when contract is delployed
    constructor(){
        manager = msg.sender;
    }

    //list of address of all participlants
    address payable[] public participants;

    //returns the contract account balance sent by the participants 
    //at last the winner will be given the amount return by this function
    function checkBal() public view returns(uint){
        require(msg.sender == manager);
        return address(this).balance;
    }

    //receives amount(ether) from the participants to the contract account
    receive() external payable{
        require(msg.value == 1 ether);
        participants.push(payable(msg.sender));
    }

    //generates a random value
    function random() private view returns(uint){
        return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,participants.length)));
    }

    //declares the winner using the above random value modulo number of participants
    //all the amount in contract address is transfered to the winner
    function winner() public {
        require(msg.sender == manager);
        require(participants.length>=2);
        uint ind = random()%participants.length;
        participants[ind].transfer(checkBal());
    }
}
