pragma solidity ^0.4.17;

contract Lottery{
    address public manager;
    address[] public players;
    
    constructor() public {
        manager = msg.sender;
    }
    
    function enter() public payable {
        require(msg.value >= .01 ether);
        
        players.push(msg.sender);
    }
    
    function pickWinner() public restricted{
        require(msg.sender == manager);
        
        uint randomIndex = random() % players.length;
        players[randomIndex].transfer(this.balance);
        players = new address[](0);
    }
    
    function random() private view returns(uint){
        return uint(keccak256(block.difficulty,now,players));
    }
    
    function getPlayers() public view returns(address[]){
        return players;
    }
    
    modifier restricted(){
        require(msg.sender == manager);
        _;
    }
}
