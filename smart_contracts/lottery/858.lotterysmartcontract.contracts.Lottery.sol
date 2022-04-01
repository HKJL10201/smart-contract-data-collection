// specifies the version of solidity
pragma solidity ^0.4.17; 

contract Lottery {
    //initialize manager variable of type adresss
    address public manager; 
    //initialize player array variable of type address 
    address[] public players; 

    //constructor function (function has always runs when contract is created)
    function Lottery() public { 
        //manager = to person initializing contract
        manager = msg.sender; 
    }
    //function type payable = to send ether
    function enter() public payable { 
        // used for validation, make sure ether is being sent
        require(msg.value > .01 ether); 
        players.push(msg.sender); 
    }  
    function random() private view returns (uint) {
        //pass difficulty, time and players in sha3 function to be hashed, sudorandom function
        return uint(keccak256(block.difficulty, now, players)); 
    }

    function pickWinner() public restricted {
        // returns the index of a "random" player address in the array
        uint index = random() % players.length;
        // sends total balance of contract to randomly picked address
        players[index].transfer(this.balance);
        //creates a new dyanmic address of type address
        players = new address[](0);   
    }
    // function modifier used to assure only the manager can perform action
    modifier restricted() {
        require(msg.sender == manager);
        // underscore is "replaced" by code inside any function with restricted modifier
        _;
    }   
    //returns a list of players in the contract
    function getPlayers() public view returns (address[]) {
        return players;
    }
}