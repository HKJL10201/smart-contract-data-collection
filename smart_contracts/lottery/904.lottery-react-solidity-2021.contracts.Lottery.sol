//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0 <0.9.0;
 

contract Lottery{

    // declaring the state variables
    address payable[] public players; //dynamic array of type address payable
    address public manager; 
    uint public minPlayers = 2;
    // declaring the constructor
    constructor(){
        //Initializing the owner to the address that deploys the contract
        manager = msg.sender; 
        
        //Automatically add the manager to the lottery
        //players.push(payable(manager));    
    }

    event PickWinnerEvent(address payable winner, uint prize);
    
    // declaring the receive() function that is necessary to receive ETH
    receive() external payable{
        // each player sends exactly 0.1 ETH 
        require(msg.value == 0.1 ether);
        
        //The manager cannot pacticiate in the Lottery
        require(msg.sender != manager,"The manager cannot pacticiate in the Lottery");
        
        // appending the player to the players array
        players.push(payable(msg.sender));
    }
    
    // returning the contract's balance in wei
    function getBalance() public view returns(uint){
        // only the manager is allowed to call it
        require(msg.sender == manager);
        return address(this).balance;
    }
    
    // helper function that returns a big random integer
    function random() internal view returns(uint){
       return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }
    
    
    // selecting the winner
    function pickWinner() public{
      //Only the manager can pick a winner if there are at least 2 players in the lottery
        if (players.length < minPlayers) {
            require(msg.sender == manager);   
        }
        
        //At least 2 players to pick the winner and end the game
        require (players.length >= minPlayers);
        
        uint r = random();
        address payable winner;
        
        // computing a random index of the array
        uint index = r % players.length;
    
        winner = players[index]; // this is the winner
        
        uint managerFee = getBalance()*10/100;
        uint winnerPrize = getBalance()*90/100;
        
        // transferring the 90% balance to the winner
        winner.transfer(winnerPrize);
        
        payable(manager).transfer(managerFee);

        emit PickWinnerEvent(winner, winnerPrize);

        // resetting the lottery for the next round
        players = new address payable[](0);
    }
    
    function getPlayers() public view returns(address payable[] memory) {
        return players;
    }

}