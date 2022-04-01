pragma solidity ^0.4.17;

contract Lottery {
    address public manager; //to hold the manager's address to make the contract pick a winner
    address[] public players; 
   
    function Lottery() public {
        manager = msg.sender;
    }
   
    function enter() public payable{
        require(msg.value > 0.01 ether); // the amount of money sent along - automatically converts to wei
       
        players.push(msg.sender); // this is global variable that will depend on the sender
    }
   
    function random() public view returns (uint){
        return uint(keccak256(block.difficulty, now, players)); // pseuod random number generator
    }
   
    function pickWinner() public restricted { // "restricted" modifier is used to call this before running a function
        uint index = random() % players.length;
        players[index].transfer(this.balance); // the address of the player
        players = new address[](0); //to create a dynamic array with no element & also to reset the contract
    }
   
    modifier restricted() {
        require(msg.sender == manager); // verify that only mannager can run this function
        _;  // adds all the code that function has, who called this modifier
    }
   
    function getPlayers() public view returns (address[]) {
        return players;
    }
}