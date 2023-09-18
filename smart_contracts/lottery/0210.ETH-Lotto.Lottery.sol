pragma solidity ^0.8.16;

contract Lottery {
    address public Admin;
    address payable[]  public players;
    
    constructor() {
        Admin = msg.sender;
    }
    
    // Only manager block
    modifier restricted() {
        require(msg.sender == Admin, "You are not the owner");
        _;
    }
    
    function enter() public payable {
        require(msg.value > .01 ether);
        players.push(payable(msg.sender));
    }
    //Pick a winning address based on a sudo-random hash converted to initergers.
    function random() private view returns (uint) {
        return uint(keccak256(abi.encode(block.difficulty, block.timestamp, players)));
    }
    //pickWinner() picks the winning address, Only manager can call this function. After each round the player array is reset to 0.
    function pickWinner() public restricted {
        uint index = random() % players.length;
        players[index].transfer(address(this).balance);
        delete players;
    }
    
    //Return all the players who entered.
    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }
}  
