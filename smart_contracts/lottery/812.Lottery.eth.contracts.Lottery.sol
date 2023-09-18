pragma solidity ^0.4.17;
// linter warnings (red underline) about pragma version can igonored!

// msg = the object data of the incoming transaction 
contract Lottery {
    address public manager;
    address[] public players;
    
    function Lottery() public {
        manager = msg.sender; // address from the caller account
    }
    
    // enter the lottery 
    function enter() public payable {  //if the func expects to receive eth, it needs to be marked 'payable'
        require(msg.value > 1 ether ); 
        // add new entrty to the array
        players.push(msg.sender);
    }
    
    function random() private view returns (uint256) {
        // 1. Current Block difficulty
        // 2. Current time 
        // 3. Addresses of players 
        //takes hash and converts to unsigned int 
        return uint(sha3(block.difficulty, now, players)); // 'block' + 'now' are global variables
    }
    
    function pickWinner() public whatever {
        require( msg.sender ==  manager); // makes sure only the manger can pick a winer
        uint index = random() % players.length;
        // players[index] = 0x523652763b23223x23d2
        
        // sends the winnings 
        players[index].transfer(this.balance); // 'this' is reference to currenr Contract
        players = new address[](0); // creates a new dynamic array with a length of 0
    }
    
    modifier whatever() {
        require(msg.sender == manager ); // makes sure only the manger can pick a winer
        _; // 
    }
    
    
    function  listPlayers () public view returns (address[]){
        return players;
    }
}