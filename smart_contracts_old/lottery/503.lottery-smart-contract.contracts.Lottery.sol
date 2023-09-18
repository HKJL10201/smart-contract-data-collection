pragma solidity ^0.4.17;

contract Lottery {
    address public manager;
    address[] public players;
    
    constructor() public {
        manager = msg.sender;
    }
    
    function enter() public payable {
        require(msg.value > 0.01 ether);
        
        players.push(msg.sender);
    }
    
    //don't have access to a random number generator function...
    function random() private view returns (uint) {
        return uint(keccak256(block.difficulty, now, players));
    }
    
    function pickWinner() public restricted {
        // pick winner and transfer money
        uint index = random() % players.length;
        players[index].transfer(this.balance);
        
        //reset lottery
        players = new address[](0);
    }
    
    function getPlayers() public view returns (address[]) {
        return players;
    }
    
    modifier restricted() {
        require(msg.sender == manager);
        _;
    }
}