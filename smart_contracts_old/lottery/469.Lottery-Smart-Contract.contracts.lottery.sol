pragma solidity ^0.4.24;

contract Lottery    {
    address public manager;
    address public lastWinner;
    address[] public players;

    constructor() public {
        manager = msg.sender;
    }

    function enter() public payable {
        require(msg.value > 0.01 ether);
        
        players.push(msg.sender);
    }

    function random() private view returns(uint) {
        //return uint(block.difficulty);
        return uint(keccak256(abi.encodePacked(block.difficulty, now,players)));
    }

    function pickWinner() public{
        uint index = random()%players.length;
        players[index].transfer(address(this).balance);
        lastWinner = players[index];
        players = new address[](0);
    }

    function getPlayers() public view returns(address[])    {
        return players;
    }

    function getPot() public view returns(uint) {
        return address(this).balance;
    }
}