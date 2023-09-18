pragma solidity ^0.4.17;

contract Lottery {
    address public manager;
    address[] public players;
    
    function Lottery() public {
        // msg is a global var available on all calls and transactions
        manager = msg.sender;
    }
    
    function enter() public payable {
        require(msg.value >= .01 ether);
        players.push(msg.sender);
    }
    
    function random() private view returns (uint) {
        return uint(keccak256(block.difficulty, now, players));
    }
    
    function pickWinner() public restricted {
        uint index = random() % players.length;
        // this is a reference to the current contract
        // which has a balance property
        players[index].transfer(this.balance);
        // create a new array of address with an initial length of 0
        players = new address[](0);
    }
    
    // the '_;' is a target for where the code contained in the function
    // calling the modifier will be or can be thought of as being added 
    modifier restricted(){
         require(msg.sender == manager);
         _;
    }
    
    function getPlayers() public view returns (address[]) {
        return players;
    }
}
