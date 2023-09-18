pragma solidity ^0.4.17;

contract Lottery {
    address public manager;
    address[] public players;
    
    constructor () public {
        manager = msg.sender;
    }
    
    function enter() public payable {
        require(msg.value >= 0.01 ether);
        players.push(msg.sender);
    }
    
    // our 'random' function will use (i)current block difficulty, (ii) current time (iii) number of
    // addresses entered. Technically all these can be known ahead of time and therefore it can be gamed.
        // sha3() is a global function to solidity, no need to import it
        // sha256 and keccak256 are the same thing, just different names 
        // 'block' is also a global variable with attribute difficulty for the current block difficulty
        // 'now' is a global variable of the current time 
        // uint() is also a function to turn a hash into a number.
        
    function random() private view returns (uint) {
        return uint(keccak256(block.difficulty, now, players));
    }
    
    
    function pickWinner() public myModifier {
        uint index = random() % players.length;
        players[index].transfer(this.balance);
        players = new address[](0);
    }
    
    modifier myModifier() {
        require(msg.sender == manager);
        _;
        // why the underscore? because we imagine all the code of any function that uses this 'require'
        // statement goes where the underscore goes. Also note how in the pickWinner() function, we
        // add the name of our modifier 'myModifier' to the end of the function. The point of this is to
        // avoid DRY. 
    }
    
    
    function getPlayers() public view returns (address[]){
        return players;
        // this function is for testing in mocha and isn't required by the contract 
    }
    

    
}