// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Lottery{
    
    address payable[] public players; //Address are two types payable and normal
    address public manager;
    
    constructor(){
        manager = msg.sender;
        //players.push(payable(manager)); //default manager to the list
    }
    
     //Receive participants money and add the player to the lottery list
    receive() external payable{   //can only have one receive() method with no data
        require(msg.value == 0.1 ether, "the value should be 100000000000000000 wei only");
        require(msg.sender != manager, "Manager not allowed to participate in the lottery");
        players.push(payable(msg.sender));  
    }
  
    // how to add more options if same player pays more number of times
    
    modifier OnlyManager(){
         require(manager == msg.sender, "only manager can see balance");
         _;
    }
    
    // only Manager can see the total money
    function getTotalBalance() public OnlyManager view returns(uint){
       
        return address(this).balance;
    }
    
    //generate a random number to pick the winner, 
    //The approach is get some random number and do module devision by the number of participants hence 
    //it's alwasy less than or equal to num of participantas and then take the coorlation as index of palyers array
    
    function getRandomnum() public view returns(uint){
       return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }
    
    // only manager can pick the winner
       //Transfer total money to winner and only manager can do it
    
    function selectWinner() public OnlyManager{
        require(players.length == 3);
       // uint totalBal = getTotalBalance();
        uint randomNum  = getRandomnum();
        uint indexNum = randomNum % players.length;
        uint totalbal = getTotalBalance();
        uint managerfee = (totalbal * 10)/100;
        uint winneramt = (totalbal * 90)/100;
        
        players[indexNum].transfer(winneramt);
        payable(manager).transfer(managerfee);
        //return players[indexNum];
        
        players = new address payable[](0); //resetting the lottery by re-define the dynamic array
    }
   
    
}