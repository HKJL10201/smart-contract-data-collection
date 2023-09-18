pragma solidity ^0.4.19;

contract Lottery{
    // address of players who created the contract
    address public manager;
    
    //player - A dynamic array of addresses of people who have entered
    address[] public players;
    
    function Lottery() public {     
        manager = msg.sender;
    }
     
     // Enter a player into the lottery
    function enter() public payable{
        require(msg.value > .01 ether);
        players.push(msg.sender);
    } 
    
    // Creates a random number
     function random() private view returns (uint){
        return uint(keccak256(block.difficulty, now, players));
     }
     
    // pickWinner Randomly picks a winner and sends them the prize pool
     function pickWinner() public restricted{
        uint index = random() % players.length; 
        // Grabs a random address from the arary and sends ALL the ether from the contract to the user
        players[index].transfer(this.balance);
        
        // creates a new dynamic array called address
        players = new address[](0);
     }
     // A modifer that requires the manager
     modifier restricted(){
         require(msg.sender == manager);
         _;
     }
     
     function getPlayers() public view returns (address[]){
         return players;
     }
     
     
}