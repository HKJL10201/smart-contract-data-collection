pragma solidity ^0.4.17;

contract Lottery {
    address public manager;
    address[] public players;

    constructor() public payable {
        manager = msg.sender;
    }
    
    function enter() public payable {
        require(msg.value >= 0.001 ether);
        
        players.push(msg.sender);
    }
    
    function random() public view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, now, players)));
    }
    
    function pickWinner() public restricted {
        //require(msg.sender == manager);
        
        uint index = random() % players.length;
        players[index].transfer(address(this).balance);
        players = new address[](0);
    }
    
    modifier restricted() {
        require(msg.sender == manager);
        _;  //The other codes to be replace here
    }

    function getPlayers() public view returns (address[] memory) {
        return players;
    }
}