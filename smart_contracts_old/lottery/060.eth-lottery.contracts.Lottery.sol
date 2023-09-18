pragma solidity ^0.4.17;

contract Lottery {
    address public manager;
    address[] public players;
    
    //Constructor
    function Lottery() public {
        manager = msg.sender;
    }
    
    function enter() public payable {
        require(msg.value > .01 ether);
        
        players.push(msg.sender); 
    }
    
    // Internal kind of random number generator
    function random() private view returns (uint) {
        
        return uint(keccak256(block.difficulty, now,  players));
    }
    
    function pickWinner() public restricted {
        
        address playerAddress = this;
        uint index = random() % players.length;
        
        players[index].transfer(playerAddress.balance);
        players = new address[](0);
    }
    
    modifier restricted() {
        require(msg.sender == manager);
        _;
    }
    
    function getPlayers() public view returns (address[]) {
        return players;
    }
}