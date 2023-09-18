pragma solidity ^0.4.25;

contract Lottery    {
    
    address public manager;
    address[]  public players; 
    address public lastWinner;
    
    constructor () public{
        manager=msg.sender;
    }
    
    function enter() public payable {
       require(msg.value > .00001 ether );
        players.push(msg.sender);
        
    }
    
    function random() private view returns(uint) {
        return uint(keccak256(block.difficulty,now,players));        
    }
 
 
    function pickWinner() public  restricted{
        uint index = random() % players.length;
        lastWinner = players[index];
        players[index].transfer(this.balance);
        players = new address[](0);
    }   

    
    modifier restricted() {
        require(msg.sender == manager);
        _;
    }
    
    function getPlayers() public view returns(address[]) {
        return players;
    }
    
}