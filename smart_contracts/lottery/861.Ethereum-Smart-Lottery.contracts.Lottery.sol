pragma solidity ^0.4.17;

// creating a Lottery smart contract
contract Lottery {
    address public manager;
    
    // create dynamic array of type address.
    address[] public players;
    
    // msg is a global object that contains account and transaction details
    function Lottery() public {
        // get the owner address who created the contract.
        manager = msg.sender;
    }
    
    // add the users  as players, who call this function.
    function enter() public payable {
        // require is used to validate the transaction.
        // here user must pay more than 0.01 ehter
        require(msg.value > .01 ether);
        
        // push the user to players array.
        players.push(msg.sender);
    }
    
    // get the random number as winner. but in solidity we don't have any specific random number generator function.
    // make this private and view only cannot edit by other.
    function random() private view returns(uint) {
        // keccak256 is global function to generate hash value.
        // we are passing block difficulty, current time and address of players.
        // since we return uint, the hex value from keccak256 is converted to uint.
       return uint(keccak256(block.difficulty, now, players));
    }
    
    // func to pick winner from players array using random func.
    function pickWinner() public restricted {
        
        // // only manager can call this function.
        // this is done using modifier 'restricted'
        // require(msg.sender == manager);
        
        // get the remainder of random num and players length, which will to taken as index.
        uint index = random() % players.length;
        
        // get a player in that index. which will be address of user and transfer all the amount in contract balance to the winner
        players[index].transfer(this.balance);
        
        // reset the players array when winner is declared.
        // create new empty address array with initial length as (0).
        players = new address[](0);
        
    }
    
    // modifier is used to keep the code dry i.e to stop repeating some operation.
    // we can use modifier name in function defination and that function will be executed inside modifier placeholder '_;'
    modifier restricted() {
        // only manager can call this function.
        require(msg.sender == manager);
        _;
        
    }
    
    function getPlayers() public view returns(address[]) {
        return players;
    }
}

