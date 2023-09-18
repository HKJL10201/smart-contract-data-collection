pragma solidity ^0.4.17;

contract Lottery {
    address public manager;
    address[] public players;
    
    // how ever creates this lottery contract must be the manager. 
    constructor() public {
        manager = msg.sender;
    }
    
    // so in order for you as a player to enter the lottery you 
    // will have to enter some amount of ether
    function enter() public payable {
        
        // this is a global function that is used for validation
        // .01 ether > this number will be automatically converted
        // into wei , notice that there is no clear message telling 
        // you that you are not meeting the minimum requirement
        require(msg.value >= .01 ether);
        players.push(msg.sender);
    }
    
    // this function will choose one of players that are participating
    // and will give this player the money to reward him of his work
    // issues : there is no random number generator in solidity 
    // it is nearly impssiable to genereate random numbers in solidity
    // but we are going to try to make that but it is not 100% random,
    // notice that we add the restricted modifier to this function
    function pickWinner() public restricted {
        
        // getting the winnir's address
        address winner = players[random() % players.length]; 
        
        // sending money to address 
        // addresses are special type of variables
        // and have methods attached to them
        // .transfer() will transfer the specified
        // wei to this variable
        // so we can access the amount of ether that 
        // exist in this contract by just using
        // this.balance
        winner.transfer(this.balance);
        
        // resetting the contract this is going 
        // to empty the array and create new empty one 
        // the zero is the initial size of the array
        players = new address[](0);
    }
    
    // helper function for generating a random number out of the 
    // out of the existing number of players
    function random() private view returns (uint) {
        
        // global sha3 function that hashes data
        // block is a global variable that contains its difficulty
        // now is gobal variabl too that is producing the time
        // the output of the sha3 function is returning a hash ( hexa dicimal )
        // so we have to convert it into an unsigned integer
        return uint(sha3(block.difficulty, now, players));
    }
    
    // this methods is just showing amount of wei 
    // that is available in this contract 
    function getAvailableWei() public view returns (uint) {
        return this.balance;
    }
    
    // function modifiers used to reduce the amount of code that you write
    // if you want to add the modifier you just add the name of the modifier 
    // before the returns keywork, the goal of using modifiers is to reduce 
    // the amount of code that we write. 
    modifier restricted() {
        
        // making sure that the manager is the only 
        // one who can call this function
        require(manager == msg.sender);
        
        // this means that the rest of code will be 
        // before this undersocre, so you can easily
        // make it before the code 
        _;
    }
    
    // a function that will return all the players with their numbers
    function getPlayers() public view returns(address[]) {
        return players;
    }
    
    // a function that will return the number of paticipants
    function getNumberOfPlayers() public view returns(uint) {
        return players.length;
    }
    
} 
