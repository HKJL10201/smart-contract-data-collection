pragma solidity ^0.4.17;

contract Lottery {
    //public means the varriable can be easily accessed
    //The value of manager needs to be public since it will need to
    //be accessed through a front end JS app eventually
    //What should we instantiate this with?
    //The value needs to be equal to whatever address deploys the contract
    address public manager;

    //Lets declare a dynamic array that only contains addresses
    //Lets make it public so everyone can see the participants
    address[] public players;
    
    function Lottery() public {
        manager = msg.sender;
    }
    
    function enter() public payable {
        //We need the participants to enter with a non-zero
        //value of ether. To make sure, we use `require` which is a Global fn like `msg`
        //which validates that some requirement has been fulfilled before execting any
        //code below it, otherwise the entire fn is immediately exited and no change is made
        //to the contract. If it evaluates to true, the code continues to execute thereon.
        //ether converts the number before it to wei
        require(msg.value > .01 ether);

        //Whatever address calls this fn, we enter them in players array
        //using `msg` global variable
        players.push(msg.sender);
    }
    
    function random() private view returns (uint) {
        //we can use versions of SHA3 algorithm like sha3() or keccack256()
        //which are global variables
        //block: global variable
        //now: global variable
        //keccak will return a hexadecimal no so we need to make it a uint
        return uint(keccak256(block.difficulty, now, players));
    }
    
    function pickWinner() public restricted {
        //index will be a number between 0 and players.length
        uint index = random() % players.length;
        //Lets transfer all of the balance to the winner.
        //this: instance of the current contract
        //balance: property that represents all the money in the contract
        players[index].transfer(this.balance);
        //Lets reset the players array to empty so we set the state back to what
        //in the beginning. This way,  we can deploy the contract once and let it run indefinitely
        players = new address[](0);
    }

    //modifier is used to reduce code duplication
    //Lets say we define a fn modifier using the keyword modifier with a name restricted
    //Now, if we can add the keyword restricted to any other fn declaration, then whenever the fn is called, they would
    //first run the contents of the modifier restricted
    //The _ in the modifier restricted means that once the fn that is declared with the restricted keyword would run rest
    //of its code once it runs the the lines in restricted
    modifier restricted() {
        //to make sure that only the manager can call this fn
        require(msg.sender == manager);
        _;
    }
    
    function getPlayers() public view returns (address[]) {
        return players;
    }
}   