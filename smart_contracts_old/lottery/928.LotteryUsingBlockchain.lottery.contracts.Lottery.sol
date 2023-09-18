pragma solidity ^0.4.17;

contract Lottery{
    address public manager;
    address[] public players;
    
    function Lottery() public{
        manager = msg.sender;
    }
    
    function enter() public payable{
        require(msg.value > 0.01 ether);
        
        players.push(msg.sender);
    }
    
    function random() public view returns (uint){
        return uint(keccak256(block.difficulty, now, players));
    }
    
    function pickWinner() public restricted{
        uint index = random()%players.length;
        players[index].transfer(this.balance);
        // lastWinner = players[index]; If you want to display the winner
        players = new address[](0);//Empty Array
    }
    
    modifier restricted (){
        require(msg.sender == manager);
        _;  //Everything will come in place of the underscore.
    }
    
    function getPlayers() public view returns (address[]){
        return players;
    }
}
