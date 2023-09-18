pragma solidity 0.4.17;

contract Lottery{
    address public manager; //'manager' is a variable, 'address' is the data type
    address[] public players;//initialising a dynamic array 'players', because we want infinite number of people to join our lottery
    
    
    function Lottery() public { 
        manager = msg.sender; //msg is a global variable, meaning its an object that is always available inside our code/functions, automatically whenever we call any function or do any transaction, we don't have to do any kind of declaration for it
    }
    
    function enter() public payable{
        require(msg.value > 0.01 ether);
        players.push(msg.sender);
    }
    function random() private view returns(uint){
        return uint(keccak256(block.difficulty, now, players));
    } //pseudo random number generator
    
    function pickWinner() public restricted {
        uint index = random() % players.length; //local var 'index' to store the index of the winner inside of our 'players' array
        players[index].transfer(this.balance);//we can call '.transfer()' function/method on 'players[index]' because players[] contains addresses and addresses in solidity are like objects that have pre-definded functions/methods attached/tied to it already.
        //'this.balance' helps us 'tranfer' all the balance the current contract holds to the 'players[index]' address
        players = new address[](0); //this helps reset the contract after winner is picked and eth is transfered, we do that by emptying the 'players' array, 
        //'players = new address[](0)' this creates a new players dynamic array with size 0 initially of type address. 
        
    }
    modifier restricted() { //modifiers help us to reduce the line of code we've to write, 'restricted' is a modifier that helps us ensure that only manager can call the 'pickWinner' function
        require(msg.sender == manager);
        _; //'_' here acts as a placeholder for that functions code where we add 'restricted' keyword in the function declaration
    }
    
    function getPlayers() public view returns(address[]) {
        return players;
    }
} 