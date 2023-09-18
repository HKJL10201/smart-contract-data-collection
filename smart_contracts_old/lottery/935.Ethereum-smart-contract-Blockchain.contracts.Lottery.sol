pragma solidity ^0.4.25;

contract Lottery {
    
    address public manager;
    
    address[] public players;
    
    constructor() public {
        
        manager = msg.sender;
        
    }
    
    function enter() public payable {
        require(msg.value > .01 ether);
        players.push(msg.sender);
    }
    
    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty,now,players)));
    }
    
    function pickWinner() public restricted {
        
        //this ensures that only the manager can call this method
        require(msg.sender == manager);
        
        uint index = random() % players.length;
        players[index].transfer(address(this).balance);
        
        // reseting players array after picking a winner with 0 elements
        players = new address[](0);
    }
     
    modifier restricted() {
         
        require(msg.sender == manager);
        _;
         //underscore is a placeholder where all the code will be placed.
    }
     
    function getPlayers() public view returns (address[] memory) {
        return players;
    }
     
}
