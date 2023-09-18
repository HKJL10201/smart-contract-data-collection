// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract lottery{
    address public manager;  //variable to hold the address of the smart contract deployer
    address payable[] public participants;  //array to hold the address of all the participants

    constructor(){
        manager = msg.sender; // assigning the address of the deployer in the manager
    }


//function to recieve the lottery ticket amount from the participants
    function recieve() external payable {
        require(msg.value == 1 ether , "ether is not enough" ); //the price of entering the lottery contest is 1 ether
        participants.push(payable(msg.sender));  // pushing the address of the participant in the participant array
    }


//function to return the balance of the contract which only the manager can call

    function getBalance() public view returns (uint){    
        require(msg.sender== manager,"only the manager is allow to call this function");
        return address(this).balance;
    }


//function to generate ab random value

    function random() private view returns(uint){  
        return uint (keccak256(abi.encodePacked(block.difficulty, block.timestamp, participants.length)));
    }


//function to find a winner randomly and transferring the contract balance 
//into its wallet and only manager can call this function

    function selectWinner() public { 
        require(msg.sender== manager,"only the manager is allow to call this function");
        require(participants.length >= 3, "minimum number of partcipants should be 3");  //the minimum number of the participants is required to be 3
        uint r=random();
        address payable winner;
        uint index = r%participants.length;
        winner = participants[index];
        winner.transfer(getBalance());  // transferring the wallet balance into the winner's wallet
        participants = new address payable[](0); // after choosing a winner all the participants will be removed
    }
}
