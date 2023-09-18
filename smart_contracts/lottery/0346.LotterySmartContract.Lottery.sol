//SPDX-License-Identifier: GPL-3.0

// telling the version on which we are creating the smart contract
pragma solidity >=0.5.0 <0.9.0;

// Creating a Contract Lottery 
contract Lottery{

// Taking players array of address type and make it payabale so that they can transfer and receive ethers
//Players is a dynamic array that is storing the address of the players that is playing the game
    address payable[] public players;
// creating a manager variable of address type   
    address public manager;

    constructor(){
// Manager is the one who has all the permission of the smart contract
//manager = msg.sender means manager is the owner , he is sending the message means it is storing the 
//address who is deploying the project that's why we are creating constructor for it
// A smart contract must have only one cunstructor       
        manager = msg.sender;
    }

// Creating a receive function of payable type
    receive () payable external{
// Require is used in place of if condition 
        require(msg.value == 0.1 ether);
        players.push(payable(msg.sender));
// any player can participate in this lottery game if and only if it has 0.1 ether
    }

// Creating aa get balance function to check the balance of the manager
    function getBalance() public view returns(uint){
        require(msg.sender == manager);
        return address(this).balance;
    }
// creating a random function to pick any random value
    function random() internal view returns(uint){
       return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }

// PickWinner function will pick the value 
    function pickWinner() public{
// to play the game we have require to deploy the game on manager address
// Player array length must be minimum of three 
        require(msg.sender == manager);
        require (players.length >= 3);
// Taking r as a unint value that is picked by the random function 
        uint r = random();
        address payable winner;
//  creating a winner variable of payable type

// The algorithm we are using says that it will pick a random value between 0 to r-1 
//and taking it in a index variable      
    
        uint index = r % players.length;
// and the winnner will be someone who will give the value of the players[index]
        winner = players[index];
// we are transfering all the balance to the winner variable which is of address type
        winner.transfer(getBalance());

// we are doing array length as zero so that this program won't run again and we have to restart the program 
//if we want to play the game again
        players = new address payable[](0);
    }

}


