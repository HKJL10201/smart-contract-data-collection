pragma solidity ^0.4.17;
//specifies the version of solidity that our code is written with

//contract is a keyword, like class
contract Lottery {
    
    //declares all the instance variables with their type
    //storage resides in blockchain different from local variable that will get rid after the contract first executed
    address public manager;
    address[] public players;
    
    function Lottery() public {
        manager = msg.sender; //no need for declaration for msg  
    }
    
    function enter() public payable {
        require(msg.value > .01 ether); //for validation, if false the function will be terminated
        
        players.push(msg.sender);
    }
    
    function random() private view returns (uint) {
        return uint(keccak256(block.difficulty, now, players));
    }
    
    function pickWinner() public restricted {
        uint index = random() % players.length;
        address winner = players[index];
        winner.transfer(this.balance);
        players = new address[](0); //inital size of 0
    }
    
    modifier restricted() { //function modifier
        require(msg.sender == manager);
        _; //take out all the code and replace the underscore
    }
    
    function getPlayers() public view returns (address[]) {
        return players;
    }
}