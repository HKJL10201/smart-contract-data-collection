pragma solidity ^0.4.25;

contract Lottery {
    address public manager;
    address[] public players;

    
    constructor  () public{
        // msg : global variable to describe who just sent a function invocation
        // data , gas , sender, value in wei
        manager =msg.sender; // the owner of the contract
    }
     
    function enter() public payable{
        require(msg.value > 0.01 ether); 
        players.push(msg.sender);
    }
    
    function random() private view returns (uint){
        // sha3 and kaccak256 are the same thing
        return uint(keccak256(block.difficulty,now,players));
    }

    function pickWinner() public restricted{
        
        uint index = random() % players.length;
        players[index].transfer(this.balance);

        players = new address[](0);// initial size of 0
    }
    
    // DRY
    modifier restricted(){
        require(msg.sender== manager);
        _;
    }

    function getPlayers() public view returns (address[]){
        return players;
    }
}