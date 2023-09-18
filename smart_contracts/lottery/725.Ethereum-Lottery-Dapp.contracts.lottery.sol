pragma solidity ^0.4.24;

contract Lottery{
    address public manager;
    address[] public players;
    
    constructor() public {
        manager = msg.sender;
    }
    
    function enter() public payable{
        require(msg.value> 0.01 ether);
        players.push(msg.sender);
    }
    
    function random() private view returns(uint){
      return uint(keccak256(block.difficulty,now,players));
    }
    
    function pickWinner() public restricted checkLength {
        uint index = random() % (players.length);
        address winner = players[index];
        winner.transfer(address(this).balance);
        players = new address[](0);
    }
    
    
    modifier restricted() {
        require(msg.sender == manager,"Only managers allowed");
        _;
    } 
    
    modifier checkLength() {
        require(players.length >= 1, "Not enough players");
        _;
    }
    
    function getPlayers () public view returns (address[]){
        return players;
    }

    
}