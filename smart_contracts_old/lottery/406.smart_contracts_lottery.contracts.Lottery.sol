pragma solidity ^0.4.17;

contract Lottery {
    
    address public manager;
    address[] private players;
    
    constructor() public{
        manager = msg.sender;
    }
    
    function enter() public payable {
        require(msg.value > .01 ether); 
        players.push(msg.sender);
    }
    
    function random() public view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, now, players)));
    }
    
    function pickWinner() public restrected {
        uint index = random() % players.length;
        players[index].transfer(address(this).balance);
        players = new address[](0);
    }
    
    modifier restrected(){
        require(msg.sender == manager);
        _;
    }
    
    function getPlayers() public view returns(address[]){
        return players;
    }
}