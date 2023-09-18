// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract  Lottery{
    address public manager;
    address[] public players;//dynamic array

    constructor(){
        manager = msg.sender; //msg is a global variable       
    } 

    function enter() public payable { //payable makes the sender sen some ether
        require(msg.value> .01 ether,"Require min amount of ETH(0.01) to enter");
        players.push(msg.sender);
    }

    modifier admin(){
       require(manager==msg.sender,"Only admin can use this call");// checks if the one using pickwinner is the manager
       _; //means enter all tge players
    }   

    function pickWinner() public payable admin{
        // require(manager==msg.sender);// checks if the one using pickwinner is the manager

        uint winner_ind= random() % players.length;
        address contract_address = address(this);
        payable(players[winner_ind]).transfer(contract_address.balance);
        // .transfer(this.balance);//sends all money to address 

        players = new address[](0);//creates empty array with size 0    
    }

    function getPlayers() public view admin returns(address[] memory){
        return players;
    }

    function random() private view returns (uint){//view means doesn't change any data in the contract
        return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,players)));
        // keccak256 is sha 256. block.timestamp return current timestamp. hash is hex so we turn into uint
    }


}
