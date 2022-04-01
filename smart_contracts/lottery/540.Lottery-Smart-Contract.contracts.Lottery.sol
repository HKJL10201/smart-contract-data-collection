
pragma solidity ^0.4.17;
//solidity version

contract Lottery{  //contract name declearation
    address public manager;
    address[] public players;
    
    
    function Lottery() public{
        manager = msg.sender;
    }
    function enter() public payable{
        require(msg.value > .01 ether); //entering the pool or contract with .01 ether 
        players.push(msg.sender);   
    }
    function random() private view returns(uint){  // Pseudo random number generator
        return uint(keccak256(block.difficulty, now, players));
    }
    function pickWinner() public restricted{
        uint index = random() % players.length; //Selecting a winner in the contract or pool
        players[index].transfer(this.balance);  //Transfering the total ether to the winner
        players = new address[](0);  //Resetting the state of our lottery contract after picking a winner, for new new lottery
    }
    
    modifier restricted(){  //declearation of new function modifier
        require(msg.sender == manager);  
        _;
    }
    
    function getPlayers() public view returns(address[]){  //returning a list or numbeers of players who enter the contract
        return players;
    }
}









