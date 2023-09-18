pragma solidity ^0.4.17;

//Lottery game, where players may join and the address of the deployer is the manager that is able to randomly draw a winner and send winnings
contract Lottery {
    
    //address of the manager (one who decides winner and sends funds)
    address public manager;
    
    //array of addresses of all the players
    address[] public players;
   
    
    function Lottery() public {
        
        manager = msg.sender;
   }
   
   //make sure the person sending the tx is the manager
   modifier restricted() {
        require(manager == msg.sender);
        _;
   }
   
   //enter a new player into the lottery
    function enter() public payable {
        require(msg.value > 0.01 ether);
        players.push(msg.sender);
    }
    
    //generate a pseudo-random number (needs improvement)
    function random() private view returns (uint) {
        return uint(keccak256(block.difficulty, now, players));
    }
    
    //pick winner index and send them the current balanace
    function pickWinner() public restricted () {
    
        //pick winner and send balance to them
        uint winnerIndex = random() % players.length;
        players[winnerIndex].transfer(this.balance);
        
        //reset contract variables
        players = new address[](0);
    }
    
    //get a list of all the players
    function getPlayers() public view returns(address[]){
        return players;
    }
}
