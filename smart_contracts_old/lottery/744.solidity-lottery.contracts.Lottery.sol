pragma solidity ^0.4.0;

contract Lottery {
    address public manager;
    address[] public players;
    
    constructor() public {
        manager = msg.sender;
    }
    
    modifier restricted() {
        require(msg.sender == manager);
        _;
    }
    
    function enter() public payable {
        require(msg.value > .01 ether);
        players.push(msg.sender);
    }
    
    // Recognized security concern: for sake of tutorial only
    function random() private view returns (uint) {
        return uint(keccak256(block.difficulty, block.timestamp, players));
    }
    
    function pickWinner() public restricted {
        uint index = random() % players.length;
        players[index].transfer(address(this).balance);
        players = new address[](0);
    }
    
    function getPlayers() public view returns (address[]) {
        return players;
    }
    
}